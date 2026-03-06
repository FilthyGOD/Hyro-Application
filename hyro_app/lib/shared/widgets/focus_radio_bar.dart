import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Persistent mini player bar for Focus Radio / Spotify.
class FocusRadioBar extends StatefulWidget {
  const FocusRadioBar({super.key});

  @override
  State<FocusRadioBar> createState() => _FocusRadioBarState();
}

class _FocusRadioBarState extends State<FocusRadioBar> {
  bool _isPlaying = false;
  int _selectedAmbience = 0;
  static const _ambiences = ['RAIN', 'CAFE', 'WHITE'];
  static const _ambienceIcons = [Icons.water_drop, Icons.coffee, Icons.graphic_eq];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.radioBarBg,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ── Track info ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deep Focus – Ambie...',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('FOCUS RADIO', style: AppTypography.labelSmall.copyWith(fontSize: 9)),
              ],
            ),
          ),
          // ── Playback controls ──
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.skip_previous, color: AppColors.textSecondary, size: 20),
            splashRadius: 18,
          ),
          IconButton(
            onPressed: () => setState(() => _isPlaying = !_isPlaying),
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: AppColors.primary,
              size: 32,
            ),
            splashRadius: 20,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.skip_next, color: AppColors.textSecondary, size: 20),
            splashRadius: 18,
          ),
          const SizedBox(width: 12),
          // ── Ambience chips ──
          ...List.generate(_ambiences.length, (i) {
            final isSelected = i == _selectedAmbience;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _selectedAmbience = i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _ambienceIcons[i],
                      size: 18,
                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _ambiences[i],
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 8,
                        color: isSelected ? AppColors.primary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          // ── Volume ──
          const Icon(Icons.volume_up, color: AppColors.textTertiary, size: 18),
        ],
      ),
    );
  }
}
