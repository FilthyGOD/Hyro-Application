import 'package:hive/hive.dart';
import '../models/task_model.dart';

class TaskRepository {
  static const String boxName = 'tasksBox';

  Future<Box<TaskModel>> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<TaskModel>(boxName);
    }
    return await Hive.openBox<TaskModel>(boxName);
  }

  Future<List<TaskModel>> getTasks() async {
    final box = await _getBox();
    return box.values.toList();
  }

  Future<void> addTask(TaskModel task) async {
    final box = await _getBox();
    await box.put(task.id, task);
  }

  Future<void> updateTask(TaskModel task) async {
    final box = await _getBox();
    await box.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
