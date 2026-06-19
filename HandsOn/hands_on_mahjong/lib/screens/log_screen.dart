import 'package:flutter/material.dart';
import '../models/save_data.dart';
import '../models/achievement.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<FlipRecord> _log = [];
  SaveData? _save;
  bool _wrongOnly = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final log = await SaveService.instance.loadFlipLog();
    final save = await SaveService.instance.load();
    if (mounted) setState(() { _log = log; _save = save; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Flip Log', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.targetHint,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Records'), Tab(text: 'Achievements')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildLogTab(), _buildAchievementsTab()],
      ),
    );
  }

  Widget _buildLogTab() {
    final displayed = _wrongOnly ? _log.where((r) => !r.isCorrect).toList() : _log;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (_save != null)
                Text(
                  'Accuracy: ${(_save!.accuracy * 100).toStringAsFixed(1)}%  ·  Total: ${_save!.totalTilesTouched}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _wrongOnly = !_wrongOnly),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _wrongOnly
                        ? AppColors.wrongFeedback.withAlpha(60)
                        : AppColors.tableTop,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mistakes Only',
                    style: TextStyle(
                      color: _wrongOnly ? AppColors.wrongFeedback : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: displayed.isEmpty
              ? const Center(
                  child: Text('No records yet',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayed.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Color(0x1AFFFFFF)),
                  itemBuilder: (_, i) {
                    final r = displayed[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            r.isCorrect ? Icons.check_circle : Icons.cancel,
                            color: r.isCorrect
                                ? AppColors.correctFeedback
                                : AppColors.wrongFeedback,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r.tileId,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 15),
                            ),
                          ),
                          Text(
                            '${r.touchDuration.inSeconds}s',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fmtTime(r.time),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAchievementsTab() {
    final unlocked = _save?.achievements ?? [];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: AchievementRegistry.all.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = AchievementRegistry.all[i];
        final isUnlocked = unlocked.contains(a.id);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.tableTop,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isUnlocked
                  ? AppColors.targetHint.withAlpha(80)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                color: isUnlocked ? AppColors.targetHint : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: TextStyle(
                        color: isUnlocked
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.description,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${t.month}/${t.day}';
  }
}
