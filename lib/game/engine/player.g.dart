// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;

  @override
  Player read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Player(
      index: fields[0] as int,
      name: fields[1] as String,
      type: fields[2] as PlayerType,
      difficulty: fields[3] as AiDifficulty,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.index)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.difficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlayerTypeAdapter extends TypeAdapter<PlayerType> {
  @override
  final int typeId = 3;

  @override
  PlayerType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlayerType.human;
      case 1:
        return PlayerType.ai;
      default:
        return PlayerType.human;
    }
  }

  @override
  void write(BinaryWriter writer, PlayerType obj) {
    switch (obj) {
      case PlayerType.human:
        writer.writeByte(0);
        break;
      case PlayerType.ai:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AiDifficultyAdapter extends TypeAdapter<AiDifficulty> {
  @override
  final int typeId = 4;

  @override
  AiDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AiDifficulty.easy;
      case 1:
        return AiDifficulty.normal;
      case 2:
        return AiDifficulty.hard;
      default:
        return AiDifficulty.normal;
    }
  }

  @override
  void write(BinaryWriter writer, AiDifficulty obj) {
    switch (obj) {
      case AiDifficulty.easy:
        writer.writeByte(0);
        break;
      case AiDifficulty.normal:
        writer.writeByte(1);
        break;
      case AiDifficulty.hard:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
