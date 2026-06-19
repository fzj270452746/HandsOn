import 'package:flutter/material.dart';
import '../models/achievements.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  List<int> _unlocked = [];

  @override
  void initState() {
    super.initState();
    SaveService.instance.load().then((save) {
      if (mounted) setState(() => _unlocked = List.from(save.achievements));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Achievements  ${_unlocked.length}/${kAchievements.length}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: kAchievements.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Color(0x1AFFFFFF), height: 1),
        itemBuilder: (ctx, i) {
          final a = kAchievements[i];
          final isUnlocked = _unlocked.contains(a.id);
          return ListTile(
            leading: Text(
              a.icon,
              style: TextStyle(
                fontSize: 28,
                color: isUnlocked ? null : const Color(0x33FFFFFF),
              ),
            ),
            title: Text(
              a.title,
              style: TextStyle(
                color: isUnlocked
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight:
                    isUnlocked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              a.description,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: isUnlocked
                ? const Icon(Icons.check_circle,
                    color: AppColors.correctFeedback, size: 20)
                : const Icon(Icons.lock_outline,
                    color: AppColors.textSecondary, size: 18),
          );
        },
      ),
    );
  }
}
