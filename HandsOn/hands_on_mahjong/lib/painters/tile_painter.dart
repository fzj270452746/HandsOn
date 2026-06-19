import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../utils/constants.dart';

class TilePainter extends CustomPainter {
  final MahjongTile tile;
  final double revealProgress; // 0.0 hidden → 1.0 fully revealed
  final bool isFlipped;
  final bool isLocked;
  final bool isSelected;
  final bool isWrong;
  final TileModifier modifier;

  TilePainter({
    required this.tile,
    required this.revealProgress,
    required this.isFlipped,
    required this.isLocked,
    this.isSelected = false,
    this.isWrong = false,
    this.modifier = TileModifier.none,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(AppSizes.tileRadius));

    if (isFlipped) {
      _drawFlippedFace(canvas, size, rRect);
      return;
    }

    // 牌背
    _drawTileBack(canvas, size, rRect);

    if (revealProgress > 0.01) {
      // 在图层上绘制牌面内容，受透明度控制
      canvas.saveLayer(rect, Paint()..color = Color.fromARGB((revealProgress * 255).round(), 255, 255, 255));
      _drawTileFace(canvas, size, rRect);
      canvas.restore();
    }

    // 锁定角标
    if (isLocked) _drawLockBadge(canvas, size);

    // 特殊牌角标（左下角）
    if (modifier != TileModifier.none) _drawModifierBadge(canvas, size);

    // 选中高亮
    if (isSelected) {
      final highlightPaint = Paint()
        ..color = AppColors.targetHint.withAlpha(80)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rRect, highlightPaint);
    }

    // 错误闪红
    if (isWrong) {
      final wrongPaint = Paint()
        ..color = AppColors.wrongFeedback.withAlpha(100)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rRect, wrongPaint);
    }
  }

  void _drawTileBack(Canvas canvas, Size size, RRect rRect) {
    final w = size.width;
    final h = size.height;

    // Base fill — slightly brighter than before for contrast vs table
    canvas.drawRRect(rRect, Paint()..color = const Color(0xFF1E4A4A));

    // Woven diagonal texture
    final patternPaint = Paint()
      ..color = const Color(0xFF266060)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const spacing = 8.0;
    canvas.save();
    canvas.clipRRect(rRect);
    for (double i = -h; i < w + h; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + h, h), patternPaint);
      canvas.drawLine(Offset(i + h, 0), Offset(i, h), patternPaint);
    }
    canvas.restore();

    // Bright border so each tile is clearly distinct on the dark table
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFF4A9090)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawTileFace(Canvas canvas, Size size, RRect rRect) {
    final w = size.width;
    final h = size.height;

    // 白色底面
    canvas.drawRRect(rRect, Paint()..color = AppColors.tileFace);

    // 轻微纸质噪声
    final noisePaint = Paint()..color = const Color(0x0A000000);
    final rng = Random(tile.hashCode);
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h),
        rng.nextDouble() * 1.5,
        noisePaint,
      );
    }

    switch (tile.suit) {
      case TileSuit.wan:
        _drawWan(canvas, size);
      case TileSuit.tiao:
        _drawTiao(canvas, size);
      case TileSuit.tong:
        _drawTong(canvas, size);
    }

    // 边框
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFFD5CDBB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawWan(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final color = AppColors.wanColor;

    // 横纹（数字+4条，最多11条）
    final lineCount = tile.number + 4;
    final lineSpacing = h / (lineCount + 1);
    final linePaint = Paint()
      ..color = color.withAlpha(60)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= lineCount; i++) {
      final y = lineSpacing * i;
      canvas.drawLine(Offset(8, y), Offset(w - 8, y), linePaint);
    }

    // 中央"万"字
    final wanPainter = TextPainter(
      text: TextSpan(
        text: '万',
        style: TextStyle(
          color: color,
          fontSize: h * 0.36,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    wanPainter.paint(
      canvas,
      Offset((w - wanPainter.width) / 2, (h - wanPainter.height) / 2 + 4),
    );

    // 左上角数字
    _drawCornerNumber(canvas, size, color);
  }

  void _drawTiao(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final color = AppColors.tiaoColor;
    final count = tile.number;

    // 竖条排列
    final colCount = count <= 3 ? count : (count <= 6 ? 3 : 3);
    final rowCount = (count / colCount).ceil();
    final stripW = (w - 20) / colCount - 4;
    final stripH = (h - 24) / rowCount - 6;

    final stripPaint = Paint()..color = color;

    int drawn = 0;
    for (int r = 0; r < rowCount && drawn < count; r++) {
      for (int c = 0; c < colCount && drawn < count; c++) {
        final x = 10 + c * (stripW + 4);
        final y = 12 + r * (stripH + 6);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, stripW, stripH),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, stripPaint);

        // 竹节纹（每条中间横线）
        final nodeY = y + stripH / 2;
        canvas.drawLine(
          Offset(x + 2, nodeY),
          Offset(x + stripW - 2, nodeY),
          Paint()
            ..color = AppColors.tileFace
            ..strokeWidth = 1.5,
        );
        drawn++;
      }
    }
    _drawCornerNumber(canvas, size, color);
  }

  void _drawTong(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final color = AppColors.tongColor;
    final count = tile.number;

    final positions = _dotPositions(count, w, h);
    final r = min(w, h) / (count <= 1 ? 4.5 : count <= 4 ? 6 : 8);

    for (final pos in positions) {
      // 外圆
      canvas.drawCircle(pos, r, Paint()..color = color);
      // 内圆（铜钱中孔）
      canvas.drawCircle(pos, r * 0.45, Paint()..color = AppColors.tileFace);
      // 外环
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = color.withAlpha(120)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    _drawCornerNumber(canvas, size, color);
  }

  List<Offset> _dotPositions(int count, double w, double h) {
    final cx = w / 2;
    final cy = h / 2;
    final step = min(w, h) / 3.5;

    switch (count) {
      case 1:
        return [Offset(cx, cy)];
      case 2:
        return [Offset(cx, cy - step * 0.6), Offset(cx, cy + step * 0.6)];
      case 3:
        return [Offset(cx, cy - step * 0.8), Offset(cx, cy), Offset(cx, cy + step * 0.8)];
      case 4:
        return [
          Offset(cx - step * 0.5, cy - step * 0.5),
          Offset(cx + step * 0.5, cy - step * 0.5),
          Offset(cx - step * 0.5, cy + step * 0.5),
          Offset(cx + step * 0.5, cy + step * 0.5),
        ];
      case 5:
        return [
          Offset(cx - step * 0.5, cy - step * 0.6),
          Offset(cx + step * 0.5, cy - step * 0.6),
          Offset(cx, cy),
          Offset(cx - step * 0.5, cy + step * 0.6),
          Offset(cx + step * 0.5, cy + step * 0.6),
        ];
      case 6:
        return [
          for (int r = 0; r < 3; r++)
            for (int c = 0; c < 2; c++)
              Offset(cx + (c - 0.5) * step, cy + (r - 1) * step * 0.7),
        ];
      case 7:
        final base = _dotPositions(6, w, h);
        return [...base, Offset(cx, cy - step * 1.1)];
      case 8:
        return [
          for (int r = 0; r < 4; r++)
            for (int c = 0; c < 2; c++)
              Offset(cx + (c - 0.5) * step, cy + (r - 1.5) * step * 0.6),
        ];
      case 9:
        return [
          for (int r = 0; r < 3; r++)
            for (int c = 0; c < 3; c++)
              Offset(cx + (c - 1) * step * 0.65, cy + (r - 1) * step * 0.65),
        ];
      default:
        return [Offset(cx, cy)];
    }
  }

  void _drawCornerNumber(Canvas canvas, Size size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: '${tile.number}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(5, 3));
  }

  void _drawModifierBadge(Canvas canvas, Size size) {
    // Bottom-left corner badge
    final color = switch (modifier) {
      TileModifier.iron   => const Color(0xFF95A5A6), // grey
      TileModifier.frozen => const Color(0xFF5DADE2), // ice blue
      TileModifier.bomb   => const Color(0xFFE74C3C), // red
      TileModifier.none   => Colors.transparent,
    };
    final label = switch (modifier) {
      TileModifier.iron   => '⚙',
      TileModifier.frozen => '❄',
      TileModifier.bomb   => '💣',
      TileModifier.none   => '',
    };

    canvas.drawCircle(Offset(10, size.height - 10), 7, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(6, size.height - 14));
  }

  void _drawLockBadge(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.targetHint;
    canvas.drawCircle(Offset(size.width - 10, 10), 7, paint);
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '🔒',
        style: TextStyle(fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, Offset(size.width - 14, 5));
  }

  void _drawFlippedFace(Canvas canvas, Size size, RRect rRect) {
    canvas.drawRRect(rRect, Paint()..color = AppColors.tileFace);
    _drawTileFace(canvas, size, rRect);
    // 正确翻开的绿色角标
    final checkPaint = Paint()..color = AppColors.correctFeedback.withAlpha(180);
    canvas.drawCircle(Offset(size.width - 10, 10), 7, checkPaint);
  }

  @override
  bool shouldRepaint(TilePainter old) =>
      old.revealProgress != revealProgress ||
      old.isFlipped != isFlipped ||
      old.isLocked != isLocked ||
      old.isSelected != isSelected ||
      old.isWrong != isWrong ||
      old.modifier != modifier;
}
