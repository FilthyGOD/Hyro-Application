import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/sidebar.dart';
import '../../core/widgets/spotify_bottom_bar.dart';
import '../../core/widgets/custom_title_bar.dart';
import '../../core/services/spotify/spotify_auth_service.dart';
import '../../core/services/spotify/spotify_player_service.dart';
import '../../core/widgets/animated_background.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ui_provider.dart';
import '../../features/focus/providers/focus_provider.dart';
import '../../features/focus/providers/focus_state.dart';
import '../widgets/global_create_modal.dart';
import '../widgets/floating_glass_navigation_bar.dart';

/// Scaffold del diseño principal con barra lateral responsiva + contenido + barra de radio.
class MainLayout extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final Widget child;

  const MainLayout({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    required this.child,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Estado para controlar la visibilidad de la barra lateral en escritorio/tableta
  bool _isDesktopSidebarVisible = true;

  // No se necesitan mapeos, el índice es 1 a 1

  late final SpotifyAuthService _spotifyAuthService;
  late final SpotifyPlayerService _spotifyPlayerService;

  @override
  void initState() {
    super.initState();
    _spotifyAuthService = SpotifyAuthService();
    _spotifyPlayerService = SpotifyPlayerService(
      authService: _spotifyAuthService,
    );
  }

  @override
  void dispose() {
    _spotifyPlayerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    final focusState = context.watch<FocusProvider>().state;
    final isTimerRunning = focusState.isRunning;
    final isPomodoroFinished =
        focusState.isFinished &&
        (focusState.mode == TimerMode.shortBreak ||
            focusState.mode == TimerMode.longBreak);
    final hideNavBars =
        isTimerRunning ||
        isPomodoroFinished ||
    focusState.isPaused;

    if (isMobile) {
      return _buildMobileLayout(hideNavBars);
    }

    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: [
          if (!kIsWeb &&
              (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
            const CustomTitleBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sidebarWidth = isTablet ? 72.0 : 220.0;
                return Stack(
                  children: [
                    // Fondo animado que respira
                    const Positioned.fill(child: AnimatedBackground()),
                    // Región de contenido principal
                    Positioned.fill(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: widget.child,
                        ),
                      ),
                    ),
                    // Base flotante de Spotify
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Consumer<UiProvider>(
                            builder: (context, ui, _) {
                              if (!ui.isMusicBarVisible)
                                return const SizedBox.shrink();
                              if (ui.isMusicBarMinimized)
                                return _buildMinimizedMusicBar(ui);
                              return SpotifyBottomBar(
                                authService: _spotifyAuthService,
                                playerService: _spotifyPlayerService,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // Fondo oscuro opcional para un mejor efecto
                    if (_isDesktopSidebarVisible && !hideNavBars)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDesktopSidebarVisible = false;
                            });
                          },
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    if (!_isDesktopSidebarVisible && !hideNavBars)
                      Positioned(
                        top: 24,
                        left: 24,
                        child: IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _isDesktopSidebarVisible = true;
                            });
                          },
                        ),
                      ),
                    // Barra lateral deslizante
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left:
                          (_isDesktopSidebarVisible && !hideNavBars)
                              ? 0
                              : -sidebarWidth,
                      top: 0,
                      bottom: 0,
                      width: sidebarWidth,
                      child: Sidebar(
                        selectedIndex: widget.selectedIndex,
                        onItemSelected: widget.onNavigate,
                        collapsed: isTablet,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool hideNavBars) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Fondo animado que respira
          const Positioned.fill(child: AnimatedBackground()),
          // Región de contenido principal
          Positioned.fill(child: widget.child),
          // Barra de Spotify
          Positioned(
            bottom: hideNavBars ? 16 : 96,
            left: 0,
            right: 0,
            child: Consumer<UiProvider>(
              builder: (context, ui, _) {
                if (!ui.isMusicBarVisible) return const SizedBox.shrink();
                if (ui.isMusicBarMinimized) return _buildMinimizedMusicBar(ui);
                return SpotifyBottomBar(
                  authService: _spotifyAuthService,
                  playerService: _spotifyPlayerService,
                );
              },
            ),
          ),
          // Barra de navegación flotante fija en la parte inferior
          if (!hideNavBars)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingGlassNavigationBar(
                selectedIndex: widget.selectedIndex,
                onNavigate: widget.onNavigate,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimizedMusicBar(UiProvider ui) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: GestureDetector(
          onTap: () => ui.setMusicBarMinimized(false),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
