import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fuente de datos remota para flashcards v\u00eda Supabase.
class CardRemoteDataSource {
  final SupabaseClient _client;

  CardRemoteDataSource(this._client);

  /// Inserta una flashcard.
  Future<void> insertCard(Map<String, dynamic> data) async {
    await _client.from('tarea_cards').insert(data);
  }

  /// Actualiza una flashcard por ID.
  Future<void> updateCard(String id, Map<String, dynamic> data) async {
    await _client.from('tarea_cards').update(data).eq('id', id);
  }

  /// Elimina un card por ID.
  Future<void> deleteCard(String id) async {
    await _client.from('tarea_cards').delete().eq('id', id);
  }

  /// Obtiene todas las flashcards de una lista de IDs de tareas desde Supabase.
  Future<List<Map<String, dynamic>>> fetchAllByTaskIds(List<String> taskIds) async {
    if (taskIds.isEmpty) return [];
    final response = await _client
        .from('tarea_cards')
        .select()
        .inFilter('tarea_id', taskIds);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Upsert masivo para sincronizaci\u00f3n inicial.
  Future<void> bulkUpsert(List<Map<String, dynamic>> cards) async {
    if (cards.isEmpty) return;
    try {
      await _client.from('tarea_cards').upsert(cards, onConflict: 'id');
    } catch (e) {
      debugPrint('⚠️ CardRemote bulkUpsert error: $e');
      rethrow;
    }
  }
}
