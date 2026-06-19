import 'package:flutter/material.dart';
import '../game/level_generator.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  bool _completedToday = false;
  double _bestTime = 0;
  int _bestStars = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final save = await SaveService.instance.load();
    final today = _todayStr();
    if (save.dailyChallenge?.lastDate == today) {
      setState(() {
        _completedToday = true;
        _bestTime = save.dailyChallenge!.bestTime;
        _bestStars = save.dailyChallenge!.stars;
      });
    }
  }

  String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _nextChallengeCountdown() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final config = LevelGenerator.generateDailyChallenge(today);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Daily Challenge', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's challenge card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.tableTop,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.targetHint.withAlpha(_completedToday ? 80 : 30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📅 ', style: TextStyle(fontSize: 16)),
                        Text(
                          _todayStr(),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5DADE2).withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF5DADE2).withAlpha(80)),
                          ),
                          child: const Text('⏱ 90s',
                              style: TextStyle(color: Color(0xFF5DADE2), fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      config.targets.first.name,
                      style: const TextStyle(
                          color: AppColors.targetHint,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tiles: ${config.totalTiles}  ·  Lives: ${config.initialLives}  ·  All penalties on',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    if (_completedToday) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Color(0x1AFFFFFF)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(
                              3,
                              (i) => Icon(
                                    i < _bestStars ? Icons.star : Icons.star_border,
                                    color: AppColors.targetHint,
                                    size: 18,
                                  )),
                          const SizedBox(width: 8),
                          Text(
                            'Best: ${_bestTime.toStringAsFixed(1)}s',
                            style: const TextStyle(
                                color: AppColors.correctFeedback,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Countdown to next challenge (shown after completing today's)
              if (_completedToday)
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.tableTop,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time,
                            color: AppColors.textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Next challenge in ${_nextChallengeCountdown()}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(config: config, isDaily: true),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.targetHint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _completedToday ? 'Play Again' : 'Start Challenge',
                      style: const TextStyle(
                          color: AppColors.background,
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
}

