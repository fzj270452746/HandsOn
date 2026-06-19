import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/save_data.dart';
import '../models/level.dart';
import '../models/achievements.dart';

class SaveService {
  static const _saveKey = 'hom_save_v1';
  static const _flipLogKey = 'hom_flip_log_v1';

  static SaveService? _instance;
  static SaveService get instance => _instance ??= SaveService._();
  SaveService._();

  SaveData _cache = SaveData();
  bool _loaded = false;

  Future<SaveData> load() async {
    if (_loaded) return _cache;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw != null) {
      try {
        _cache = SaveData.fromJson(jsonDecode(raw));
      } catch (_) {
        _cache = SaveData();
      }
    }
    _loaded = true;
    return _cache;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(_cache.toJson()));
  }

  SaveData get current => _cache;

  Future<List<int>> applyResult(LevelResult result) async {
    await load();

    if (result.passed) {
      if (result.levelNumber > 0) {
        if (result.levelNumber >= _cache.maxUnlockedLevel) {
          _cache.maxUnlockedLevel = result.levelNumber + 1;
        }
        if (result.levelNumber > _cache.currentLevel) {
          _cache.currentLevel = result.levelNumber;
        }
      }

      final prev = _cache.levelStars[result.levelNumber] ?? 0;
      if (result.stars > prev) {
        _cache.levelStars[result.levelNumber] = result.stars;
      }
    }

    _cache.totalCorrect += result.passed ? 1 : 0;
    _cache.totalWrong += result.passed ? 0 : 1;

    // Check and unlock achievements before saving
    final newlyUnlocked = checkAchievements(result, _cache);
    for (final id in newlyUnlocked) {
      if (!_cache.achievements.contains(id)) {
        _cache.achievements.add(id);
      }
    }

    await save();
    return newlyUnlocked;
  }

  Future<void> addFlipRecord(FlipRecord record) async {
    await load();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_flipLogKey) ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    list.insert(0, {
      'tileId': record.tileId,
      'isCorrect': record.isCorrect,
      'time': record.time.toIso8601String(),
      'touchDuration': record.touchDuration.inMilliseconds,
    });
    // 最多保留 50 条
    final trimmed = list.take(50).toList();
    await prefs.setString(_flipLogKey, jsonEncode(trimmed));

    if (record.isCorrect) _cache.totalCorrect++;
    if (!record.isCorrect) _cache.totalWrong++;
    _cache.totalTilesTouched++;
    await save();
  }

  Future<List<FlipRecord>> loadFlipLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_flipLogKey) ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((m) => FlipRecord(
      tileId: m['tileId'],
      isCorrect: m['isCorrect'],
      time: DateTime.parse(m['time']),
      touchDuration: Duration(milliseconds: m['touchDuration']),
    )).toList();
  }

  Future<void> unlockAchievement(int id) async {
    await load();
    if (!_cache.achievements.contains(id)) {
      _cache.achievements.add(id);
      await save();
    }
  }

  bool hasAchievement(int id) => _cache.achievements.contains(id);

  Future<void> updateSettings(AppSettings settings) async {
    await load();
    _cache.settings = settings;
    await save();
  }

  Future<void> updateDailyChallenge(String date, double time, int stars) async {
    await load();
    final existing = _cache.dailyChallenge;
    if (existing == null || existing.lastDate != date || time < existing.bestTime) {
      _cache.dailyChallenge = DailyChallengeData(
        lastDate: date,
        bestTime: time,
        stars: stars,
      );
      await save();
    }
  }
}
