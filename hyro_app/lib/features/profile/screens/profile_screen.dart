import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/ui_provider.dart';
import '../../mascot/mascot_controller.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/widgets/mobile_stats_bar.dart';
import '../../../core/widgets/achievement_summary.dart';
import '../../../core/widgets/recent_milestones.dart';

/// Profile screen showing user info, level/XP, coins, and daily missions.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();

    final isMobile = MediaQuery.of(context).size.width < 800;

    final content = SingleChildScrollView(
      padding:
          isMobile
              ? EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 72,
                bottom: 32,
                left: 24,
                right: 24,
              )
              : const EdgeInsets.all(32),
      child: Column(
        children: [
          if (!isMobile)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          if (!isMobile) const SizedBox(height: 8),
          // ── Mascot Avatar ──
          Consumer<MascotController>(
            builder: (context, mascot, _) {
              if (!mascot.isLoaded) {
                return CircleAvatar(
                  radius: 72,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    auth.currentUser?.name?.substring(0, 1).toUpperCase() ??
                        'H',
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
          // ── Identificador único: NombreUsuario#Código ──
          if (!auth.isGuest && profile.displayTag != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Text(
                  profile.displayTag!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
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
                        SvgPicture.asset(
                          'assets/images/HyroCoins.svg',
                          width: 20,
                          height: 20,
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

    if (isMobile) {
      final topPadding = MediaQuery.of(context).padding.top;
      return Stack(
        children: [
          content,
          Positioned(
            top: topPadding + 8,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardBorder.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }
}
