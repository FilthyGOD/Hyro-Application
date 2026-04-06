import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for categories via Supabase.
class CategoryRemoteDataSource {
  final SupabaseClient _client;

  CategoryRemoteDataSource(this._client);

  /// Insert a single category.
  Future<void> insertCategory(Map<String, dynamic> data) async {
    await _client.from('categorias').insert(data);
  }

  /// Update a category by ID.
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _client.from('categorias').update(data).eq('id', id);
  }

  /// Delete a category by ID.
  Future<void> deleteCategory(String id) async {
    await _client.from('categorias').delete().eq('id', id);
  }

  /// Fetch all categories for a user from Supabase.
  Future<List<Map<String, dynamic>>> fetchAllForUser(String userId) async {
    final response = await _client
        .from('categorias')
        .select()
        .eq('usuario_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Bulk upsert for initial sync.
  Future<void> bulkUpsert(List<Map<String, dynamic>> categories) async {
    if (categories.isEmpty) return;
    try {
      await _client.from('categorias').upsert(categories, onConflict: 'id');
    } catch (e) {
      debugPrint('⚠️ CategoryRemote bulkUpsert error: $e');
      rethrow;
    }
  }
}
