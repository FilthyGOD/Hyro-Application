import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../widgets/sidebar.dart';
import '../widgets/spotify_bottom_bar.dart';
import '../../core/services/spotify/spotify_auth_service.dart';
import '../../core/services/spotify/spotify_player_service.dart';

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

    if (isMobile) {
      return _buildMobileLayout();
    }

    return Scaffold(
      key: _scaffoldKey,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidebarWidth = isTablet ? 72.0 : 220.0;
          return Stack(
            children: [
              // Main Content Region
              Positioned.fill(child: widget.child),
              // Floating Spotify Base
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: SpotifyBottomBar(
                  authService: _spotifyAuthService,
                  playerService: _spotifyPlayerService,
                ),
              ),
              // Optional backdrop for a nicer effect
              if (_isDesktopSidebarVisible)
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
              if (!_isDesktopSidebarVisible)
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
                left: _isDesktopSidebarVisible ? 0 : -sidebarWidth,
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

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SizedBox(
        width: 220,
        child: Sidebar(
          selectedIndex: widget.selectedIndex,
          onItemSelected: (index) {
            widget.onNavigate(index);
            Navigator.of(context).pop(); // close drawer
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: SpotifyBottomBar(
              authService: _spotifyAuthService,
              playerService: _spotifyPlayerService,
            ),
          ),
          Positioned(
            top: 24,
            left: 16,
            child: Builder(
              builder:
                  (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () {
                      Scaffold.of(ctx).openDrawer();
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
