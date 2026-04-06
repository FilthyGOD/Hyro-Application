import 'package:flutter/material.dart';
import '../local/task_local_ds.dart';
import '../remote/task_remote_ds.dart';
import '../models/task_model.dart';
import '../local/category_local_ds.dart';

/// Repository that abstracts local and remote task operations.
///
/// - Always writes to local (Hive) first.
/// - If the user is authenticated, also writes to Supabase.
/// - Reads always come from local (offline-first).
class TaskRepository {
  final TaskLocalDataSource _local;
  final TaskRemoteDataSource _remote;
  final bool Function() _isAuthenticated;
  final String? Function() _getUserId;

  TaskRepository({
    required TaskLocalDataSource local,
    required TaskRemoteDataSource remote,
    required bool Function() isAuthenticated,
    required String? Function() getUserId,
  })  : _local = local,
        _remote = remote,
        _isAuthenticated = isAuthenticated,
        _getUserId = getUserId;

  /// Get all tasks from local storage.
  List<TaskModel> getTasks() {
    return _local.getAllTasks();
  }

  /// Get a single task by ID.
  TaskModel? getTask(String id) {
    return _local.getTask(id);
  }

  /// Pull all tasks from Supabase and replace local data.
  Future<void> pullRemoteToLocal() async {
    final userId = _getUserId();
    if (userId == null) return;
    try {
      final maps = await _remote.fetchAllForUser(userId);
      await _local.clearAll();
      final categoryLocal = CategoryLocalDataSource();
      for (final map in maps) {
        final task = TaskModel.fromSupabaseJson(map);
        // Resolve category name
        if (task.categoryId != null) {
          final cat = categoryLocal.getCategory(task.categoryId!);
          if (cat != null) task.category = cat.name;
        }
        await _local.putTask(task);
      }
    } catch (e) {
      debugPrint('⚠️ TaskRepo: Error pulling from remote: $e');
    }
  }

  /// Add a new task — local first, then remote if authenticated.
  Future<void> addTask(TaskModel task) async {
    await _local.putTask(task);
    if (_isAuthenticated()) {
      try {
        final userId = _getUserId();
        if (userId != null) {
          await _remote.insertTask(task.toSupabaseJson(userId));
        }
      } catch (e) {
        debugPrint('⚠️ TaskRepo: Error syncing new task to remote: $e');
      }
    }
  }

  /// Update a task — local first, then remote if authenticated.
  Future<void> updateTask(TaskModel task) async {
    await _local.putTask(task);
    if (_isAuthenticated()) {
      try {
        final userId = _getUserId();
        if (userId != null) {
          await _remote.updateTask(task.id, task.toSupabaseJson(userId));
        }
      } catch (e) {
        debugPrint('⚠️ TaskRepo: Error syncing task update to remote: $e');
      }
    }
  }

  /// Delete a task — local first, then remote if authenticated.
  Future<void> deleteTask(String id) async {
    await _local.deleteTask(id);
    if (_isAuthenticated()) {
      try {
        await _remote.deleteTask(id);
      } catch (e) {
        debugPrint('⚠️ TaskRepo: Error syncing task deletion to remote: $e');
      }
    }
  }
}
