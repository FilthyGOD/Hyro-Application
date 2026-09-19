import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format_time.dart';

import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';

/// Reloj de pausa integrado que reemplaza al temporizador circular principal cuando está pausado.
class PauseClock extends StatelessWidget {
  final double size;

  const PauseClock({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final remainingPauseSeconds = context.watch<FocusProvider>().state.remainingPauseSeconds;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Concentración en pausa',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  FormatTime.mmss(remainingPauseSeconds),
                  style: AppTypography.timerDisplay.copyWith(
                    color: Colors.white,
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
