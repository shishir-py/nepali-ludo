// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameStateAdapter extends TypeAdapter<GameState> {
  @override
  final int typeId = 2;

  @override
  GameState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameState(
      players: (fields[0] as List).cast<Player>(),
      currentPlayerIndex: fields[1] as int,
      lastDiceValue: fields[2] as int,
      diceRolled: fields[3] as bool,
      phase: fields[4] as GamePhase,
      winnerIndex: fields[5] as int?,
      finishedOrder: (fields[6] as List).cast<int>(),
      consecutiveSixes: fields[7] as int,
      startedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GameState obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.players)
      ..writeByte(1)
      ..write(obj.currentPlayerIndex)
      ..writeByte(2)
      ..write(obj.lastDiceValue)
      ..writeByte(3)
      ..write(obj.diceRolled)
      ..writeByte(4)
      ..write(obj.phase)
      ..writeByte(5)
      ..write(obj.winnerIndex)
      ..writeByte(6)
      ..write(obj.finishedOrder)
      ..writeByte(7)
      ..write(obj.consecutiveSixes)
      ..writeByte(8)
      ..write(obj.startedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GamePhaseAdapter extends TypeAdapter<GamePhase> {
  @override
  final int typeId = 5;

  @override
  GamePhase read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GamePhase.setup;
      case 1:
        return GamePhase.playing;
      case 2:
        return GamePhase.finished;
      default:
        return GamePhase.playing;
    }
  }

  @override
  void write(BinaryWriter writer, GamePhase obj) {
    switch (obj) {
      case GamePhase.setup:
        writer.writeByte(0);
        break;
      case GamePhase.playing:
        writer.writeByte(1);
        break;
      case GamePhase.finished:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamePhaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
