import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fuente de datos remota para task notes v\u00eda Supabase.
class NoteRemoteDataSource {
  final SupabaseClient _client;

  NoteRemoteDataSource(this._client);

  /// Inserta una nota.
  Future<void> insertNote(Map<String, dynamic> data) async {
    await _client.from('tarea_notas').insert(data);
  }

  /// Actualiza una nota por ID.
  Future<void> updateNote(String id, Map<String, dynamic> data) async {
    await _client.from('tarea_notas').update(data).eq('id', id);
  }

  /// Elimina un note por ID.
  Future<void> deleteNote(String id) async {
    await _client.from('tarea_notas').delete().eq('id', id);
  }

  /// Obtiene todas las notas de un usuario desde Supabase.
  Future<List<Map<String, dynamic>>> fetchAllForUser(String userId) async {
    final response = await _client
        .from('tarea_notas')
        .select()
        .eq('usuario_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Upsert masivo para sincronizaci\u00f3n inicial.
  Future<void> bulkUpsert(List<Map<String, dynamic>> notes) async {
    if (notes.isEmpty) return;
    try {
      await _client.from('tarea_notas').upsert(notes, onConflict: 'id');
    } catch (e) {
      debugPrint('⚠️ NoteRemote bulkUpsert error: $e');
      rethrow;
    }
  }
}
