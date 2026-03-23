import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_provider.dart';
import 'settings_provider.dart';
import '../focus/bloc/timer_cubit.dart';

/// Settings screen for Pomodoro durations, notifications, and theme.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return SingleChildScrollView(
      padding:
          MediaQuery.of(context).size.width < 800
              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 32)
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
                    'Ajustes',
                    style: isMobile ? AppTypography.h2 : AppTypography.h1,
                    textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  ),
                  const SizedBox(height: 8),
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
                  min: 1,
                  max: 60,
                  suffix: 'min',
                  onChanged: (v) {
                    settings.setPomodoroDuration(v);
                    context.read<TimerCubit>().refreshIfIdle();
                  },
                ),
                const SizedBox(height: 16),
                _SliderSetting(
                  label: 'Descanso Corto',
                  value: settings.shortBreakDuration,
                  min: 1,
                  max: 15,
                  suffix: 'min',
                  onChanged: (v) {
                    settings.setShortBreakDuration(v);
                    context.read<TimerCubit>().refreshIfIdle();
                  },
                ),
                const SizedBox(height: 16),
                _SliderSetting(
                  label: 'Descanso Largo',
                  value: settings.longBreakDuration,
                  min: 5,
                  max: 30,
                  suffix: 'min',
                  onChanged: (v) {
                    settings.setLongBreakDuration(v);
                    context.read<TimerCubit>().refreshIfIdle();
                  },
                ),
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
                const SizedBox(height: 16),
                _ToggleSetting(
                  label: 'Notificaciones',
                  subtitle: 'Recibe notificaciones al terminar el temporizador',
                  value: settings.notificationsEnabled,
                  onChanged: (v) => settings.setNotificationsEnabled(v),
                ),
                const Divider(height: 24),
                _ToggleSetting(
                  label: 'Pausa Automática',
                  subtitle: 'Si sales de la app, el contador se pausa',
                  value: settings.autoPauseTimer,
                  onChanged: (v) => settings.setAutoPauseTimer(v),
                ),
                const Divider(height: 24),
                _ToggleSetting(
                  label: 'Modo Estricto',
                  subtitle: 'Bloquea salir de la pantalla mientras el temporizador esté activo',
                  value: settings.strictMode,
                  onChanged: (v) => settings.setStrictMode(v),
                ),
                const Divider(height: 24),
                _ToggleSetting(
                  label: 'Ocultar Tarjetas',
                  subtitle: 'Oculta las tarjetas de tareas y estadísticas en la vista de enfoque',
                  value: settings.hideFocusCards,
                  onChanged: (v) => settings.setHideFocusCards(v),
                ),
                const Divider(height: 24),
                _ToggleSetting(
                  label: 'Modo Oscuro',
                  subtitle: 'Usar tema oscuro',
                  value: true, // App uses hardcoded dark theme for now
                  onChanged: (v) {},
                ),
              ],
            ),
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
                      subtitle: 'Mostrar controles de música en la parte inferior',
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
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
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
              '${value.toInt()} $suffix',
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
            divisions: (max - min).toInt(),
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
  final ValueChanged<bool> onChanged;

  const _ToggleSetting({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
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
              side: WidgetStateProperty.all(const BorderSide(color: AppColors.cardBorder)),
            ),
          ),
        ),
      ],
    );
  }
}
