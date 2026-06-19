import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../models/level.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  TileSuit _suit = TileSuit.wan;
  int _startNum = 1;
  bool _showFace = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Free Practice', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Suit', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: TileSuit.values.map((s) {
                  final selected = s == _suit;
                  final color = s == TileSuit.wan
                      ? AppColors.wanColor
                      : s == TileSuit.tiao
                          ? AppColors.tiaoColor
                          : AppColors.tongColor;
                  final label = s == TileSuit.wan
                      ? 'Characters'
                      : s == TileSuit.tiao
                          ? 'Bamboo'
                          : 'Circles';
                  return GestureDetector(
                    onTap: () => setState(() => _suit = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color.withAlpha(60) : AppColors.tableTop,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selected ? color : Colors.transparent),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              color: selected ? color : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Starting Number',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(7, (i) {
                  final n = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _startNum = n),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _startNum == n
                            ? AppColors.tiaoColor.withAlpha(60)
                            : AppColors.tableTop,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _startNum == n
                                ? AppColors.tiaoColor
                                : Colors.transparent),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$n',
                        style: TextStyle(
                          color: _startNum == n
                              ? AppColors.tiaoColor
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Show Tile Face (learning aid)',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const Spacer(),
                  Switch(
                    value: _showFace,
                    onChanged: (v) => setState(() => _showFace = v),
                    activeThumbColor: AppColors.correctFeedback,
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _startPractice,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.tiaoColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Start Practice',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startPractice() {
    final tiles = [_startNum, _startNum + 1, _startNum + 2]
        .map((n) => MahjongTile(suit: _suit, number: n))
        .toList();
    final suitName = _suit == TileSuit.wan
        ? 'Characters'
        : _suit == TileSuit.tiao
            ? 'Bamboo'
            : 'Circles';
    final config = LevelConfig(
      levelNumber: 0,
      chapter: LevelChapter.tutorial,
      targets: [
        TargetPattern(
          type: TargetPatternType.sameColorSequence,
          tiles: tiles,
          name: '$suitName Practice $_startNum-${_startNum + 1}-${_startNum + 2}',
        )
      ],
      totalTiles: 6,
      initialLives: 99,
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(config: config)));
  }
}
