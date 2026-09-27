import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/services/username_service.dart';

/// Dialog modal para cambiar el nombre de usuario.
class UsernameChangeDialog extends StatefulWidget {
  final String? currentUsername;
  const UsernameChangeDialog({super.key, this.currentUsername});

  static Future<String?> show(BuildContext context, {String? currentUsername}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UsernameChangeDialog(currentUsername: currentUsername),
    );
  }

  @override
  State<UsernameChangeDialog> createState() => _UsernameChangeDialogState();
}

class _UsernameChangeDialogState extends State<UsernameChangeDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUsername ?? '');
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() => _shakeController.forward(from: 0);

  Future<void> _save() async {
    final validationError = UsernameService.validate(_controller.text);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      _triggerShake();
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
      _triggerShake();
      return;
    }

    final newName = _controller.text.trim();
    final profile = context.read<ProfileProvider>();
    profile.updateNombreUsuario(newName);

    if (!mounted) return;
    Navigator.of(context).pop(newName);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            _shakeAnimation.value * (_shakeController.value < 0.5 ? 1 : -1),
            0,
          ),
          child: child,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1226),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withAlpha(30), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(20),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cambiar nombre de usuario',
                            style: AppTypography.h3.copyWith(fontSize: 17)),
                        const SizedBox(height: 2),
                        Text('Letras, numeros, _, - y . (3-24 caracteres)',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 24,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                onSubmitted: (_) => _isSaving ? null : _save(),
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Ej: Hyro_Player99',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.alternate_email,
                      color: AppColors.primary, size: 18),
                  errorText: _errorText,
                  errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B)),
                  filled: true,
                  fillColor: const Color(0xFF141726),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.white.withAlpha(30)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancelar',
                          style: AppTypography.labelLarge
                              .copyWith(color: Colors.white60, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF0095FF), Color(0xFF202BC8)]),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0095FF).withAlpha(60),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Guardar',
                                style: AppTypography.labelLarge
                                    .copyWith(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
