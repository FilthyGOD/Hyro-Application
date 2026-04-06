import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for flashcards via Supabase.
class CardRemoteDataSource {
  final SupabaseClient _client;

  CardRemoteDataSource(this._client);

  /// Insert a single card.
  Future<void> insertCard(Map<String, dynamic> data) async {
    await _client.from('tarea_cards').insert(data);
  }

  /// Update a card by ID.
  Future<void> updateCard(String id, Map<String, dynamic> data) async {
    await _client.from('tarea_cards').update(data).eq('id', id);
  }

  /// Delete a card by ID.
  Future<void> deleteCard(String id) async {
    await _client.from('tarea_cards').delete().eq('id', id);
  }

  /// Fetch all cards for a list of task IDs from Supabase.
  Future<List<Map<String, dynamic>>> fetchAllByTaskIds(List<String> taskIds) async {
    if (taskIds.isEmpty) return [];
    final response = await _client
        .from('tarea_cards')
        .select()
        .inFilter('tarea_id', taskIds);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Bulk upsert for initial sync.
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
