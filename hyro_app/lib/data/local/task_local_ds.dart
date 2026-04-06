import 'package:hive/hive.dart';
import '../models/task_model.dart';

/// Local data source for tasks using Hive.
class TaskLocalDataSource {
  static const String boxName = 'tasksBox';

  Box<TaskModel> get _box => Hive.box<TaskModel>(boxName);

  /// Get all tasks.
  List<TaskModel> getAllTasks() {
    return _box.values.toList();
  }

  /// Get a single task by ID.
  TaskModel? getTask(String id) {
    return _box.get(id);
  }

  /// Insert or update a task.
  Future<void> putTask(TaskModel task) async {
    await _box.put(task.id, task);
  }

  /// Delete a task by ID.
  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  /// Clear all tasks from local storage.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Get all tasks for bulk sync.
  List<TaskModel> getAllForSync() {
    return _box.values.toList();
  }
}
