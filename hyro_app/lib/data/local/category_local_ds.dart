import 'package:hive/hive.dart';
import '../models/category_model.dart';

/// Local data source for categories using Hive.
class CategoryLocalDataSource {
  static const String boxName = 'categoriesBox';

  Box<CategoryModel> get _box => Hive.box<CategoryModel>(boxName);

  /// Get all categories.
  List<CategoryModel> getAllCategories() {
    return _box.values.toList();
  }

  /// Get a single category by ID.
  CategoryModel? getCategory(String id) {
    return _box.get(id);
  }

  /// Insert or update a category.
  Future<void> putCategory(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  /// Delete a category by ID.
  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
  }

  /// Clear all categories from local storage.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Get all categories for bulk sync.
  List<CategoryModel> getAllForSync() {
    return _box.values.toList();
  }
}
