import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/versus_provider.dart';
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
          height: 160,
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

  Widget _buildMatchCard(BuildContext context, VersusMatch match) {
    final isYourTurn = match.status == VersusStatus.yourTurn;
    final isPending = match.estadoDb == 'pendiente';
    final isCompleted = match.estadoDb == 'completada';
    final isWinner = isCompleted && match.ganadorId == match.localPlayer.id;

    final Color statusColor;
    final String statusText;

    if (isCompleted) {
      statusColor = isWinner ? const Color(0xFF10B981) : const Color(0xFFEF4444);
      statusText = isWinner ? '¡Ganaste!' : 'Perdiste';
    } else if (isYourTurn) {
      statusColor = AppColors.breakGreen;
      statusText = '¡Tu Turno!';
    } else if (isPending) {
      statusColor = AppColors.primary;
      statusText = 'Pendiente';
    } else {
      statusColor = AppColors.pomodoroRedLight;
      statusText = 'Esperando a ${match.opponent.username}...';
    }

    // Determinar si la tarjeta está deshabilitada (no es tu turno y no es pendiente/completada)
    final isDisabled = !isYourTurn && !isPending && !isCompleted;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? statusColor.withValues(alpha: 0.6)
                : (isYourTurn
                    ? AppColors.breakGreen.withValues(alpha: 0.6)
                    : (isPending ? AppColors.primary.withValues(alpha: 0.5) : AppColors.cardBorder)),
            width: (isYourTurn || isPending || isCompleted) ? 1.8 : 1.0,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : (isYourTurn
                  ? [
                      BoxShadow(
                        color: AppColors.breakGreen.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : (isPending
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : () => onResumeMatch(match),
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

                // Chip de Estado (Tu Turno / Esperando a [Nombre]... / Terminado)
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Pie: Marcador de rondas O Botones si está completada
                if (isCompleted)
                  Column(
                    children: [
                      Text(
                        'Marcador Final: ${match.localRoundsWon} - ${match.opponentRoundsWon}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isWinner && !match.premioReclamado) {
                              context.read<VersusProvider>().reclamarPremio(match.id);
                              _showClaimDialog(context, match.betCoins * 2);
                            } else {
                              context.read<VersusProvider>().archivarBatalla(match.id, match.isChallenger);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isWinner && !match.premioReclamado ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isWinner && !match.premioReclamado ? 'Reclamar' : 'Eliminar',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset('assets/images/HyroCoins.svg', width: 12, height: 12),
                          const SizedBox(width: 3),
                          Text(
                            '${match.betCoins * 2} Monedas',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ronda ${match.currentRound}   |   ${match.localRoundsWon} - ${match.opponentRoundsWon}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClaimDialog(BuildContext context, int coinsWon) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('¡Recompensa!', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Has reclamado tu premio de la batalla:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/images/HyroCoins.svg', width: 32, height: 32),
                const SizedBox(width: 8),
                Text(
                  '+$coinsWon Monedas',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Genial', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
