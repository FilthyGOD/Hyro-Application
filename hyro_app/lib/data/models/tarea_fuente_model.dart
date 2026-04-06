import 'package:hive/hive.dart';

part 'tarea_fuente_model.g.dart';

@HiveType(typeId: 5)
class TareaFuenteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tareaId;

  @HiveField(2)
  String usuarioId;

  @HiveField(3)
  String nombreArchivo;

  @HiveField(4)
  String rutaArchivo; // Path local o URL de Supabase post-sync

  @HiveField(5)
  String? tipoArchivo;

  @HiveField(6)
  DateTime creadoEn;

  TareaFuenteModel({
    required this.id,
    required this.tareaId,
    required this.usuarioId,
    required this.nombreArchivo,
    required this.rutaArchivo,
    this.tipoArchivo,
    DateTime? creadoEn,
  }) : creadoEn = creadoEn ?? DateTime.now();

  /// Whether this source points to a local file (not yet synced).
  bool get isLocal => !rutaArchivo.startsWith('http');

  TareaFuenteModel copyWith({
    String? nombreArchivo,
    String? rutaArchivo,
    String? tipoArchivo,
  }) {
    return TareaFuenteModel(
      id: id,
      tareaId: tareaId,
      usuarioId: usuarioId,
      nombreArchivo: nombreArchivo ?? this.nombreArchivo,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      tipoArchivo: tipoArchivo ?? this.tipoArchivo,
      creadoEn: creadoEn,
    );
  }

  Map<String, dynamic> toSupabaseJson(String realUserId) => {
        'id': id,
        'tarea_id': tareaId,
        'usuario_id': realUserId,
        'nombre_archivo': nombreArchivo,
        'ruta_archivo': rutaArchivo,
        'tipo_archivo': tipoArchivo,
      };

  /// Creates a TareaFuenteModel from Supabase JSON response.
  factory TareaFuenteModel.fromSupabaseJson(Map<String, dynamic> json) {
    return TareaFuenteModel(
      id: json['id'] as String,
      tareaId: json['tarea_id'] as String,
      usuarioId: (json['usuario_id'] as String?) ?? '',
      nombreArchivo: (json['nombre_archivo'] as String?) ?? '',
      rutaArchivo: (json['ruta_archivo'] as String?) ?? '',
      tipoArchivo: json['tipo_archivo'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'] as String)
          : null,
    );
  }
}
