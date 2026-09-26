import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:hyro/core/theme/app_colors.dart';
import 'package:hyro/core/theme/app_typography.dart';
import 'package:hyro/features/onboarding/screens/onboarding_screen.dart';
import 'package:hyro/features/auth/providers/auth_provider.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Mascot Saludo SVG
              SvgPicture.asset(
                'assets/images/JairitoHD_Saludo.svg',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Hyro',
                style: AppTypography.displayLarge.copyWith(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                '¡Hola! Soy Jairo. Prepárate para estudiar inteligente,\n ganar recompensas y destruir las distracciones.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: const Color.fromARGB(255, 120, 129, 156),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              // Primary Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 0, 149, 255),
                      Color.fromARGB(255, 32, 43, 200),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        0,
                        149,
                        255,
                      ).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'EMPIEZA AHORA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Secondary Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.02),
                  ),
                  child: const Text(
                    'YA TENGO UNA CUENTA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Continuar sin cuenta — solo guardados locales
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    context.read<AuthProvider>().continueWithoutAccount();
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'CONTINUAR SIN CUENTA',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
