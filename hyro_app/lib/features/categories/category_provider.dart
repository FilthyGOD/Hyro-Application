import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/local/category_local_ds.dart';
import '../../data/remote/category_remote_ds.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryProvider extends ChangeNotifier {
  late final CategoryRepository _repository;

  List<CategoryModel> _categories = [];

  List<CategoryModel> get categories => _categories;

  /// Auth state callbacks - set externally by AppShell
  bool Function() isAuthenticated = () => false;
  String? Function() getUserId = () => null;

  CategoryProvider() {
    _repository = CategoryRepository(
      local: CategoryLocalDataSource(),
      remote: CategoryRemoteDataSource(Supabase.instance.client),
      isAuthenticated: () => isAuthenticated(),
      getUserId: () => getUserId(),
    );
    // Defer to after the build frame to avoid notifyListeners() during build
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  void _loadCategories() {
    _categories = _repository.getCategories();
    notifyListeners();
  }

  /// Reload categories — if authenticated, first pull from Supabase.
  Future<void> reload() async {
    try {
      if (isAuthenticated()) {
        try {
          await _repository.pullRemoteToLocal();
        } catch (e) {
          debugPrint('Error pulling remote categories (offline?): $e');
        }
      }
      _categories = _repository.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error reloading categories: $e');
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    await _repository.addCategory(category);
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _repository.updateCategory(category);
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
