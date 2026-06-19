import 'package:flutter/material.dart';

enum TileSuit { wan, tiao, tong }

// Special modifiers placed on distractor tiles by the level generator.
// Target tiles are never modified — only distractors.
enum TileModifier {
  none,
  iron,   // requires 2× scrub distance to reveal
  frozen, // decay speed doubled
  bomb,   // wrong flip clears revealProgress of adjacent 3 tiles
}

class MahjongTile {
  final TileSuit suit;
  final int number; // 1-9

  const MahjongTile({required this.suit, required this.number});

  String get id => '${suit.name}_$number';

  Color get suitColor {
    switch (suit) {
      case TileSuit.wan:
        return const Color(0xFFC0392B);
      case TileSuit.tiao:
        return const Color(0xFF2980B9);
      case TileSuit.tong:
        return const Color(0xFF27AE60);
    }
  }

  String get displayName {
    final suitName = suit == TileSuit.wan ? 'W' : suit == TileSuit.tiao ? 'B' : 'C';
    return '$number$suitName';
  }

  @override
  bool operator ==(Object other) =>
      other is MahjongTile && other.suit == suit && other.number == number;

  @override
  int get hashCode => Object.hash(suit, number);

  @override
  String toString() => displayName;
}

class BoardTile {
  final MahjongTile tile;
  final TileModifier modifier;
  Offset position;
  bool isFlipped;
  bool isLocked;
  double revealProgress; // 0.0 = hidden, 1.0 = fully revealed
  bool isCorrect;
  bool hasBeenScrubbed; // consumed one scrub budget slot

  BoardTile({
    required this.tile,
    required this.position,
    this.modifier = TileModifier.none,
    this.isFlipped = false,
    this.isLocked = false,
    this.revealProgress = 0.0,
    this.isCorrect = false,
    this.hasBeenScrubbed = false,
  });

  BoardTile copyWith({
    Offset? position,
    TileModifier? modifier,
    bool? isFlipped,
    bool? isLocked,
    double? revealProgress,
    bool? isCorrect,
    bool? hasBeenScrubbed,
  }) {
    return BoardTile(
      tile: tile,
      position: position ?? this.position,
      modifier: modifier ?? this.modifier,
      isFlipped: isFlipped ?? this.isFlipped,
      isLocked: isLocked ?? this.isLocked,
      revealProgress: revealProgress ?? this.revealProgress,
      isCorrect: isCorrect ?? this.isCorrect,
      hasBeenScrubbed: hasBeenScrubbed ?? this.hasBeenScrubbed,
    );
  }
}
