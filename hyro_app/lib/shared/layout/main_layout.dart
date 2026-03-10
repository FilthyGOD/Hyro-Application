import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../widgets/sidebar.dart';
import '../widgets/focus_radio_bar.dart';
import '../widgets/breathing_background.dart';

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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    if (isMobile) {
      return _buildMobileLayout();
    }

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          const Positioned.fill(child: BreathingBackground()),
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Sidebar(
                      selectedIndex: widget.selectedIndex,
                      onItemSelected: widget.onNavigate,
                      collapsed: isTablet,
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
              const FocusRadioBar(),
            ],
          ),
        ],
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Hyro'),
        actions: [
          IconButton(icon: const Icon(Icons.dark_mode), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: BreathingBackground()),
          Column(
            children: [Expanded(child: widget.child), const FocusRadioBar()],
          ),
        ],
      ),
    );
  }
}
