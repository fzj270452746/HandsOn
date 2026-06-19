import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../models/level.dart';
import 'level_generator.dart';

enum GamePhase { idle, playing, won, lost }

class GameState extends ChangeNotifier {
  final _rng = Random();
  LevelConfig _config = const LevelConfig(
    levelNumber: 0,
    chapter: LevelChapter.tutorial,
    targets: [],
    totalTiles: 0,
    initialLives: 0,
  );
  List<BoardTile> _boardTiles = [];
  List<MahjongTile> _collected = [];
  int _lives = 0;
  int _locksRemaining = 0;
  GamePhase _phase = GamePhase.idle;
  DateTime? _startTime;
  int _correctFlips = 0;
  int _wrongFlips = 0;
  int _touchCount = 0;
  int _locksUsed = 0;
  bool _isTenpai = false;

  // Scrub budget: how many distinct tiles the player may scrub this level
  // = number of target tiles (e.g. 3 for a sequence)
  int _scrubBudget = 0;
  int _scrubBudgetUsed = 0;
  int _hintsRemaining = 1;
  int _comboCount = 0;
  int _maxCombo = 0;

  final Map<int, Timer> _decayTimers = {};
  final Map<String, int> _touchCounts = {};

  LevelConfig get config => _config;
  List<BoardTile> get boardTiles => List.unmodifiable(_boardTiles);
  List<MahjongTile> get collected => List.unmodifiable(_collected);
  int get lives => _lives;
  int get locksRemaining => _locksRemaining;
  GamePhase get phase => _phase;
  bool get isTenpai => _isTenpai;
  int get correctFlips => _correctFlips;
  int get wrongFlips => _wrongFlips;
  int get touchCount => _touchCount;
  int get locksUsed => _locksUsed;
  int get scrubBudget => _scrubBudget;
  int get scrubBudgetUsed => _scrubBudgetUsed;
  int get scrubBudgetRemaining => _scrubBudget - _scrubBudgetUsed;
  int get hintsRemaining => _hintsRemaining;
  int get comboCount => _comboCount;
  int get maxCombo => _maxCombo;
  Duration get elapsed =>
      _startTime == null ? Duration.zero : DateTime.now().difference(_startTime!);

  void startLevel(LevelConfig config, Size boardSize) {
    _cancelAllTimers();
    _config = config;
    _lives = config.initialLives;
    _locksRemaining = config.lockCount;
    _collected = [];
    _correctFlips = 0;
    _wrongFlips = 0;
    _touchCount = 0;
    _locksUsed = 0;
    _isTenpai = false;
    _phase = GamePhase.playing;
    _startTime = DateTime.now();
    _touchCounts.clear();
    // Scrub budget = target tile count (tutorial gets unlimited)
    final targetCount = config.targets.expand((t) => t.tiles).length;
    _scrubBudget = config.isTutorial ? 999 : targetCount;
    _scrubBudgetUsed = 0;
    _hintsRemaining = 1;
    _comboCount = 0;
    _maxCombo = 0;
    _boardTiles = _layoutTiles(LevelGenerator.generateBoardTiles(config), boardSize);
    notifyListeners();
  }

  List<BoardTile> _layoutTiles(List<BoardTile> tiles, Size boardSize) {
    final rng = Random();
    const tw = 72.0, th = 96.0, spacing = 20.0;
    final cols = ((boardSize.width - spacing) / (tw + spacing)).floor();
    final List<BoardTile> result = [];
    final List<Offset> positions = [];

    for (int i = 0; i < tiles.length; i++) {
      Offset pos;
      int tries = 0;
      do {
        final col = rng.nextInt(max(1, cols));
        final row = rng.nextInt(max(1, ((tiles.length / cols).ceil()) + 1));
        pos = Offset(
          spacing + col * (tw + spacing) + rng.nextDouble() * 10 - 5,
          spacing + row * (th + spacing) + rng.nextDouble() * 10 - 5,
        );
        tries++;
      } while (
          tries < 20 && positions.any((p) => (p - pos).distance < tw + spacing));
      positions.add(pos);
      result.add(tiles[i].copyWith(position: pos));
    }
    return result;
  }

  /// Returns false if scrub is blocked (budget exhausted and tile not yet scrubbed)
  bool canScrub(int index) {
    if (_boardTiles[index].hasBeenScrubbed) return true; // already claimed a slot
    return scrubBudgetRemaining > 0;
  }

  void onTileScrub(int index, double delta) {
    if (_phase != GamePhase.playing) return;
    if (_boardTiles[index].isFlipped) return;
    if (!canScrub(index)) return; // budget exhausted — silent block

    _touchCount++;
    _decayTimers[index]?.cancel();

    final bt = _boardTiles[index];

    // Consume one budget slot the first time this tile is scrubbed
    bool consumed = false;
    if (!bt.hasBeenScrubbed) {
      _scrubBudgetUsed++;
      consumed = true;
    }

    final newProgress = (bt.revealProgress + delta * (bt.modifier == TileModifier.iron ? 0.5 : 1.0)).clamp(0.0, 1.0);
    _boardTiles[index] = bt.copyWith(
      revealProgress: newProgress,
      hasBeenScrubbed: consumed ? true : bt.hasBeenScrubbed,
    );

    final tileId = bt.tile.id;
    _touchCounts[tileId] = (_touchCounts[tileId] ?? 0) + 1;

    notifyListeners();
    _scheduleDecay(index);
  }

  void _scheduleDecay(int index) {
    if (_boardTiles[index].isLocked) return;
    _decayTimers[index]?.cancel();
    _decayTimers[index] = Timer(
      const Duration(milliseconds: 2000),
      () => _startDecay(index),
    );
  }

  void _startDecay(int index) {
    if (index >= _boardTiles.length) return;
    if (_boardTiles[index].isLocked || _boardTiles[index].isFlipped) return;

    const decayPerTick = 0.008;
    Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (index >= _boardTiles.length ||
          _boardTiles[index].isLocked ||
          _boardTiles[index].isFlipped) {
        t.cancel();
        return;
      }
      final bt = _boardTiles[index];
      final rate = bt.modifier == TileModifier.frozen ? decayPerTick * 2.5 : decayPerTick;
      final newProg = (bt.revealProgress - rate).clamp(0.0, 1.0);
      _boardTiles[index] = bt.copyWith(revealProgress: newProg);
      notifyListeners();
      if (newProg <= 0) t.cancel();
    });
  }

  FlipResult flipTile(int index) {
    if (_phase != GamePhase.playing) return FlipResult.none;
    final bt = _boardTiles[index];
    if (bt.isFlipped) return FlipResult.none;

    final allTargetTiles = _config.targets.expand((t) => t.tiles).toList();
    final neededTiles =
        allTargetTiles.where((t) => !_collected.contains(t)).toList();
    final isCorrect = neededTiles.contains(bt.tile);

    _boardTiles[index] = bt.copyWith(isFlipped: true, isCorrect: isCorrect);
    _decayTimers[index]?.cancel();

    if (isCorrect) {
      _correctFlips++;
      _collected.add(bt.tile);
      _comboCount++;
      if (_comboCount > _maxCombo) _maxCombo = _comboCount;
      _checkTenpai();
      _checkWin();
    } else {
      _wrongFlips++;
      _comboCount = 0;
      _lives--;
      _handleWrongFlip(index);
      // Bomb: clear revealProgress of up to 3 random unflipped tiles
      if (bt.modifier == TileModifier.bomb) {
        final targets = _boardTiles
            .asMap()
            .entries
            .where((e) => e.key != index && !e.value.isFlipped && !e.value.isLocked)
            .map((e) => e.key)
            .toList()
          ..shuffle(_rng);
        for (final i in targets.take(3)) {
          _boardTiles[i] = _boardTiles[i].copyWith(revealProgress: 0.0);
          _decayTimers[i]?.cancel();
        }
      }
      if (_lives <= 0) {
        _phase = GamePhase.lost;
      }
    }

    notifyListeners();
    return isCorrect ? FlipResult.correct : FlipResult.wrong;
  }

  void _handleWrongFlip(int wrongIndex) {
    final rng = Random();
    Timer(const Duration(milliseconds: 800), () {
      if (wrongIndex >= _boardTiles.length) return;
      final bt = _boardTiles[wrongIndex];
      final newPos = Offset(
        rng.nextDouble() * 280 + 20,
        rng.nextDouble() * 320 + 60,
      );
      _boardTiles[wrongIndex] = bt.copyWith(
        isFlipped: false,
        revealProgress: _config.extraRevealDecayOnWrong
            ? bt.revealProgress * 0.7
            : bt.revealProgress,
        position: newPos,
        // Scrubbed flag is preserved — player already spent the budget
      );

      if (_config.shuffleOnWrong) {
        final unflipped = _boardTiles
            .asMap()
            .entries
            .where((e) => !e.value.isFlipped && e.key != wrongIndex)
            .map((e) => e.key)
            .toList()
          ..shuffle(rng);
        final swapCount = min(3, unflipped.length ~/ 2);
        for (int i = 0; i < swapCount; i++) {
          final a = unflipped[i * 2];
          final b = unflipped[i * 2 + 1];
          final posA = _boardTiles[a].position;
          _boardTiles[a] =
              _boardTiles[a].copyWith(position: _boardTiles[b].position);
          _boardTiles[b] = _boardTiles[b].copyWith(position: posA);
        }
      }

      if (_config.decayAllOnWrong) {
        for (int i = 0; i < _boardTiles.length; i++) {
          if (!_boardTiles[i].isFlipped && !_boardTiles[i].isLocked) {
            _boardTiles[i] = _boardTiles[i].copyWith(revealProgress: 0.0);
          }
        }
      }

      notifyListeners();
    });
  }

  bool lockTile(int index) {
    if (_locksRemaining <= 0) return false;
    if (_boardTiles[index].isFlipped || _boardTiles[index].isLocked) return false;
    _decayTimers[index]?.cancel();
    _boardTiles[index] = _boardTiles[index].copyWith(isLocked: true);
    _locksRemaining--;
    _locksUsed++;
    notifyListeners();
    return true;
  }

  // Shuffle positions of all unflipped, unlocked tiles. Costs 1 life (free in tutorial).
  // Returns false if not enough lives or not enough tiles to shuffle.
  bool reshuffle() {
    if (_phase != GamePhase.playing) return false;
    if (!_config.isTutorial && _lives <= 1) return false;

    final indices = _boardTiles
        .asMap()
        .entries
        .where((e) => !e.value.isFlipped && !e.value.isLocked)
        .map((e) => e.key)
        .toList();
    if (indices.length < 2) return false;

    if (!_config.isTutorial) _lives--;

    final positions = indices.map((i) => _boardTiles[i].position).toList()
      ..shuffle(_rng);
    for (int i = 0; i < indices.length; i++) {
      _boardTiles[indices[i]] = _boardTiles[indices[i]].copyWith(position: positions[i]);
    }
    notifyListeners();
    return true;
  }

  // Briefly reveal one uncollected target tile (uses 1 of the level's hint allowance).
  // Returns the revealed tile index, or null if no hints remain / no valid tile.
  int? triggerHint() {
    if (_phase != GamePhase.playing) return null;
    if (_hintsRemaining <= 0) return null;

    final allTargetTiles = _config.targets.expand((t) => t.tiles).toList();
    final uncollected = allTargetTiles.where((t) => !_collected.contains(t)).toList();

    final candidates = _boardTiles
        .asMap()
        .entries
        .where((e) => !e.value.isFlipped && uncollected.contains(e.value.tile))
        .toList();
    if (candidates.isEmpty) return null;

    candidates.shuffle(_rng);
    final idx = candidates.first.key;

    _hintsRemaining--;
    _boardTiles[idx] = _boardTiles[idx].copyWith(revealProgress: 1.0);
    notifyListeners();
    _scheduleDecay(idx);
    return idx;
  }

  void _checkTenpai() {
    final allTargetTiles = _config.targets.expand((t) => t.tiles).toList();
    final remaining =
        allTargetTiles.where((t) => !_collected.contains(t)).toList();
    _isTenpai = remaining.length == 1;
  }

  void _checkWin() {
    final allTargetTiles = _config.targets.expand((t) => t.tiles).toSet();
    if (_collected.toSet().containsAll(allTargetTiles)) {
      _phase = GamePhase.won;
    }
  }

  LevelResult buildResult({bool isDaily = false}) {
    final total = _correctFlips + _wrongFlips;
    final accuracy = total == 0 ? 0.0 : _correctFlips / total;
    final time = elapsed;
    int stars = 1;
    double score = accuracy * 0.4;
    if (time.inSeconds < 60) {
      score += 0.3;
    } else if (time.inSeconds < 120) {
      score += 0.15;
    }
    if (_locksUsed == 0) {
      score += 0.15;
    } else if (_locksUsed == 1) {
      score += 0.08;
    }
    if (_touchCount < 30) {
      score += 0.15;
    } else if (_touchCount < 60) {
      score += 0.08;
    }
    if (score >= 0.85) {
      stars = 3;
    } else if (score >= 0.6) {
      stars = 2;
    }

    // Game over always gives 0 stars
    if (_phase != GamePhase.won) stars = 0;

    return LevelResult(
      levelNumber: _config.levelNumber,
      passed: _phase == GamePhase.won,
      stars: stars,
      accuracy: accuracy,
      timeTaken: time,
      locksUsed: _locksUsed,
      touchCount: _touchCount,
      maxCombo: _maxCombo,
      hintsUsed: 1 - _hintsRemaining,
      isDaily: isDaily,
    );
  }

  int touchCountForTile(String tileId) => _touchCounts[tileId] ?? 0;

  // Called by GameScreen when the countdown reaches zero
  void forceTimeout() {
    if (_phase != GamePhase.playing) return;
    _phase = GamePhase.lost;
    notifyListeners();
  }

  void _cancelAllTimers() {
    for (final t in _decayTimers.values) {
      t.cancel();
    }
    _decayTimers.clear();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }
}

enum FlipResult { none, correct, wrong }
