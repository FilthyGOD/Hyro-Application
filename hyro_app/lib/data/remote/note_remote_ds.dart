import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for task notes via Supabase.
class NoteRemoteDataSource {
  final SupabaseClient _client;

  NoteRemoteDataSource(this._client);

  /// Insert a single note.
  Future<void> insertNote(Map<String, dynamic> data) async {
    await _client.from('tarea_notas').insert(data);
  }

  /// Update a note by ID.
  Future<void> updateNote(String id, Map<String, dynamic> data) async {
    await _client.from('tarea_notas').update(data).eq('id', id);
  }

  /// Delete a note by ID.
  Future<void> deleteNote(String id) async {
    await _client.from('tarea_notas').delete().eq('id', id);
  }

  /// Fetch all notes for a user from Supabase.
  Future<List<Map<String, dynamic>>> fetchAllForUser(String userId) async {
    final response = await _client
        .from('tarea_notas')
        .select()
        .eq('usuario_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Bulk upsert for initial sync.
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
