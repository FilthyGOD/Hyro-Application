import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fuente de datos remota para tasks v\u00eda Supabase.
class TaskRemoteDataSource {
  final SupabaseClient _client;

  TaskRemoteDataSource(this._client);

  /// Inserta una tarea.
  Future<void> insertTask(Map<String, dynamic> data) async {
    await _client.from('tareas').insert(data);
  }

  /// Actualiza una tarea por ID.
  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _client.from('tareas').update(data).eq('id', id);
  }

  /// Elimina un task por ID.
  Future<void> deleteTask(String id) async {
    // Eliminar registros hijos primero (Supabase no hace cascada autom\u00e1tica)
    await _client.from('tarea_cards').delete().eq('tarea_id', id);
    await _client.from('tarea_notas').delete().eq('tarea_id', id);
    await _client.from('tarea_fuentes').delete().eq('tarea_id', id);
    await _client.from('tareas').delete().eq('id', id);
  }

  /// Obtiene todas las tareas de un usuario desde Supabase.
  Future<List<Map<String, dynamic>>> fetchAllForUser(String userId) async {
    final response = await _client
        .from('tareas')
        .select()
        .eq('usuario_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Upsert masivo para sincronizaci\u00f3n inicial. Usa sem\u00e1ntica ON CONFLICT DO NOTHING.
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
