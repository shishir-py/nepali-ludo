/// Events emitted by the game engine so the UI can react / play sounds.
enum GameEventType {
  diceRolled,
  tokenMoved,
  tokenCaptured,
  landedOnSafe,
  tokenEnteredHome,
  tokenFinished,
  playerWon,
  turnChanged,
  sixRolled,
  noValidMove,
  gameOver,
}

class GameEvent {
  final GameEventType type;
  final int playerIndex;
  final int? tokenId;
  final int? diceValue;
  final int? capturedPlayerIndex;
  final int? capturedTokenId;
  final String? message; // Nepali announcement

  const GameEvent({
    required this.type,
    required this.playerIndex,
    this.tokenId,
    this.diceValue,
    this.capturedPlayerIndex,
    this.capturedTokenId,
    this.message,
  });
}
