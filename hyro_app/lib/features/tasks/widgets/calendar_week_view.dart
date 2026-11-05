import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/task_model.dart';
import 'calendar_legend.dart';
import 'calendar_week_strip.dart';

/// Vista de Semana para el calendario (Estilo Imagen 4).
class CalendarWeekView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<TaskModel> tasks;
  final VoidCallback onAddTask;

  const CalendarWeekView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.tasks,
    required this.onAddTask,
  });

  String _formatMonthYear(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatHourLabel(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final now = DateTime.now();
    // Horas de 7 AM a 11 PM (23:00)
    final hours = List.generate(17, (i) => i + 7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Mes y Año con navegación de semanas ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatMonthYear(selectedDate),
              style: AppTypography.h2.copyWith(fontSize: 20),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                  onPressed: () {
                    onDateSelected(selectedDate.subtract(const Duration(days: 7)));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  onPressed: () {
                    onDateSelected(selectedDate.add(const Duration(days: 7)));
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tira de la semana ──
        CalendarWeekStrip(
          selectedDate: selectedDate,
          onDateSelected: onDateSelected,
        ),
        const SizedBox(height: 16),

        // ── Leyenda ──
        const CalendarLegend(),
        const SizedBox(height: 20),

        // ── Tabla Semanal (Timetable de 7 Columnas) ──
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13182C).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            children: hours.map((hour) {
              return Container(
                height: 52,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Columna de hora izquierda
                    Container(
                      width: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        _formatHourLabel(hour),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 7 Columnas de días
                    ...List.generate(7, (dayIndex) {
                      final dayDate = weekDays[dayIndex];
                      final isSelectedColumn = _isSameDay(dayDate, selectedDate);

                      // Tareas de este día y hora
                      final slotTasks = tasks.where((t) {
                        if (t.dueDate == null) return false;
                        return _isSameDay(t.dueDate!, dayDate) &&
                            (t.dueDate!.hour == hour);
                      }).toList();

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            onDateSelected(dayDate);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelectedColumn
                                  ? const Color(0xFF1E6BFF).withValues(alpha: 0.06)
                                  : Colors.transparent,
                              border: Border(
                                right: dayIndex < 6
                                    ? BorderSide(
                                        color: Colors.white.withValues(alpha: 0.04),
                                        width: 1,
                                      )
                                    : BorderSide.none,
                              ),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: slotTasks.isEmpty
                                ? const SizedBox.shrink()
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: slotTasks.map((t) {
                                      final color = Color(t.priorityColorValue);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          t.title,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

