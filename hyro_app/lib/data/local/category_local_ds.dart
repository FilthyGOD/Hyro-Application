import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import '../models/category_model.dart';

/// Fuente de datos local para categorías usando Hive.
class CategoryLocalDataSource {
  static const String boxName = 'categoriesBox';

  // Caché en memoria para entorno Web
  static final Map<String, CategoryModel> _webCache = {};

  Box<CategoryModel> get _box => Hive.box<CategoryModel>(boxName);

  /// Obtiene todas las categorías.
  List<CategoryModel> getAllCategories() {
    if (kIsWeb) return _webCache.values.toList();
    return _box.values.toList();
  }

  /// Obtiene una categoría por ID.
  CategoryModel? getCategory(String id) {
    if (kIsWeb) return _webCache[id];
    return _box.get(id);
  }

  /// Inserta o actualiza una categoría.
  Future<void> putCategory(CategoryModel category) async {
    if (kIsWeb) {
      _webCache[category.id] = category;
      return;
    }
    await _box.put(category.id, category);
  }

  /// Elimina una categoría por ID.
  Future<void> deleteCategory(String id) async {
    if (kIsWeb) {
      _webCache.remove(id);
      return;
    }
    await _box.delete(id);
  }

  /// Limpia todas las categorías del almacenamiento local.
  Future<void> clearAll() async {
    if (kIsWeb) {
      _webCache.clear();
      return;
    }
    await _box.clear();
  }

  /// Obtiene todas las categorías para sincronización masiva.
  List<CategoryModel> getAllForSync() {
    if (kIsWeb) return _webCache.values.toList();
    return _box.values.toList();
  }
}
