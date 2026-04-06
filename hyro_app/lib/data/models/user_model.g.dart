// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 2;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      displayName: fields[1] as String,
      email: fields[2] as String?,
      avatarUrl: fields[3] as String?,
      focusStreak: fields[4] as int,
      totalFocusMinutes: fields[5] as int,
      totalSessions: fields[6] as int,
      pomodoroDuration: fields[7] as int,
      shortBreakDuration: fields[8] as int,
      longBreakDuration: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.focusStreak)
      ..writeByte(5)
      ..write(obj.totalFocusMinutes)
      ..writeByte(6)
      ..write(obj.totalSessions)
      ..writeByte(7)
      ..write(obj.pomodoroDuration)
      ..writeByte(8)
      ..write(obj.shortBreakDuration)
      ..writeByte(9)
      ..write(obj.longBreakDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
