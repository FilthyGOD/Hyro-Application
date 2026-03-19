import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';
import 'stats_provider.dart';
import 'widgets/streak_calendar.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, statsProvider, child) {
        final streak = statsProvider.currentStreak;
        final monthStats = statsProvider.getStatsForMonth(
          _displayMonth.year,
          _displayMonth.month,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estadísticas y Logros', style: AppTypography.h1),
              const SizedBox(height: 8),
              Text(
                'Haz seguimiento de tu consistencia de enfoque y progreso',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 32),

              // ── Current Streak Card ──
              _buildCurrentStreakCard(streak),
              const SizedBox(height: 24),

              // ── Bottom Row/Column: Calendar & Milestones ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: StreakCalendar(
                            displayMonth: _displayMonth,
                            monthStats: monthStats,
                            onPreviousMonth: _previousMonth,
                            onNextMonth: _nextMonth,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: _buildRecentMilestones(
                            statsProvider.totalFocusHours,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreakCalendar(
                          displayMonth: _displayMonth,
                          monthStats: monthStats,
                          onPreviousMonth: _previousMonth,
                          onNextMonth: _nextMonth,
                        ),
                        const SizedBox(height: 24),
                        _buildRecentMilestones(statsProvider.totalFocusHours),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentStreakCard(int streak) {
    // Next milestone logic: 10, 30, 50, 100, 365, etc.
    final milestones = [10, 30, 50, 100, 365, 900, 1000];
    int nextMilestone = milestones.firstWhere(
      (m) => m > streak,
      orElse: () => streak + 100,
    );
    double progress = streak / nextMilestone;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'RACHA ACTUAL',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.orange,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: clampDouble(MediaQuery.of(context).size.width * 0.3, 80, 150),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    streak.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.orange,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'días de racha',
            style: AppTypography.h3.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximo Logro: $nextMilestone Días',
                style: AppTypography.bodySmall,
              ),
              Text(
                '$streak / $nextMilestone DÍAS',
                style: AppTypography.labelSmall.copyWith(color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceLight,
            color: Colors.orange,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMilestones(double totalHours) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Logros Recientes', style: AppTypography.h3),
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${totalHours.toStringAsFixed(1)} h',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          _MilestoneItem(
            icon: Icons.local_fire_department,
            title: 'Primera Llama',
            description: 'Alcanzaste una racha de 1 día',
            isCompleted: true,
            progress: 1.0,
          ),
          const SizedBox(height: 16),
          _MilestoneItem(
            icon: Icons.auto_awesome,
            title: 'Maestro del Enfoque',
            description: '100 Horas Totales',
            isCompleted: totalHours >= 100,
            progress: (totalHours / 100).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 16),
          _MilestoneItem(
            icon: Icons.military_tech,
            title: 'Club del Siglo',
            description: 'Meta de Racha de 100 Días',
            isCompleted: false, // Could pass current streak here too
            progress: 0.1, // Placeholder
          ),
        ],
      ),
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isCompleted;
  final double progress;

  const _MilestoneItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isCompleted
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted ? AppColors.primary : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.white : Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 16,
              ),
            )
          else
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTypography.labelSmall.copyWith(color: Colors.white54),
            ),
        ],
      ),
    );
  }
}
