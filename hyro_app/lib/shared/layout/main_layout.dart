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
        (focusState.isPaused && focusState.isManualPause);

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
              child: _buildFloatingGlassBar(context),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingGlassBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SizedBox(
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ── Cápsula Glassmórfica ──
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C101A).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildGlassNavItem(
                                  index: 0,
                                  icon: Icons.storefront_outlined,
                                  activeIcon: Icons.storefront,
                                ),
                              ),
                              Expanded(
                                child: _buildGlassNavItem(
                                  index: 1,
                                  icon: Icons.calendar_month_outlined,
                                  activeIcon: Icons.calendar_month_rounded,
                                ),
                              ),
                              // Espacio reservado para el botón central '+'
                              const SizedBox(width: 64),
                              Expanded(
                                child: _buildGlassNavItem(
                                  index: 2,
                                  icon: Icons.timer_outlined,
                                  activeIcon: Icons.timer,
                                ),
                              ),
                              Expanded(
                                child: _buildGlassNavItem(
                                  index: 3,
                                  icon: Icons.person_outline_rounded,
                                  activeIcon: Icons.person_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Botón Agregar Central (+) Estilo Saliente ──
                  Center(
                    child: Container(
                      width: 58,
                      height: 74,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF266EFA),
                            Color(0xFF0448DB),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0052E0).withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          splashColor: Colors.white.withValues(alpha: 0.2),
                          highlightColor: Colors.white.withValues(alpha: 0.1),
                          onTap: () {
                            // Botón de agregar sin funcionalidad aún
                          },
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onNavigate(index),
        borderRadius: BorderRadius.circular(30),
        splashColor: AppColors.primary.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF8A93A6),
                size: 26,
                shadows: isSelected
                    ? [
                        Shadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 4 : 0,
                height: isSelected ? 4 : 0,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
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
