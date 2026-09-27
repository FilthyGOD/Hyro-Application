import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Overlay de carga animado que oscurece el fondo y muestra JairitoCarga.lottie.
/// Se anima con fade al aparecer y desaparecer.
/// [isVisible] controla la visibilidad.
/// [message] es el texto que se muestra bajo la animacion.
class LoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final Widget child;
  final String message;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    required this.child,
    this.message = 'Cargando...',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Positioned.fill garantiza que el overlay cubra toda la pantalla
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: isVisible
                ? _HyroLoadingOverlay(key: const ValueKey('overlay'), message: message)
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ],
    );
  }
}

/// Pantalla de carga completa reutilizable (sin Stack padre).
class HyroLoadingScreen extends StatelessWidget {
  final String message;
  const HyroLoadingScreen({super.key, this.message = 'Cargando...'});

  @override
  Widget build(BuildContext context) => _HyroLoadingOverlay(message: message);
}

class _HyroLoadingOverlay extends StatelessWidget {
  final String message;
  const _HyroLoadingOverlay({super.key, this.message = 'Cargando...'});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE0050A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/mascot/JairitoCarga.lottie',
              width: 190,
              height: 190,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

