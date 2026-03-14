import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';

/// Profile screen showing user info and achievements.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // ── Avatar ──
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary,
            child: Text(
              context
                      .watch<AuthProvider>()
                      .currentUser
                      ?.name
                      ?.substring(0, 1)
                      .toUpperCase() ??
                  'H',
              style: AppTypography.h1.copyWith(fontSize: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.watch<AuthProvider>().currentUser?.name ?? 'Usuario',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 4),
          Text(
            context.watch<AuthProvider>().currentUser?.usernameOrEmail ??
                'correo@hyro.app',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 32),
          // ── Achievement cards ──
          Row(
            children: [
              Expanded(
                child: _AchievementCard(
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  title: 'Racha de 5 días',
                  subtitle: 'Récord Actual',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AchievementCard(
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                  title: '32 Sesiones',
                  subtitle: 'Este Mes',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AchievementCard(
                  icon: Icons.timer,
                  color: AppColors.primary,
                  title: '12.5 Horas',
                  subtitle: 'Enfoque Total',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AchievementCard(
                  icon: Icons.task_alt,
                  color: AppColors.breakGreen,
                  title: '18 Tareas',
                  subtitle: 'Completadas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // ── Actions ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AuthProvider>().logout();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _AchievementCard({
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
              color: color.withAlpha(30),
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
