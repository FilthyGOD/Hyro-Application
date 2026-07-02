import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía de la aplicación Hyro — estilos de fuente premium usando Inter.
class AppTypography {
  AppTypography._();

  // ── Familia de fuentes base ──
  static String get _fontFamily => GoogleFonts.inter().fontFamily!;

  // ── Display ──
  static TextStyle get displayLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Colors.white,
  );

  // ── Encabezados ──
  static TextStyle get h1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Colors.white,
  );

  static TextStyle get h2 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get h3 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ── Específico del Temporizador ──
  static TextStyle get timerDisplay => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 104,
    fontWeight: FontWeight.w800,
    letterSpacing: -3,
    color: Colors.white,
    shadows: [
      Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 16),
      Shadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.5), blurRadius: 32),
    ],
  );

  static TextStyle get timerLabel => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 2,
    color: const Color(0xFF8B95B0),
  );

  // ── Cuerpo ──
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF8B95B0),
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF8B95B0),
  );

  // ── Etiquetas ──
  static TextStyle get labelLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: const Color(0xFF8B95B0),
  );

  // ── Barra Lateral ──
  static TextStyle get sidebarItem => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF8B95B0),
  );

  static TextStyle get sidebarItemActive => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF60A5FA),
  );

  // ── Chips ──
  static TextStyle get chip => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ── Números de estadísticas de tarjeta ──
  static TextStyle get statNumber => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle get statLabel => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: const Color(0xFF8B95B0),
  );
}
