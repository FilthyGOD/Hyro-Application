import 'package:flutter/material.dart';

/// Paleta de colores de la aplicación Hyro — Tema oscuro inspirado en el diseño de referencia.
class AppColors {
  AppColors._();

  // ── Fondos (Azul Marino Profundo) ──
  static const Color background = Color(0xFF050A1A);
  static const Color surface = Color(0xFF0A1024);
  static const Color surfaceLight = Color(0xFF131A33);
  static const Color cardBorder = Color(0xFF1A2244);

  // ── Acento Primario (Azul Eléctrico) ──
  static const Color primary = Color(0xFF00F2FF);
  static const Color primaryLight = Color(0xFF80FAFF);
  static const Color primaryDark = Color(0xFF00B3BC);
  static const Color primaryGlow = Color(0x4000F2FF);

  // ── Colores originales del temporizador ──
  static const Color timerColor = Color(0xFF3B82F6);
  static const Color timerColorDark = Color(0xFF2563EB);
  static const Color timerGlow = Color(0x403B82F6);

  // ── Acento Secundario (Violeta Vibrante e indicador Pomodoro) ──
  static const Color pomodoroRed = Color(0xFF6A25F4); // Vibrant Violet
  static const Color pomodoroRedLight = Color(0xFFA855F7); // Soft Neon Purple

  // ── Colores de Éxito / Descanso ──
  static const Color breakGreen = Color(0xFF22C55E);
  static const Color breakGreenLight = Color(0xFF4ADE80);

  // ── Neutros — Texto ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B95B0);
  static const Color textTertiary = Color(0xFF5A6380);
  static const Color textDisabled = Color(0xFF3A4260);

  // ── Barra Lateral ──
  static const Color sidebarBg = Color(0xFF0D1120);
  static const Color sidebarActive = Color(0xFF1A2548);
  static const Color sidebarActiveText = Color(0xFF60A5FA);

  // ── Barra de Focus Radio ──
  static const Color radioBarBg = Color(0xFF0F1425);

  // ── Gradientes ──
  static const LinearGradient timerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [timerColor, timerColorDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF182040),
      Color(0xFF131829),
    ],
  );

  // ── Sombras ──
  static List<BoxShadow> glowShadow(Color color, {double blur = 20}) => [
        BoxShadow(
          color: color.withAlpha(60),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];
}
