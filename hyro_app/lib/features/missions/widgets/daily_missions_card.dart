import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../missions_provider.dart';
import '../models/daily_mission.dart';
import '../../tutorial/services/interactive_tutorial_controller.dart';

/// Tarjeta y lista de Misiones Diarias con recompensas de XP y Monedas.
class DailyMissionsCard extends StatelessWidget {
  const DailyMissionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final missionsProvider = context.watch<MissionsProvider>();

    if (missionsProvider.missions.isEmpty && !missionsProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        missionsProvider.initialize();
      });
    }

    return Container(
      key: InteractiveTutorialController.instance.missionsCardKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Misiones Diarias',
                style: AppTypography.h3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (missionsProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (missionsProvider.missions.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Las misiones se generarán automáticamente.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...missionsProvider.missions.map(
              (mission) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MissionItemCard(mission: mission),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissionItemCard extends StatelessWidget {
  final DailyMission mission;

  const _MissionItemCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final missions = context.read<MissionsProvider>();

    Widget statusWidget;
    Color progressColor;

    if (mission.isClaimed) {
      progressColor = AppColors.breakGreen;
      statusWidget = const Icon(
        Icons.check_circle_rounded,
        color: AppColors.breakGreen,
        size: 22,
      );
    } else if (mission.isCompleted) {
      progressColor = Colors.amber;
      statusWidget = const Icon(
        Icons.stars_rounded,
        color: Colors.amber,
        size: 22,
      );
    } else {
      progressColor = AppColors.primary;
      statusWidget = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 2.2,
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              statusWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mission.title,
                  style: AppTypography.labelLarge.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration:
                        mission.isClaimed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withAlpha(50),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '+${mission.xpReward} XP',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (mission.coinReward > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withAlpha(50),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/Moneda3.svg',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${mission.coinReward}',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: mission.progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF0F172A),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${mission.currentProgress}/${mission.targetValue}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (mission.isCompleted && !mission.isClaimed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () async {
                  final userId = auth.supabaseUserId;
                  await missions.claimMission(mission.id, userId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '¡Reclamar Recompensa!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
