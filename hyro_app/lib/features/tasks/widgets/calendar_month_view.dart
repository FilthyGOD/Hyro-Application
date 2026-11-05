import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/task_model.dart';
import '../../stats/stats_provider.dart';
import 'calendar_legend.dart';

/// Vista de Mes para el calendario (Estilo Imagen 2).
class CalendarMonthView extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final List<TaskModel> tasks;
  final StatsProvider statsProvider;
  final VoidCallback onAddTask;

  const CalendarMonthView({
    super.key,
    required this.displayMonth,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.tasks,
    required this.statsProvider,
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // Tareas del día seleccionado
    final selectedDayTasks = tasks.where((t) {
      if (t.dueDate == null) return false;
      return _isSameDay(t.dueDate!, selectedDate);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Mes y Año con Flechas ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatMonthYear(displayMonth),
              style: AppTypography.h2.copyWith(fontSize: 20),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                  onPressed: onPreviousMonth,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  onPressed: onNextMonth,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Leyenda de tipos/categorías ──
        const CalendarLegend(),
        const SizedBox(height: 16),

        // ── Grilla Completa de Mes (Estilo Imagen 2) ──
        _buildMonthGrid(context),
        const SizedBox(height: 24),

        // ── Notas / Eventos del día seleccionado ──
        Text(
          'Notas del ${selectedDate.day} de ${_formatMonthYear(selectedDate)}',
          style: AppTypography.h3,
        ),
        const SizedBox(height: 12),
        if (selectedDayTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Text(
                  'No hay notas ni tareas para este día',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...selectedDayTasks.map((t) => _buildDayTaskTile(context, t)),
      ],
    );
  }

  Widget _buildMonthGrid(BuildContext context) {
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInCurrentMonth = DateUtils.getDaysInMonth(
      displayMonth.year,
      displayMonth.month,
    );

    // 1: Lunes, 7: Domingo
    final firstWeekday = firstDayOfMonth.weekday; // 1 to 7
    final prevMonthDaysCount = firstWeekday - 1;

    final prevMonth = DateTime(displayMonth.year, displayMonth.month - 1, 1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(
      prevMonth.year,
      prevMonth.month,
    );

    const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    // Total cells: 35 or 42
    final totalCells = (prevMonthDaysCount + daysInCurrentMonth > 35) ? 42 : 35;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13182C).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Fila de encabezado de días (L M M J V S D)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: weekdays.map((w) {
                return Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),

          // Grilla de celdas
          ...List.generate((totalCells / 7).ceil(), (row) {
            return Container(
              height: 52,
              decoration: BoxDecoration(
                border: Border(
                  bottom: (row < (totalCells / 7).ceil() - 1)
                      ? BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        )
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  DateTime cellDate;
                  bool isCurrentMonth = true;

                  if (cellIndex < prevMonthDaysCount) {
                    // Días del mes anterior
                    final dayNum = daysInPrevMonth -
                        prevMonthDaysCount +
                        cellIndex +
                        1;
                    cellDate = DateTime(
                      displayMonth.year,
                      displayMonth.month - 1,
                      dayNum,
                    );
                    isCurrentMonth = false;
                  } else if (cellIndex <
                      prevMonthDaysCount + daysInCurrentMonth) {
                    // Días del mes actual
                    final dayNum = cellIndex - prevMonthDaysCount + 1;
                    cellDate = DateTime(
                      displayMonth.year,
                      displayMonth.month,
                      dayNum,
                    );
                  } else {
                    // Días del mes siguiente
                    final dayNum = cellIndex -
                        (prevMonthDaysCount + daysInCurrentMonth) +
                        1;
                    cellDate = DateTime(
                      displayMonth.year,
                      displayMonth.month + 1,
                      dayNum,
                    );
                    isCurrentMonth = false;
                  }

                  final isSelected = _isSameDay(cellDate, selectedDate);
                  final isToday = _isSameDay(cellDate, DateTime.now());

                  // Buscar tareas de esta fecha para pintar dots
                  final cellTasks = tasks.where((t) {
                    if (t.dueDate == null) return false;
                    return _isSameDay(t.dueDate!, cellDate);
                  }).toList();

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDateSelected(cellDate),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: col < 6
                                ? BorderSide(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    width: 1,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFF246CF9)
                                    : (isToday
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                        : Colors.transparent),
                                border: isToday && !isSelected
                                    ? Border.all(
                                        color: const Color(0xFF00E5FF),
                                        width: 1.2,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${cellDate.day}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : (isCurrentMonth
                                            ? Colors.white
                                            : Colors.white24),
                                  ),
                                ),
                              ),
                            ),

                            // Puntos de eventos (dots de colores)
                            const SizedBox(height: 2),
                            if (cellTasks.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: cellTasks.take(3).map((t) {
                                  final dotColor =
                                      Color(t.priorityColorValue);
                                  return Container(
                                    width: 4,
                                    height: 4,
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: isCurrentMonth
                                          ? dotColor
                                          : dotColor.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayTaskTile(BuildContext context, TaskModel task) {
    final color = Color(task.priorityColorValue);
    final timeStr = task.dueDate != null
        ? '${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (timeStr.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

