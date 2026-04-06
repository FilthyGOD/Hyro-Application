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

  @HiveField(4)
  String? usuarioId; // UUID del usuario (guest o real)

  CategoryModel({
    required this.id,
    required this.name,
    this.colorValue = 0xFF22C55E, // Default green
    this.iconCodePoint,
    this.usuarioId,
  });

  CategoryModel copyWith({
    String? name,
    int? colorValue,
    int? iconCodePoint,
    String? usuarioId,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }

  /// Serializes this category for Supabase upsert.
  Map<String, dynamic> toSupabaseJson(String realUserId) => {
        'id': id,
        'usuario_id': realUserId,
        'nombre': name,
        'color': colorValue.toRadixString(16).padLeft(8, '0'),
        'icono': iconCodePoint?.toString(),
      };

  /// Creates a CategoryModel from Supabase JSON response.
  factory CategoryModel.fromSupabaseJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: (json['nombre'] as String?) ?? '',
      colorValue: _parseColor(json['color'] as String?),
      iconCodePoint: json['icono'] != null
          ? int.tryParse(json['icono'] as String)
          : null,
      usuarioId: json['usuario_id'] as String?,
    );
  }

  static int _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return 0xFF22C55E;
    final clean = hex.replaceAll('#', '');
    return int.tryParse(clean, radix: 16) ?? 0xFF22C55E;
  }
}
