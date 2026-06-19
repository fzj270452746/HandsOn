import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../models/level.dart';

class LevelGenerator {
  static final _rng = Random();

  static List<MahjongTile> get _allTiles => [
        for (final suit in TileSuit.values)
          for (int n = 1; n <= 9; n++) MahjongTile(suit: suit, number: n)
      ];

  static LevelConfig generateLevel(int levelNumber) {
    if (levelNumber <= 0) return _tutorialLevel(levelNumber);
    if (levelNumber <= 9) return _chapter1Level(levelNumber);
    if (levelNumber <= 18) return _chapter2Level(levelNumber);
    if (levelNumber <= 27) return _chapter3Level(levelNumber);
    return _chapter4Level(levelNumber);
  }

  // Tutorial levels: 0 = Characters, -1 = Bamboo, -2 = Circles, -3 = Mixed
  static LevelConfig _tutorialLevel(int n) {
    List<MahjongTile> targetTiles;
    String name;

    if (n == 0) {
      targetTiles = [1, 2, 3].map((i) => MahjongTile(suit: TileSuit.wan, number: i)).toList();
      name = 'Feel the Characters';
    } else if (n == -1) {
      targetTiles = [1, 2, 3].map((i) => MahjongTile(suit: TileSuit.tiao, number: i)).toList();
      name = 'Feel the Bamboo';
    } else if (n == -2) {
      targetTiles = [1, 2, 3].map((i) => MahjongTile(suit: TileSuit.tong, number: i)).toList();
      name = 'Feel the Circles';
    } else {
      targetTiles = [
        MahjongTile(suit: TileSuit.wan, number: 1),
        MahjongTile(suit: TileSuit.tiao, number: 1),
        MahjongTile(suit: TileSuit.tong, number: 1),
      ];
      name = 'Mixed Recognition';
    }

    return LevelConfig(
      levelNumber: n,
      chapter: LevelChapter.tutorial,
      targets: [TargetPattern(type: TargetPatternType.sequence, tiles: targetTiles, name: name)],
      totalTiles: 6,
      initialLives: 99,
    );
  }

  static TargetPattern _randomSequence(TileSuit? suit) {
    suit ??= TileSuit.values[_rng.nextInt(3)];
    final start = _rng.nextInt(7) + 1;
    final tiles = [start, start + 1, start + 2]
        .map((n) => MahjongTile(suit: suit!, number: n))
        .toList();
    final suitName = suit == TileSuit.wan ? 'Characters' : suit == TileSuit.tiao ? 'Bamboo' : 'Circles';
    return TargetPattern(
      type: TargetPatternType.sameColorSequence,
      tiles: tiles,
      name: '$suitName ${tiles.first.number}-${tiles[1].number}-${tiles.last.number}',
    );
  }

  static LevelConfig _chapter1Level(int n) {
    final target = _randomSequence(null);
    return LevelConfig(
      levelNumber: n,
      chapter: LevelChapter.chapter1,
      targets: [target],
      totalTiles: 9,
      initialLives: 3,
    );
  }

  static LevelConfig _chapter2Level(int n) {
    final suit = TileSuit.values[_rng.nextInt(3)];
    final target = _randomSequence(suit);
    return LevelConfig(
      levelNumber: n,
      chapter: LevelChapter.chapter2,
      targets: [TargetPattern(type: TargetPatternType.sameColorSequence, tiles: target.tiles, name: target.name)],
      totalTiles: 10,
      initialLives: 3,
      extraRevealDecayOnWrong: true,
    );
  }

  static LevelConfig _chapter3Level(int n) {
    final suit = TileSuit.values[_rng.nextInt(3)];
    final tiles = List.generate(9, (i) => MahjongTile(suit: suit, number: i + 1));
    final suitName = suit == TileSuit.wan ? 'Characters' : suit == TileSuit.tiao ? 'Bamboo' : 'Circles';
    return LevelConfig(
      levelNumber: n,
      chapter: LevelChapter.chapter3,
      targets: [TargetPattern(type: TargetPatternType.dragon, tiles: tiles, name: '$suitName 1-9')],
      totalTiles: 12,
      initialLives: 3,
      shuffleOnWrong: true,
    );
  }

  static LevelConfig _chapter4Level(int n) {
    final seq1 = _randomSequence(TileSuit.wan);
    final seq2Suit = TileSuit.values[_rng.nextInt(2) + 1];
    final seq2 = _randomSequence(seq2Suit);
    return LevelConfig(
      levelNumber: n,
      chapter: LevelChapter.chapter4,
      targets: [
        TargetPattern(type: TargetPatternType.sameColorSequence, tiles: seq1.tiles, name: seq1.name),
        TargetPattern(type: TargetPatternType.sameColorSequence, tiles: seq2.tiles, name: seq2.name),
      ],
      totalTiles: 12,
      initialLives: 3,
      shuffleOnWrong: true,
      decayAllOnWrong: true,
    );
  }

  /// Build the board list with special modifiers injected on distractor slots.
  /// Target tiles are never modified.
  static List<BoardTile> generateBoardTiles(LevelConfig config) {
    final targetTiles = config.targets.expand((t) => t.tiles).toSet().toList();
    final remaining = _allTiles.where((t) => !targetTiles.contains(t)).toList()..shuffle(_rng);
    final distractors = remaining.take(config.totalTiles - targetTiles.length).toList();
    final board = [...targetTiles, ...distractors]..shuffle(_rng);

    // Determine how many distractors get special modifiers (0 for ch1, 1-2 for ch2+, bomb from ch3)
    final availableModifiers = _modifiersForChapter(config.chapter);
    final modifierSlots = _modifierCountForChapter(config.chapter);

    // Indices of distractor positions in shuffled board
    final distractorIndices = board
        .asMap()
        .entries
        .where((e) => !targetTiles.contains(e.value))
        .map((e) => e.key)
        .toList()
      ..shuffle(_rng);

    final modList = List<TileModifier>.filled(board.length, TileModifier.none);
    for (int i = 0; i < modifierSlots && i < distractorIndices.length; i++) {
      modList[distractorIndices[i]] =
          availableModifiers[_rng.nextInt(availableModifiers.length)];
    }

    return board.asMap().entries.map((e) {
      return BoardTile(tile: e.value, position: Offset.zero, modifier: modList[e.key]);
    }).toList();
  }

  static List<TileModifier> _modifiersForChapter(LevelChapter ch) {
    switch (ch) {
      case LevelChapter.tutorial:
      case LevelChapter.chapter1:
        return [TileModifier.none];
      case LevelChapter.chapter2:
        return [TileModifier.iron, TileModifier.frozen];
      case LevelChapter.chapter3:
        return [TileModifier.iron, TileModifier.frozen, TileModifier.bomb];
      case LevelChapter.chapter4:
        return [TileModifier.iron, TileModifier.frozen, TileModifier.bomb];
    }
  }

  static int _modifierCountForChapter(LevelChapter ch) {
    switch (ch) {
      case LevelChapter.tutorial:
      case LevelChapter.chapter1:
        return 0;
      case LevelChapter.chapter2:
        return 1;
      case LevelChapter.chapter3:
        return 2;
      case LevelChapter.chapter4:
        return 2;
    }
  }

  static LevelConfig generateDailyChallenge(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final rng = Random(seed);
    final suit = TileSuit.values[rng.nextInt(3)];
    final start = rng.nextInt(7) + 1;
    final tiles = [start, start + 1, start + 2]
        .map((n) => MahjongTile(suit: suit, number: n))
        .toList();
    final suitName = suit == TileSuit.wan ? 'Characters' : suit == TileSuit.tiao ? 'Bamboo' : 'Circles';
    return LevelConfig(
      levelNumber: 0,
      chapter: LevelChapter.chapter2,
      targets: [TargetPattern(type: TargetPatternType.sameColorSequence, tiles: tiles, name: 'Daily · $suitName ${tiles.first.number}-${tiles[1].number}-${tiles.last.number}')],
      totalTiles: 10,
      initialLives: 3,
      extraRevealDecayOnWrong: true,
      shuffleOnWrong: true,
      timeLimitSeconds: 90,
    );
  }
}
