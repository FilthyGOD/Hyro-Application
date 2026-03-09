import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/spotify/spotify_auth_service.dart';
import '../../core/services/spotify/spotify_player_service.dart';

class SpotifyBottomBar extends StatefulWidget {
  final SpotifyAuthService authService;
  final SpotifyPlayerService playerService;

  const SpotifyBottomBar({
    super.key,
    required this.authService,
    required this.playerService,
  });

  @override
  State<SpotifyBottomBar> createState() => _SpotifyBottomBarState();
}

class _SpotifyBottomBarState extends State<SpotifyBottomBar> {
  int _selectedAmbience = 0;
  static const _ambiences = ['RAIN', 'CAFE', 'WHITE'];
  static const _ambienceIcons = [
    Icons.water_drop,
    Icons.coffee,
    Icons.graphic_eq,
  ];

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onStateChanged);
    widget.playerService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onStateChanged);
    widget.playerService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authService.isAuthenticated) {
      return SafeArea(
        child: Center(
          child: Container(
            height: 64,
            constraints: const BoxConstraints(maxWidth: 800),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.radioBarBg,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.music_note, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Conectar Spotify para escuchar música',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.authService.authenticate,
                  child: const Text('Conectar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final track = widget.playerService.currentTrack;

    return SafeArea(
      child: Center(
        child: Container(
          height: 64,
          constraints: const BoxConstraints(maxWidth: 800),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.radioBarBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 0, 24, 0),
          child: Row(
            children: [
              // ── Track info ──
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  image:
                      track != null && track.imageUrl.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(track.imageUrl),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    track == null || track.imageUrl.isEmpty
                        ? const Icon(
                          Icons.music_note,
                          color: AppColors.primary,
                          size: 20,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track?.name ?? 'Sin reproducción actual',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track?.artist ?? 'Spotify',
                      style: AppTypography.labelSmall.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
              // ── Playback controls ──
              IconButton(
                onPressed: widget.playerService.skipPrevious,
                icon: const Icon(
                  Icons.skip_previous,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                splashRadius: 18,
              ),
              IconButton(
                onPressed: () {
                  if (track?.isPlaying == true) {
                    widget.playerService.pause();
                  } else {
                    widget.playerService.play();
                  }
                },
                icon: Icon(
                  track?.isPlaying == true
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: AppColors.primary,
                  size: 32,
                ),
                splashRadius: 20,
              ),
              IconButton(
                onPressed: widget.playerService.skipNext,
                icon: const Icon(
                  Icons.skip_next,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                splashRadius: 18,
              ),
              const SizedBox(width: 12),
              // ── Ambience chips (Keep user's current ambience vibes) ──
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
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _ambiences[i],
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 8,
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              // ── Volume ──
              const Icon(
                Icons.volume_up,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
