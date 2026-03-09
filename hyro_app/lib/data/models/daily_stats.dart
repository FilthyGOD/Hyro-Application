import 'package:hive/hive.dart';

part 'daily_stats.g.dart'; // Run `dart run build_runner build -d` to generate

@HiveType(typeId: 2)
class DailyStats extends HiveObject {
  @HiveField(0)
  final String date;

  @HiveField(1)
  int focusSessions;

  @HiveField(2)
  int focusMinutes;

  DailyStats({
    required this.date,
    this.focusSessions = 0,
    this.focusMinutes = 0,
  });
}
