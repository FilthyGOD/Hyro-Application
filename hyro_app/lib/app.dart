import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/focus/bloc/timer_cubit.dart';
import 'features/focus/bloc/timer_state.dart';
import 'features/focus/focus_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/tasks/tasks_provider.dart';
import 'features/stats/stats_provider.dart';
import 'features/mascot/mascot_controller.dart';
import 'package:isar/isar.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'shared/layout/main_layout.dart';
import 'shared/widgets/floating_mascot.dart';

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
        ChangeNotifierProvider(create: (_) => MascotController()),
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

  void _onNavigate(int index) {
    final previousIndex = _selectedIndex;
    setState(() => _selectedIndex = index);

    if (previousIndex == index) return;

    final mascot = context.read<MascotController>();

    // Leaving Focus or Shop → always reset mascot to idle
    if (previousIndex == 0 || previousIndex == 3) {
      mascot.triggerVolver();
    }

    // Arriving at Focus → resume animation if timer is running
    if (index == 0) {
      final timerState = context.read<TimerCubit>().state;
      if (timerState.isRunning) {
        if (timerState.mode == TimerMode.pomodoro) {
          mascot.triggerEstudiando();
        } else {
          mascot.triggerHueva();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MainLayout(
          selectedIndex: _selectedIndex,
          onNavigate: _onNavigate,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _screens[_selectedIndex],
          ),
        ),
        // Floating mascot overlay — hidden on the Shop screen (index 3)
        FloatingMascot(visible: _selectedIndex != 3),
      ],
    );
  }
}
