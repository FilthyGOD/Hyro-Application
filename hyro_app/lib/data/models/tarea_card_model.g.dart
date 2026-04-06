// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tarea_card_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TareaCardModelAdapter extends TypeAdapter<TareaCardModel> {
  @override
  final int typeId = 6;

  @override
  TareaCardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TareaCardModel(
      id: fields[0] as String,
      tareaId: fields[1] as String,
      frente: fields[2] as String,
      reverso: fields[3] as String,
      creadoEn: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TareaCardModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tareaId)
      ..writeByte(2)
      ..write(obj.frente)
      ..writeByte(3)
      ..write(obj.reverso)
      ..writeByte(4)
      ..write(obj.creadoEn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TareaCardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
