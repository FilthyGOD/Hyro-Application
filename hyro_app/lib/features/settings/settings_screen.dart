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
                  min: 10,
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
                  label: 'Modo Oscuro',
                  subtitle: 'Usar tema oscuro',
                  value: true, // App uses hardcoded dark theme for now
                  onChanged: (v) {},
                ),
                const Divider(height: 24),
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
