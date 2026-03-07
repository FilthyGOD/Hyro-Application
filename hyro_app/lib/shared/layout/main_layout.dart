import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../widgets/sidebar.dart';
import '../widgets/focus_radio_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    if (isMobile) {
      return _buildMobileLayout();
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(isMobile),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sidebarWidth = isTablet ? 72.0 : 220.0;
                return Stack(
                  children: [
                    // Main Content Region
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: _isDesktopSidebarVisible ? sidebarWidth : 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: widget.child,
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
          ),
          const FocusRadioBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          if (isMobile) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() {
              _isDesktopSidebarVisible = !_isDesktopSidebarVisible;
            });
          }
        },
      ),
      title: const Text('Hyro'),
      actions: [
        IconButton(icon: const Icon(Icons.dark_mode), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
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
      appBar: _buildAppBar(true),
      body: Column(
        children: [Expanded(child: widget.child), const FocusRadioBar()],
      ),
    );
  }
}
