import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/services/username_service.dart';

/// Pantalla obligatoria para usuarios que se registran via Google.
/// Se muestra despues del login y antes de ir al Home.
/// El usuario no puede omitirla.
class UsernameSetupScreen extends StatefulWidget {
  /// Callback que se invoca cuando el usuario configura su nombre exitosamente.
  final VoidCallback onComplete;

  const UsernameSetupScreen({super.key, required this.onComplete});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();

    // Pre-rellenar con metadatos de Google si estan disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final googleName = auth.currentUser?.name;
      if (googleName != null && googleName.isNotEmpty) {
        final suggestion = googleName
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '')
            .substring(0, googleName.length.clamp(0, 20));
        _controller.text = suggestion;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final validationError = UsernameService.validate(_controller.text);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    final auth = context.read<AuthProvider>();
    final userId = auth.supabaseUserId;
    if (userId == null) {
      setState(() => _errorText = 'No hay sesion activa.');
      return;
    }

    setState(() { _isSaving = true; _errorText = null; });

    final error = await UsernameService.updateUsername(
      userId: userId,
      newUsername: _controller.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() { _isSaving = false; _errorText = error; });
      return;
    }

    final newName = _controller.text.trim();
    if (!mounted) return;
    context.read<ProfileProvider>().updateNombreUsuario(newName);

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animacion Lottie
                  Lottie.asset(
                    'assets/mascot/JairitoCarga.lottie',
                    width: 140,
                    height: 140,
                    repeat: true,
                  ),
                  const SizedBox(height: 24),

                  // Titulo
                  Text(
                    'Un ultimo paso',
                    style: AppTypography.h1.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Elige tu nombre de usuario en Hyro.\nTus amigos lo usaran para encontrarte.',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Input
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOMBRE DE USUARIO',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _controller,
                          autofocus: true,
                          maxLength: 24,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          onSubmitted: (_) => _isSaving ? null : _save(),
                          onChanged: (_) {
                            if (_errorText != null) setState(() => _errorText = null);
                          },
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Ej: Hyro_Player99',
                            hintStyle: const TextStyle(color: Colors.white24),
                            prefixIcon: const Icon(
                              Icons.alternate_email,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            errorText: _errorText,
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF6B6B),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0A1024),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Solo letras, numeros, guion bajo, guion y punto',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Boton Guardar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0095FF), Color(0xFF202BC8)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0095FF).withAlpha(70),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Continuar a Hyro',
                                    style: AppTypography.labelLarge.copyWith(fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
