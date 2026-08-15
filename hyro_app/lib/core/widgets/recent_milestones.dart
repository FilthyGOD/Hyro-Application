import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/stats/stats_provider.dart';
import 'glass_card.dart';

class MilestoneData {
  final IconData icon;
  final String title;
  final String description;
  final double current;
  final double target;

  MilestoneData({
    required this.icon,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
  });
}

class MilestoneItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isCompleted;
  final double progress;

  const MilestoneItem({
    super.key,
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
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
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
                color: AppColors.primary.withValues(alpha: 0.2),
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

class RecentMilestonesCard extends StatelessWidget {
  const RecentMilestonesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<StatsProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    
    final streak = profileProvider.rachaActual;
    final sessionsToday = statsProvider.todaysStats?.focusSessions ?? 0;
    final totalHours = statsProvider.totalFocusHours;

    final achievements = [
      MilestoneData(
        icon: Icons.local_fire_department,
        title: 'Primera Llama',
        description: 'Construye una racha de 1 día',
        current: streak.toDouble(),
        target: 1.0,
      ),
      MilestoneData(
        icon: Icons.local_cafe,
        title: 'Racha de Bronce',
        description: 'Mantén una racha de 7 días',
        current: streak.toDouble(),
        target: 7.0,
      ),
      MilestoneData(
        icon: Icons.psychology,
        title: 'Hábito Formado',
        description: 'Alcanza una racha de 21 días',
        current: streak.toDouble(),
        target: 21.0,
      ),
      MilestoneData(
        icon: Icons.military_tech,
        title: 'Club del Siglo',
        description: 'Meta legendaria de 100 días',
        current: streak.toDouble(),
        target: 100.0,
      ),
      MilestoneData(
        icon: Icons.timer,
        title: 'Calentando Motores',
        description: 'Acumula 5 horas totales de enfoque',
        current: totalHours,
        target: 5.0,
      ),
      MilestoneData(
        icon: Icons.explore,
        title: 'Explorador del Tiempo',
        description: 'Acumula 50 horas de dedicación',
        current: totalHours,
        target: 50.0,
      ),
      MilestoneData(
        icon: Icons.auto_awesome,
        title: 'Maestro del Enfoque',
        description: 'Completa 100 horas totales',
        current: totalHours,
        target: 100.0,
      ),
      MilestoneData(
        icon: Icons.task_alt,
        title: 'Doble Sesión',
        description: 'Completa 2 sesiones en un día',
        current: sessionsToday.toDouble(),
        target: 2.0,
      ),
      MilestoneData(
        icon: Icons.bolt,
        title: 'Imparable',
        description: 'Completa 5 sesiones en un solo día',
        current: sessionsToday.toDouble(),
        target: 5.0,
      ),
      MilestoneData(
        icon: Icons.self_improvement,
        title: 'Monje del Silencio',
        description: 'Alcanza 200 horas de concentración',
        current: totalHours,
        target: 200.0,
      ),
    ];

    final completed = achievements.where((a) => a.current >= a.target).toList();
    final inProgress = achievements.where((a) => a.current < a.target).toList();

    completed.sort((a, b) => b.target.compareTo(a.target));
    inProgress.sort((a, b) {
      final aProgress = a.current / a.target;
      final bProgress = b.current / b.target;
      return bProgress.compareTo(aProgress);
    });

    final displayAchievements =
        [...completed.take(2), ...inProgress.take(4)].take(5).toList();

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
          ...displayAchievements.map((ach) {
            final isLast = ach == displayAchievements.last;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: MilestoneItem(
                icon: ach.icon,
                title: ach.title,
                description: ach.description,
                isCompleted: ach.current >= ach.target,
                progress: (ach.current / ach.target).clamp(0.0, 1.0),
              ),
            );
          }),
        ],
      ),
    );
  }
}
