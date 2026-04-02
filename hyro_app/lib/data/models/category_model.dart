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

  @HiveField(3)
  int? iconCodePoint;

  CategoryModel({
    required this.id,
    required this.name,
    this.colorValue = 0xFF22C55E, // Default green
    this.iconCodePoint,
  });

  CategoryModel copyWith({
    String? name,
    int? colorValue,
    int? iconCodePoint,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }
}
