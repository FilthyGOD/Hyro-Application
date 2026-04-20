import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      home: const StrictOverlayScreen(),
    ),
  );
}

class StrictOverlayScreen extends StatefulWidget {
  const StrictOverlayScreen({super.key});

  @override
  State<StrictOverlayScreen> createState() => _StrictOverlayScreenState();
}

class _StrictOverlayScreenState extends State<StrictOverlayScreen> {
  String delayedAppName = "";

  @override
  void initState() {
    super.initState();
    // Listen to data from the main app
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event != null && event is String) {
        setState(() {
          delayedAppName = event;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon / tree replacement
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.eco_rounded,
                    size: 80,
                    color: Colors.green[700],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Text message
              Text(
                "¿Te está distrayendo\n${delayedAppName.toUpperCase()}?",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Tu sesión sigue en curso. Por favor, ¡vuelve a Hyro inmediatamente para continuar tu trayecto de concentración!",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Return Button
              ElevatedButton(
                onPressed: () async {
                  await FlutterOverlayWindow.closeOverlay();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF67DFB8),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Volver a Hyro",
                  style: GoogleFonts.nunito(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
