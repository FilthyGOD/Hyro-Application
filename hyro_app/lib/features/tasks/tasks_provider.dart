import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/local/task_local_ds.dart';
import '../../data/remote/task_remote_ds.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskProvider extends ChangeNotifier {
  late final TaskRepository _repository;

  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  /// Auth state callbacks - set externally by AppShell
  bool Function() isAuthenticated = () => false;
  String? Function() getUserId = () => null;

  TaskProvider() {
    _repository = TaskRepository(
      local: TaskLocalDataSource(),
      remote: TaskRemoteDataSource(Supabase.instance.client),
      isAuthenticated: () => isAuthenticated(),
      getUserId: () => getUserId(),
    );
    // Defer to after the build frame to avoid notifyListeners() during build
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasks());
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = _repository.getTasks();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload tasks — if authenticated, first pull from Supabase, then read from local.
  Future<void> reload() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isAuthenticated()) {
        await _repository.pullRemoteToLocal();
      }
      _tasks = _repository.getTasks();
    } catch (e) {
      debugPrint('Error reloading tasks: $e');
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

  /// Delete all tasks associated with a specific category
  Future<void> deleteTasksByCategory(String? categoryId, String? categoryName) async {
    final tasksToDelete = _tasks.where((t) {
      return (categoryId != null && t.categoryId == categoryId) ||
             (categoryName != null && t.category == categoryName);
    }).toList();

    if (tasksToDelete.isEmpty) return;

    for (final task in tasksToDelete) {
      try {
        await _repository.deleteTask(task.id);
      } catch (e) {
        debugPrint('Error deleting task ${task.id}: $e');
      }
    }
    
    _tasks.removeWhere((t) {
      return (categoryId != null && t.categoryId == categoryId) ||
             (categoryName != null && t.category == categoryName);
    });
    notifyListeners();
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
    return _tasks;
  }

  /// Delete orphaned tasks that don't belong to any existing category.
  Future<void> deleteOrphanedTasks(List<String> validCategoryNames, List<String> validCategoryIds) async {
    final orphans = _tasks.where((t) {
      final matchesName = t.category != null && validCategoryNames.contains(t.category);
      final matchesId = t.categoryId != null && validCategoryIds.contains(t.categoryId);
      return !matchesName && !matchesId;
    }).toList();

    for (final orphan in orphans) {
      debugPrint('Deleting orphaned task: ${orphan.title} (${orphan.id})');
      await _repository.deleteTask(orphan.id);
    }

    _tasks.removeWhere((t) => orphans.any((o) => o.id == t.id));
    if (orphans.isNotEmpty) notifyListeners();
  }
}
