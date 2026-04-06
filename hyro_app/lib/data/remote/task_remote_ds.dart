import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for tasks via Supabase.
class TaskRemoteDataSource {
  final SupabaseClient _client;

  TaskRemoteDataSource(this._client);

  /// Insert a single task.
  Future<void> insertTask(Map<String, dynamic> data) async {
    await _client.from('tareas').insert(data);
  }

  /// Update a task by ID.
  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _client.from('tareas').update(data).eq('id', id);
  }

  /// Delete a task by ID.
  Future<void> deleteTask(String id) async {
    // Delete child records first (Supabase doesn't auto-cascade)
    await _client.from('tarea_cards').delete().eq('tarea_id', id);
    await _client.from('tarea_notas').delete().eq('tarea_id', id);
    await _client.from('tarea_fuentes').delete().eq('tarea_id', id);
    await _client.from('tareas').delete().eq('id', id);
  }

  /// Fetch all tasks for a user from Supabase.
  Future<List<Map<String, dynamic>>> fetchAllForUser(String userId) async {
    final response = await _client
        .from('tareas')
        .select()
        .eq('usuario_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Bulk upsert for initial sync. Uses ON CONFLICT DO NOTHING semantics.
  Future<void> bulkUpsert(List<Map<String, dynamic>> tasks) async {
    if (tasks.isEmpty) return;
    try {
      await _client.from('tareas').upsert(tasks, onConflict: 'id');
    } catch (e) {
      debugPrint('⚠️ TaskRemote bulkUpsert error: $e');
      rethrow;
    }
  }
}
