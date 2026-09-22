import 'dart:async';
import 'board_config.dart';
import 'dice.dart';
import 'game_event.dart';
import 'game_state.dart';
import 'player.dart';
import 'token.dart';

/// The core Ludo game engine — pure Dart, no Flutter dependencies.
///
/// Rules implemented:
///  • Roll 6 to bring a token out of yard.
///  • Exact roll required to reach centre (position 57).
///  • Rolling 6 grants an extra turn (unless it's the 3rd consecutive 6).
///  • Three consecutive 6s → forfeit turn, no move.
///  • Capturing an opponent's token (not on safe cell) sends it back to yard
///    and grants an extra turn.
///  • Safe cells: global 0, 8, 13, 21, 26, 34, 39, 47 + all player starts.
///  • If no valid moves exist after rolling, turn passes automatically.
class GameEngine {
  final Dice _dice;
  GameState state;

  /// Exposes the dice for testing (forceValue).
  Dice get dice => _dice;

  final StreamController<GameEvent> _eventController =
      StreamController<GameEvent>.broadcast();

  Stream<GameEvent> get events => _eventController.stream;

  GameEngine({required this.state, Dice? dice}) : _dice = dice ?? Dice();

  /// Convenience constructor — builds a fresh GameState from a player list.
  factory GameEngine.withPlayers(List<Player> players, {Dice? dice}) {
    return GameEngine(
      state: GameState(players: players),
      dice: dice,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Dice
  // ─────────────────────────────────────────────────────────────

  /// Roll the dice for the current player. Returns the value rolled.
  int rollDice() {
    assert(!state.diceRolled, 'Dice already rolled this turn');

    final value = _dice.roll();
    state = state.copyWith(
      lastDiceValue: value,
      diceRolled: true,
      consecutiveSixes:
          value == 6 ? state.consecutiveSixes + 1 : 0,
    );

    _emit(GameEvent(
      type: GameEventType.diceRolled,
      playerIndex: state.currentPlayerIndex,
      diceValue: value,
    ));

    if (value == 6) {
      _emit(GameEvent(
        type: GameEventType.sixRolled,
        playerIndex: state.currentPlayerIndex,
        diceValue: value,
        message: '🎲 छक्का!',
      ));
    }

    // Three consecutive 6s → forfeit turn.
    if (state.consecutiveSixes >= 3) {
      _advanceTurn(resetSixes: true);
      return value;
    }

    // Check if any move is available.
    final moves = validMoves(state.currentPlayerIndex, value);
    if (moves.isEmpty) {
      _emit(GameEvent(
        type: GameEventType.noValidMove,
        playerIndex: state.currentPlayerIndex,
        diceValue: value,
      ));
      _advanceTurn();
    }

    return value;
  }

  // ─────────────────────────────────────────────────────────────
  // Movement
  // ─────────────────────────────────────────────────────────────

  /// Move [token] belonging to [playerIndex] using the current dice value.
  /// Returns the game event(s) produced.
  List<GameEvent> moveToken(int playerIndex, Token token) {
    assert(state.diceRolled, 'Must roll dice before moving');
    assert(playerIndex == state.currentPlayerIndex, 'Not this player\'s turn');

    final diceValue = state.lastDiceValue;
    final List<GameEvent> produced = [];

    // Bring token out of yard.
    if (token.isInYard) {
      assert(diceValue == 6, 'Need 6 to leave yard');
      token.position = 0;
      final ev = GameEvent(
        type: GameEventType.tokenMoved,
        playerIndex: playerIndex,
        tokenId: token.id,
        diceValue: diceValue,
      );
      produced.add(ev);
      _emit(ev);
    } else {
      // Normal move.
      final newPos = token.position + diceValue;
      token.position = newPos;

      if (newPos >= 57) {
        // Finished!
        token.position = 57;
        produced.add(_handleTokenFinished(playerIndex, token));
      } else if (newPos >= 52) {
        // Entered home column.
        final ev = GameEvent(
          type: GameEventType.tokenEnteredHome,
          playerIndex: playerIndex,
          tokenId: token.id,
          message: '🏠 घर पुग्यो!',
        );
        produced.add(ev);
        _emit(ev);
      } else {
        final ev = GameEvent(
          type: GameEventType.tokenMoved,
          playerIndex: playerIndex,
          tokenId: token.id,
          diceValue: diceValue,
        );
        produced.add(ev);
        _emit(ev);
      }
    }

    // Check for capture (only on main track, position 0-51).
    bool captured = false;
    if (token.position >= 0 && token.position <= 51) {
      final capture = _checkCapture(playerIndex, token);
      if (capture != null) {
        produced.add(capture);
        captured = true;
      }

      // If we didn't capture and landed on a safe cell, emit a safe event
      // (so the UI can play the safe-cell sound / show a shield).
      if (!captured && !token.isInYard) {
        final globalPos = globalTrackIndex(playerIndex, token.position);
        if (globalPos != null && BoardConfig.isGlobalSafe(globalPos)) {
          final safeEv = GameEvent(
            type: GameEventType.landedOnSafe,
            playerIndex: playerIndex,
            tokenId: token.id,
            message: '🛡️ सुरक्षित!',
          );
          produced.add(safeEv);
          _emit(safeEv);
        }
      }
    }

    // Check player win.
    final player = state.players[playerIndex];
    if (player.allTokensFinished && !player.hasWon) {
      player.hasWon = true;
      final order = state.finishedOrder.length + 1;
      player.finishOrder = order;
      state.finishedOrder.add(playerIndex);

      final winEv = GameEvent(
        type: GameEventType.playerWon,
        playerIndex: playerIndex,
        message: '🏆 बधाई छ!',
      );
      produced.add(winEv);
      _emit(winEv);

      if (state.activePlayers <= 1) {
        state = state.copyWith(phase: GamePhase.finished, winnerIndex: playerIndex);
        _emit(GameEvent(type: GameEventType.gameOver, playerIndex: playerIndex));
        return produced;
      }
    }

    // Decide next turn.
    final didCapture = produced.any((e) => e.type == GameEventType.tokenCaptured);
    final finishedToken = produced.any((e) => e.type == GameEventType.tokenFinished);
    final extraTurn = diceValue == 6 || didCapture;

    if (extraTurn && state.consecutiveSixes < 3) {
      // Stay on this player — reset dice but keep consecutive 6 count.
      state = state.copyWith(diceRolled: false);
    } else {
      _advanceTurn();
    }

    return produced;
  }

  // ─────────────────────────────────────────────────────────────
  // Queries
  // ─────────────────────────────────────────────────────────────

  /// Returns the list of tokens that can legally be moved for [diceValue].
  List<Token> validMoves(int playerIndex, int diceValue) {
    return state.players[playerIndex]
        .tokens
        .where((t) => t.canMove(diceValue))
        .toList();
  }

  /// Returns the global main-track index for a token at [localPos].
  /// Returns null if the token is in yard, home column, or finished.
  int? globalTrackIndex(int playerIndex, int localPos) {
    if (localPos < 0 || localPos > 51) return null;
    return BoardConfig.localToGlobal(playerIndex, localPos);
  }

  // ─────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────

  GameEvent _handleTokenFinished(int playerIndex, Token token) {
    final ev = GameEvent(
      type: GameEventType.tokenFinished,
      playerIndex: playerIndex,
      tokenId: token.id,
      message: '🏠 घर पुग्यो! 🎉',
    );
    _emit(ev);
    return ev;
  }

  GameEvent? _checkCapture(int playerIndex, Token movingToken) {
    final globalPos = globalTrackIndex(playerIndex, movingToken.position);
    if (globalPos == null) return null;

    // Cannot capture on safe cells.
    if (BoardConfig.isGlobalSafe(globalPos)) return null;

    for (int pi = 0; pi < state.players.length; pi++) {
      if (pi == playerIndex) continue;
      for (final t in state.players[pi].tokens) {
        if (t.isInYard || t.isFinished || t.isInHomeColumn) continue;
        final opponentGlobal = globalTrackIndex(pi, t.position);
        if (opponentGlobal == globalPos) {
          // Capture!
          t.position = -1; // back to yard
          final ev = GameEvent(
            type: GameEventType.tokenCaptured,
            playerIndex: playerIndex,
            tokenId: movingToken.id,
            capturedPlayerIndex: pi,
            capturedTokenId: t.id,
            message: '💥 काटियो!',
          );
          _emit(ev);
          return ev;
        }
      }
    }
    return null;
  }

  void _advanceTurn({bool resetSixes = false}) {
    int next = (state.currentPlayerIndex + 1) % state.players.length;
    // Skip players who have won.
    int tries = 0;
    while (state.players[next].allTokensFinished && tries < state.players.length) {
      next = (next + 1) % state.players.length;
      tries++;
    }

    state = state.copyWith(
      currentPlayerIndex: next,
      diceRolled: false,
      consecutiveSixes: resetSixes ? 0 : state.consecutiveSixes,
    );

    _emit(GameEvent(
      type: GameEventType.turnChanged,
      playerIndex: next,
    ));
  }

  void _emit(GameEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void dispose() {
    _eventController.close();
  }

  // ─────────────────────────────────────────────────────────────
  // Serialisation helpers
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'players': state.players.map((p) => {
          'index': p.index,
          'name': p.name,
          'type': p.type.name,
          'difficulty': p.difficulty.name,
          'hasWon': p.hasWon,
          'finishOrder': p.finishOrder,
          'tokens': p.tokens.map((t) => {'id': t.id, 'position': t.position}).toList(),
        }).toList(),
        'currentPlayerIndex': state.currentPlayerIndex,
        'lastDiceValue': state.lastDiceValue,
        'diceRolled': state.diceRolled,
        'phase': state.phase.name,
        'winnerIndex': state.winnerIndex,
        'finishedOrder': state.finishedOrder,
        'consecutiveSixes': state.consecutiveSixes,
        'startedAt': state.startedAt.toIso8601String(),
      };
}
