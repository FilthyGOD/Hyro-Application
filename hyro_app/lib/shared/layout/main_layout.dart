import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/sidebar.dart';
import '../widgets/spotify_bottom_bar.dart';
import '../../core/services/spotify/spotify_auth_service.dart';
import '../../core/services/spotify/spotify_player_service.dart';
import '../widgets/animated_background.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../providers/ui_provider.dart';
import '../../features/focus/bloc/timer_cubit.dart';

/// Main layout scaffold with responsive sidebar + content + radio bar.
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

  // State to control sidebar visibility on desktop/tablet
  bool _isDesktopSidebarVisible = true;

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
    final isTimerRunning = context.watch<TimerCubit>().state.isRunning;

    if (isMobile) {
      return _buildMobileLayout(isTimerRunning);
    }

    return Scaffold(
      key: _scaffoldKey,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidebarWidth = isTablet ? 72.0 : 220.0;
          return Stack(
            children: [
              // Animated breathing background
              const Positioned.fill(child: AnimatedBackground()),
              // Main Content Region
              Positioned.fill(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: widget.child,
                  ),
                ),
              ),
              // Floating Spotify Base
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
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
                ),
              ),
              // Optional backdrop for a nicer effect
              if (_isDesktopSidebarVisible && !isTimerRunning)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDesktopSidebarVisible = false;
                      });
                    },
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                ),
              if (!_isDesktopSidebarVisible && !isTimerRunning)
                Positioned(
                  top: 24,
                  left: 24,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () {
                      setState(() {
                        _isDesktopSidebarVisible = true;
                      });
                    },
                  ),
                ),
              // Sliding Sidebar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: (_isDesktopSidebarVisible && !isTimerRunning) ? 0 : -sidebarWidth,
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
    );
  }

  Widget _buildMobileLayout(bool isTimerRunning) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Animated breathing background
          const Positioned.fill(child: AnimatedBackground()),
          // Main Content Region
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
          if (!isTimerRunning)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                    onPressed: () {
                      widget.onNavigate(5);
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isTimerRunning
          ? null
          : Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed,
          currentIndex: widget.selectedIndex < 5 ? widget.selectedIndex : 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          showUnselectedLabels: true,
          onTap: (index) {
            widget.onNavigate(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer),
              label: 'Enfoque',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Tareas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Estads', /* Shortened for fit */
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Tienda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
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
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
