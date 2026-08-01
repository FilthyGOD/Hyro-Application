import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../friends/widgets/static_mascot_widget.dart';
import '../models/versus_models.dart';
import 'select_opponent_bottom_sheet.dart';

/// Sección horizontal de "Combates en Proceso" y botón "Iniciar Duelo".
/// Diseñado para colocarse justo debajo del Ranking Semanal en FriendsScreen.
class VersusActiveBattlesSection extends StatelessWidget {
  final List<VersusMatch> activeMatches;
  final Function(VersusMatch match) onResumeMatch;
  final Function(VersusPlayer opponent) onStartDuel;

  const VersusActiveBattlesSection({
    super.key,
    required this.activeMatches,
    required this.onResumeMatch,
    required this.onStartDuel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de la Sección
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.pomodoroRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: AppColors.pomodoroRedLight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Modo Versus',
                  style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
            if (activeMatches.isNotEmpty)
              Text(
                '${activeMatches.length} activas',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista Horizontal: Botón "Iniciar Duelo" + Tarjetas de Combates
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // ── Botón Principal "Iniciar Duelo" ──
              _buildStartDuelButton(context),

              const SizedBox(width: 12),

              // ── Tarjetas de Combates en Proceso ──
              ...activeMatches.map((match) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildMatchCard(context, match),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  /// Botón principal llamativo con icono de espadas/duelo
  Widget _buildStartDuelButton(BuildContext context) {
    return Container(
      width: 125,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6D28D9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            SelectOpponentBottomSheet.show(
              context: context,
              onChallengeSent: (opponent) {
                onStartDuel(opponent);
              },
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'INICIAR\nDUELO',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta de Combate en Proceso
  Widget _buildMatchCard(BuildContext context, VersusMatch match) {
    final isYourTurn = match.status == VersusStatus.yourTurn;
    final isPending = match.estadoDb == 'pendiente';
    final statusColor = isYourTurn
        ? AppColors.breakGreen
        : (isPending ? AppColors.primary : AppColors.pomodoroRedLight);
    final statusText = isYourTurn
        ? '¡Tu Turno!'
        : (isPending ? 'Pendiente' : 'Esperando...');

    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isYourTurn
              ? AppColors.breakGreen.withValues(alpha: 0.6)
              : (isPending ? AppColors.primary.withValues(alpha: 0.5) : AppColors.cardBorder),
          width: (isYourTurn || isPending) ? 1.8 : 1.0,
        ),
        boxShadow: isYourTurn
            ? [
                BoxShadow(
                  color: AppColors.breakGreen.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : isPending
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onResumeMatch(match),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar de Jairo (Oponente)
              Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: StaticMascotWidget(
                      sombrero: match.opponent.sombreroId,
                      cosmetico: match.opponent.cosmeticoId,
                      traje: match.opponent.trajeId,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.opponent.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          match.subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: match.subjectColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Chip de Estado (Tu Turno / Esperando)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Pie: Marcador de rondas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        '${match.betCoins * 2}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${match.localRoundsWon} - ${match.opponentRoundsWon}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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
