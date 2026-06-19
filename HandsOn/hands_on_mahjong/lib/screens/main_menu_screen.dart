import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../models/save_data.dart';
import '../utils/constants.dart';
import 'achievement_screen.dart';
import 'daily_challenge_screen.dart';
import 'practice_screen.dart';
import 'log_screen.dart';
import 'level_select_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  SaveData? _saveData;
  late AnimationController _logoCtrl;
  late Animation<double> _logoGlow;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _logoGlow = Tween<double>(begin: 0.6, end: 1.0).animate(_logoCtrl);
    _loadSave();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSave() async {
    final data = await SaveService.instance.load();
    if (mounted) setState(() => _saveData = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            _buildLogo(),
            const SizedBox(height: 48),
            _buildMenuButtons(),
            const Spacer(),
            _buildFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoGlow,
      builder: (_, __) => Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.wanColor,
                AppColors.targetHint,
                AppColors.tongColor,
              ],
            ).createShader(bounds),
            child: const Text(
              'Hands On\nMahjong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BLIND TOUCH',
            style: TextStyle(
              color: AppColors.textSecondary.withAlpha((_logoGlow.value * 255).round()),
              fontSize: 14,
              letterSpacing: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _menuBtn(
            icon: Icons.play_arrow_rounded,
            label: 'Play',
            color: AppColors.correctFeedback,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelSelectScreen())),
          ),
          const SizedBox(height: 16),
          _menuBtn(
            icon: Icons.calendar_today_outlined,
            label: 'Daily Challenge',
            color: AppColors.targetHint,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyChallengeScreen())),
          ),
          const SizedBox(height: 16),
          _menuBtn(
            icon: Icons.sports_esports_outlined,
            label: 'Free Practice',
            color: AppColors.tiaoColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeScreen())),
          ),
          const SizedBox(height: 16),
          _menuBtn(
            icon: Icons.history,
            label: 'Flip Log',
            color: AppColors.textSecondary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogScreen())),
          ),
        ],
      ),
    );
  }

  Widget _menuBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.tableTop,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textSecondary.withAlpha(120), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_saveData == null) return const SizedBox.shrink();
    final maxLevel = _saveData!.maxUnlockedLevel;
    final achievements = _saveData!.achievements.length;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AchievementScreen()),
      ),
      child: Text(
        'Level $maxLevel / 36  ·  Achievements $achievements / 12  ›',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
