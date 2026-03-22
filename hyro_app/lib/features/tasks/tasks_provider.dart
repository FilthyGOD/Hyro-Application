import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository = TaskRepository();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  TaskProvider() {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(TaskModel task) async {
    try {
      await _repository.addTask(task);
      _tasks.add(task);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _repository.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Future<void> toggleTaskCompletion(String id) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final isNowCompleted = !task.isCompleted;
      final updatedTask = task.copyWith(
        isCompleted: isNowCompleted,
        completedAt: isNowCompleted ? DateTime.now() : null,
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> incrementTaskPomodoro(String id) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(
        pomodorosCompleted: task.pomodorosCompleted + 1,
      );
      await updateTask(updatedTask);
    }
  }

  List<TaskModel> get filteredTasks {
    // Add logic here if we want filtering by status, priority, etc.
    return _tasks;
  }
}
