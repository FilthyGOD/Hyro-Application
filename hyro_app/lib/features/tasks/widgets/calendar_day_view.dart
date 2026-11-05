import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/task_model.dart';
import 'calendar_legend.dart';
import 'calendar_week_strip.dart';

/// Vista de Día para el calendario (Estilo Imagen 3).
class CalendarDayView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<TaskModel> tasks;
  final VoidCallback onAddTask;

  const CalendarDayView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.tasks,
    required this.onAddTask,
  });

  String _formatHeaderDate(DateTime date) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} de $monthName';
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
    final dayTasks = tasks.where((t) {
      if (t.dueDate == null) return false;
      return _isSameDay(t.dueDate!, selectedDate);
    }).toList();

    final now = DateTime.now();
    final isToday = _isSameDay(selectedDate, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header con Fecha y Flechas de Navegación ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _formatHeaderDate(selectedDate),
                style: AppTypography.h2.copyWith(fontSize: 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                  onPressed: () {
                    onDateSelected(selectedDate.subtract(const Duration(days: 1)));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  onPressed: () {
                    onDateSelected(selectedDate.add(const Duration(days: 1)));
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

        // ── Leyenda de tipos/categorías ──
        const CalendarLegend(),
        const SizedBox(height: 20),

        // ── Cronograma / Horario del día ──
        if (dayTasks.isEmpty)
          _buildEmptyDayState(context)
        else
          _buildTimeline(context, dayTasks, isToday, now),
      ],
    );
  }

  Widget _buildEmptyDayState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E6BFF).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1E6BFF).withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF00E5FF),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nada programado',
              style: AppTypography.h3.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Disfruta de tu día libre o agrega una tarea.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAddTask,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Programar Nota / Tarea'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    List<TaskModel> dayTasks,
    bool isToday,
    DateTime now,
  ) {
    // Horas a mostrar: de 6 AM a 11 PM (23:00)
    final hours = List.generate(18, (i) => i + 6);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final hour = hours[index];
        final tasksAtThisHour = dayTasks.where((t) {
          final tHour = t.dueDate?.hour ?? 9;
          return tHour == hour;
        }).toList();

        final isCurrentHour = isToday && now.hour == hour;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiqueta de la hora
                  SizedBox(
                    width: 58,
                    child: Text(
                      _formatHourLabel(hour),
                      style: AppTypography.bodySmall.copyWith(
                        color: isCurrentHour
                            ? const Color(0xFF00E5FF)
                            : Colors.white54,
                        fontWeight:
                            isCurrentHour ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Línea divisoria y tareas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        if (tasksAtThisHour.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...tasksAtThisHour.map((task) => _buildTaskCard(task)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Línea indicadora de hora actual si corresponde
            if (isCurrentHour)
              Positioned(
                top: 10 + (now.minute / 60.0) * 36,
                left: 54,
                right: 0,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00E5FF),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final color = Color(task.priorityColorValue);

    final timeStr = task.dueDate != null
        ? '${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (timeStr.isNotEmpty)
                Text(
                  timeStr,
                  style: AppTypography.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white60,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

