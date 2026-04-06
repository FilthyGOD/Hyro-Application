// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tarea_nota_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TareaNotaModelAdapter extends TypeAdapter<TareaNotaModel> {
  @override
  final int typeId = 4;

  @override
  TareaNotaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TareaNotaModel(
      id: fields[0] as String,
      tareaId: fields[1] as String,
      usuarioId: fields[2] as String,
      contenido: fields[3] as String,
      creadoEn: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TareaNotaModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tareaId)
      ..writeByte(2)
      ..write(obj.usuarioId)
      ..writeByte(3)
      ..write(obj.contenido)
      ..writeByte(4)
      ..write(obj.creadoEn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TareaNotaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
