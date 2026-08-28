import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'dart:io';
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
    _spotifyAuthService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isTimerRunning = context.watch<FocusProvider>().state.isRunning;

    if (isMobile) {
      return _buildMobileLayout(isTimerRunning);
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
                    if (_isDesktopSidebarVisible && !isTimerRunning)
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
                    if (!_isDesktopSidebarVisible && !isTimerRunning)
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
                          (_isDesktopSidebarVisible && !isTimerRunning)
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

  Widget _buildMobileLayout(bool isTimerRunning) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Fondo animado que respira
          const Positioned.fill(child: AnimatedBackground()),
          // Región de contenido principal
          Positioned.fill(child: widget.child),
          Positioned(
            bottom: 16,
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
        ],
      ),
      bottomNavigationBar:
          isTimerRunning
              ? null
              : Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: const Color.fromARGB(
                        255,
                        30,
                        38,
                        64,
                      ).withValues(alpha: 1),
                      width: 3.0,
                    ),
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: AppColors.surface,
                    type: BottomNavigationBarType.fixed,
                    currentIndex:
                        widget.selectedIndex < 6 ? widget.selectedIndex : 5,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: AppColors.textSecondary,
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    onTap: (index) {
                      widget.onNavigate(index);
                    },
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.storefront_outlined),
                        activeIcon: _buildActiveIcon(Icons.storefront),
                        label: 'Tienda',
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.book_outlined),
                        activeIcon: _buildActiveIcon(Icons.book_rounded),
                        label: 'Tareas',
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.timer_outlined),
                        activeIcon: _buildActiveIcon(Icons.timer),
                        label: 'Enfoque',
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.emoji_events_outlined),
                        activeIcon: _buildActiveIcon(Icons.emoji_events),
                        label: 'Desafíos',
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.people_outline_rounded),
                        activeIcon: _buildActiveIcon(Icons.people_rounded),
                        label: 'Amigos',
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.person_outline),
                        activeIcon: _buildActiveIcon(Icons.person),
                        label: 'Perfil',
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildActiveIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Icon(icon),
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
