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
import 'features/settings/settings_provider.dart';
import 'features/missions/missions_provider.dart';
import 'features/categories/category_provider.dart';
import 'providers/ui_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/shop_provider.dart';
import 'package:isar/isar.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'shared/layout/main_layout.dart';
import 'shared/widgets/floating_mascot.dart';
import 'features/focus/mini_focus_screen.dart';
import 'core/utils/responsive.dart';

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
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UiProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider(isar)),
        ChangeNotifierProvider(create: (_) => ShopProvider(isar)),
        ChangeNotifierProxyProvider<ProfileProvider, MissionsProvider>(
          create: (ctx) => MissionsProvider(
            profileProvider: ctx.read<ProfileProvider>(),
          ),
          update: (ctx, profile, previous) =>
              previous ?? MissionsProvider(profileProvider: profile),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) =>
                    TimerCubit(
                      statsProvider: context.read<StatsProvider>(),
                      settingsProvider: context.read<SettingsProvider>(),
                      profileProvider: context.read<ProfileProvider>(),
                      missionsProvider: context.read<MissionsProvider>(),
                      taskProvider: context.read<TaskProvider>(),
                    ),
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
              // Todos entran al shell (invitados o usuarios logueados)
              return AppShell(authProvider: auth);
            },
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final AuthProvider authProvider;
  const AppShell({super.key, required this.authProvider});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _initialized = false;
  late final PageController _pageController;
  String? _lastUserId;
  bool _lastIsGuest = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _lastUserId = widget.authProvider.supabaseUserId;
    _lastIsGuest = widget.authProvider.isGuest;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentUserId = widget.authProvider.supabaseUserId;
    final currentIsGuest = widget.authProvider.isGuest;
    if (_lastUserId != currentUserId || _lastIsGuest != currentIsGuest) {
      _lastUserId = currentUserId;
      _lastIsGuest = currentIsGuest;
      // Defer to avoid calling notifyListeners() during the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGamificationData();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.detached) {
      final cubit = context.read<TimerCubit>();
      final settings = context.read<SettingsProvider>();
      if (cubit.state.isRunning && settings.autoPauseTimer) {
        cubit.pause();
      }
    }
  }

  static const _screens = <Widget>[
    FocusScreen(), // 0
    TasksScreen(), // 1
    StatsScreen(), // 2
    ShopScreen(), // 3
    ProfileScreen(), // 4
    SettingsScreen(), // 5
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Defer to avoid calling notifyListeners() during the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGamificationData();
      });
    }
  }

  Future<void> _loadGamificationData() async {
    // Give TimerCubit access to auth for userId lookups
    context.read<TimerCubit>().authProvider = widget.authProvider;

    final userId = widget.authProvider.supabaseUserId;
    final isAuth = widget.authProvider.isAuthenticated;

    // Wire auth state into task & category providers so they
    // can dual-write to Supabase when the user is authenticated
    final categoryProvider = context.read<CategoryProvider>();
    categoryProvider.isAuthenticated = () => isAuth;
    categoryProvider.getUserId = () => userId;
    await categoryProvider.reload();

    final taskProvider = context.read<TaskProvider>();
    taskProvider.isAuthenticated = () => isAuth;
    taskProvider.getUserId = () => userId;
    await taskProvider.reload();

    // Clean up orphaned tasks that don't belong to any existing category
    final validNames = categoryProvider.categories.map((c) => c.name).toList();
    final validIds = categoryProvider.categories.map((c) => c.id).toList();
    await taskProvider.deleteOrphanedTasks(validNames, validIds);
    
    final profileProvider = context.read<ProfileProvider>();
    final shopProvider = context.read<ShopProvider>();
    
    await profileProvider.loadProfile(userId);
    await shopProvider.loadShop(userId);
    if (!mounted) return;

    final missionsProvider = context.read<MissionsProvider>();
    await missionsProvider.initialize();
    if (!mounted) return;

    // SM starts in cargando → transition to movimiento_suave
    final mascot = context.read<MascotController>();
    mascot.triggerVolver();
    mascot.markInitialLoadComplete();
  }

  void navigateTo(int index) {
    final previousIndex = _selectedIndex;
    final timerState = context.read<TimerCubit>().state;
    final settings = context.read<SettingsProvider>();

    if (settings.strictMode && timerState.isRunning && previousIndex == 0 && index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modo estricto activado. ¡Termina tu sesión de enfoque primero!')),
      );
      return;
    }

    setState(() => _selectedIndex = index);
    
    if (index == 5 || !Responsive.isMobile(context)) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (previousIndex == index) return;

    final mascot = context.read<MascotController>();

    // Leaving Focus, Shop, or Stats → reset mascot to idle
    if (previousIndex == 0 || previousIndex == 3) {
      mascot.triggerVolver();
    }
    if (previousIndex == 2) {
      mascot.triggerVolver();
    }

    // Arriving at Focus → resume animation if timer is running
    if (index == 0) {
      // Also fire volver to ensure we leave any other animation state
      mascot.triggerVolver();
      if (timerState.isRunning) {
        if (timerState.mode == TimerMode.pomodoro) {
          mascot.triggerEstudiando();
        } else {
          mascot.triggerHueva();
        }
      }
    }

    // Arriving at Stats → trigger racha animation
    if (index == 2) {
      final streak = context.read<StatsProvider>().currentStreak;
      mascot.triggerRacha(streak);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<UiProvider>().isMiniMode) {
      return const MiniFocusScreen();
    }

    return Stack(
      children: [
        MainLayout(
          selectedIndex: _selectedIndex,
          onNavigate: navigateTo,
          child: PageView(
            controller: _pageController,
            physics: (context.watch<SettingsProvider>().strictMode && context.watch<TimerCubit>().state.isRunning)
                ? const NeverScrollableScrollPhysics() // Bloquea el swipe en modo estricto si está corriendo
                : const BouncingScrollPhysics(),
            onPageChanged: (index) {
              final previousIndex = _selectedIndex;
              if (index != _selectedIndex) {
                setState(() => _selectedIndex = index);
                
                final mascot = context.read<MascotController>();
                if (previousIndex == 0 || previousIndex == 3 || previousIndex == 2) {
                  mascot.triggerVolver();
                }
                if (index == 0) {
                  mascot.triggerVolver();
                  final timerState = context.read<TimerCubit>().state;
                  if (timerState.isRunning) {
                    if (timerState.mode == TimerMode.pomodoro) {
                      mascot.triggerEstudiando();
                    } else {
                      mascot.triggerHueva();
                    }
                  }
                }
                if (index == 2) {
                  final streak = context.read<StatsProvider>().currentStreak;
                  mascot.triggerRacha(streak);
                }
              }
            },
            children: _screens,
          ),
        ),
        // Floating mascot overlay — only visible on Focus (0) and Tasks (1), and not during completed session view
        Builder(
          builder: (context) {
            final timerState = context.watch<TimerCubit>().state;
            final isPomodoroFinished = timerState.isFinished &&
                (timerState.mode == TimerMode.shortBreak ||
                 timerState.mode == TimerMode.longBreak);
                 
            final isQuizActive = timerState.quizDue;
            final isVisible = (_selectedIndex == 0 || _selectedIndex == 1) && !isPomodoroFinished && !isQuizActive;
            return FloatingMascot(visible: isVisible);
          },
        ),
      ],
    );
  }
}
