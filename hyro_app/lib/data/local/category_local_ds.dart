import 'package:hive/hive.dart';
import '../models/category_model.dart';

/// Fuente de datos local para categor\u00edas usando Hive.
class CategoryLocalDataSource {
  static const String boxName = 'categoriesBox';

  Box<CategoryModel> get _box => Hive.box<CategoryModel>(boxName);

  /// Obtiene todas las categor\u00edas.
  List<CategoryModel> getAllCategories() {
    return _box.values.toList();
  }

  /// Obtiene una categor\u00eda por ID.
  CategoryModel? getCategory(String id) {
    return _box.get(id);
  }

  /// Inserta o actualiza una categor\u00eda.
  Future<void> putCategory(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  /// Elimina una categor\u00eda por ID.
  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
  }

  /// Limpia todas las categor\u00edas del almacenamiento local.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Obtiene todas las categor\u00edas para sincronizaci\u00f3n masiva.
  List<CategoryModel> getAllForSync() {
    return _box.values.toList();
  }
}
