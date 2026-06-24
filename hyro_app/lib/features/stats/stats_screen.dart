import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide Animation;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';
import 'stats_provider.dart';
import 'widgets/streak_calendar.dart';
import '../../providers/ui_provider.dart';
import '../focus/widgets/session_info_card.dart';
import '../focus/widgets/activity_chart.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
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
          padding: MediaQuery.of(context).size.width < 800
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
                        textAlign: isMobile ? TextAlign.center : TextAlign.start,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supera tus metas y desbloquea logros',
                        style: AppTypography.bodyMedium,
                        textAlign: isMobile ? TextAlign.center : TextAlign.start,
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

              // ── Achievement Summary Cards ──
              _buildAchievementSummary(profileProvider),
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
                            streak,
                            sessionsToday,
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
                        _buildRecentMilestones(statsProvider.totalFocusHours, streak, sessionsToday),
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
                        const Expanded(
                          flex: 3,
                          child: ActivityChart(),
                        ),
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SessionInfoCard(
                          completedSessions: sessionsToday,
                          totalFocusMinutes: minutesToday,
                        ),
                        const SizedBox(height: 24),
                        const ActivityChart(),
                      ],
                    );
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
              final height = clampDouble(MediaQuery.of(context).size.width * 0.3, 80, 150);
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

  Widget _buildRecentMilestones(double totalHours, int streak, int sessionsToday) {
    final achievements = [
      _MilestoneData(
        icon: Icons.local_fire_department,
        title: 'Primera Llama',
        description: 'Construye una racha de 1 día',
        current: streak.toDouble(),
        target: 1.0,
      ),
      _MilestoneData(
        icon: Icons.local_cafe,
        title: 'Racha de Bronce',
        description: 'Mantén una racha de 7 días',
        current: streak.toDouble(),
        target: 7.0,
      ),
      _MilestoneData(
        icon: Icons.psychology,
        title: 'Hábito Formado',
        description: 'Alcanza una racha de 21 días',
        current: streak.toDouble(),
        target: 21.0,
      ),
      _MilestoneData(
        icon: Icons.military_tech,
        title: 'Club del Siglo',
        description: 'Meta legendaria de 100 días',
        current: streak.toDouble(),
        target: 100.0,
      ),
      _MilestoneData(
        icon: Icons.timer,
        title: 'Calentando Motores',
        description: 'Acumula 5 horas totales de enfoque',
        current: totalHours,
        target: 5.0,
      ),
      _MilestoneData(
        icon: Icons.explore,
        title: 'Explorador del Tiempo',
        description: 'Acumula 50 horas de dedicación',
        current: totalHours,
        target: 50.0,
      ),
      _MilestoneData(
        icon: Icons.auto_awesome,
        title: 'Maestro del Enfoque',
        description: 'Completa 100 horas totales',
        current: totalHours,
        target: 100.0,
      ),
      _MilestoneData(
        icon: Icons.task_alt,
        title: 'Doble Sesión',
        description: 'Completa 2 sesiones en un día',
        current: sessionsToday.toDouble(),
        target: 2.0,
      ),
      _MilestoneData(
        icon: Icons.bolt,
        title: 'Imparable',
        description: 'Completa 5 sesiones en un solo día',
        current: sessionsToday.toDouble(),
        target: 5.0,
      ),
      _MilestoneData(
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

    final displayAchievements = [
      ...completed.take(2),
      ...inProgress.take(4),
    ].take(5).toList();

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
              child: _MilestoneItem(
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

  // ── Daily Missions Section ──
  Widget _buildDailyMissionsSection(BuildContext context) {
    final missions = context.watch<MissionsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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

  // ── Achievement Summary Cards ──
  Widget _buildAchievementSummary(ProfileProvider profile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AchievementCard(
                icon: Icons.local_fire_department,
                color: Colors.orange,
                title: 'Racha de ${profile.rachaMaxima} días',
                subtitle: 'Récord Actual',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AchievementCard(
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
              child: _AchievementCard(
                icon: Icons.timer,
                color: AppColors.primary,
                title: '${(profile.minutosEnfoqueTotal / 60.0).toStringAsFixed(1)} Horas',
                subtitle: 'Enfoque Total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AchievementCard(
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
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isCompleted
                  ? AppColors.primary.withValues(alpha: 0.3)
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

class _MilestoneData {
  final IconData icon;
  final String title;
  final String description;
  final double current;
  final double target;

  _MilestoneData({
    required this.icon,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
  });
}
