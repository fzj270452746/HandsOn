enum AchievementType { progress, skill, explore }

class Achievement {
  final int id;
  final String name;
  final String description;
  final AchievementType type;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
  });
}

class AchievementRegistry {
  static const List<Achievement> all = [
    Achievement(id: 0, name: 'First Steps', description: 'Complete level 1', type: AchievementType.progress),
    Achievement(id: 1, name: 'All Three Suits', description: 'Complete tutorial levels', type: AchievementType.progress),
    Achievement(id: 2, name: 'Sequence Master', description: 'Complete level 18', type: AchievementType.progress),
    Achievement(id: 3, name: 'Dragon Legend', description: 'Complete level 27', type: AchievementType.progress),
    Achievement(id: 4, name: 'Tenpai King', description: 'Complete level 36', type: AchievementType.progress),
    Achievement(id: 5, name: 'Perfect Touch', description: '100% accuracy in a single level', type: AchievementType.skill),
    Achievement(id: 6, name: 'Speed Reader', description: 'Complete a level in under 30 seconds', type: AchievementType.skill),
    Achievement(id: 7, name: 'No Locks', description: 'Complete 3 consecutive levels without locking', type: AchievementType.skill),
    Achievement(id: 8, name: 'Focused Mind', description: '10 consecutive correct flips', type: AchievementType.skill),
    Achievement(id: 9, name: 'Tactile Master', description: 'Correctly identify 100 tiles', type: AchievementType.explore),
    Achievement(id: 10, name: 'Daily Devotion', description: 'Complete 7 daily challenges', type: AchievementType.explore),
    Achievement(id: 11, name: 'Texture Memory', description: 'Scrub the same tile 5 times before flipping correctly', type: AchievementType.explore),
  ];
}
