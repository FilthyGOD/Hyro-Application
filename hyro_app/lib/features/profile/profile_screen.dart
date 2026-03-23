import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../missions/missions_provider.dart';
import '../missions/models/daily_mission.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';
import '../../providers/ui_provider.dart';

/// Profile screen showing user info, level/XP, coins, and daily missions.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final missions = context.watch<MissionsProvider>();

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
              auth.currentUser?.name?.substring(0, 1).toUpperCase() ?? 'H',
              style: AppTypography.h1.copyWith(fontSize: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            auth.isGuest
                ? 'Modo Invitado'
                : (auth.currentUser?.name ?? 'Usuario'),
            style: AppTypography.h2,
          ),
          const SizedBox(height: 4),
          if (!auth.isGuest)
            Text(
              auth.currentUser?.usernameOrEmail ?? '',
              style: AppTypography.bodyMedium,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Progreso Local',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ── Level & XP Bar ──
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A25F4), Color(0xFFA855F7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Nv. ${profile.nivel}',
                            style: AppTypography.labelLarge.copyWith(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${profile.experiencia} / ${profile.xpForNextLevel} XP',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.monedas}',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // XP progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: profile.levelProgress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Daily Missions ──
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.assignment,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Misiones Diarias',
                  style: AppTypography.h3.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (missions.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (missions.missions.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Las misiones se generarán automáticamente.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            ...missions.missions.map(
              (mission) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MissionCard(mission: mission),
              ),
            ),
          const SizedBox(height: 24),

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

          // ── Action Button (Login for Guests, Logout for Users) ──
          if (auth.isGuest)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.timerColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cloud_sync, color: Colors.white),
                label: Text(
                  'Iniciar Sesión para Sincronizar',
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
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
          // ── Music Bar Spacing ──
          Consumer<UiProvider>(
            builder: (context, ui, _) {
              return SizedBox(height: ui.isMusicBarVisible ? 100 : 20);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Mission Card Widget ──────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final DailyMission mission;

  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final missions = context.read<MissionsProvider>();

    Color statusColor;
    IconData statusIcon;
    if (mission.isClaimed) {
      statusColor = AppColors.breakGreen;
      statusIcon = Icons.check_circle;
    } else if (mission.isCompleted) {
      statusColor = Colors.amber;
      statusIcon = Icons.star;
    } else {
      statusColor = AppColors.primary;
      statusIcon = Icons.radio_button_unchecked;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mission.title,
                  style: AppTypography.labelLarge.copyWith(
                    fontSize: 14,
                    decoration:
                        mission.isClaimed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '+${mission.xpReward} XP',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(mission.description, style: AppTypography.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: mission.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${mission.currentProgress}/${mission.targetValue}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (mission.isCompleted && !mission.isClaimed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final userId = auth.supabaseUserId;
                  await missions.claimMission(mission.id, userId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '¡Reclamar!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Achievement Card Widget ──────────────────────────────────────────

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
