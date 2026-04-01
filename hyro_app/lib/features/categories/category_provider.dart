import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final Box<CategoryModel> _box = Hive.box<CategoryModel>('categoriesBox');
  List<CategoryModel> _categories = [];

  List<CategoryModel> get categories => _categories;

  CategoryProvider() {
    _loadCategories();
  }

  void _loadCategories() {
    _categories = _box.values.toList();
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _box.put(category.id, category);
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _box.put(category.id, category);
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
