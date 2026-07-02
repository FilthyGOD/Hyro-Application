import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';


class StrictModeViolationCard extends StatelessWidget {
  final String appName;

  const StrictModeViolationCard({super.key, required this.appName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(230),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.redAccent.withAlpha(100),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 120, child: Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 80)),
              const SizedBox(height: 24),
              Text(
                '¡Distracción detectada!',
                style: AppTypography.h2.copyWith(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '¿Qué hacías en \'${_formatAppName(appName)}\'?\nEste tiempo es para enfocarte.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Vuelve a enfocarte',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.surface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAppName(String rawName) {
    if (rawName.isEmpty) return rawName;
    String name = rawName.toLowerCase();
    
    // Ej: com.whatsapp, org.telegram.messenger, com.instagram.android
    final parts = name.split('.');
    if (parts.length >= 2) {
      // Generalmente la segunda palabra es el nombre si empieza con com, org, net, etc.
      if (['com', 'org', 'net', 'io'].contains(parts[0])) {
        name = parts[1];
      } else {
        name = parts[0];
      }
    }
    
    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }
    return name;
  }
}
