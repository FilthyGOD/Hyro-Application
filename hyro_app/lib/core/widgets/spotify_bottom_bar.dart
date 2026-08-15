import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../services/spotify/spotify_auth_service.dart';
import '../services/spotify/spotify_player_service.dart';
import '../providers/ui_provider.dart';
import 'package:provider/provider.dart';

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
      return _buildLiquidBarContainer(
        child: Row(
          children: [
            const Icon(Icons.music_note, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Conectar Spotify para escuchar música',
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: widget.authService.authenticate,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Conectar'),
            ),
          ],
        ),
      );
    }

    final track = widget.playerService.currentTrack;

    return _buildLiquidBarContainer(
      child: Row(
        children: [
          // ── Información de la pista ──
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                      color: Colors.white70,
                      size: 24,
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track?.name ?? 'Sin reproducción actual',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track?.artist ?? 'Spotify',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // ── Controles de reproducción ──
          IconButton(
            onPressed: widget.playerService.skipPrevious,
            icon: const Icon(
              Icons.skip_previous_rounded,
              color: Colors.white,
              size: 28,
            ),
            splashRadius: 24,
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
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 40,
            ),
            splashRadius: 24,
          ),
          IconButton(
            onPressed: widget.playerService.skipNext,
            icon: const Icon(
              Icons.skip_next_rounded,
              color: Colors.white,
              size: 28,
            ),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidBarContainer({required Widget child}) {
    return Dismissible(
      key: const Key('spotify_bottom_bar'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) {
        context.read<UiProvider>().setMusicBarMinimized(true);
      },
      child: SafeArea(
        child: Center(
        child: Container(
          height: 72,
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
