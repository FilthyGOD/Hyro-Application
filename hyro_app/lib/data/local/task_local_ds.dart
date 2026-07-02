import 'package:hive/hive.dart';
import '../models/task_model.dart';

/// Fuente de datos local para tareas usando Hive.
class TaskLocalDataSource {
  static const String boxName = 'tasksBox';

  Box<TaskModel> get _box => Hive.box<TaskModel>(boxName);

  /// Obtiene todas las tareas.
  List<TaskModel> getAllTasks() {
    return _box.values.toList();
  }

  /// Obtiene una tarea por ID.
  TaskModel? getTask(String id) {
    return _box.get(id);
  }

  /// Inserta o actualiza una tarea.
  Future<void> putTask(TaskModel task) async {
    await _box.put(task.id, task);
  }

  /// Elimina una tarea por ID.
  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  /// Limpia todas las tareas del almacenamiento local.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Obtiene todas las tareas para sincronizaci\u00f3n masiva.
  List<TaskModel> getAllForSync() {
    return _box.values.toList();
  }
}
