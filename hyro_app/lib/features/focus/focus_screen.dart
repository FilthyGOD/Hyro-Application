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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left column: header + timer ──
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                Center(
                  child: CircularTimer(
                    remainingSeconds: state.remainingSeconds,
                    progress: state.progress,
                    label: _getTimerLabel(state.mode),
                    size: 320,
                  ),
                ),
                const SizedBox(height: 28),
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
              ],
            ),
          ),
          const SizedBox(width: 24),
          // ── Right column: info cards ──
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
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
                ],
              ),
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
        return 'LONG BREAK';
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
