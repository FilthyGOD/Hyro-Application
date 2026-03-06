import 'package:hive/hive.dart';

// part 'user_model.g.dart'; // TODO: uncomment after running build_runner

@HiveType(typeId: 2)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String displayName;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? avatarUrl;

  @HiveField(4)
  int focusStreak;

  @HiveField(5)
  int totalFocusMinutes;

  @HiveField(6)
  int totalSessions;

  @HiveField(7)
  int pomodoroDuration;

  @HiveField(8)
  int shortBreakDuration;

  @HiveField(9)
  int longBreakDuration;

  UserModel({
    required this.id,
    this.displayName = 'User',
    this.email,
    this.avatarUrl,
    this.focusStreak = 0,
    this.totalFocusMinutes = 0,
    this.totalSessions = 0,
    this.pomodoroDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
  });
}
