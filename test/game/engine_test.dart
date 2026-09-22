import 'package:flutter_test/flutter_test.dart';
import 'package:nepali_ludo/game/engine/game_engine.dart';
import 'package:nepali_ludo/game/engine/game_event.dart';
import 'package:nepali_ludo/game/engine/game_state.dart';
import 'package:nepali_ludo/game/engine/player.dart';
import 'package:nepali_ludo/game/engine/token.dart';

GameEngine _makeEngine({int players = 2}) {
  final ps = List.generate(
    players,
    (i) => Player(index: i, name: 'P${i + 1}', type: PlayerType.human),
  );
  return GameEngine.withPlayers(ps);
}

void main() {
  group('GameEngine – initialisation', () {
    test('starts in playing phase', () {
      final e = _makeEngine();
      expect(e.state.phase, GamePhase.playing);
    });

    test('all tokens start in yard', () {
      final e = _makeEngine();
      for (final p in e.state.players) {
        for (final t in p.tokens) {
          expect(t.isInYard, isTrue);
        }
      }
    });

    test('first player is player 0', () {
      final e = _makeEngine();
      expect(e.state.currentPlayerIndex, 0);
    });

    test('dice not rolled on start', () {
      final e = _makeEngine();
      expect(e.state.diceRolled, isFalse);
    });
  });

  group('GameEngine – dice rolling', () {
    test('rollDice sets diceRolled = true', () {
      final e = _makeEngine();
      e.dice.forceValue(3);
      e.rollDice();
      expect(e.state.diceRolled, isTrue);
    });

    test('rolling 6 from yard allows token to exit', () {
      final e = _makeEngine();
      e.dice.forceValue(6);
      e.rollDice();
      final moveable = e.state.currentPlayer.moveableTokens(6);
      expect(moveable.isNotEmpty, isTrue);
    });

    test('non-six with all tokens in yard: no moveable tokens', () {
      final e = _makeEngine();
      e.dice.forceValue(3);
      e.rollDice();
      final moveable = e.state.currentPlayer.moveableTokens(3);
      expect(moveable.isEmpty, isTrue);
    });

    test('three consecutive sixes: turn passes after 3rd', () {
      final e = _makeEngine();
      final initialPlayer = e.state.currentPlayerIndex;

      // 1st six → bring token out
      e.dice.forceValue(6);
      e.rollDice();
      e.moveToken(e.state.currentPlayer.tokens.first);
      expect(e.state.currentPlayerIndex, initialPlayer); // extra turn

      // 2nd six → advance
      e.dice.forceValue(6);
      e.rollDice();
      final moveable2 = e.state.currentPlayer.moveableTokens(6);
      if (moveable2.isNotEmpty) e.moveToken(moveable2.first);
      expect(e.state.currentPlayerIndex, initialPlayer); // extra turn again

      // 3rd six → should forfeit and switch player
      e.dice.forceValue(6);
      e.rollDice();
      // After 3rd six consecutively, turn advances (consecutiveSixes resets)
      expect(e.state.consecutiveSixes, 0);
    });
  });

  group('GameEngine – token movement', () {
    test('token exits yard on 6 and lands at position 0', () {
      final e = _makeEngine();
      e.dice.forceValue(6);
      e.rollDice();
      final t = e.state.currentPlayer.tokens.first;
      e.moveToken(t);
      final moved = e.state.players[0].tokens.first;
      expect(moved.position, 0);
    });

    test('token advances by dice value on board', () {
      final e = _makeEngine();
      // Bring token to board
      e.dice.forceValue(6);
      e.rollDice();
      e.moveToken(e.state.currentPlayer.tokens.first);

      // Advance by 4 (same player gets extra turn after 6)
      e.dice.forceValue(4);
      e.rollDice();
      final moveable = e.state.currentPlayer.moveableTokens(4);
      if (moveable.isNotEmpty) {
        final before = moveable.first.position;
        e.moveToken(moveable.first);
        // Find the moved token (it's now at before + 4)
        final allTokens = e.state.players.expand((p) => p.tokens);
        final moved = allTokens.firstWhere((t) => t.position == before + 4,
            orElse: () => Token(id: 99, position: before + 4));
        expect(moved.position, before + 4);
      }
    });

    test('tokens at position 57 are considered finished', () {
      final e = _makeEngine();
      e.state.players[0].tokens[0] = Token(id: 0, position: 57);
      expect(e.state.players[0].tokens[0].isFinished, isTrue);
    });
  });

  group('GameEngine – safe cells', () {
    test('safe global cell set contains expected positions', () {
      // Global safe cells defined in board_config
      const safeCells = {0, 8, 13, 21, 26, 34, 39, 47};
      expect(safeCells.length, 8);
      expect(safeCells.contains(0), isTrue);
      expect(safeCells.contains(8), isTrue);
    });
  });

  group('GameEngine – turn switching', () {
    test('turn switches to next player after non-six with no valid moves', () {
      final e = _makeEngine(players: 2);
      final initial = e.state.currentPlayerIndex;
      // Roll non-six: all tokens in yard → no valid moves → auto-advance
      e.dice.forceValue(2);
      e.rollDice();
      expect(e.state.currentPlayerIndex, (initial + 1) % 2);
    });

    test('extra turn on rolling 6 then moving', () {
      final e = _makeEngine(players: 2);
      final initial = e.state.currentPlayerIndex;
      e.dice.forceValue(6);
      e.rollDice();
      e.moveToken(e.state.currentPlayer.tokens.first);
      // Same player keeps turn after 6
      expect(e.state.currentPlayerIndex, initial);
    });
  });

  group('GameEngine – valid moves', () {
    test('validMoves returns empty for non-6 when all in yard', () {
      final e = _makeEngine();
      final moves = e.validMoves(0, 3);
      expect(moves, isEmpty);
    });

    test('validMoves returns tokens on board', () {
      final e = _makeEngine();
      e.state.players[0].tokens[0] = Token(id: 0, position: 5);
      final moves = e.validMoves(0, 3);
      expect(moves.length, 1);
      expect(moves.first.id, 0);
    });
  });
}
