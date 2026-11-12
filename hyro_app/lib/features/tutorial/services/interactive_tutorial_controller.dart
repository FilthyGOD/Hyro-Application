import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';

/// Modelo de paso para el tutorial interactivo con foco en pantalla
class InteractiveTutorialStep {
  final GlobalKey? targetKey;
  final String title;
  final String description;
  final String mascotSvg;
  final String actionPrompt;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onBeforeShow;

  const InteractiveTutorialStep({
    this.targetKey,
    required this.title,
    required this.description,
    required this.mascotSvg,
    required this.actionPrompt,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.onBeforeShow,
  });
}

/// Controlador y gestor del tutorial interactivo
class InteractiveTutorialController extends ChangeNotifier {
  static final InteractiveTutorialController instance = InteractiveTutorialController._();
  InteractiveTutorialController._();

  static const String _prefKey = 'has_seen_interactive_spotlight_tutorial_v1';
  static const String _autoLaunchKey = 'auto_launch_interactive_tutorial';

  bool _isActive = false;
  int _currentStepIndex = 0;
  List<InteractiveTutorialStep> _steps = [];

  bool get isActive => _isActive;
  int get currentStepIndex => _currentStepIndex;
  int get totalSteps => _steps.length;
  InteractiveTutorialStep? get currentStep =>
      _isActive && _currentStepIndex < _steps.length ? _steps[_currentStepIndex] : null;

  // GlobalKeys para anclar los focos en la interfaz real
  final GlobalKey startButtonKey = GlobalKey();
  final GlobalKey agendaButtonKey = GlobalKey();
  final GlobalKey friendsButtonKey = GlobalKey();
  final GlobalKey missionsCardKey = GlobalKey();
  final GlobalKey globalAddButtonKey = GlobalKey();
  final GlobalKey profileNavKey = GlobalKey();

  Future<bool> hasSeenTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      await prefs.setBool(_autoLaunchKey, false);
    } catch (_) {}
  }

  Future<void> resetTutorial({bool autoLaunch = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, false);
      await prefs.setBool(_autoLaunchKey, autoLaunch);
    } catch (_) {}
  }

  Future<void> checkAutoLaunch(BuildContext context) async {
    if (_isActive) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoLaunch = prefs.getBool(_autoLaunchKey) ?? false;
      final seen = prefs.getBool(_prefKey) ?? false;
      if (autoLaunch || !seen) {
        await prefs.setBool(_autoLaunchKey, false);
        if (context.mounted) {
          startTutorial(context);
        }
      }
    } catch (_) {}
  }

  void startTutorial(BuildContext context) {
    _steps = [
      // 1. Bienvenida
      const InteractiveTutorialStep(
        title: '¡Hola! Soy Jairito 👋',
        description:
            'Te guiaré paso a paso por toda la aplicación para que aprendas a usar tu Pomodoro, tus materias, el modo estricto y los duelos.',
        mascotSvg: 'assets/images/JairitoHD_Saludo.svg',
        actionPrompt: 'Toca "Comenzar" para iniciar el recorrido guiado',
        icon: Icons.waving_hand_rounded,
        accentColor: AppColors.primary,
      ),

      // 2. Pomodoro (Botón Iniciar)
      InteractiveTutorialStep(
        targetKey: startButtonKey,
        title: '1. Iniciar un Pomodoro 🍅',
        description:
            'Al pulsar "Iniciar" podrás elegir la duración (25m, 45m, 60m o 90m) y estudiar con una tarea específica, con toda la materia o sin tarea (estudio libre). Recuerda que tienes descansos y quizzes de repaso.',
        mascotSvg: 'assets/images/JairitoHD_Apuntando.svg',
        actionPrompt: 'Toca "Siguiente" o el botón resaltado para continuar',
        icon: Icons.timer_rounded,
        accentColor: AppColors.timerColor,
      ),

      // 3. Crear Categoría y Tareas (Botón +)
      InteractiveTutorialStep(
        targetKey: globalAddButtonKey,
        title: '2. Crear Categorías y Tareas 📁',
        description:
            'Con el botón "+" creas tus materias (nombre, color e icono). ¡Detalle clave!: al guardar una categoría, la app abre de inmediato su pantalla para que crees sus tareas con prioridad y fecha de entrega.',
        mascotSvg: 'assets/images/Jairo_Constructor.svg',
        actionPrompt: 'Aquí creas tus asignaturas y tareas organizadas',
        icon: Icons.add_circle_outline_rounded,
        accentColor: AppColors.pomodoroRed,
      ),

      // 4. Modo Estricto
      InteractiveTutorialStep(
        targetKey: profileNavKey,
        title: '3. Activar el Modo Estricto 🔒',
        description:
            'Entra a tu Perfil -> Ajustes ⚙️ para encender "Modo Estricto". Si intentas salirte de Hyro a WhatsApp o redes mientras corre el temporizador, Jairito te interceptará y pausará el tiempo para proteger tu concentración.',
        mascotSvg: 'assets/images/JairitoHD_Pensando.svg',
        actionPrompt: 'Actívalo en Ajustes para estudiar sin distracciones',
        icon: Icons.shield_rounded,
        accentColor: AppColors.breakGreen,
      ),

      // 5. Agenda
      InteractiveTutorialStep(
        targetKey: agendaButtonKey,
        title: '4. Agenda y Calendario 📅',
        description:
            'Toca "Agenda" para ver tus tareas organizadas por fechas en vistas de Día, Semana y Mes con los colores de cada materia, tu horario semanal y el gráfico de entregas completadas.',
        mascotSvg: 'assets/images/JairitoHD_DeHechoBueno.svg',
        actionPrompt: 'Visualiza tus entregas y exámenes a tiempo',
        icon: Icons.book_rounded,
        accentColor: Colors.blueAccent,
      ),

      // 6. Amigos y Duelos
      InteractiveTutorialStep(
        targetKey: friendsButtonKey,
        title: '5. Amigos y Duelos (Versus) ⚔️',
        description:
            'En "Amigos" puedes ver el ranking semanal de estudio y retar a tus compañeros a Duelos en tiempo real (Misma Materia o Choque). ¡Apuestan HyroCoins y el ganador de 3 rondas se lleva el botín!',
        mascotSvg: 'assets/images/JairitoHD_Apuntando.svg',
        actionPrompt: 'Compite sanamente y gana monedas en combate',
        icon: Icons.sports_esports_rounded,
        accentColor: Colors.amber,
      ),

      // 7. Misiones Diarias y Racha
      InteractiveTutorialStep(
        targetKey: missionsCardKey,
        title: '6. Misiones Diarias y Racha 🎯',
        description:
            'Cada día tienes 3 misiones (fácil, media y difícil). Complétalas para ganar XP y HyroCoins para vestir a Jairito en la Tienda. ¡Estudia diario para mantener tu llama de racha encendida!',
        mascotSvg: 'assets/images/JairitoRecompensaRemake.svg',
        actionPrompt: '¡Estás listo para dominar tu estudio con Hyro!',
        icon: Icons.military_tech_rounded,
        accentColor: Colors.deepOrangeAccent,
      ),
    ];

    _currentStepIndex = 0;
    _isActive = true;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      _steps[_currentStepIndex].onBeforeShow?.call();
      notifyListeners();
    } else {
      finishTutorial();
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  void finishTutorial() {
    _isActive = false;
    _steps = [];
    _currentStepIndex = 0;
    markCompleted();
    notifyListeners();
  }
}

