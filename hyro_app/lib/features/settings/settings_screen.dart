import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ui_provider.dart';
import 'settings_provider.dart';
import '../focus/bloc/timer_cubit.dart';
import '../../core/services/notifications_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../tasks/tasks_provider.dart';
import '../stats/stats_provider.dart';
import 'dart:io';
import '../../core/services/strict_mode_service.dart';

/// Settings screen for Pomodoro durations, notifications, and theme.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _awaitingStrictModePermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _awaitingStrictModePermission) {
      _awaitingStrictModePermission = false;
      final service = StrictModeService();
      final granted = await service.checkAndRequestPermissions();
      if (granted && mounted) {
        context.read<SettingsProvider>().setStrictMode(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modo Estricto activado correctamente')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Ajustes', style: AppTypography.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding:
            MediaQuery.of(context).size.width < 800
                ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
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
                      'Personaliza tu experiencia de enfoque',
                      style: AppTypography.bodyMedium,
                      textAlign: isMobile ? TextAlign.center : TextAlign.start,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // ── Timer settings ──
            GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Temporizador', style: AppTypography.h3),
                const SizedBox(height: 20),
                _SliderSetting(
                  label: 'Duración del Pomodoro',
                  value: settings.pomodoroDuration,
                  min: Supabase.instance.client.auth.currentUser?.email == 'jairothehyrax@gmail.com' ? 2 : 25,
                  max: 60,
                  suffix: 'min',
                  onChanged: (v) {
                    settings.setPomodoroDuration(v);
                    if (Supabase.instance.client.auth.currentUser?.email != 'jairothehyrax@gmail.com') {
                      settings.setShortBreakDuration(v / 5);
                    }
                    context.read<TimerCubit>().refreshIfIdle();
                  },
                ),
                if (Supabase.instance.client.auth.currentUser?.email == 'jairothehyrax@gmail.com') ...[
                  const SizedBox(height: 16),
                  _SliderSetting(
                    label: 'Descanso Corto (Debug)',
                    value: settings.shortBreakDuration,
                    min: 0.5,
                    max: 5,
                    suffix: 'min',
                    onChanged: (v) {
                      settings.setShortBreakDuration(v);
                      context.read<TimerCubit>().refreshIfIdle();
                    },
                  ),
                ],
                const SizedBox(height: 16),
                _TimerSizeSelector(
                  currentSize: settings.timerSize,
                  onSizeChanged: (v) {
                    settings.setTimerSize(v);
                    context.read<TimerCubit>().refreshIfIdle();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Preferences ──
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preferencias', style: AppTypography.h3),
                const Divider(height: 24),
                _ToggleSetting(
                  label: 'Pausa Automática',
                  subtitle: 'Si sales de la app, el contador se pausa',
                  value: settings.autoPauseTimer,
                  disabled: settings.strictMode,
                  onChanged: (v) => settings.setAutoPauseTimer(v),
                ),
                if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ...[
                  const Divider(height: 24),
                  _ToggleSetting(
                    label: 'Minimizar a la Bandeja',
                    subtitle: 'Al cerrar la ventana, la app seguirá activa en 2do plano',
                    value: settings.minimizeToTray,
                    onChanged: (v) => settings.setMinimizeToTray(v),
                  ),
                ],
                if (Platform.isAndroid) ...[
                  const Divider(height: 24),
                  _ToggleSetting(
                    label: 'Modo Estricto (Experimental)',
                    subtitle:
                        'Si sales de Hyro durante una sesión, te mostraremos una alerta para que vuelvas',
                    value: settings.strictMode,
                    onChanged: (v) async {
                      debugPrint('[StrictMode][Settings] Toggle changed to: $v');
                      if (v) {
                        // Request permissions when enabling
                        debugPrint('[StrictMode][Settings] Requesting permissions...');
                        final service = StrictModeService();
                        await service.init();
                        final granted = await service.checkAndRequestPermissions();
                        debugPrint('[StrictMode][Settings] Permissions granted: $granted');
                        if (!granted) {
                          // User was sent to system settings — don't enable yet
                          debugPrint('[StrictMode][Settings] Permissions NOT granted, showing snackbar');
                          _awaitingStrictModePermission = true;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Acepta los permisos necesarios y vuelve a Hyro.'),
                              ),
                            );
                          }
                          return;
                        }
                        debugPrint('[StrictMode][Settings] ✅ Enabling strict mode');
                      } else {
                        debugPrint('[StrictMode][Settings] Disabling strict mode');
                      }
                      settings.setStrictMode(v);
                    },
                  ),
                ],
                const Divider(height: 24),
                _ToggleSetting(
                  label: 'Focus Quiz',
                  subtitle: 'Preguntas automáticas para mantener el enfoque',
                  value: settings.focusQuizEnabled,
                  onChanged: (v) {
                    settings.setFocusQuizEnabled(v);
                    context.read<TimerCubit>().refreshIfIdle();
                  },
                ),
                if (settings.focusQuizEnabled) ...[
                  const SizedBox(height: 16),
                  _SliderSetting(
                    label: 'Intervalo del Quiz',
                    value: settings.focusQuizIntervalMinutes,
                    min: 1,
                    max: 15,
                    suffix: 'min',
                    onChanged: (v) {
                      settings.setFocusQuizIntervalMinutes(v);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Notifications Test (debug only) ──
          if (Supabase.instance.client.auth.currentUser?.email == 'jairothehyrax@gmail.com')
            Builder(
              builder: (context) {
                final pendingTasks = context.read<TaskProvider>().tasks.where((t) => !t.isCompleted).length;
                final streak = context.read<StatsProvider>().currentStreak;
                return GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prueba de Notificaciones (Debug)', style: AppTypography.h3),
                      const SizedBox(height: 12),
                      Text(
                        'Usa mensajes reales con datos actuales (tareas: $pendingTasks, racha: $streak)',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      // ── Morning ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.wb_sunny_rounded),
                          label: const Text('☀️ Mañana (8 AM)'),
                          onPressed: () {
                            NotificationsService.instance.testMorningMotivation(
                              pendingTasks: pendingTasks,
                              streak: streak,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withAlpha(50),
                            foregroundColor: Colors.orange,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Afternoon ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.wb_cloudy_rounded),
                          label: const Text('☁️ Tarde (2 PM)'),
                          onPressed: () {
                            NotificationsService.instance.testAfternoonMotivation(
                              pendingTasks: pendingTasks,
                              streak: streak,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.withAlpha(50),
                            foregroundColor: Colors.blueAccent,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Evening ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.nightlight_round),
                          label: const Text('🌙 Noche (8 PM)'),
                          onPressed: () {
                            NotificationsService.instance.testEveningMotivation(
                              pendingTasks: pendingTasks,
                              streak: streak,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.withAlpha(50),
                            foregroundColor: Colors.indigoAccent,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Task Due ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.timer),
                          label: const Text('⏱️ Tarea por Vencer (1 día)'),
                          onPressed: () {
                            final tasks = context.read<TaskProvider>().tasks;
                            final pending = tasks.where((t) => !t.isCompleted).toList();
                            // Pick a real task: prefer one with dueDate, else first pending, else fallback
                            final taskWithDue = pending.where((t) => t.dueDate != null).toList();
                            final taskName = taskWithDue.isNotEmpty
                                ? taskWithDue.first.title
                                : (pending.isNotEmpty ? pending.first.title : 'Mi Tarea');
                            NotificationsService.instance.testTaskReminderDay(taskName, 1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withAlpha(50),
                            foregroundColor: AppColors.primary,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Pomodoro ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('🎯 Fin del Pomodoro'),
                          onPressed: () {
                            NotificationsService.instance.testPomodoroEnd();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withAlpha(50),
                            foregroundColor: Colors.green,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Session Completed ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.bug_report),
                          label: const Text('🐛 Pantalla de Sesión Completada'),
                          onPressed: () {
                             context.read<TimerCubit>().debugForceSessionCompleted();
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Simulando fin de sesión. Revisa la pantalla de Focus.')),
                             );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.withAlpha(50),
                            foregroundColor: Colors.purpleAccent,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Device Time ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: const Text('🕒 Mostrar Hora del Dispositivo'),
                          onPressed: () {
                             final now = DateTime.now();
                             final hourStr = now.hour.toString().padLeft(2, '0');
                             final minStr = now.minute.toString().padLeft(2, '0');
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('🕒 La hora local es: $hourStr:$minStr')),
                             );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.withAlpha(50),
                            foregroundColor: Colors.tealAccent,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          // ── Spotify ──
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spotify', style: AppTypography.h3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conectar Spotify',
                            style: AppTypography.labelLarge,
                          ),
                          Text(
                            'Escucha listas de reproducción para enfocarte',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                      ),
                      child: const Text('Conectar'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Consumer<UiProvider>(
                  builder: (context, ui, _) {
                    return _ToggleSetting(
                      label: 'Barra de Música',
                      subtitle:
                          'Mostrar controles de música en la parte inferior',
                      value: ui.isMusicBarVisible,
                      onChanged: (v) => ui.setMusicBarVisibility(v),
                    );
                  },
                ),
              ],
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
    ));
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelLarge),
            Text(
              value == value.toInt() ? '${value.toInt()} $suffix' : '${value.toStringAsFixed(1)} $suffix',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withAlpha(30),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions ?? ((max - min) * 2).toInt(), // Default to 0.5 steps if no divisions given
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  const _ToggleSetting({
    required this.label,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelLarge),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeThumbColor: disabled ? AppColors.textSecondary : AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _TimerSizeSelector extends StatelessWidget {
  final TimerSize currentSize;
  final ValueChanged<TimerSize> onSizeChanged;

  const _TimerSizeSelector({
    required this.currentSize,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tamaño del Reloj', style: AppTypography.labelLarge),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<TimerSize>(
            segments: const [
              ButtonSegment(
                value: TimerSize.small,
                label: Text('Pequeño', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: TimerSize.medium,
                label: Text('Mediano', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {currentSize},
            onSelectionChanged: (Set<TimerSize> newSelection) {
              onSizeChanged(newSelection.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary.withAlpha(50);
                }
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.white70;
              }),
              side: WidgetStateProperty.all(
                const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
