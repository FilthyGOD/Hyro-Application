import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/focus/bloc/timer_cubit.dart';
import 'features/focus/focus_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/tasks/tasks_provider.dart';
import 'features/stats/stats_provider.dart';
import 'package:isar/isar.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'shared/layout/main_layout.dart';

/// Root widget for the Hyro app.
class HyroApp extends StatelessWidget {
  final Isar isar;
  const HyroApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(isar)),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) =>
                    TimerCubit(statsProvider: context.read<StatsProvider>()),
          ),
        ],
        child: MaterialApp(
          title: 'Hyro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isLoading) {
                return const SplashScreen();
              }
              if (auth.isAuthenticated) {
                return const _AppShell();
              }
              return const LoginScreen();
            },
          ),
        ),
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
    FocusScreen(), // 0
    TasksScreen(), // 1
    StatsScreen(), // 2
    ShopScreen(), // 3
    ProfileScreen(), // 4
    SettingsScreen(), // 5
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
