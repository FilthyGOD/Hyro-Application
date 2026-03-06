import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/focus/bloc/timer_cubit.dart';
import 'features/focus/focus_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/layout/main_layout.dart';

/// Root widget for the Hyro app.
class HyroApp extends StatelessWidget {
  const HyroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TimerCubit()),
      ],
      child: MaterialApp(
        title: 'Hyro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    FocusScreen(),   // 0
    TasksScreen(),   // 1
    StatsScreen(),   // 2
    ShopScreen(),    // 3
    ProfileScreen(), // 4
    SettingsScreen(),// 5
  ];

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: _selectedIndex,
      onNavigate: (index) => setState(() => _selectedIndex = index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
    );
  }
}
