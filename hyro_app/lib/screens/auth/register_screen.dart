import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'package:hyro/providers/auth_provider.dart';
import '../../shared/widgets/animated_background.dart';
import '../../features/mascot/mascot_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  Timer? _greetingTimer;
  final _random = Random();
  bool _hasFiredInitialSaludo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fireInitialSaludo();
    });
  }

  void _fireInitialSaludo() {
    if (_hasFiredInitialSaludo) return;
    _hasFiredInitialSaludo = true;

    final mascot = context.read<MascotController>();
    if (mascot.isLoaded) {
      mascot.triggerSaludo();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          mascot.triggerVolver();
          _startGreetingLoop();
        }
      });
    } else {
      void listener() {
        if (mascot.isLoaded && mounted) {
          mascot.removeListener(listener);
          mascot.triggerSaludo();
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              mascot.triggerVolver();
              _startGreetingLoop();
            }
          });
        }
      }

      mascot.addListener(listener);
    }

    // Listener de Auth para cerrar RegisterScreen automáticamente cuando OAuth se complete vía navegador externo (Deep Link)
    final authProvider = context.read<AuthProvider>();
    void authListener() {
      if (mounted && authProvider.isAuthenticated && !authProvider.isGuest) {
        authProvider.removeListener(authListener);
        Navigator.of(context).popUntil((route) => route.isFirst);
        appShellKey.currentState?.navigateTo(0);
      }
    }

    authProvider.addListener(authListener);
  }

  void _startGreetingLoop() {
    _greetingTimer?.cancel();
    final delay = Duration(seconds: 12 + _random.nextInt(9));
    _greetingTimer = Timer(delay, () {
      if (mounted) {
        final mascot = context.read<MascotController>();
        mascot.triggerSaludo();
        _startGreetingLoop();
      }
    });
  }

  void _onMascotTap() {
    final mascot = context.read<MascotController>();
    mascot.triggerSaludo();
    _startGreetingLoop();
  }

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();

    try {
      await auth.signUpWithEmail(email, password, name);

      if (mounted) {
        setState(() => _isLoading = false);
        // Mostrar diálogo indicando al usuario que revise su correo
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF191D32),
                title: const Text(
                  'Â¡Cuenta creada!',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Hemos enviado un enlace de confirmaciÃ³n a tu correo. Por favor, revÃ­salo para verificar tu cuenta y poder iniciar sesiÃ³n.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar diálogo
                      Navigator.of(context).pop(); // Regresar a la pantalla de Login
                    },
                    child: const Text(
                      'Entendido',
                      style: TextStyle(color: Color(0xFF3CDCF8)),
                    ),
                  ),
                ],
              ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear cuenta: $e')));
      }
    }
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101422),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: AnimatedBackground()),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 850) {
                  return _buildDesktopLayout();
                } else {
                  return _buildMobileLayout();
                }
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Crea tu Cuenta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF2B3352),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 56),
                        _buildInputField(
                          label: 'NOMBRE',
                          hint: 'Tu nombre',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          label: 'EMAIL',
                          hint: 'user@ejemplo.com',
                          controller: _emailController,
                          prefixIcon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          label: 'CONTRASEÃ‘A',
                          hint: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 32),
                        _buildGradientButton(
                          text: 'Registrarse',
                          onPressed: _register,
                        ),
                        const SizedBox(height: 32),
                        _buildDivider('O REGÃSTRATE CON'),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                'Google',
                                Icons.g_mobiledata,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -30,
                    child: GestureDetector(
                      onTap: _onMascotTap,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3CDCF8), Color(0xFF265691)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3CDCF8).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1B2236),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Consumer<MascotController>(
                            builder: (context, mascot, _) {
                              if (!mascot.isLoaded) {
                                return const Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: Colors.white70,
                                );
                              }
                              return Transform.scale(
                                scale: 1.4,
                                child: Transform.translate(
                                  offset: const Offset(0, -5),
                                  child: RiveWidget(
                                    controller: mascot.controller!,
                                    fit: Fit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildLoginText(isMobile: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.only(left: 64.0, top: 48.0, right: 64.0),
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: 'A un paso\nde la\n',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'excelencia.',
                        style: TextStyle(color: Color(0xFF3CDCF8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ãšnete a miles de personas que estÃ¡n\nmejorando sus vidas con Hyro.',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(48.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF191D32).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ãšnete a Hyro',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa tus datos para registrarte',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 40),
                    _buildInputField(
                      label: 'NOMBRE',
                      hint: 'Tu nombre',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      isDesktop: true,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'EMAIL',
                      hint: 'user@ejemplo.com',
                      controller: _emailController,
                      prefixIcon: Icons.alternate_email,
                      isDesktop: true,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'CONTRASEÃ‘A',
                      hint: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      isDesktop: true,
                    ),
                    const SizedBox(height: 32),
                    _buildGradientButton(
                      text: 'Registrarse',
                      onPressed: _register,
                      isDesktop: true,
                    ),
                    const SizedBox(height: 32),
                    _buildDivider('O REGÃSTRATE CON'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSocialButton(
                            'Google',
                            Icons.g_mobiledata,
                            isDesktop: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Center(child: _buildLoginText(isMobile: false)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isDesktop = false,
  }) {
    final labelColor = isDesktop ? Colors.white54 : Colors.white60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: isDesktop ? 10 : 13,
            letterSpacing: isDesktop ? 1.0 : 0.0,
            fontWeight: isDesktop ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(
              prefixIcon,
              color: const Color(0xFF3CDCF8),
              size: 18,
            ),
            suffixIcon:
                isPassword
                    ? const Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.white38,
                      size: 18,
                    )
                    : null,
            filled: true,
            fillColor:
                isDesktop
                    ? const Color(0xFF141725)
                    : Colors.white.withOpacity(0.0),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF3CDCF8),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool isDesktop = false,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF3CDCF8), Color(0xFFCC88FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3CDCF8).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
      ],
    );
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    await auth.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (auth.isAuthenticated && !auth.isGuest) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        appShellKey.currentState?.navigateTo(0);
      }
    }
  }

  Widget _buildSocialButton(
    String text,
    IconData icon, {
    bool isDesktop = false,
  }) {
    return OutlinedButton.icon(
      onPressed:
          text == 'Google' ? (_isLoading ? null : _signInWithGoogle) : () {},
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF101422), size: 16),
      ),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(
          color: Colors.white.withOpacity(isDesktop ? 0.0 : 0.08),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor:
            isDesktop
                ? const Color(0xFF141725)
                : Colors.white.withOpacity(0.02),
      ),
    );
  }

  Widget _buildLoginText({required bool isMobile}) {
    final textColor = Colors.white54;
    final actionColor =
        isMobile ? const Color(0xFF3CDCF8) : const Color(0xFFCC88FF);
    const prefix = "Â¿Ya tienes una cuenta? ";
    const suffix = "Iniciar sesiÃ³n";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prefix, style: TextStyle(color: textColor, fontSize: 13)),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Text(
            suffix,
            style: TextStyle(
              color: actionColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
