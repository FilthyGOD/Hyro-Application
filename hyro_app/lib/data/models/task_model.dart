import 'package:hive/hive.dart';
import 'subtask_model.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? category;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  int pomodorosCompleted;

  @HiveField(6)
  int pomodorosTarget;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  String priority;

  @HiveField(10)
  int priorityColorValue;

  @HiveField(11)
  DateTime? dueDate;

  @HiveField(12)
  String? notes;

  @HiveField(13)
  List<SubTaskModel>? subtasks;

  @HiveField(14)
  List<String>? attachedDocumentUrls;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.isCompleted = false,
    this.pomodorosCompleted = 0,
    this.pomodorosTarget = 1,
    this.priority = 'MEDIUM',
    this.priorityColorValue = 0xFFF59E0B, // Default orange
    DateTime? createdAt,
    this.completedAt,
    this.dueDate,
    this.notes,
    this.subtasks,
    this.attachedDocumentUrls,
  }) : createdAt = createdAt ?? DateTime.now();

  TaskModel copyWith({
    String? title,
    String? description,
    String? category,
    bool? isCompleted,
    int? pomodorosCompleted,
    int? pomodorosTarget,
    String? priority,
    int? priorityColorValue,
    DateTime? completedAt,
    DateTime? dueDate,
    String? notes,
    List<SubTaskModel>? subtasks,
    List<String>? attachedDocumentUrls,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      pomodorosCompleted: pomodorosCompleted ?? this.pomodorosCompleted,
      pomodorosTarget: pomodorosTarget ?? this.pomodorosTarget,
      priority: priority ?? this.priority,
      priorityColorValue: priorityColorValue ?? this.priorityColorValue,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      subtasks: subtasks ?? this.subtasks,
      attachedDocumentUrls: attachedDocumentUrls ?? this.attachedDocumentUrls,
    );
  }
}
