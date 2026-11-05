import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/ui_provider.dart';
import '../../../data/models/task_model.dart';
import '../../stats/stats_provider.dart';
import '../../stats/widgets/streak_calendar.dart';
import '../tasks_provider.dart';
import '../widgets/quick_note_sheet.dart';

/// Pantalla independiente de Calendario accesible desde la barra inferior de navegación.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _displayMonth = DateTime.now();
  DateTime? _selectedCalendarDate;

  String _getMonthAbbrev(int month) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Consumer<UiProvider>(
        builder: (context, ui, _) {
          return Padding(
            padding: EdgeInsets.only(bottom: ui.isMusicBarVisible ? 160 : 88),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const QuickNoteSheet(),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 0, 149, 255),
                      Color.fromARGB(255, 32, 43, 200),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          );
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;

          return Padding(
            padding: isLargeScreen
                ? const EdgeInsets.only(
                    left: 72,
                    top: 32,
                    right: 32,
                    bottom: 0,
                  )
                : EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 24,
                    bottom: 0,
                    left: 24,
                    right: 24,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calendario', style: AppTypography.h2),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Consumer2<StatsProvider, TaskProvider>(
                        builder: (context, statsProvider, taskProvider, child) {
                          final stats = statsProvider.getStatsForMonth(
                            _displayMonth.year,
                            _displayMonth.month,
                          );

                          final Map<int, Color> dayNoteColors = {};
                          for (final t in taskProvider.tasks) {
                            if (t.dueDate != null &&
                                t.dueDate!.year == _displayMonth.year &&
                                t.dueDate!.month == _displayMonth.month) {
                              dayNoteColors.putIfAbsent(
                                t.dueDate!.day,
                                () => Color(t.priorityColorValue),
                              );
                            }
                          }

                          final selectedTasks = _selectedCalendarDate != null
                              ? taskProvider.tasks
                                  .where((t) =>
                                      t.dueDate != null &&
                                      t.dueDate!.year ==
                                          _selectedCalendarDate!.year &&
                                      t.dueDate!.month ==
                                          _selectedCalendarDate!.month &&
                                      t.dueDate!.day ==
                                          _selectedCalendarDate!.day)
                                  .toList()
                              : <TaskModel>[];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              StreakCalendar(
                                displayMonth: _displayMonth,
                                monthStats: stats,
                                selectedDate: _selectedCalendarDate,
                                dayNoteColors: dayNoteColors,
                                onDaySelected: (date) {
                                  setState(() {
                                    if (_selectedCalendarDate == date) {
                                      _selectedCalendarDate = null;
                                    } else {
                                      _selectedCalendarDate = date;
                                    }
                                  });
                                },
                                onPreviousMonth: () {
                                  setState(() {
                                    _displayMonth = DateTime(
                                      _displayMonth.year,
                                      _displayMonth.month - 1,
                                      1,
                                    );
                                  });
                                },
                                onNextMonth: () {
                                  setState(() {
                                    _displayMonth = DateTime(
                                      _displayMonth.year,
                                      _displayMonth.month + 1,
                                      1,
                                    );
                                  });
                                },
                              ),
                              if (_selectedCalendarDate != null) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Notas del ${_selectedCalendarDate!.day}',
                                  style: AppTypography.h3,
                                ),
                                const SizedBox(height: 16),
                                if (selectedTasks.isEmpty)
                                  Text(
                                    'No hay notas para este día',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                else
                                  ...selectedTasks.map((t) {
                                    final timeStr = TimeOfDay.fromDateTime(
                                      t.dueDate!,
                                    ).format(context);
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _CalendarEventTile(
                                        month: _getMonthAbbrev(
                                          t.dueDate!.month,
                                        ),
                                        day: t.dueDate!.day.toString(),
                                        title: t.title,
                                        time: timeStr,
                                      ),
                                    );
                                  }),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalendarEventTile extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String time;

  const _CalendarEventTile({
    required this.month,
    required this.day,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Text(
                month,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              Text(day, style: AppTypography.h3.copyWith(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

