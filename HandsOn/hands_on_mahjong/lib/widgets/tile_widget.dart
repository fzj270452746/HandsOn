import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../painters/tile_painter.dart';
import '../utils/constants.dart';

class TileWidget extends StatefulWidget {
  final BoardTile boardTile;
  final int index;
  final bool isWrong;
  final bool scrubBlocked; // budget exhausted, tile cannot be scrubbed
  final void Function(int index, double delta) onScrub;
  final void Function(int index) onFlip;
  final void Function(int index) onLock;

  const TileWidget({
    super.key,
    required this.boardTile,
    required this.index,
    required this.onScrub,
    required this.onFlip,
    required this.onLock,
    this.isWrong = false,
    this.scrubBlocked = false,
  });

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget> with SingleTickerProviderStateMixin {
  bool _pressing = false;
  Offset? _lastScrubPos;

  // Two-finger lock: track pointer count and hold timer
  int _pointerCount = 0;
  Timer? _lockHoldTimer;
  bool _lockTriggered = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TileWidget old) {
    super.didUpdateWidget(old);
    if (widget.boardTile.isFlipped && !old.boardTile.isFlipped) {
      _flipController.forward();
    }
  }

  @override
  void dispose() {
    _lockHoldTimer?.cancel();
    _flipController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerCount++;
    _lockTriggered = false;
    if (_pointerCount >= 2) {
      // Two fingers detected — start 1.5s hold timer for lock
      _lockHoldTimer?.cancel();
      _lockHoldTimer = Timer(const Duration(milliseconds: 1500), () {
        if (_pointerCount >= 2 && !widget.boardTile.isFlipped) {
          _lockTriggered = true;
          widget.onLock(widget.index);
        }
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerCount = (_pointerCount - 1).clamp(0, 10);
    if (_pointerCount < 2) {
      _lockHoldTimer?.cancel();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerCount = (_pointerCount - 1).clamp(0, 10);
    if (_pointerCount < 2) {
      _lockHoldTimer?.cancel();
    }
  }

  void _handlePanStart(DragStartDetails d) {
    _pressing = true;
    _lastScrubPos = d.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (!_pressing || widget.boardTile.isFlipped) return;
    if (_pointerCount >= 2) return; // two-finger gesture reserved for lock
    final delta = d.localPosition - (_lastScrubPos ?? d.localPosition);
    final dist = delta.distance;
    if (dist > 1) {
      final speed = dist / 16.0;
      final increment = speed < 3 ? 0.012 : 0.006;
      widget.onScrub(widget.index, increment);
    }
    _lastScrubPos = d.localPosition;
  }

  void _handlePanEnd(DragEndDetails d) {
    _pressing = false;
    _lastScrubPos = null;
  }

  void _handleTap() {
    if (_lockTriggered) return;
    if (!widget.boardTile.isFlipped) {
      widget.onFlip(widget.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressing ? 1.05 : 1.0;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, _) {
          final t = _flipAnimation.value; // 0→1
          // Front half (0~0.5): rotate 0→π/2; back half (0.5~1): rotate -π/2→0
          // This avoids the mirrored-content problem: each face only ever
          // spans ±90°, so neither ever goes past the mirror point.
          final showFront = t >= 0.5;
          final angle = showFront ? (t - 1.0) * 3.14159 : t * 3.14159;

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle);

          // When showing the front face we pass isFlipped=true to TilePainter
          // so it draws the revealed tile art; otherwise draw the back.
          final paintIsFlipped = showFront;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 100),
              child: GestureDetector(
                onTap: _handleTap,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: AppSizes.tileWidth,
                  height: AppSizes.tileHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.tileRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(_pressing ? 160 : 110),
                        blurRadius: _pressing ? 14 : 8,
                        spreadRadius: _pressing ? 1 : 0,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(AppSizes.tileWidth, AppSizes.tileHeight),
                        painter: TilePainter(
                          tile: widget.boardTile.tile,
                          revealProgress: widget.boardTile.revealProgress,
                          isFlipped: paintIsFlipped,
                          isLocked: widget.boardTile.isLocked,
                          isWrong: widget.isWrong,
                          modifier: widget.boardTile.modifier,
                        ),
                      ),
                      // Scrub-blocked overlay: dim the tile with a red tint
                      if (widget.scrubBlocked && !widget.boardTile.isFlipped)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0x55000000),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.tileRadius),
                              border: Border.all(
                                color: const Color(0x88E74C3C),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.touch_app_outlined,
                                color: Color(0xAAE74C3C),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
