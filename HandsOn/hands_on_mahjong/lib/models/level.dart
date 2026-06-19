import 'tile.dart';

enum LevelChapter { tutorial, chapter1, chapter2, chapter3, chapter4 }

enum TargetPatternType { sequence, sameColorSequence, dragon, mixed }

class TargetPattern {
  final TargetPatternType type;
  final List<MahjongTile> tiles;
  final String name;

  const TargetPattern({
    required this.type,
    required this.tiles,
    required this.name,
  });
}

class LevelConfig {
  final int levelNumber;
  final LevelChapter chapter;
  final List<TargetPattern> targets;
  final int totalTiles;
  final int initialLives;
  final bool extraRevealDecayOnWrong;
  final bool shuffleOnWrong;
  final bool decayAllOnWrong;
  final int lockCount;
  final int? timeLimitSeconds; // null = no time limit

  const LevelConfig({
    required this.levelNumber,
    required this.chapter,
    required this.targets,
    required this.totalTiles,
    required this.initialLives,
    this.extraRevealDecayOnWrong = false,
    this.shuffleOnWrong = false,
    this.decayAllOnWrong = false,
    this.lockCount = 2,
    this.timeLimitSeconds,
  });

  bool get isTutorial => chapter == LevelChapter.tutorial;
}

class LevelResult {
  final int levelNumber;
  final bool passed;
  final int stars;
  final double accuracy;
  final Duration timeTaken;
  final int locksUsed;
  final int touchCount;
  final int maxCombo;
  final int hintsUsed;
  final bool isDaily;

  const LevelResult({
    required this.levelNumber,
    required this.passed,
    required this.stars,
    required this.accuracy,
    required this.timeTaken,
    required this.locksUsed,
    required this.touchCount,
    this.maxCombo = 0,
    this.hintsUsed = 0,
    this.isDaily = false,
  });
}
