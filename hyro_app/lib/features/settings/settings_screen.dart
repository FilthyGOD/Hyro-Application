import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';

/// Settings screen for Pomodoro durations, notifications, and theme.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _pomodoroDuration = 25;
  double _shortBreak = 5;
  double _longBreak = 15;
  bool _notifications = true;
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTypography.h1),
          const SizedBox(height: 8),
          Text('Customize your focus experience', style: AppTypography.bodyMedium),
          const SizedBox(height: 32),
          // ── Timer settings ──
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Timer', style: AppTypography.h3),
                const SizedBox(height: 20),
                _SliderSetting(
                  label: 'Pomodoro Duration',
                  value: _pomodoroDuration,
                  min: 10,
                  max: 60,
                  suffix: 'min',
                  onChanged: (v) => setState(() => _pomodoroDuration = v),
                ),
                const SizedBox(height: 16),
                _SliderSetting(
                  label: 'Short Break',
                  value: _shortBreak,
                  min: 1,
                  max: 15,
                  suffix: 'min',
                  onChanged: (v) => setState(() => _shortBreak = v),
                ),
                const SizedBox(height: 16),
                _SliderSetting(
                  label: 'Long Break',
                  value: _longBreak,
                  min: 5,
                  max: 30,
                  suffix: 'min',
                  onChanged: (v) => setState(() => _longBreak = v),
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
                Text('Preferences', style: AppTypography.h3),
                const SizedBox(height: 16),
                _ToggleSetting(
                  label: 'Notifications',
                  subtitle: 'Get notified when timer finishes',
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                const Divider(height: 24),
                _ToggleSetting(
                  label: 'Dark Mode',
                  subtitle: 'Use dark theme',
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
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
                          Text('Connect Spotify', style: AppTypography.labelLarge),
                          Text('Listen to focus playlists', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                      ),
                      child: const Text('Connect'),
                    ),
                  ],
                ),
              ],
            ),
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
            Text('${value.toInt()} $suffix', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary)),
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
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}
