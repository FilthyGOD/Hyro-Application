import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fuente de datos remota para categories v\u00eda Supabase.
class CategoryRemoteDataSource {
  final SupabaseClient _client;

  CategoryRemoteDataSource(this._client);

  /// Inserta una categor\u00eda.
  Future<void> insertCategory(Map<String, dynamic> data) async {
    await _client.from('categorias').insert(data);
  }

  /// Actualiza una categor\u00eda por ID.
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _client.from('categorias').update(data).eq('id', id);
  }

  /// Elimina un category por ID.
  Future<void> deleteCategory(String id) async {
    await _client.from('categorias').delete().eq('id', id);
  }

  /// Obtiene todas las categor\u00edas de un usuario desde Supabase.
  Future<List<Map<String, dynamic>>> fetchAllForUser(String userId) async {
    final response = await _client
        .from('categorias')
        .select()
        .eq('usuario_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Upsert masivo para sincronizaci\u00f3n inicial.
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
