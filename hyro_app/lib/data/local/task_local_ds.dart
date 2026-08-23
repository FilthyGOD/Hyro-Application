import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import '../models/task_model.dart';

/// Fuente de datos local para tareas usando Hive.
class TaskLocalDataSource {
  static const String boxName = 'tasksBox';

  // Caché en memoria para entorno Web (compartido globalmente en la sesión)
  static final Map<String, TaskModel> _webCache = {};

  Box<TaskModel> get _box => Hive.box<TaskModel>(boxName);

  /// Obtiene todas las tareas.
  List<TaskModel> getAllTasks() {
    if (kIsWeb) return _webCache.values.toList();
    return _box.values.toList();
  }

  /// Obtiene una tarea por ID.
  TaskModel? getTask(String id) {
    if (kIsWeb) return _webCache[id];
    return _box.get(id);
  }

  /// Inserta o actualiza una tarea.
  Future<void> putTask(TaskModel task) async {
    if (kIsWeb) {
      _webCache[task.id] = task;
      return;
    }
    await _box.put(task.id, task);
  }

  /// Elimina una tarea por ID.
  Future<void> deleteTask(String id) async {
    if (kIsWeb) {
      _webCache.remove(id);
      return;
    }
    await _box.delete(id);
  }

  /// Limpia todas las tareas del almacenamiento local.
  Future<void> clearAll() async {
    if (kIsWeb) {
      _webCache.clear();
      return;
    }
    await _box.clear();
  }

  /// Obtiene todas las tareas para sincronización masiva.
  List<TaskModel> getAllForSync() {
    if (kIsWeb) return _webCache.values.toList();
    return _box.values.toList();
  }
}
