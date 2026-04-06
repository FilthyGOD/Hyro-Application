import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for task document sources via Supabase.
class SourceRemoteDataSource {
  final SupabaseClient _client;

  SourceRemoteDataSource(this._client);

  /// Insert a single source.
  Future<void> insertSource(Map<String, dynamic> data) async {
    await _client.from('tarea_fuentes').insert(data);
  }

  /// Update a source by ID.
  Future<void> updateSource(String id, Map<String, dynamic> data) async {
    await _client.from('tarea_fuentes').update(data).eq('id', id);
  }

  /// Delete a source by ID.
  Future<void> deleteSource(String id) async {
    await _client.from('tarea_fuentes').delete().eq('id', id);
  }

  /// Fetch all sources for a user from Supabase.
  Future<List<Map<String, dynamic>>> fetchAllForUser(String userId) async {
    final response = await _client
        .from('tarea_fuentes')
        .select()
        .eq('usuario_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Bulk upsert for initial sync.
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
