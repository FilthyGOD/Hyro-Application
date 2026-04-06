// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tarea_fuente_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TareaFuenteModelAdapter extends TypeAdapter<TareaFuenteModel> {
  @override
  final int typeId = 5;

  @override
  TareaFuenteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TareaFuenteModel(
      id: fields[0] as String,
      tareaId: fields[1] as String,
      usuarioId: fields[2] as String,
      nombreArchivo: fields[3] as String,
      rutaArchivo: fields[4] as String,
      tipoArchivo: fields[5] as String?,
      creadoEn: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TareaFuenteModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tareaId)
      ..writeByte(2)
      ..write(obj.usuarioId)
      ..writeByte(3)
      ..write(obj.nombreArchivo)
      ..writeByte(4)
      ..write(obj.rutaArchivo)
      ..writeByte(5)
      ..write(obj.tipoArchivo)
      ..writeByte(6)
      ..write(obj.creadoEn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TareaFuenteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
