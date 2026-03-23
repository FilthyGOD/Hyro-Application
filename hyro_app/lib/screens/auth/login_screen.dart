import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hyro_app/providers/auth_provider.dart';
import '../../shared/widgets/animated_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    // Simulating network delay
    await Future.delayed(const Duration(seconds: 1));
    await auth.loginPersonal(email, email.split('@').first);

    if (mounted) {
      setState(() => _isLoading = false);
      if (auth.isAuthenticated &&
          !auth.isGuest &&
          Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101422), // Deep navy from designs
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
            if (Navigator.of(context).canPop())
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
              _buildLogo(showText: true),
              const SizedBox(height: 16),
              const Text(
                'Comencemos',
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
                        const SizedBox(height: 56), // Space for avatar
                        _buildInputField(
                          label: 'EMAIL O USUARIO',
                          hint: 'user@Hyro.com',
                          controller: _emailController,
                          prefixIcon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          label: 'CONTRASEÑA',
                          hint: '••••••••',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          actionText: 'Olvide mi contraseña',
                        ),
                        const SizedBox(height: 32),
                        _buildGradientButton(
                          text: 'Iniciar Sesión',
                          onPressed: _login,
                        ),
                        const SizedBox(height: 32),
                        _buildDivider('INGRESAR CON'),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                'Google',
                                Icons.g_mobiledata,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSocialButton(
                                'Facebook',
                                Icons.facebook,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF101422),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3CDCF8), Color(0xFF265691)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 38,
                          backgroundColor: Color(0xFF1B2236),
                          child: Icon(
                            Icons.flash_on,
                            size: 40,
                            color: Colors.white70,
                          ), // Placeholder for logo
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSignUpText(isMobile: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Side
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.only(left: 64.0, top: 48.0, right: 64.0),
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogo(
                  showText: true,
                  size: 40,
                  labelText: 'Hyro',
                  useThinFont: false,
                ),
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
                        text: 'Eleva tu\n',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'potencial.',
                        style: TextStyle(color: Color(0xFF3CDCF8)),
                      ), // Cyan
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Domina tu tiempo, organiza tus tareas\ny alcanza tus metas con Hyro.',
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
        // Right Side
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.transparent, // Let animated background show through
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
                      'Bienvenido',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Por favor ingresa tus credenciales para continuar',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 40),
                    _buildInputField(
                      label: 'EMAIL O USUARIO',
                      hint: 'user@Hyro.com',
                      controller: _emailController,
                      prefixIcon: Icons.alternate_email,
                      isDesktop: true,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'CONTRASEÑA',
                      hint: '••••••••',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      actionText: 'Olvide mi contraseña',
                      isDesktop: true,
                    ),
                    const SizedBox(height: 32),
                    _buildGradientButton(
                      text: 'Iniciar Sesión',
                      onPressed: _login,
                      isDesktop: true,
                    ),
                    const SizedBox(height: 32),
                    _buildDivider('INGRESAR CON'),
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSocialButton(
                            'Facebook',
                            Icons.facebook,
                            isDesktop: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Center(child: _buildSignUpText(isMobile: false)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo({
    required bool showText,
    double size = 32,
    String labelText = 'Hyro',
    bool useThinFont = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.flash_on, size: size, color: const Color(0xFF3CDCF8));
            },
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            labelText,
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: useThinFont ? FontWeight.w500 : FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool isPassword = false,
    String? actionText,
    bool isDesktop = false,
  }) {
    final labelColor = isDesktop ? Colors.white54 : Colors.white60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            if (actionText != null)
              Text(
                actionText,
                style: TextStyle(
                  color: const Color(0xFF3CDCF8),
                  fontSize: isDesktop ? 12 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
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
    // Only gradient button in both images, maybe desktop is slightly different but mostly same
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF3CDCF8), Color(0xFFCC88FF)], // Cyan to purple
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
      if (auth.isAuthenticated &&
          !auth.isGuest &&
          Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
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
        ), // Desktop has no border, just background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor:
            isDesktop
                ? const Color(0xFF141725)
                : Colors.white.withOpacity(0.02),
      ),
    );
  }

  Widget _buildSignUpText({required bool isMobile}) {
    final textColor = Colors.white54;
    final actionColor =
        isMobile
            ? const Color(0xFF3CDCF8)
            : const Color(0xFFCC88FF); // Mobile uses Cyan, Desktop uses Purple
    final prefix = isMobile ? "¿No tienes una cuenta? " : "¿Nuevo en Hyro? ";
    final suffix = isMobile ? "Regístrate" : "Crear una cuenta";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prefix, style: TextStyle(color: textColor, fontSize: 13)),
        GestureDetector(
          onTap: () {},
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
