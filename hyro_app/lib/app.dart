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
import 'services/notifications_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'dart:io';

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
          create:
              (ctx) => MissionsProvider(
                profileProvider: ctx.read<ProfileProvider>(),
              ),
          update:
              (ctx, profile, previous) =>
                  previous ?? MissionsProvider(profileProvider: profile),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => TimerCubit(
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
              return AppShell(key: appShellKey, authProvider: auth);
            },
          ),
        ),
      ),
    );
  }
}

final GlobalKey<AppShellState> appShellKey = GlobalKey<AppShellState>();

class AppShell extends StatefulWidget {
  final AuthProvider authProvider;
  const AppShell({super.key, required this.authProvider});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell>
    with WidgetsBindingObserver, WindowListener, TrayListener {
  int _selectedIndex = 2; // Default to Focus
  int _previousIndex = 2;
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
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      _initTray();
    }
  }

  Future<void> _initTray() async {
    try {
      await trayManager.setIcon(
        Platform.isWindows
            ? 'assets/images/app_icon.ico'
            : 'assets/images/app_icon.png',
      );
      await trayManager.setToolTip('Hyro');
      Menu menu = Menu(
        items: [
          MenuItem(key: 'show_window', label: 'Abrir Hyro'),
          MenuItem.separator(),
          MenuItem(key: 'exit_app', label: 'Salir (Cerrar notificaciones)'),
        ],
      );
      await trayManager.setContextMenu(menu);
    } catch (e) {
      debugPrint('Tray initialization error: $e');
    }
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if (!mounted) return;
      final minimizeToTray = context.read<SettingsProvider>().minimizeToTray;
      if (minimizeToTray) {
        await windowManager.hide();
      } else {
        try {
          await trayManager.destroy();
        } catch (_) {}
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
        exit(0);
      }
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    debugPrint('Tray clicked: key=${menuItem.key}, label=${menuItem.label}');
    final key = menuItem.key;
    final label = menuItem.label ?? '';

    if (key == 'show_window' ||
        label == 'Abrir Hyro' ||
        label.contains('Abrir')) {
      windowManager.show();
      windowManager.focus();
    } else if (key == 'exit_app' ||
        label == 'Salir (Cerrar notificaciones)' ||
        label.contains('Salir')) {
      windowManager.setPreventClose(false);

      // Attempt cleanup but force exit after 500ms to guarantee termination
      Future.delayed(const Duration(milliseconds: 500), () => exit(0));

      try {
        windowManager.destroy();
        trayManager.destroy().then((_) => exit(0));
      } catch (e) {
        exit(0);
      }
    }
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
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Don't auto-pause on desktop, let users minimize to tray and keep timer running.
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final cubit = context.read<TimerCubit>();
      final settings = context.read<SettingsProvider>();
      if (cubit.state.isRunning && settings.autoPauseTimer) {
        cubit.pause(manual: false);
      }
    }
  }

  static const _screens = <Widget>[
    ShopScreen(), // 0
    StatsScreen(), // 1
    FocusScreen(), // 2
    TasksScreen(), // 3
    ProfileScreen(), // 4
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

    // ── Schedule notifications with real data ──
    try {
      final statsProvider = context.read<StatsProvider>();
      final pendingTasks =
          taskProvider.tasks.where((t) => !t.isCompleted).toList();
      final currentStreak = statsProvider.currentStreak;
      final hadSessionToday = statsProvider.todaysStats != null;

      await NotificationsService.instance.scheduleDailyNotifications(
        pendingTaskCount: pendingTasks.length,
        currentStreak: currentStreak,
        hadSessionToday: hadSessionToday,
      );

      // Schedule reminders for tasks due in 1-2 days
      final taskDueData =
          pendingTasks
              .where((t) => t.dueDate != null)
              .map((t) => {'id': t.id, 'title': t.title, 'dueDate': t.dueDate!})
              .toList();
      await NotificationsService.instance.scheduleTaskDueReminders(taskDueData);
    } catch (e) {
      debugPrint('⚠️ Error programando notificaciones: $e');
    }

    // SM starts in cargando → transition to movimiento_suave
    final mascot = context.read<MascotController>();
    mascot.triggerVolver();
    mascot.markInitialLoadComplete();
  }

  void navigateTo(int index) {
    if (index == 5 && _selectedIndex == 5) {
      index = _previousIndex;
    }

    final previousIndex = _selectedIndex;
    final timerState = context.read<TimerCubit>().state;
    final settings = context.read<SettingsProvider>();

    if (settings.strictMode &&
        timerState.isRunning &&
        previousIndex == 0 &&
        index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Modo estricto activado. ¡Termina tu sesión de enfoque primero!',
          ),
        ),
      );
      return;
    }

    setState(() {
      _previousIndex = previousIndex;
      _selectedIndex = index;
    });

    if (index != 5) {
      if (!Responsive.isMobile(context)) {
        _pageController.jumpToPage(index);
      } else {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    if (previousIndex == index) return;

    final mascot = context.read<MascotController>();

    // Leaving Focus, Shop, or Stats → reset mascot to idle
    if (previousIndex == 2 || previousIndex == 0 || previousIndex == 1) {
      mascot.triggerVolver();
    }

    // Arriving at Focus → resume animation if timer is running
    if (index == 2) {
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
    if (index == 1) {
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
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics:
                    (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux ||
                            context.watch<TimerCubit>().state.isRunning)
                        ? const NeverScrollableScrollPhysics() // Bloquea el swipe en PC o si el timer corre
                        : const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  final previousIndex = _selectedIndex;
                  if (index != _selectedIndex) {
                    setState(() {
                      _previousIndex = previousIndex;
                      _selectedIndex = index;
                    });

                    final mascot = context.read<MascotController>();
                    if (previousIndex == 2 ||
                        previousIndex == 0 ||
                        previousIndex == 1) {
                      mascot.triggerVolver();
                    }
                    if (index == 2) {
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
                    if (index == 1) {
                      final streak =
                          context.read<StatsProvider>().currentStreak;
                      mascot.triggerRacha(streak);
                    }
                  }
                },
                children: _screens,
              ),
            ],
          ),
        ),
        // Floating mascot overlay — only visible on Focus (0) and Tasks (1), and not during completed session view
        Builder(
          builder: (context) {
            final timerState = context.watch<TimerCubit>().state;
            final isPomodoroFinished =
                timerState.isFinished &&
                (timerState.mode == TimerMode.shortBreak ||
                    timerState.mode == TimerMode.longBreak);

            final isQuizActive = timerState.quizDue;
            final isVisible =
                (_selectedIndex == 2 || _selectedIndex == 3) &&
                !isPomodoroFinished &&
                !isQuizActive;
            return FloatingMascot(visible: isVisible);
          },
        ),
      ],
    );
  }
}
