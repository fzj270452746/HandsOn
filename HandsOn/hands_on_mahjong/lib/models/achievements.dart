import '../models/level.dart';
import '../models/save_data.dart';

class Achievement {
  final int id;
  final String title;
  final String description;
  final String icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const List<Achievement> kAchievements = [
  Achievement(id: 1,  icon: '🎯', title: 'First Win',       description: 'Clear any level'),
  Achievement(id: 2,  icon: '⭐', title: 'Perfect',         description: 'Get 3 stars on any level'),
  Achievement(id: 3,  icon: '🔥', title: 'On Fire',         description: 'Achieve a 3× combo'),
  Achievement(id: 4,  icon: '💥', title: 'Unstoppable',     description: 'Achieve a 5× combo'),
  Achievement(id: 5,  icon: '🔒', title: 'Lock Master',     description: 'Clear a level without using any locks'),
  Achievement(id: 6,  icon: '💡', title: 'Self-Sufficient', description: 'Clear a level without using any hints'),
  Achievement(id: 7,  icon: '⚡', title: 'Speed Demon',     description: 'Clear a level in under 30 seconds'),
  Achievement(id: 8,  icon: '📅', title: 'Daily Devotee',   description: 'Complete the Daily Challenge'),
  Achievement(id: 9,  icon: '🏆', title: 'Chapter Master',  description: 'Clear all Chapter 4 levels'),
  Achievement(id: 10, icon: '🧘', title: 'Zen',             description: 'Clear a level with 100% accuracy'),
  Achievement(id: 11, icon: '🌟', title: 'Completionist',   description: 'Get 3 stars on 10 levels'),
  Achievement(id: 12, icon: '🐉', title: 'Dragon Tamer',    description: 'Clear a Full Dragon (1-9) level'),
];

/// Returns the IDs of any achievements newly unlocked by this result.
/// Does NOT write to SaveService — caller must call unlockAchievement.
List<int> checkAchievements(LevelResult result, SaveData save) {
  final unlocked = <int>[];

  void tryUnlock(int id) {
    if (!save.achievements.contains(id)) unlocked.add(id);
  }

  if (result.passed) {
    tryUnlock(1); // First Win

    if (result.stars == 3) tryUnlock(2); // Perfect

    if (result.maxCombo >= 3) tryUnlock(3); // On Fire
    if (result.maxCombo >= 5) tryUnlock(4); // Unstoppable

    if (result.locksUsed == 0) tryUnlock(5); // Lock Master

    // hint-free: tracked via hintsRemaining — we check if maxCombo is ≥ 1 as proxy;
    // the actual flag is passed in the result via hintsUsed (added below)
    if (result.hintsUsed == 0) tryUnlock(6); // Self-Sufficient

    if (result.timeTaken.inSeconds < 30) tryUnlock(7); // Speed Demon

    if (result.isDaily && result.passed) tryUnlock(8); // Daily Devotee

    // Chapter Master: all levels 28-36 cleared
    final ch4Cleared = List.generate(9, (i) => i + 28).every(
      (lvl) => (save.levelStars[lvl] ?? 0) >= 1,
    );
    if (ch4Cleared) tryUnlock(9);

    // Completionist: 10 levels with 3 stars
    final threeStarCount = save.levelStars.values.where((s) => s == 3).length;
    if (threeStarCount >= 10) tryUnlock(11);

    // Dragon Tamer: chapter3 level passed
    if (result.levelNumber >= 19 && result.levelNumber <= 27) tryUnlock(12);
  }

  return unlocked;
}
