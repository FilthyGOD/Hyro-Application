import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/versus_provider.dart';
import '../../../../features/categories/category_provider.dart';
import '../models/versus_models.dart';

/// Modal para configurar y enviar un reto de Versus a un amigo.
class CreateVersusModal extends StatefulWidget {
  final VersusPlayer opponent;
  final Function(Map<String, dynamic> payload)? onChallengeSent;

  const CreateVersusModal({
    super.key,
    required this.opponent,
    this.onChallengeSent,
  });

  /// Método estático conveniente para desplegar este BottomSheet
  static Future<void> show({
    required BuildContext context,
    required VersusPlayer opponent,
    Function(Map<String, dynamic> payload)? onChallengeSent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateVersusModal(
        opponent: opponent,
        onChallengeSent: onChallengeSent,
      ),
    );
  }

  @override
  State<CreateVersusModal> createState() => _CreateVersusModalState();
}

class _CreateVersusModalState extends State<CreateVersusModal> {
  // ── Variables de Estado ──
  BattleMode _modoSeleccionado = BattleMode.sameSubject;
  String? _categoriaSeleccionadaId; // ID de CategoryModel
  int _costoMonedas = 50;
  bool _isLanzando = false;

  // Opciones de apuesta disponibles
  static const List<int> _opcionesApuesta = [20, 50, 100];

  @override
  void initState() {
    super.initState();
    // Pre-seleccionar la primera categoría del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = context.read<CategoryProvider>().categories;
      if (categories.isNotEmpty && mounted) {
        setState(() {
          _categoriaSeleccionadaId = categories.first.id;
        });
      }
    });
  }
  /// Lanza el reto llamando a VersusProvider.crearBatalla (conexión real con Supabase).
  Future<void> _lanzarReto() async {
    final auth = context.read<AuthProvider>();
    final versus = context.read<VersusProvider>();
    final userId = auth.supabaseUserId;

    if (userId == null) {
      _mostrarError('Debes iniciar sesión para lanzar un reto.');
      return;
    }

    if (_categoriaSeleccionadaId == null) {
      _mostrarError('Selecciona una materia antes de lanzar el reto.');
      return;
    }

    setState(() => _isLanzando = true);

    final modoBatallaDb = _modoSeleccionado.toDb;

    final exito = await versus.crearBatalla(
      retadorId: userId,
      oponenteId: widget.opponent.id,
      modoBatalla: modoBatallaDb,
      categoriaRetadorId: _categoriaSeleccionadaId!,
      apuestaMonedas: _costoMonedas,
    );

    if (!mounted) return;
    setState(() => _isLanzando = false);

    if (exito) {
      // Notificar al callback si existe
      widget.onChallengeSent?.call({
        'oponente_id': widget.opponent.id,
        'modo_batalla': modoBatallaDb,
        'categoria_retador_id': _categoriaSeleccionadaId,
        'apuesta_monedas': _costoMonedas,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceLight,
          content: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Reto enviado a ${widget.opponent.username}!',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _mostrarError(versus.actionMessage ?? 'Error al crear el reto.');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtener las categorías reales del usuario desde CategoryProvider
    final categories = context.watch<CategoryProvider>().categories;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Título del Modal
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_esports_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurar Duelo',
                      style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                    ),
                    Text(
                      'Desafiando a ${widget.opponent.username}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Selector de Modo de Batalla
          Text(
            'Modo de Batalla',
            style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...BattleMode.values.map((mode) => _buildModeOption(mode)),

          const SizedBox(height: 20),

          // 2. Selector de Materia/Categoría (datos reales del usuario)
          Text(
            'Tu Materia / Categoría',
            style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (categories.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No tienes materias creadas. Crea una en la sección de Tareas.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _categoriaSeleccionadaId == cat.id;
                  final color = Color(cat.colorValue);

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.iconCodePoint != null
                              ? IconData(cat.iconCodePoint!, fontFamily: 'MaterialIcons')
                              : Icons.folder_rounded,
                          size: 16,
                          color: isSelected ? Colors.black : color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? color : AppColors.cardBorder,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _categoriaSeleccionadaId = cat.id;
                        });
                      }
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 24),

          // 3. Selector de Apuesta (20, 50, 100 monedas)
          Text(
            'Apuesta de Monedas',
            style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: _opcionesApuesta.map((monto) {
              final isSelected = _costoMonedas == monto;
              final Color chipColor = monto == 20
                  ? const Color(0xFF22C55E)
                  : monto == 50
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _costoMonedas = monto),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? chipColor.withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? chipColor : AppColors.cardBorder,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: chipColor.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.monetization_on_rounded,
                              color: isSelected ? chipColor : AppColors.textTertiary,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$monto',
                              style: AppTypography.labelLarge.copyWith(
                                color: isSelected ? chipColor : AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Resumen dinámico del Pozo Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Pozo total: ${_costoMonedas * 2} Monedas',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Botón Lanzar Reto
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isLanzando || categories.isEmpty) ? null : _lanzarReto,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: _isLanzando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 22, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          'LANZAR RETO',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(BattleMode mode) {
    final isSelected = _modoSeleccionado == mode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _modoSeleccionado = mode),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
