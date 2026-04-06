import 'package:hive/hive.dart';

part 'tarea_nota_model.g.dart';

@HiveType(typeId: 4)
class TareaNotaModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tareaId;

  @HiveField(2)
  String usuarioId;

  @HiveField(3)
  String contenido;

  @HiveField(4)
  DateTime creadoEn;

  TareaNotaModel({
    required this.id,
    required this.tareaId,
    required this.usuarioId,
    required this.contenido,
    DateTime? creadoEn,
  }) : creadoEn = creadoEn ?? DateTime.now();

  TareaNotaModel copyWith({
    String? contenido,
  }) {
    return TareaNotaModel(
      id: id,
      tareaId: tareaId,
      usuarioId: usuarioId,
      contenido: contenido ?? this.contenido,
      creadoEn: creadoEn,
    );
  }

  Map<String, dynamic> toSupabaseJson(String realUserId) => {
        'id': id,
        'tarea_id': tareaId,
        'usuario_id': realUserId,
        'contenido': contenido,
      };

  /// Creates a TareaNotaModel from Supabase JSON response.
  factory TareaNotaModel.fromSupabaseJson(Map<String, dynamic> json) {
    return TareaNotaModel(
      id: json['id'] as String,
      tareaId: json['tarea_id'] as String,
      usuarioId: (json['usuario_id'] as String?) ?? '',
      contenido: (json['contenido'] as String?) ?? '',
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'] as String)
          : null,
    );
  }
}
