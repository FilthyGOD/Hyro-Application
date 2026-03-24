import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../features/mascot/mascot_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rive cargando animation (SM starts in cargando state)
            Consumer<MascotController>(
              builder: (context, mascot, _) {
                if (!mascot.isLoaded) {
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    ),
                  );
                }
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: RiveWidget(
                    controller: mascot.controller!,
                    fit: Fit.contain,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Hyro',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
