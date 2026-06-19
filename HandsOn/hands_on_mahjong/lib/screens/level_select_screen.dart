import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../models/save_data.dart';
import '../utils/constants.dart';
import '../game/level_generator.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  SaveData? _saveData;

  @override
  void initState() {
    super.initState();
    SaveService.instance.load().then((d) {
      if (mounted) setState(() => _saveData = d);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Select Level', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildChapterSection('Tutorial', [-3, -2, -1, 0],
              ['Mixed Recognition', 'Feel the Circles', 'Feel the Bamboo', 'Feel the Characters']),
          _buildChapterSection('Chapter 1 · Identification', List.generate(9, (i) => i + 1), null),
          _buildChapterSection('Chapter 2 · Same-Suit Sequence', List.generate(9, (i) => i + 10), null),
          _buildChapterSection('Chapter 3 · Full Dragon', List.generate(9, (i) => i + 19), null),
          _buildChapterSection('Chapter 4 · Mixed Tenpai', List.generate(9, (i) => i + 28), null),
        ],
      ),
    );
  }

  Widget _buildChapterSection(String title, List<int> levels, List<String>? labels) {
    final maxUnlocked = _saveData?.maxUnlockedLevel ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title,
              style: const TextStyle(
                  color: AppColors.targetHint, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: levels.length,
          itemBuilder: (ctx, i) {
            final lvl = levels[i];
            final isTutorial = lvl <= 0;
            final isUnlocked = isTutorial || lvl <= maxUnlocked;
            final stars = _saveData?.levelStars[lvl] ?? 0;
            final label = labels != null ? labels[i] : (lvl > 0 ? 'Level $lvl' : 'Tutorial ${-lvl + 1}');

            return GestureDetector(
              onTap: isUnlocked
                  ? () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(config: LevelGenerator.generateLevel(lvl)),
                        ),
                      )
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.tableTop : AppColors.tableTop.withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUnlocked ? AppColors.textSecondary.withAlpha(60) : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isUnlocked)
                      const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20)
                    else
                      Text(
                        label,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 4),
                    if (isUnlocked && stars > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            3,
                            (j) => Icon(
                                  j < stars ? Icons.star : Icons.star_border,
                                  color: AppColors.targetHint,
                                  size: 14,
                                )),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
