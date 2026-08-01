import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/versus_provider.dart';
import '../../features/categories/category_provider.dart';
import '../../data/models/category_model.dart';
import '../friends/widgets/static_mascot_widget.dart';
import 'models/versus_models.dart';
import 'versus_combat_screen.dart';
import 'widgets/category_selector_sheet.dart';

/// Pantalla épica de introducción al combate (Versus Intro / Pantalla VS).
/// Muestra al jugador local arriba, al oponente abajo, y un emblema animado "VS" al centro.
class VersusIntroScreen extends StatefulWidget {
  final VersusMatch match;

  const VersusIntroScreen({super.key, required this.match});

  @override
  State<VersusIntroScreen> createState() => _VersusIntroScreenState();
}

class _VersusIntroScreenState extends State<VersusIntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _topSlideAnimation;
  late Animation<Offset> _bottomSlideAnimation;
  late Animation<double> _vsScaleAnimation;
  bool _isCargando = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Animación del jugador local deslizándose desde arriba
    _topSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    // Animación del oponente deslizándose desde abajo
    _bottomSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    // Animación de escala/pop para el emblema "VS"
    _vsScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _aceptarDuelo() async {
    final versusProvider = context.read<VersusProvider>();

    if (widget.match.battleMode == BattleMode.clashSubjects) {
      // Pedir categoría al oponente
      final categorias = context.read<CategoryProvider>().categories;
      if (categorias.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crea una materia primero antes de aceptar el duelo.')),
        );
        return;
      }

      // Mostrar modal para seleccionar categoría
      final selectedCategory = await showModalBottomSheet<CategoryModel>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => CategorySelectorSheet(categorias: categorias),
      );

      if (selectedCategory == null) return; // Canceló

      setState(() => _isCargando = true);
      final exito = await versusProvider.aceptarBatalla(
        batallaId: widget.match.id,
        categoriaOponenteId: selectedCategory.id,
      );

      if (mounted) {
        setState(() => _isCargando = false);
        if (exito) {
          // Navegar al combate con la batalla activa
          final updatedMatch = VersusMatch(
            id: widget.match.id,
            localPlayer: widget.match.localPlayer,
            opponent: widget.match.opponent,
            battleMode: widget.match.battleMode,
            subjectName: widget.match.subjectName,
            subjectColor: widget.match.subjectColor,
            betCoins: widget.match.betCoins,
            status: VersusStatus.yourTurn,
            currentRound: widget.match.currentRound,
            localRoundsWon: widget.match.localRoundsWon,
            opponentRoundsWon: widget.match.opponentRoundsWon,
            lastActivity: DateTime.now(),
            categoriaRetadorId: widget.match.categoriaRetadorId,
            categoriaOponenteId: selectedCategory.id,
            estadoDb: 'activa',
            isChallenger: widget.match.isChallenger,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => VersusCombatScreen(match: updatedMatch)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(versusProvider.actionMessage ?? 'Error al aceptar el duelo')),
          );
        }
      }
    } else {
      // Misma materia, no requiere elegir categoría
      setState(() => _isCargando = true);
      final exito = await versusProvider.aceptarBatalla(
        batallaId: widget.match.id,
        categoriaOponenteId: null,
      );

      if (mounted) {
        setState(() => _isCargando = false);
        if (exito) {
          final updatedMatch = VersusMatch(
            id: widget.match.id,
            localPlayer: widget.match.localPlayer,
            opponent: widget.match.opponent,
            battleMode: widget.match.battleMode,
            subjectName: widget.match.subjectName,
            subjectColor: widget.match.subjectColor,
            betCoins: widget.match.betCoins,
            status: VersusStatus.yourTurn,
            currentRound: widget.match.currentRound,
            localRoundsWon: widget.match.localRoundsWon,
            opponentRoundsWon: widget.match.opponentRoundsWon,
            lastActivity: DateTime.now(),
            categoriaRetadorId: widget.match.categoriaRetadorId,
            categoriaOponenteId: widget.match.categoriaRetadorId, // misma materia
            estadoDb: 'activa',
            isChallenger: widget.match.isChallenger,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => VersusCombatScreen(match: updatedMatch)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(versusProvider.actionMessage ?? 'Error al aceptar el duelo')),
          );
        }
      }
    }
  }

  Future<void> _rechazarDuelo() async {
    setState(() => _isCargando = true);
    final versusProvider = context.read<VersusProvider>();
    final exito = await versusProvider.rechazarBatalla(widget.match.id);
    if (mounted) {
      setState(() => _isCargando = false);
      if (exito) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duelo rechazado.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(versusProvider.actionMessage ?? 'Error al rechazar el duelo')),
        );
      }
    }
  }

  void _startCombat() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VersusCombatScreen(match: widget.match),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.match.localPlayer;
    final opponent = widget.match.opponent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Fondo con gradientes de neón divididos ──
          Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.background,
                        AppColors.pomodoroRed.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Contenido Principal (División Vertical) ──
          SafeArea(
            child: Column(
              children: [
                // Encabezado con información del combate
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Text(
                            'MODO VERSUS',
                            style: AppTypography.h3.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Materia: ${widget.match.subjectName}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on_rounded, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.match.betCoins * 2}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 1. Mitad Superior: Usuario Local
                Expanded(
                  child: SlideTransition(
                    position: _topSlideAnimation,
                    child: _buildPlayerCard(
                      player: local,
                      isLocal: true,
                    ),
                  ),
                ),

                // 2. Mitad Inferior: Oponente
                Expanded(
                  child: SlideTransition(
                    position: _bottomSlideAnimation,
                    child: _buildPlayerCard(
                      player: opponent,
                      isLocal: false,
                    ),
                  ),
                ),

                // Botón al pie (con lógica de aceptación/espera si está pendiente)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _isCargando
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : widget.match.estadoDb == 'pendiente'
                          ? widget.match.isChallenger
                              ? SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.surfaceLight,
                                      disabledBackgroundColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      'ESPERANDO QUE RIVAL ACEPTE',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _rechazarDuelo,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                            foregroundColor: const Color(0xFFEF4444),
                                            side: const BorderSide(color: Color(0xFFEF4444)),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Text(
                                            'RECHAZAR',
                                            style: AppTypography.labelLarge.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _aceptarDuelo,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Text(
                                            'ACEPTAR DUELO',
                                            style: AppTypography.labelLarge.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                          : SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _startCombat,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.breakGreen,
                                  foregroundColor: Colors.black,
                                  elevation: 8,
                                  shadowColor: AppColors.breakGreen.withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.sports_esports_rounded, size: 24, color: Colors.black),
                                    const SizedBox(width: 10),
                                    Text(
                                      '¡COMENZAR COMBATE!',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),

          // ── Emblem central "VS" Animado ──
          Center(
            child: ScaleTransition(
              scale: _vsScaleAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F2FF), Color(0xFFA855F7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FF).withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    'VS',
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        const Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({required VersusPlayer player, required bool isLocal}) {
    final accentColor = isLocal ? AppColors.primary : AppColors.pomodoroRedLight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Jairo (Mascota con cosméticos)
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceLight,
            border: Border.all(color: accentColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: StaticMascotWidget(
              sombrero: player.sombreroId,
              cosmetico: player.cosmeticoId,
              traje: player.trajeId,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Nombre de Usuario
        Text(
          player.username,
          style: AppTypography.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        // Badge de Nivel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            isLocal ? 'TÚ (Nivel ${player.level})' : 'RIVAL (Nivel ${player.level})',
            style: AppTypography.bodySmall.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
