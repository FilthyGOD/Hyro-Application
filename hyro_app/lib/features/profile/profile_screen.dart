import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../screens/auth/login_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';
import '../../providers/ui_provider.dart';
import '../mascot/mascot_controller.dart';
import '../settings/settings_screen.dart';
import '../../shared/widgets/achievement_summary.dart';
import '../../shared/widgets/recent_milestones.dart';
/// Profile screen showing user info, level/XP, coins, and daily missions.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();

    return SingleChildScrollView(
      padding: MediaQuery.of(context).size.width < 800
          ? EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 72,
              bottom: 32,
              left: 24,
              right: 24,
            )
          : const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Mascot Avatar ──
          Consumer<MascotController>(
            builder: (context, mascot, _) {
              if (!mascot.isLoaded) {
                return CircleAvatar(
                  radius: 72,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    auth.currentUser?.name?.substring(0, 1).toUpperCase() ?? 'H',
                    style: AppTypography.h1.copyWith(fontSize: 48),
                  ),
                );
              }
              return Container(
                width: 144,
                height: 144,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLight,
                ),
                clipBehavior: Clip.hardEdge,
                child: RiveWidget(
                  controller: mascot.controller!,
                  fit: Fit.contain,
                ),
              );
            },
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
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
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
          
          // ── Logros ──
          const AchievementSummaryGrid(),
          const SizedBox(height: 24),
          const RecentMilestonesCard(),
          
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

