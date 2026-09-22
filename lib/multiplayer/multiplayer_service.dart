/// Online multiplayer service — architecture stub for v1.0
///
/// This file defines the interface and data models for online multiplayer.
/// The actual backend implementation will be added in v1.1.
///
/// The architecture is designed so the game engine (GameEngine) can be driven
/// by either a local GameProvider or a remote MultiplayerService without
/// changing any game logic code.
library;

// ─────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────

class GameRoom {
  final String id;
  final String code; // 6-char invite code
  final String hostId;
  final List<String> playerIds;
  final RoomStatus status;
  final int maxPlayers;
  final DateTime createdAt;

  const GameRoom({
    required this.id,
    required this.code,
    required this.hostId,
    required this.playerIds,
    required this.status,
    required this.maxPlayers,
    required this.createdAt,
  });

  bool get isFull => playerIds.length >= maxPlayers;
  bool get canStart => playerIds.length >= 2;
}

enum RoomStatus { waiting, starting, playing, finished }

class OnlinePlayer {
  final String id;
  final String name;
  final bool isConnected;
  final bool isHost;

  const OnlinePlayer({
    required this.id,
    required this.name,
    required this.isConnected,
    required this.isHost,
  });
}

// ─────────────────────────────────────────────────────────────
// Service Interface
// ─────────────────────────────────────────────────────────────

/// Abstract interface for multiplayer backends.
/// Swap implementations to switch between WebSocket, Firebase, etc.
abstract class MultiplayerService {
  /// Create a new room; returns the room with a shareable code.
  Future<GameRoom> createRoom({required int maxPlayers});

  /// Join an existing room by its 6-char code.
  Future<GameRoom> joinRoom({required String code});

  /// Leave the current room.
  Future<void> leaveRoom();

  /// Signal ready to start (host only).
  Future<void> startGame();

  /// Send a dice roll result to all players.
  Future<void> sendDiceRoll({required int value});

  /// Send a token move to all players.
  Future<void> sendTokenMove({required int tokenId});

  /// Send a reaction string to all players.
  Future<void> sendReaction({required String reaction});

  /// Stream of room state updates (players joining/leaving, status changes).
  Stream<GameRoom> get roomUpdates;

  /// Stream of game actions from remote players.
  Stream<RemoteAction> get actionStream;

  /// Dispose resources.
  Future<void> dispose();
}

// ─────────────────────────────────────────────────────────────
// Remote Actions
// ─────────────────────────────────────────────────────────────

enum RemoteActionType {
  diceRolled,
  tokenMoved,
  reaction,
  playerLeft,
  playerRejoined
}

class RemoteAction {
  final RemoteActionType type;
  final String playerId;
  final Map<String, dynamic> payload;

  const RemoteAction({
    required this.type,
    required this.playerId,
    required this.payload,
  });
}

// ─────────────────────────────────────────────────────────────
// Coming Soon Stub
// ─────────────────────────────────────────────────────────────

/// Placeholder implementation that throws [UnimplementedError].
/// Replace with a real WebSocket or Firebase implementation for v1.1.
class StubMultiplayerService implements MultiplayerService {
  @override
  Future<GameRoom> createRoom({required int maxPlayers}) =>
      Future.error(const _NotImplemented());

  @override
  Future<GameRoom> joinRoom({required String code}) =>
      Future.error(const _NotImplemented());

  @override
  Future<void> leaveRoom() => Future.error(const _NotImplemented());

  @override
  Future<void> startGame() => Future.error(const _NotImplemented());

  @override
  Future<void> sendDiceRoll({required int value}) =>
      Future.error(const _NotImplemented());

  @override
  Future<void> sendTokenMove({required int tokenId}) =>
      Future.error(const _NotImplemented());

  @override
  Future<void> sendReaction({required String reaction}) =>
      Future.error(const _NotImplemented());

  @override
  Stream<GameRoom> get roomUpdates => const Stream.empty();

  @override
  Stream<RemoteAction> get actionStream => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

class _NotImplemented implements Exception {
  const _NotImplemented();
  @override
  String toString() => 'Online multiplayer is coming in v1.1! '
      'Follow the GitHub repository for updates.';
}
