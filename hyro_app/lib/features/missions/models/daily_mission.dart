/// Represents a single daily mission.
class DailyMission {
  final String id;
  final String title;
  final String description;
  final String type; // e.g. 'pomodoro_completed', 'minutes_studied', 'task_completed'
  final int targetValue;
  int currentProgress;
  bool isClaimed;
  final int xpReward;
  final int coinReward;

  DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentProgress = 0,
    this.isClaimed = false,
    this.xpReward = 50,
    this.coinReward = 0,
  });

  bool get isCompleted => currentProgress >= targetValue;

  /// Progress fraction (0.0 – 1.0).
  double get progress =>
      targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;

  /// Serialize to a Map for Hive storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'targetValue': targetValue,
        'currentProgress': currentProgress,
        'isClaimed': isClaimed,
        'xpReward': xpReward,
        'coinReward': coinReward,
      };

  /// Deserialize from a Map.
  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        type: json['type'] as String,
        targetValue: json['targetValue'] as int,
        currentProgress: json['currentProgress'] as int? ?? 0,
        isClaimed: json['isClaimed'] as bool? ?? false,
        xpReward: json['xpReward'] as int? ?? 50,
        coinReward: json['coinReward'] as int? ?? 0,
      );
}
