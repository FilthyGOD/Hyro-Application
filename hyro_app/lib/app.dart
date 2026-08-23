import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/focus/providers/focus_provider.dart';
import 'features/focus/providers/focus_state.dart';
import 'features/focus/screens/focus_screen.dart';
import 'features/tasks/screens/tasks_screen.dart';
import 'features/stats/screens/stats_screen.dart';
import 'features/shop/screens/shop_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/friends/screens/friends_screen.dart';
import 'features/tasks/tasks_provider.dart';
import 'features/stats/stats_provider.dart';
import 'features/mascot/mascot_controller.dart';
import 'features/settings/settings_provider.dart';
import 'features/missions/missions_provider.dart';
import 'features/categories/category_provider.dart';
import 'core/providers/ui_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/shop/providers/shop_provider.dart';
import 'features/friends/providers/friends_provider.dart';
import 'features/versus/providers/versus_provider.dart';
import 'package:isar/isar.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'shared/layout/main_layout.dart';
import 'core/widgets/floating_mascot.dart';
import 'features/focus/screens/mini_focus_screen.dart';
import 'core/utils/responsive.dart';
import 'core/services/notifications_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'core/utils/platform_utils_web.dart';
import 'dart:io';

/// Widget raíz para la aplicación Hyro.
class HyroApp extends StatelessWidget {
  final Isar? isar;
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
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => VersusProvider()),
        ChangeNotifierProxyProvider<ProfileProvider, MissionsProvider>(
          create:
              (ctx) => MissionsProvider(
                profileProvider: ctx.read<ProfileProvider>(),
              ),
          update:
              (ctx, profile, previous) =>
                  previous ?? MissionsProvider(profileProvider: profile),
        ),
        ChangeNotifierProvider(
          create:
              (context) => FocusProvider(
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
            if (auth.isGuest) {
              return const WelcomeScreen();
            }
            // Solo los usuarios logueados o que hayan pasado el tutorial entrarán al shell
            return AppShell(key: appShellKey, authProvider: auth);
          },
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
  int _selectedIndex = 2; // Por defecto en Focus
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
    if (PlatformUtils.isDesktop) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      _initTray();
    }
  }

  Future<void> _initTray() async {
    try {
      await trayManager.setIcon(
        PlatformUtils.isWindows
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

      // Intenta limpiar, pero fuerza la salida después de 500ms para garantizar el cierre
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
      // Diferido para evitar llamar a notifyListeners() durante la fase de construcción
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGamificationData();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (PlatformUtils.isDesktop) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (PlatformUtils.isDesktop) {
      // No pausar automáticamente en escritorio, permite minimizar a la bandeja del sistema y mantener el temporizador.
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final focusProvider = context.read<FocusProvider>();
      final settings = context.read<SettingsProvider>();
      if (focusProvider.state.isRunning && settings.autoPauseTimer) {
        focusProvider.pause(manual: false);
      }
    }
  }

  static const _screens = <Widget>[
    ShopScreen(), // 0
    StatsScreen(), // 1
    FocusScreen(), // 2
    TasksScreen(), // 3
    FriendsScreen(), // 4
    ProfileScreen(), // 5
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Diferido para evitar llamar a notifyListeners() durante la fase de construcción
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGamificationData();
      });
    }
  }

  Future<void> _loadGamificationData() async {
    // Dar acceso de autenticación al FocusProvider para búsqueda de userId
    context.read<FocusProvider>().authProvider = widget.authProvider;

    final userId = widget.authProvider.supabaseUserId;
    final isAuth = widget.authProvider.isAuthenticated;

    // Conecta el estado de autenticación a los proveedores de tareas y categorías
    // para que puedan escribir de forma dual en Supabase cuando el usuario está autenticado
    final categoryProvider = context.read<CategoryProvider>();
    categoryProvider.isAuthenticated = () => isAuth;
    categoryProvider.getUserId = () => userId;
    await categoryProvider.reload();

    final taskProvider = context.read<TaskProvider>();
    taskProvider.isAuthenticated = () => isAuth;
    taskProvider.getUserId = () => userId;
    await taskProvider.reload();

    // Limpia las tareas huérfanas que no pertenecen a ninguna categoría existente
    final validNames = categoryProvider.categories.map((c) => c.name).toList();
    final validIds = categoryProvider.categories.map((c) => c.id).toList();
    await taskProvider.deleteOrphanedTasks(validNames, validIds);

    final profileProvider = context.read<ProfileProvider>();
    final shopProvider = context.read<ShopProvider>();

    await profileProvider.loadProfile(userId);
    await shopProvider.loadShop(userId);
    if (!mounted) return;

    // Cargar datos de amigos si el usuario está autenticado
    if (userId != null) {
      final friendsProvider = context.read<FriendsProvider>();
      friendsProvider.loadFriendsData(userId);

      // Inicializar el stream de batallas Versus
      final versusProvider = context.read<VersusProvider>();
      versusProvider.initStream(userId);
    }
    if (!mounted) return;

    final missionsProvider = context.read<MissionsProvider>();
    await missionsProvider.initialize();
    if (!mounted) return;

    // ── Programar notificaciones con datos reales ──
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

      // Programar recordatorios para tareas que vencen en 1-2 días
      final taskDueData =
          pendingTasks
              .where((t) => t.dueDate != null)
              .map((t) => {'id': t.id, 'title': t.title, 'dueDate': t.dueDate!})
              .toList();
      await NotificationsService.instance.scheduleTaskDueReminders(taskDueData);
    } catch (e) {
      debugPrint('⚠️ Error programando notificaciones: $e');
    }

    // SM comienza en cargando → transición a movimiento_suave
    final mascot = context.read<MascotController>();
    mascot.triggerVolver();
    mascot.markInitialLoadComplete();
  }

  void navigateTo(int index) {
    if (index == 6 && _selectedIndex == 6) {
      index = _previousIndex;
    }

    final previousIndex = _selectedIndex;
    final timerState = context.read<FocusProvider>().state;
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

    if (index != 6) {
      _pageController.jumpToPage(index);
    }

    if (previousIndex == index) return;

    final mascot = context.read<MascotController>();

    // Saliendo de Focus, Shop, o Stats → reinicia la mascota a inactivo
    if (previousIndex == 2 || previousIndex == 0 || previousIndex == 1) {
      mascot.triggerVolver();
    }

    // Llegando a Focus → reanuda la animación si el temporizador está corriendo
    if (index == 2) {
      // También dispara volver para asegurar que salimos de cualquier otro estado de animación
      mascot.triggerVolver();
      if (timerState.isRunning) {
        if (timerState.mode == TimerMode.pomodoro) {
          mascot.triggerEstudiando();
        } else {
          mascot.triggerHueva();
        }
      }
    }

    // Llegando a Stats → dispara la animación de racha
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
                physics: const NeverScrollableScrollPhysics(),
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
                      final timerState = context.read<FocusProvider>().state;
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
        // Capa superpuesta de la mascota flotante — visible solo en Focus (2), Tareas (3) y Amigos (4), y no durante la vista de sesión completada
        Builder(
          builder: (context) {
            final timerState = context.watch<FocusProvider>().state;
            final isPomodoroFinished =
                timerState.isFinished &&
                (timerState.mode == TimerMode.shortBreak ||
                    timerState.mode == TimerMode.longBreak);

            final isQuizActive = timerState.quizDue;
            final isVisible =
                (_selectedIndex == 2 ||
                    _selectedIndex == 3 ||
                    _selectedIndex == 4) &&
                !isPomodoroFinished &&
                !isQuizActive;
            return FloatingMascot(visible: isVisible);
          },
        ),
      ],
    );
  }
}
