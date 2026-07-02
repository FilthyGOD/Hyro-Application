import 'package:flutter/material.dart';
import '../local/category_local_ds.dart';
import '../remote/category_remote_ds.dart';
import '../models/category_model.dart';

/// Repositorio que abstrae las operaciones locales y remotas de categor\u00edas.
class CategoryRepository {
  final CategoryLocalDataSource _local;
  final CategoryRemoteDataSource _remote;
  final bool Function() _isAuthenticated;
  final String? Function() _getUserId;

  CategoryRepository({
    required CategoryLocalDataSource local,
    required CategoryRemoteDataSource remote,
    required bool Function() isAuthenticated,
    required String? Function() getUserId,
  })  : _local = local,
        _remote = remote,
        _isAuthenticated = isAuthenticated,
        _getUserId = getUserId;

  /// Obtiene todas las categor\u00edas desde el almacenamiento local.
  List<CategoryModel> getCategories() {
    return _local.getAllCategories();
  }

  /// Obtiene una categor\u00eda por ID.
  CategoryModel? getCategory(String id) {
    return _local.getCategory(id);
  }

  /// Descarga todas las categor\u00edas de Supabase y reemplaza los datos locales.
  Future<void> pullRemoteToLocal() async {
    final userId = _getUserId();
    if (userId == null) return;
    try {
      final maps = await _remote.fetchAllForUser(userId);
      await _local.clearAll();
      for (final map in maps) {
        final cat = CategoryModel.fromSupabaseJson(map);
        await _local.putCategory(cat);
      }
    } catch (e) {
      debugPrint('⚠️ CategoryRepo: Error pulling from remote: $e');
    }
  }

  /// Add a new category — local first, then remote if authenticated.
  Future<void> addCategory(CategoryModel category) async {
    await _local.putCategory(category);
    if (_isAuthenticated()) {
      try {
        final userId = _getUserId();
        if (userId != null) {
          await _remote.insertCategory(category.toSupabaseJson(userId));
        }
      } catch (e) {
        debugPrint('⚠️ CategoryRepo: Error syncing new category to remote: $e');
      }
    }
  }

  /// Update a category — local first, then remote if authenticated.
  Future<void> updateCategory(CategoryModel category) async {
    await _local.putCategory(category);
    if (_isAuthenticated()) {
      try {
        final userId = _getUserId();
        if (userId != null) {
          await _remote.updateCategory(category.id, category.toSupabaseJson(userId));
        }
      } catch (e) {
        debugPrint('⚠️ CategoryRepo: Error syncing category update to remote: $e');
      }
    }
  }

  /// Delete a category — local first, then remote if authenticated.
  Future<void> deleteCategory(String id) async {
    await _local.deleteCategory(id);
    if (_isAuthenticated()) {
      try {
        await _remote.deleteCategory(id);
      } catch (e) {
        debugPrint('⚠️ CategoryRepo: Error syncing category deletion to remote: $e');
      }
    }
  }
}
