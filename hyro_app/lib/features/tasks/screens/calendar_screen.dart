import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/ui_provider.dart';
import '../../stats/stats_provider.dart';
import '../tasks_provider.dart';
import '../widgets/quick_note_sheet.dart';
import '../widgets/calendar_segmented_control.dart';
import '../widgets/calendar_day_view.dart';
import '../widgets/calendar_week_view.dart';
import '../widgets/calendar_month_view.dart';

/// Pantalla independiente de Calendario accesible desde la barra inferior de navegación.
/// Soporta 3 visualizaciones: Día, Semana y Mes con selector superior.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarViewMode _viewMode = CalendarViewMode.month;
  DateTime _selectedDate = DateTime.now();
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (date.year != _displayMonth.year || date.month != _displayMonth.month) {
        _displayMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  void _previousMonth() {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + 1,
        1,
      );
    });
  }

  void _openAddNoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickNoteSheet(initialDate: _selectedDate),
    );
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
              onTap: _openAddNoteSheet,
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
                      color: const Color(0xFF0095FF).withValues(alpha: 0.4),
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
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 0,
                    left: 20,
                    right: 20,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Título principal ──
                Text('Calendario', style: AppTypography.h2),
                const SizedBox(height: 16),

                // ── Selector de 3 modos: Día, Semana, Mes ──
                CalendarSegmentedControl(
                  currentMode: _viewMode,
                  onModeChanged: (mode) {
                    setState(() {
                      _viewMode = mode;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // ── Contenido según el modo seleccionado ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Consumer2<StatsProvider, TaskProvider>(
                        builder: (context, statsProvider, taskProvider, child) {
                          switch (_viewMode) {
                            case CalendarViewMode.day:
                              return CalendarDayView(
                                selectedDate: _selectedDate,
                                onDateSelected: _onDateSelected,
                                tasks: taskProvider.tasks,
                                onAddTask: _openAddNoteSheet,
                              );
                            case CalendarViewMode.week:
                              return CalendarWeekView(
                                selectedDate: _selectedDate,
                                onDateSelected: _onDateSelected,
                                tasks: taskProvider.tasks,
                                onAddTask: _openAddNoteSheet,
                              );
                            case CalendarViewMode.month:
                              return CalendarMonthView(
                                displayMonth: _displayMonth,
                                selectedDate: _selectedDate,
                                onDateSelected: _onDateSelected,
                                onPreviousMonth: _previousMonth,
                                onNextMonth: _nextMonth,
                                tasks: taskProvider.tasks,
                                statsProvider: statsProvider,
                                onAddTask: _openAddNoteSheet,
                              );
                          }
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
