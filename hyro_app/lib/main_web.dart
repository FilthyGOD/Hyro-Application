import 'package:flutter/material.dart';

/// Inicialización específica para web — no-op para funcionalidades nativas.
Future<void> platformInit(List<String> args) async {
  debugPrint('🌐 [Hyro Web] Ejecutando en navegador web');
  // No hay notificaciones locales, window_manager, single instance, ni Rive nativo en web.
}

/// En web no hay Isar. Devuelve null.
Future<dynamic> openIsar() async {
  return null;
}
