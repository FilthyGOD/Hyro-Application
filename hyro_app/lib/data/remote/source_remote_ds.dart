import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fuente de datos remota para task document sources v\u00eda Supabase.
class SourceRemoteDataSource {
  final SupabaseClient _client;

  SourceRemoteDataSource(this._client);

  /// Inserta una fuente.
  Future<void> insertSource(Map<String, dynamic> data) async {
    await _client.from('tarea_fuentes').insert(data);
  }

  /// Actualiza una fuente por ID.
  Future<void> updateSource(String id, Map<String, dynamic> data) async {
    await _client.from('tarea_fuentes').update(data).eq('id', id);
  }

  /// Elimina un source por ID.
  Future<void> deleteSource(String id) async {
    await _client.from('tarea_fuentes').delete().eq('id', id);
  }

  /// Obtiene todas las fuentes de un usuario desde Supabase.
  Future<List<Map<String, dynamic>>> fetchAllForUser(String userId) async {
    final response = await _client
        .from('tarea_fuentes')
        .select()
        .eq('usuario_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Upsert masivo para sincronizaci\u00f3n inicial.
  Future<void> bulkUpsert(List<Map<String, dynamic>> sources) async {
    if (sources.isEmpty) return;
    try {
      await _client.from('tarea_fuentes').upsert(sources, onConflict: 'id');
    } catch (e) {
      debugPrint('⚠️ SourceRemote bulkUpsert error: $e');
      rethrow;
    }
  }
}
