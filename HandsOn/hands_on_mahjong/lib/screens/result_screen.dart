import 'package:flutter/material.dart';
import '../models/level.dart';
import '../models/achievements.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
import '../game/level_generator.dart';

class ResultScreen extends StatefulWidget {
  final LevelResult result;
  final bool isDaily;
  final List<int> newAchievements;

  const ResultScreen({
    super.key,
    required this.result,
    this.isDaily = false,
    this.newAchievements = const [],
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late AnimationController _starsCtrl;
  late List<Animation<double>> _starAnims;

  @override
  void initState() {
    super.initState();
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _starAnims = List.generate(3, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _starsCtrl,
          curve: Interval(i * 0.25, i * 0.25 + 0.5, curve: Curves.elasticOut),
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 300), () => _starsCtrl.forward());
  }

  @override
  void dispose() {
    _starsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                r.passed ? 'Level Clear!' : 'Try Again',
                style: TextStyle(
                  color: r.passed ? AppColors.correctFeedback : AppColors.wrongFeedback,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildStars(r.stars),
              const SizedBox(height: 16),
              _buildAchievements(),
              _buildStats(r),
              const SizedBox(height: 24),
              _buildButtons(r),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStars(int stars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _starAnims[i],
          builder: (_, __) => Transform.scale(
            scale: _starAnims[i].value,
            child: Icon(
              i < stars ? Icons.star : Icons.star_border,
              color: i < stars ? AppColors.targetHint : AppColors.textSecondary,
              size: 56,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStats(LevelResult r) {
    final mm = r.timeTaken.inMinutes.toString().padLeft(2, '0');
    final ss = (r.timeTaken.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tableTop,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _statRow('Accuracy', '${(r.accuracy * 100).toStringAsFixed(1)}%'),
          _statRow('Time', '$mm:$ss'),
          _statRow('Locks Used', '${r.locksUsed}'),
          _statRow('Touches', '${r.touchCount}'),
          if (r.maxCombo >= 2) _statRow('Best Combo', '×${r.maxCombo}'),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    if (widget.newAchievements.isEmpty) return const SizedBox.shrink();
    final defs = kAchievements.where((a) => widget.newAchievements.contains(a.id)).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 0, 32, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.targetHint.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.targetHint.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievement Unlocked!',
            style: TextStyle(
              color: AppColors.targetHint,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...defs.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(a.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(a.description,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildButtons(LevelResult r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          if (r.passed && !widget.isDaily)
            _btn('Next Level', AppColors.correctFeedback, () async {
              await SaveService.instance.load();
              final nextLevel = r.levelNumber + 1;
              if (!mounted) return;
              if (nextLevel <= 36) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => GameScreen(config: LevelGenerator.generateLevel(nextLevel)),
                ));
              } else {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            }),
          const SizedBox(height: 12),
          _btn('Play Again', AppColors.tableTop, () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => GameScreen(
                config: LevelGenerator.generateLevel(r.levelNumber),
                isDaily: widget.isDaily,
              ),
            ));
          }),
          const SizedBox(height: 12),
          _btn('Main Menu', Colors.transparent, () {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }, outlined: true),
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap, {bool outlined = false}) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(12),
            border: outlined ? Border.all(color: AppColors.textSecondary) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: outlined ? AppColors.textSecondary : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
