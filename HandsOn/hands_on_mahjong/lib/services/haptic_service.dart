import 'package:flutter/services.dart';
import '../models/tile.dart';

// 通过 MethodChannel 调用 iOS Core Haptics
// 频道名需与 iOS AppDelegate 中注册的一致
class HapticService {
  static const _channel = MethodChannel('com.example.handsOnMahjong/haptic');

  static HapticService? _instance;
  static HapticService get instance => _instance ??= HapticService._();
  HapticService._();

  double intensity = 0.8;
  bool enabled = true;

  Future<void> _trigger(String type, [Map<String, dynamic>? params]) async {
    if (!enabled) return;
    try {
      await _channel.invokeMethod(type, {
        'intensity': intensity,
        ...?params,
      });
    } catch (_) {
      // 非 iOS 或不支持 Taptic Engine 时静默失败
    }
  }

  // 搓牌震动（持续，按花色区分）
  Future<void> scrubTile(TileSuit suit, double speed) async {
    final suitStr = suit.name; // 'wan', 'tiao', 'tong'
    await _trigger('scrub', {'suit': suitStr, 'speed': speed});
  }

  Future<void> tileFullyRevealed() => _trigger('revealed');
  Future<void> tileDecayed() => _trigger('decayed');
  Future<void> flipCorrect() => _trigger('flipCorrect');
  Future<void> flipWrong() => _trigger('flipWrong');
  Future<void> lockSuccess() => _trigger('lockSuccess');
  Future<void> tenpaiPulse() => _trigger('tenpai');
  Future<void> levelWon() => _trigger('levelWon');
  Future<void> levelLost() => _trigger('levelLost');

  // 简单降级方案：UIImpactFeedbackGenerator（用 Flutter 内置）
  Future<void> lightImpact() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> mediumImpact() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavyImpact() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> selectionClick() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }
}
