import 'package:hive/hive.dart';

part 'pomodoro_session.g.dart';

@HiveType(typeId: 1)
class PomodoroSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startedAt;

  @HiveField(2)
  final int durationMinutes;

  @HiveField(3)
  final String mode; // 'pomodoro', 'shortBreak', 'longBreak'

  @HiveField(4)
  final bool completed;

  @HiveField(5)
  final String? taskId;

  PomodoroSession({
    required this.id,
    required this.startedAt,
    required this.durationMinutes,
    required this.mode,
    this.completed = true,
    this.taskId,
  });
}
