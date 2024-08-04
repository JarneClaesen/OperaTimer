// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setlist.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SetlistAdapter extends TypeAdapter<Setlist> {
  @override
  final int typeId = 1;

  @override
  Setlist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Setlist(
      partName: fields[0] as String,
      playTimes: (fields[1] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Setlist obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.partName)
      ..writeByte(1)
      ..write(obj.playTimes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetlistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
