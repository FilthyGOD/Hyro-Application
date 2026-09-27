import 'package:flutter/material.dart';

class SharedTaskModel {
  final String id;
  final String remitenteId;
  final String remitenteNombre;
  final String tareaTitulo;
  final Map<String, dynamic> tareaDatos;
  final DateTime enviadoEn;

  const SharedTaskModel({
    required this.id,
    required this.remitenteId,
    required this.remitenteNombre,
    required this.tareaTitulo,
    required this.tareaDatos,
    required this.enviadoEn,
  });

  factory SharedTaskModel.fromJson(Map<String, dynamic> json) {
    return SharedTaskModel(
      id: json['id'] as String,
      remitenteId: json['remitente_id'] as String,
      remitenteNombre: json['perfiles'] != null ? (json['perfiles']['nombre_usuario'] as String? ?? 'Usuario') : 'Usuario',
      tareaTitulo: json['tarea_titulo'] as String? ?? 'Tarea Compartida',
      tareaDatos: Map<String, dynamic>.from(json['tarea_datos'] ?? {}),
      enviadoEn: DateTime.parse(json['enviado_en'] as String),
    );
  }
}
