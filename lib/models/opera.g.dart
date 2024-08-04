// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opera.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OperaAdapter extends TypeAdapter<Opera> {
  @override
  final int typeId = 0;

  @override
  Opera read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Opera(
      name: fields[0] as String,
      parts: (fields[1] as List).cast<Setlist>(),
    );
  }

  @override
  void write(BinaryWriter writer, Opera obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.parts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
