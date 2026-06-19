import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF1A1A2E);
  static const tableTop = Color(0xFF2D2D44);
  static const tileFace = Color(0xFFF5F0E8);
  static const tileBack = Color(0xFF1A3A3A);
  static const wanColor = Color(0xFFC0392B);
  static const tiaoColor = Color(0xFF2980B9);
  static const tongColor = Color(0xFF27AE60);
  static const targetHint = Color(0xFFF1C40F);
  static const correctFeedback = Color(0xFF2ECC71);
  static const wrongFeedback = Color(0xFFE74C3C);
  static const textPrimary = Color(0xFFECF0F1);
  static const textSecondary = Color(0xFF95A5A6);
}

class AppSizes {
  static const tileWidth = 72.0;
  static const tileHeight = 96.0;
  static const tileSpacing = 20.0;
  static const tileRadius = 8.0;
  static const revealDecayDelay = 2.0; // seconds before decay starts
  static const revealDecayDuration = 5.0; // seconds to fully decay
  static const revealDecayPerFrame = 0.004; // ~60fps → ~4s full decay
}
