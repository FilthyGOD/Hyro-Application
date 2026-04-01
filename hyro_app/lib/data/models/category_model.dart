import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  CategoryModel({
    required this.id,
    required this.name,
    this.colorValue = 0xFF22C55E, // Default green
  });

  CategoryModel copyWith({
    String? name,
    int? colorValue,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
