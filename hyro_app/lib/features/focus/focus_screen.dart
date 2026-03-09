import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import 'bloc/timer_cubit.dart';
import 'bloc/timer_state.dart';
import 'widgets/circular_timer.dart';
import 'widgets/timer_controls.dart';
import 'widgets/mode_selector.dart';
import 'widgets/session_info_card.dart';
import 'widgets/mascot_card.dart';
import 'widgets/mini_task_list.dart';
import 'widgets/activity_chart.dart';

/// The main Focus screen with the Pomodoro timer and sidebar widgets.
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        if (isDesktop) {
          return _DesktopLayout(state: state);
        }
        return _MobileLayout(state: state);
      },
    );
  }
}

// ── Desktop: two-column layout ──
class _DesktopLayout extends StatelessWidget {
  final TimerState state;
  const _DesktopLayout({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimerCubit>();

    return Padding(
      padding: const EdgeInsets.only(left: 72, top: 32, right: 32, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left column: timer (SCROLLABLE IF NEEDED) ──
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      Expanded(
                        flex: 10,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate a dynamic size based on available height,
                            // ensuring it leaves room for controls and spacing.
                            // Max size 460, Min size 160 (to force it to fit without scroll).
                            final availableHeight = constraints.maxHeight;
                            final desiredTimerSize =
                                availableHeight -
                                240; // 240px reserved for controls and padding
                            final timerSize = desiredTimerSize.clamp(
                              160.0,
                              460.0,
                            );

                            return Column(
                              children: [
                                // Top spacer to push content down
                                const Spacer(flex: 1),

                                // The content (Timer, Controls, Scroller)
                                CircularTimer(
                                  remainingSeconds: state.remainingSeconds,
                                  progress: state.progress,
                                  label: _getTimerLabel(state.mode),
                                  size: timerSize,
                                ),
                                const SizedBox(height: 32),
                                TimerControls(
                                  isRunning: state.isRunning,
                                  isPaused: state.isPaused,
                                  onStart: cubit.start,
                                  onPause: cubit.pause,
                                  onResume: cubit.resume,
                                  onReset: cubit.reset,
                                  onStop: cubit.stop,
                                ),
                                const SizedBox(height: 24),
                                ModeSelector(
                                  currentMode: state.mode,
                                  onModeChanged: cubit.setMode,
                                ),

                                // Bottom spacer (flex: 2) to push content higher up
                                // compensating for the space the music player takes later.
                                const Spacer(flex: 3),
                              ],
                            );
                          },
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                // ── Right column: info cards (SCROLLABLE) ──
                SizedBox(
                  width: 320, // Fixed width so data cards aren't stretched
                  child: ListView(
                    // ListView instead of SingleChildScrollView+Column for better scroll behavior
                    children: [
                      SessionInfoCard(
                        completedSessions: state.completedSessions,
                        totalFocusMinutes: state.totalFocusMinutes,
                      ),
                      const SizedBox(height: 16),
                      const MascotCard(),
                      const SizedBox(height: 16),
                      const MiniTaskList(),
                      const SizedBox(height: 16),
                      const ActivityChart(),
                      const SizedBox(height: 32), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deep Work Session', style: AppTypography.h1),
            const SizedBox(height: 4),
            Text(
              '${dayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day} • Focus Streak: 5 days 🔥',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.dark_mode, color: AppColors.textSecondary),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getTimerLabel(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return 'TIME UNTIL BREAK';
      case TimerMode.shortBreak:
        return 'SHORT BREAK';
      case TimerMode.longBreak:
        return 'LONG 12 BREAK';
    }
  }
}

// ── Mobile: single-column scrollable layout ──
class _MobileLayout extends StatelessWidget {
  final TimerState state;
  const _MobileLayout({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimerCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 64, left: 20, right: 20, bottom: 20),
      child: Column(
        children: [
          // Header
          Text('Deep Work Session', style: AppTypography.h2),
          const SizedBox(height: 4),
          Text('Focus Streak: 5 days 🔥', style: AppTypography.bodySmall),
          const SizedBox(height: 24),
          // Session info
          SessionInfoCard(
            completedSessions: state.completedSessions,
            totalFocusMinutes: state.totalFocusMinutes,
          ),
          const SizedBox(height: 24),
          // Timer
          CircularTimer(
            remainingSeconds: state.remainingSeconds,
            progress: state.progress,
            label: _getTimerLabel(state.mode),
            size: 260,
          ),
          const SizedBox(height: 24),
          // Controls
          TimerControls(
            isRunning: state.isRunning,
            isPaused: state.isPaused,
            onStart: cubit.start,
            onPause: cubit.pause,
            onResume: cubit.resume,
            onReset: cubit.reset,
            onStop: cubit.stop,
          ),
          const SizedBox(height: 20),
          // Mode selector
          ModeSelector(currentMode: state.mode, onModeChanged: cubit.setMode),
          const SizedBox(height: 24),
          const MascotCard(),
          const SizedBox(height: 16),
          const MiniTaskList(),
          const SizedBox(height: 16),
          const ActivityChart(),
          const SizedBox(height: 80), // space for radio bar
        ],
      ),
    );
  }

  String _getTimerLabel(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return 'TIME UNTIL BREAK';
      case TimerMode.shortBreak:
        return 'SHORT BREAK';
      case TimerMode.longBreak:
        return 'LONG BREAK';
    }
  }
}
