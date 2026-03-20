// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MusicAdapter extends TypeAdapter<Music> {
  @override
  final int typeId = 1;

  @override
  Music read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Music(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      isUrl: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      artist: fields[5] as String?,
      album: fields[6] as String?,
      duration: fields[7] as int?,
      thumbnailPath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Music obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.isUrl)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.artist)
      ..writeByte(6)
      ..write(obj.album)
      ..writeByte(7)
      ..write(obj.duration)
      ..writeByte(8)
      ..write(obj.thumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
