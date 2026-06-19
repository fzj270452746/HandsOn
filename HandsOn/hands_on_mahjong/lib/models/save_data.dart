class SaveData {
  int currentLevel;
  int maxUnlockedLevel;
  int totalTilesTouched;
  int totalCorrect;
  int totalWrong;
  List<int> achievements;
  Map<int, int> levelStars; // levelNumber -> stars (1-3)
  DailyChallengeData? dailyChallenge;
  AppSettings settings;

  SaveData({
    this.currentLevel = 1,
    this.maxUnlockedLevel = 1,
    this.totalTilesTouched = 0,
    this.totalCorrect = 0,
    this.totalWrong = 0,
    List<int>? achievements,
    Map<int, int>? levelStars,
    this.dailyChallenge,
    AppSettings? settings,
  })  : achievements = achievements ?? [],
        levelStars = levelStars ?? {},
        settings = settings ?? AppSettings();

  double get accuracy =>
      (totalCorrect + totalWrong) == 0 ? 0 : totalCorrect / (totalCorrect + totalWrong);

  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel,
        'maxUnlockedLevel': maxUnlockedLevel,
        'totalTilesTouched': totalTilesTouched,
        'totalCorrect': totalCorrect,
        'totalWrong': totalWrong,
        'achievements': achievements,
        'levelStars': levelStars.map((k, v) => MapEntry(k.toString(), v)),
        'dailyChallenge': dailyChallenge?.toJson(),
        'settings': settings.toJson(),
      };

  factory SaveData.fromJson(Map<String, dynamic> json) => SaveData(
        currentLevel: (json['currentLevel'] as int?) ?? 1,
        maxUnlockedLevel: (json['maxUnlockedLevel'] as int?) ?? 1,
        totalTilesTouched: (json['totalTilesTouched'] as int?) ?? 0,
        totalCorrect: (json['totalCorrect'] as int?) ?? 0,
        totalWrong: (json['totalWrong'] as int?) ?? 0,
        achievements: List<int>.from(json['achievements'] ?? []),
        levelStars: (json['levelStars'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(int.parse(k), v as int)),
        dailyChallenge: json['dailyChallenge'] != null
            ? DailyChallengeData.fromJson(json['dailyChallenge'] as Map<String, dynamic>)
            : null,
        settings: json['settings'] != null
            ? AppSettings.fromJson(json['settings'] as Map<String, dynamic>)
            : AppSettings(),
      );
}

class DailyChallengeData {
  String lastDate;
  double bestTime;
  int stars;

  DailyChallengeData({
    required this.lastDate,
    this.bestTime = 0,
    this.stars = 0,
  });

  Map<String, dynamic> toJson() => {
        'lastDate': lastDate,
        'bestTime': bestTime,
        'stars': stars,
      };

  factory DailyChallengeData.fromJson(Map<String, dynamic> json) => DailyChallengeData(
        lastDate: json['lastDate'] ?? '',
        bestTime: (json['bestTime'] ?? 0).toDouble(),
        stars: json['stars'] ?? 0,
      );
}

class AppSettings {
  double hapticIntensity;
  bool hapticEnabled;
  bool soundEnabled;
  String bgSound; // 'rain', 'fire', 'book', 'none'
  bool immersiveMode;
  bool showVibrationIndicator;

  AppSettings({
    this.hapticIntensity = 0.8,
    this.hapticEnabled = true,
    this.soundEnabled = true,
    this.bgSound = 'rain',
    this.immersiveMode = false,
    this.showVibrationIndicator = false,
  });

  Map<String, dynamic> toJson() => {
        'hapticIntensity': hapticIntensity,
        'hapticEnabled': hapticEnabled,
        'soundEnabled': soundEnabled,
        'bgSound': bgSound,
        'immersiveMode': immersiveMode,
        'showVibrationIndicator': showVibrationIndicator,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        hapticIntensity: (json['hapticIntensity'] ?? 0.8).toDouble(),
        hapticEnabled: (json['hapticEnabled'] as bool?) ?? true,
        soundEnabled: (json['soundEnabled'] as bool?) ?? true,
        bgSound: (json['bgSound'] as String?) ?? 'rain',
        immersiveMode: (json['immersiveMode'] as bool?) ?? false,
        showVibrationIndicator: (json['showVibrationIndicator'] as bool?) ?? false,
      );
}

class FlipRecord {
  final String tileId;
  final bool isCorrect;
  final DateTime time;
  final Duration touchDuration;

  const FlipRecord({
    required this.tileId,
    required this.isCorrect,
    required this.time,
    required this.touchDuration,
  });
}
