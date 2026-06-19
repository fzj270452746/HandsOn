import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../models/level.dart';
import '../models/tile.dart';
import '../services/haptic_service.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';
import '../widgets/tile_widget.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final LevelConfig config;
  final bool isDaily;

  const GameScreen({super.key, required this.config, this.isDaily = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState _gs;
  final Set<int> _wrongAnimating = {};
  Timer? _tenpaiTimer;
  Timer? _countdownTimer;
  int _timeRemaining = 0;

  late AnimationController _tenpaiGlowCtrl;
  late Animation<double> _tenpaiGlow;
  late AnimationController _comboCtrl;
  late Animation<double> _comboScale;

  @override
  void initState() {
    super.initState();
    _gs = GameState();
    _tenpaiGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _tenpaiGlow = Tween<double>(begin: 0, end: 1).animate(_tenpaiGlowCtrl);
    _comboCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _comboScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _comboCtrl, curve: Curves.elasticOut),
    );
    _applyPersistedSettings();
  }

  Future<void> _applyPersistedSettings() async {
    final save = await SaveService.instance.load();
    HapticService.instance.enabled = save.settings.hapticEnabled;
    HapticService.instance.intensity = save.settings.hapticIntensity;
  }

  @override
  void dispose() {
    _tenpaiTimer?.cancel();
    _countdownTimer?.cancel();
    _tenpaiGlowCtrl.dispose();
    _comboCtrl.dispose();
    _gs.dispose();
    super.dispose();
  }

  void _startGame(BoxConstraints constraints) {
    final boardSize = Size(constraints.maxWidth, constraints.maxHeight * 0.6);
    _gs.startLevel(widget.config, boardSize);
    if (widget.config.timeLimitSeconds != null) {
      _timeRemaining = widget.config.timeLimitSeconds!;
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _timeRemaining--);
        if (_timeRemaining <= 0) {
          _countdownTimer?.cancel();
          _gs.forceTimeout();
          _checkEndCondition();
        }
      });
    }
  }

  Future<void> _handleFlip(int index) async {
    final result = _gs.flipTile(index);
    if (result == FlipResult.correct) {
      await HapticService.instance.flipCorrect();
      // Escalate haptic on combo ≥ 3
      final combo = _gs.comboCount;
      if (combo >= 3) {
        _comboCtrl.forward(from: 0);
        if (combo >= 5) {
          await HapticService.instance.heavyImpact();
        } else {
          await HapticService.instance.mediumImpact();
        }
      }
      _checkEndCondition();
    } else if (result == FlipResult.wrong) {
      await HapticService.instance.flipWrong();
      setState(() => _wrongAnimating.add(index));
      Timer(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _wrongAnimating.remove(index));
      });
      _checkEndCondition();
    }
  }

  Future<void> _handleLock(int index) async {
    final ok = _gs.lockTile(index);
    if (ok) {
      await HapticService.instance.lockSuccess();
    } else {
      await HapticService.instance.lightImpact();
    }
  }

  Future<void> _handleScrub(int index, double delta) async {
    if (!_gs.canScrub(index)) return; // budget exhausted for this tile
    _gs.onTileScrub(index, delta);
    await HapticService.instance.scrubTile(_gs.boardTiles[index].tile.suit, delta * 10);
  }

  Future<void> _handleHint() async {
    final idx = _gs.triggerHint();
    if (idx != null) {
      await HapticService.instance.lightImpact();
    }
  }

  Future<void> _handleReshuffle() async {
    if (_gs.lives <= 1 && !_gs.config.isTutorial) {
      // Not enough lives — show warning instead
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.tableTop,
          title: const Text('Cannot Reshuffle', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
            'You need at least 2 lives to reshuffle.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.tableTop,
        title: const Text('Reshuffle', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          _gs.config.isTutorial
              ? 'Reshuffle the board?'
              : 'Spend 1 life to reshuffle the board?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final ok = _gs.reshuffle();
              if (ok) {
                HapticService.instance.mediumImpact();
                _checkEndCondition();
              }
            },
            child: const Text('Reshuffle'),
          ),
        ],
      ),
    );
  }

  void _checkEndCondition() {
    if (_gs.phase == GamePhase.won || _gs.phase == GamePhase.lost) {
      _countdownTimer?.cancel();
      Timer(const Duration(milliseconds: 1200), () async {
        if (!mounted) return;
        final newAchievements = await _saveResult();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              result: _gs.buildResult(isDaily: widget.isDaily),
              isDaily: widget.isDaily,
              newAchievements: newAchievements,
            ),
          ),
        );
      });
    }
    if (_gs.isTenpai) {
      HapticService.instance.tenpaiPulse();
    }
  }

  Future<List<int>> _saveResult() async {
    final result = _gs.buildResult(isDaily: widget.isDaily);
    final newAchievements = await SaveService.instance.applyResult(result);
    if (widget.isDaily) {
      final date = DateTime.now();
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await SaveService.instance.updateDailyChallenge(
          dateStr, result.timeTaken.inSeconds.toDouble(), result.stars);
    }
    return newAchievements;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gs,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (ctx, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_gs.phase == GamePhase.idle) _startGame(constraints);
            });
            return Consumer<GameState>(
              builder: (ctx, gs, _) => _buildBody(ctx, gs, constraints),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GameState gs, BoxConstraints constraints) {
    return Stack(
      children: [
        Column(
          children: [
            _buildHUD(gs),
            Expanded(child: _buildBoard(gs, constraints)),
            _buildCollectionArea(gs),
            _buildBottomBar(gs),
          ],
        ),
        if (gs.isTenpai) _buildTenpaiGlow(),
        if (gs.phase == GamePhase.won || gs.phase == GamePhase.lost)
          _buildEndOverlay(gs.phase == GamePhase.won),
      ],
    );
  }

  Widget _buildHUD(GameState gs) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isDaily ? 'Daily Challenge' : 'Level ${widget.config.levelNumber}',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildStarsDisplay(gs),
            ],
          ),
          const SizedBox(height: 6),
          _buildTargetDisplay(gs),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildLives(gs),
              const SizedBox(width: 12),
              Text(
                'Collected: ${gs.collected.length}/${gs.config.targets.expand((t) => t.tiles).length}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              if (gs.comboCount >= 2) _buildCombo(gs),
              const SizedBox(width: 8),
              _buildTimer(gs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetDisplay(GameState gs) {
    return Row(
      children: [
        const Text('Target: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: gs.config.targets.map((t) {
                return Row(
                  children: [
                    Text(
                      t.name,
                      style: const TextStyle(
                          color: AppColors.targetHint,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (gs.isTenpai)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.targetHint.withAlpha(40),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.targetHint.withAlpha(120)),
            ),
            child: const Text(
              'TENPAI!',
              style: TextStyle(
                  color: AppColors.targetHint, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildLives(GameState gs) {
    // Tutorial levels have 99 lives — show numeric display instead
    if (gs.config.initialLives > 8) {
      return Row(
        children: [
          const Icon(Icons.favorite, color: Color(0xFFE74C3C), size: 16),
          const SizedBox(width: 4),
          Text(
            '${gs.lives}',
            style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
    return Row(
      children: List.generate(gs.config.initialLives, (i) {
        return Icon(
          i < gs.lives ? Icons.favorite : Icons.favorite_border,
          color: i < gs.lives ? const Color(0xFFE74C3C) : AppColors.textSecondary,
          size: 16,
        );
      }),
    );
  }

  Widget _buildStarsDisplay(GameState gs) {
    return Row(
      children: List.generate(3, (i) => const Icon(Icons.star, color: AppColors.targetHint, size: 14)),
    );
  }

  Widget _buildCombo(GameState gs) {
    final combo = gs.comboCount;
    final color = combo >= 5 ? AppColors.wrongFeedback : AppColors.targetHint;
    return AnimatedBuilder(
      animation: _comboScale,
      builder: (_, __) => Transform.scale(
        scale: _comboScale.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withAlpha(150)),
          ),
          child: Text(
            '×$combo',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimer(GameState gs) {
    if (widget.config.timeLimitSeconds != null) {
      final secs = _timeRemaining.clamp(0, widget.config.timeLimitSeconds!);
      final color = secs <= 10 ? AppColors.wrongFeedback : AppColors.textSecondary;
      return Text(
        '${secs}s',
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
      );
    }
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (_, __) {
        final e = gs.elapsed;
        final mm = e.inMinutes.toString().padLeft(2, '0');
        final ss = (e.inSeconds % 60).toString().padLeft(2, '0');
        return Text('$mm:$ss',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
      },
    );
  }

  Widget _buildBoard(GameState gs, BoxConstraints constraints) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tableTop,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: gs.boardTiles.asMap().entries.map((entry) {
          final i = entry.key;
          final bt = entry.value;
          // A tile is scrub-blocked if budget is used up AND this tile hasn't been touched
          final scrubBlocked = !gs.config.isTutorial &&
              !bt.hasBeenScrubbed &&
              gs.scrubBudgetRemaining <= 0;
          return Positioned(
            left: bt.position.dx,
            top: bt.position.dy,
            child: TileWidget(
              key: ValueKey('tile_$i'),
              boardTile: bt,
              index: i,
              isWrong: _wrongAnimating.contains(i),
              scrubBlocked: scrubBlocked,
              onScrub: _handleScrub,
              onFlip: _handleFlip,
              onLock: _handleLock,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCollectionArea(GameState gs) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Collected:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: gs.collected.map((t) => _miniTile(t)).toList(),
            ),
          ),
          if (!gs.config.isTutorial) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Scrubs: ${gs.scrubBudgetRemaining}/${gs.scrubBudget}',
                  style: TextStyle(
                    color: gs.scrubBudgetRemaining > 0
                        ? AppColors.tiaoColor
                        : AppColors.wrongFeedback,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (gs.locksRemaining > 0)
                  Text(
                    'Locks: ${gs.locksRemaining}',
                    style: const TextStyle(color: AppColors.targetHint, fontSize: 11),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniTile(MahjongTile tile) {
    return Container(
      width: 40,
      height: 52,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: AppColors.tileFace,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tile.suitColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          tile.displayName,
          style: TextStyle(
            color: tile.suitColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomBar(GameState gs) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bottomBtn(
            Icons.lightbulb_outline,
            'Hint',
            gs.hintsRemaining > 0 ? AppColors.targetHint : AppColors.textSecondary,
            gs.hintsRemaining > 0 ? _handleHint : null,
          ),
          _bottomBtn(Icons.shuffle, 'Reshuffle', AppColors.textSecondary, _handleReshuffle),
          _bottomBtn(Icons.settings_outlined, 'Settings', AppColors.textSecondary, () {
            _showSettings();
          }),
        ],
      ),
    );
  }

  Widget _bottomBtn(IconData icon, String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTenpaiGlow() {
    return AnimatedBuilder(
      animation: _tenpaiGlow,
      builder: (_, __) => IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.targetHint.withAlpha((_tenpaiGlow.value * 25).round()),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(0),
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    final settings = SaveService.instance.current.settings;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tableTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _settingRow(
                Icons.vibration,
                'Haptic Feedback',
                'Scrub & flip vibration',
                settings.hapticEnabled,
                (v) {
                  setSheetState(() => settings.hapticEnabled = v);
                  HapticService.instance.enabled = v;
                  SaveService.instance.updateSettings(settings);
                },
              ),
              const Divider(color: Color(0x1AFFFFFF), height: 24),
              _settingRow(
                Icons.music_note_outlined,
                'Sound Effects',
                'Flip, lock and result sounds',
                settings.soundEnabled,
                (v) {
                  setSheetState(() => settings.soundEnabled = v);
                  SaveService.instance.updateSettings(settings);
                },
              ),
              const Divider(color: Color(0x1AFFFFFF), height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.exit_to_app, color: AppColors.wrongFeedback),
                title: const Text('Quit Level',
                    style: TextStyle(color: AppColors.wrongFeedback)),
                subtitle: const Text('Return to main menu',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context); // close sheet
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingRow(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.correctFeedback,
        ),
      ],
    );
  }

  Widget _buildEndOverlay(bool won) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? 'You Win!' : 'Game Over',
              style: TextStyle(
                color: won ? AppColors.correctFeedback : AppColors.wrongFeedback,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Loading results...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
