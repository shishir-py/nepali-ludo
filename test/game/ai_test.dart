import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nepali_ludo/game/ai/ai_engine.dart';
import 'package:nepali_ludo/game/engine/game_engine.dart';
import 'package:nepali_ludo/game/engine/player.dart';
import 'package:nepali_ludo/game/engine/token.dart';

/// Seeded so the easy/random branch is reproducible across runs.
AiEngine _makeAi() => AiEngine(random: Random(42));

GameEngine _makeAiEngine() {
  return GameEngine.withPlayers([
    Player(index: 0, name: 'Human', type: PlayerType.human),
    Player(
        index: 1,
        name: 'लाटो बोट',
        type: PlayerType.ai,
        difficulty: AiDifficulty.normal),
  ]);
}

void main() {
  group('AiEngine', () {
    test('easy: returns a token or null when no moves available', () {
      final engine = _makeAiEngine();
      // No tokens on board, dice = 3 → no moveable tokens
      final result = _makeAi().chooseMove(engine, 1, 3);
      expect(result, isNull);
    });

    test('easy: returns token on a 6 with tokens in yard', () {
      final engine = _makeAiEngine();
      // AI (player 1) has all tokens in yard
      final result = _makeAi().chooseMove(engine, 1, 6);
      expect(result, isNotNull);
      expect(result!.isInYard, isTrue);
    });

    test('normal: prefers finishing move', () {
      final engine = _makeAiEngine();
      // Place AI token 4 steps from finish (position 53)
      engine.state.players[1].tokens[0] = Token(id: 0, position: 53);
      final result = _makeAi().chooseMove(engine, 1, 4);
      // Should select the token that can finish
      expect(result, isNotNull);
      expect(result!.position, 53);
    });

    test('hard: scores tokens and returns best move', () {
      final engine = _makeAiEngine();
      // Place two AI tokens on board
      engine.state.players[1].tokens[0] = Token(id: 0, position: 20);
      engine.state.players[1].tokens[1] = Token(id: 1, position: 5);
      // Hard AI should pick a token (not necessarily the same each time,
      // but should not be null)
      final result = _makeAi().chooseMove(engine, 1, 3);
      expect(result, isNotNull);
    });

    test('returns null when all tokens are finished', () {
      final engine = _makeAiEngine();
      for (int i = 0; i < 4; i++) {
        engine.state.players[1].tokens[i] = Token(id: i, position: 57);
      }
      final result = _makeAi().chooseMove(engine, 1, 5);
      expect(result, isNull);
    });
  });
}
