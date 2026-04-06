import 'package:hive/hive.dart';

part 'tarea_card_model.g.dart';

@HiveType(typeId: 6)
class TareaCardModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tareaId;

  @HiveField(2)
  String frente;

  @HiveField(3)
  String reverso;

  @HiveField(4)
  DateTime creadoEn;

  TareaCardModel({
    required this.id,
    required this.tareaId,
    required this.frente,
    required this.reverso,
    DateTime? creadoEn,
  }) : creadoEn = creadoEn ?? DateTime.now();

  TareaCardModel copyWith({
    String? frente,
    String? reverso,
  }) {
    return TareaCardModel(
      id: id,
      tareaId: tareaId,
      frente: frente ?? this.frente,
      reverso: reverso ?? this.reverso,
      creadoEn: creadoEn,
    );
  }

  Map<String, dynamic> toSupabaseJson() => {
        'id': id,
        'tarea_id': tareaId,
        'frente': frente,
        'reverso': reverso,
      };

  /// Creates a TareaCardModel from Supabase JSON response.
  factory TareaCardModel.fromSupabaseJson(Map<String, dynamic> json) {
    return TareaCardModel(
      id: json['id'] as String,
      tareaId: json['tarea_id'] as String,
      frente: (json['frente'] as String?) ?? '',
      reverso: (json['reverso'] as String?) ?? '',
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'] as String)
          : null,
    );
  }
}
