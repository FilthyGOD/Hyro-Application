import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'glass_card.dart';
import 'package:provider/provider.dart';
import '../../features/profile/providers/profile_provider.dart';

class AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const AchievementCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), // Approximately withAlpha(30)
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(fontSize: 13),
                ),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementSummaryGrid extends StatelessWidget {
  const AchievementSummaryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AchievementCard(
                icon: Icons.local_fire_department,
                color: Colors.orange,
                title: 'Racha de ${profile.rachaMaxima} días',
                subtitle: 'Récord Actual',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AchievementCard(
                icon: Icons.emoji_events,
                color: Colors.amber,
                title: '${profile.sesionesMes} Sesiones',
                subtitle: 'Este Mes',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AchievementCard(
                icon: Icons.timer,
                color: AppColors.primary,
                title: '${(profile.minutosEnfoqueTotal / 60.0).toStringAsFixed(1)} Horas',
                subtitle: 'Enfoque Total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AchievementCard(
                icon: Icons.task_alt,
                color: AppColors.breakGreen,
                title: '${profile.tareasCompletadas} Tareas',
                subtitle: 'Completadas',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
