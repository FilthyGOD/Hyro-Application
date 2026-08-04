import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide Animation;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';
import 'stats_provider.dart';
import 'widgets/streak_calendar.dart';
import '../../core/providers/ui_provider.dart';
import '../focus/widgets/session_info_card.dart';
import '../focus/widgets/activity_chart.dart';
import '../profile/providers/profile_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../mascot/mascot_controller.dart';
import '../missions/missions_provider.dart';
import '../missions/models/daily_mission.dart';

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

    // Trigger racha animation on entering stats screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mascot = context.read<MascotController>();

      // Use ProfileProvider which correctly syncs 'racha_actual' from Supabase
      final profileProvider = context.read<ProfileProvider>();
      final streak = profileProvider.rachaActual;

      mascot.triggerRacha(streak);
    });
  }

  @override
  void dispose() {
    // Return mascot to movimiento_suave when leaving stats
    // (in case this widget gets disposed independently of navigation)
    super.dispose();
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
    return Consumer2<StatsProvider, ProfileProvider>(
      builder: (context, statsProvider, profileProvider, child) {
        final streak = profileProvider.rachaActual;
        final monthStats = statsProvider.getStatsForMonth(
          _displayMonth.year,
          _displayMonth.month,
        );
        final sessionsToday = statsProvider.todaysStats?.focusSessions ?? 0;
        final minutesToday = statsProvider.todaysStats?.focusMinutes ?? 0;

        return SingleChildScrollView(
          padding:
              MediaQuery.of(context).size.width < 800
                  ? EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 72,
                    bottom: 32,
                    left: 24,
                    right: 24,
                  )
                  : const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment:
                MediaQuery.of(context).size.width < 800
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = MediaQuery.of(context).size.width < 800;
                  return Column(
                    children: [
                      Text(
                        'Desafíos y Logros',
                        style: isMobile ? AppTypography.h2 : AppTypography.h1,
                        textAlign:
                            isMobile ? TextAlign.center : TextAlign.start,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supera tus metas y desbloquea logros',
                        style: AppTypography.bodyMedium,
                        textAlign:
                            isMobile ? TextAlign.center : TextAlign.start,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // ── Current Streak Card ──
              _buildCurrentStreakCard(streak),
              const SizedBox(height: 24),

              // ── Daily Missions ──
              _buildDailyMissionsSection(context),
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
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(flex: 3, child: ActivityChart()),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: SessionInfoCard(
                            completedSessions: sessionsToday,
                            totalFocusMinutes: minutesToday,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column();
                  }
                },
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
          // Rive racha animation replaces the number + fire icon
          Consumer<MascotController>(
            builder: (context, mascot, _) {
              final height = clampDouble(
                MediaQuery.of(context).size.width * 0.3,
                80,
                150,
              );
              if (!mascot.isLoaded) {
                return SizedBox(
                  height: height,
                  child: Center(
                    child: Text(
                      streak.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                        fontSize: 64,
                      ),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: height,
                child: RiveWidget(
                  controller: mascot.controller!,
                  fit: Fit.contain,
                ),
              );
            },
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



  // ── Daily Missions Section ──
  Widget _buildDailyMissionsSection(BuildContext context) {
    final missions = context.watch<MissionsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Misiones Diarias',
              style: AppTypography.h3.copyWith(fontSize: 18),
            ),
          ],
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
      ],
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


