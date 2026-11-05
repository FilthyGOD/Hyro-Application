import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

/// Leyenda de tipos/categorías de eventos para el calendario.
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  static const List<Map<String, dynamic>> _items = [
    {'label': 'Clase', 'color': Color(0xFF3B82F6)},
    {'label': 'Examen', 'color': Color(0xFFEF4444)},
    {'label': 'Tarea', 'color': Color(0xFFF59E0B)},
    {'label': 'Festivo', 'color': Color(0xFF64748B)},
    {'label': 'Actividad', 'color': Color(0xFF8B5CF6)},
    {'label': 'Sincronizado', 'color': Color(0xFF10B981)},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _items.map((item) {
          final color = item['color'] as Color;
          final label = item['label'] as String;

          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

