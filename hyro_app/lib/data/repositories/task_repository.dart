import 'package:flutter/material.dart';
import '../local/task_local_ds.dart';
import '../remote/task_remote_ds.dart';
import '../models/task_model.dart';
import '../local/category_local_ds.dart';

/// Repositorio que abstrae las operaciones locales y remotas de tareas.
///
/// - Siempre escribe en local (Hive) primero.
/// - Si el usuario est\u00e1 autenticado, tambi\u00e9n escribe en Supabase.
/// - Las lecturas siempre vienen de local (offline-first).
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

  /// Obtiene todas las tareas desde el almacenamiento local.
  List<TaskModel> getTasks() {
    return _local.getAllTasks();
  }

  /// Obtiene una tarea por ID.
  TaskModel? getTask(String id) {
    return _local.getTask(id);
  }

  /// Descarga todas las tareas de Supabase y reemplaza los datos locales.
  Future<void> pullRemoteToLocal() async {
    final userId = _getUserId();
    if (userId == null) return;
    try {
      final maps = await _remote.fetchAllForUser(userId);
      await _local.clearAll();
      final categoryLocal = CategoryLocalDataSource();
      for (final map in maps) {
        final task = TaskModel.fromSupabaseJson(map);
        // Resolver nombre de categor\u00eda
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
