import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'interactive_tutorial_controller.dart';

/// Servicio para gestionar el estado y la visualización del tutorial guiado de Hyro.
class TutorialService {
  static const String _hasSeenTutorialKey = 'has_seen_app_tutorial_v1';
  static const String _shouldAutoLaunchKey = 'auto_launch_tutorial_on_home';

  static TutorialService? _instance;
  static TutorialService get instance => _instance ??= TutorialService._();
  TutorialService._();

  bool _isAutoLaunching = false;

  /// Comprueba si el usuario ya vio el tutorial interactivo
  Future<bool> hasSeenTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenTutorialKey) ?? false;
    } catch (e) {
      debugPrint('Error leyendo estado de tutorial: $e');
      return false;
    }
  }

  /// Marca el tutorial como visto
  Future<void> markTutorialSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenTutorialKey, true);
      await prefs.setBool(_shouldAutoLaunchKey, false);
    } catch (e) {
      debugPrint('Error guardando estado de tutorial: $e');
    }
  }

  /// Restablece el tutorial para pruebas o si el usuario quiere reiniciar todo.
  /// Si [autoLaunch] es verdadero, al volver a la pantalla de inicio se abrirá automáticamente.
  Future<void> resetTutorial({bool autoLaunch = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenTutorialKey, false);
      await prefs.setBool(_shouldAutoLaunchKey, autoLaunch);
      await InteractiveTutorialController.instance.resetTutorial(autoLaunch: autoLaunch);
    } catch (e) {
      debugPrint('Error restableciendo estado de tutorial: $e');
    }
  }

  /// Abre el tutorial interactivo automáticamente si está pendiente o si se reinició para debug
  Future<void> autoLaunchIfNeeded(BuildContext context) async {
    await InteractiveTutorialController.instance.checkAutoLaunch(context);
  }

  /// Inicia el tutorial interactivo con foco en pantalla
  Future<void> showTutorial(BuildContext context, {int initialStep = 0}) async {
    InteractiveTutorialController.instance.startTutorial(context);
  }
}
