import 'package:hive/hive.dart';
import 'player.dart';

part 'game_state.g.dart';

enum GamePhase { setup, playing, finished }

@HiveType(typeId: 2)
class GameState {
  @HiveField(0)
  List<Player> players;

  @HiveField(1)
  int currentPlayerIndex;

  @HiveField(2)
  int lastDiceValue;

  @HiveField(3)
  bool diceRolled;

  @HiveField(4)
  GamePhase phase;

  @HiveField(5)
  int? winnerIndex;

  @HiveField(6)
  List<int> finishedOrder; // player indices in order of finish

  @HiveField(7)
  int consecutiveSixes; // track consecutive 6s for the 3×6 rule

  @HiveField(8)
  DateTime startedAt;

  GameState({
    required this.players,
    this.currentPlayerIndex = 0,
    this.lastDiceValue = 0,
    this.diceRolled = false,
    this.phase = GamePhase.playing,
    this.winnerIndex,
    List<int>? finishedOrder,
    this.consecutiveSixes = 0,
    DateTime? startedAt,
  })  : finishedOrder = finishedOrder ?? [],
        startedAt = startedAt ?? DateTime.now();

  Player get currentPlayer => players[currentPlayerIndex];

  bool get isOver => phase == GamePhase.finished;

  /// Number of players still in the game (not yet finished all tokens).
  int get activePlayers => players.where((p) => !p.allTokensFinished).length;

  GameState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    int? lastDiceValue,
    bool? diceRolled,
    GamePhase? phase,
    int? winnerIndex,
    List<int>? finishedOrder,
    int? consecutiveSixes,
  }) {
    return GameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      lastDiceValue: lastDiceValue ?? this.lastDiceValue,
      diceRolled: diceRolled ?? this.diceRolled,
      phase: phase ?? this.phase,
      winnerIndex: winnerIndex ?? this.winnerIndex,
      finishedOrder: finishedOrder ?? List.from(this.finishedOrder),
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      startedAt: startedAt,
    );
  }
}
