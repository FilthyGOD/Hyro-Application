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

  @HiveField(15)
  String? categoryId; // UUID FK to CategoryModel.id (for relational sync)

  @HiveField(16)
  String? usuarioId; // UUID del usuario (guest o real)

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
    this.categoryId,
    this.usuarioId,
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
    String? categoryId,
    String? usuarioId,
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
      categoryId: categoryId ?? this.categoryId,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }

  /// Converts local priority names to Supabase format.
  String get _supabasePriority {
    switch (priority.toUpperCase()) {
      case 'HIGH': return 'ALTA';
      case 'LOW': return 'BAJA';
      default: return 'MEDIA';
    }
  }

  /// Serializes this task for Supabase upsert.
  Map<String, dynamic> toSupabaseJson(String realUserId) => {
        'id': id,
        'usuario_id': realUserId,
        'categoria_id': categoryId,
        'titulo': title,
        'descripcion': description,
        'sesiones_objetivo': pomodorosTarget,
        'prioridad': _supabasePriority,
        'fecha_limite': dueDate?.toIso8601String(),
      };

  /// Creates a TaskModel from Supabase JSON response.
  factory TaskModel.fromSupabaseJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: (json['titulo'] as String?) ?? '',
      description: json['descripcion'] as String?,
      categoryId: json['categoria_id'] as String?,
      usuarioId: json['usuario_id'] as String?,
      pomodorosTarget: (json['sesiones_objetivo'] as int?) ?? 1,
      priority: _fromSupabasePriority(json['prioridad'] as String?),
      priorityColorValue: _priorityColorFor(json['prioridad'] as String?),
      dueDate: json['fecha_limite'] != null
          ? DateTime.tryParse(json['fecha_limite'] as String)
          : null,
      createdAt: json['creada_en'] != null
          ? DateTime.tryParse(json['creada_en'] as String)
          : null,
    );
  }

  static String _fromSupabasePriority(String? p) {
    switch (p) {
      case 'ALTA':
        return 'HIGH';
      case 'BAJA':
        return 'LOW';
      default:
        return 'MEDIUM';
    }
  }

  static int _priorityColorFor(String? p) {
    switch (p) {
      case 'ALTA':
        return 0xFFEF4444; // Red
      case 'BAJA':
        return 0xFF22C55E; // Green
      default:
        return 0xFFF59E0B; // Orange
    }
  }
}
