import 'package:flutter/material.dart';

/// Hyro App color palette — Dark theme inspired by the reference design.
class AppColors {
  AppColors._();

  // ── Backgrounds ──
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF131829);
  static const Color surfaceLight = Color(0xFF1A2035);
  static const Color cardBorder = Color(0xFF1E2540);

  // ── Primary Accent (Blue glow) ──
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryGlow = Color(0x403B82F6);

  // ── Secondary Accent (Red — Pomodoro indicator) ──
  static const Color pomodoroRed = Color(0xFFEF4444);
  static const Color pomodoroRedLight = Color(0xFFFF6B6B);

  // ── Success / Break colors ──
  static const Color breakGreen = Color(0xFF22C55E);
  static const Color breakGreenLight = Color(0xFF4ADE80);

  // ── Neutrals — Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B95B0);
  static const Color textTertiary = Color(0xFF5A6380);
  static const Color textDisabled = Color(0xFF3A4260);

  // ── Sidebar ──
  static const Color sidebarBg = Color(0xFF0D1120);
  static const Color sidebarActive = Color(0xFF1A2548);
  static const Color sidebarActiveText = Color(0xFF60A5FA);

  // ── Focus Radio bar ──
  static const Color radioBarBg = Color(0xFF0F1425);

  // ── Gradients ──
  static const LinearGradient timerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF182040),
      Color(0xFF131829),
    ],
  );

  // ── Shadows ──
  static List<BoxShadow> glowShadow(Color color, {double blur = 20}) => [
        BoxShadow(
          color: color.withAlpha(60),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];
}
