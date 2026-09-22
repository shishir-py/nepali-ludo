import 'dart:math';
import '../engine/board_config.dart';
import '../engine/game_engine.dart';
import '../engine/player.dart';
import '../engine/token.dart';

/// AI decision engine for लाटो बोट (and all computer players).
///
/// Three difficulty levels:
///  Easy   — random valid move selection
///  Normal — basic strategy (prefer captures > home moves > advance)
///  Hard   — look-ahead with scoring of all possible moves
class AiEngine {
  final Random _random;

  AiEngine({Random? random}) : _random = random ?? Random();

  /// Choose the best token to move given the current engine state.
  /// Returns the chosen Token, or null if no valid move exists.
  Token? chooseMove(GameEngine engine, int playerIndex, int diceValue) {
    final moves = engine.validMoves(playerIndex, diceValue);
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;

    final player = engine.state.players[playerIndex];
    switch (player.difficulty) {
      case AiDifficulty.easy:
        return _easyChoice(moves);
      case AiDifficulty.normal:
        return _normalChoice(moves, engine, playerIndex, diceValue);
      case AiDifficulty.hard:
        return _hardChoice(moves, engine, playerIndex, diceValue);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Easy: random
  // ─────────────────────────────────────────────────────────────

  Token _easyChoice(List<Token> moves) {
    return moves[_random.nextInt(moves.length)];
  }

  // ─────────────────────────────────────────────────────────────
  // Normal: prioritised heuristics
  // ─────────────────────────────────────────────────────────────

  Token _normalChoice(
      List<Token> moves, GameEngine engine, int playerIndex, int diceValue) {
    // 1. Finishing a token is highest priority.
    final finishing = moves.where((t) => t.position + diceValue >= 57);
    if (finishing.isNotEmpty) return finishing.first;

    // 2. Bringing a token out of yard (dice = 6).
    if (diceValue == 6) {
      final inYard = moves.where((t) => t.isInYard);
      if (inYard.isNotEmpty) return inYard.first;
    }

    // 3. Capture an opponent token.
    final capturing =
        moves.where((t) => _wouldCapture(engine, playerIndex, t, diceValue));
    if (capturing.isNotEmpty) return capturing.first;

    // 4. Move the token closest to home.
    moves.sort((a, b) => b.position.compareTo(a.position));
    return moves.first;
  }

  // ─────────────────────────────────────────────────────────────
  // Hard: scored evaluation
  // ─────────────────────────────────────────────────────────────

  Token _hardChoice(
      List<Token> moves, GameEngine engine, int playerIndex, int diceValue) {
    Token? best;
    double bestScore = double.negativeInfinity;

    for (final token in moves) {
      final score = _score(engine, playerIndex, token, diceValue);
      if (score > bestScore) {
        bestScore = score;
        best = token;
      }
    }
    return best ?? moves.first;
  }

  double _score(
      GameEngine engine, int playerIndex, Token token, int diceValue) {
    double score = 0;
    final newPos = token.isInYard ? 0 : token.position + diceValue;

    // Finishing a token: maximum value.
    if (newPos >= 57) return 1000;

    // Entering home column.
    if (newPos >= 52) score += 50;

    // Bringing token out of yard.
    if (token.isInYard) score += 30;

    // Capture opponent.
    if (_wouldCapture(engine, playerIndex, token, diceValue)) score += 80;

    // Avoid being captured at new position.
    if (_isInDanger(engine, playerIndex, newPos)) score -= 40;

    // Prefer safe cells.
    if (newPos <= 51) {
      final globalNew = BoardConfig.localToGlobal(playerIndex, newPos);
      if (BoardConfig.isGlobalSafe(globalNew)) score += 20;
    }

    // Advance tokens in home column.
    if (newPos >= 52 && newPos < 57) score += (newPos - 52) * 5.0;

    // General advancement preference.
    score += newPos * 0.5;

    return score;
  }

  bool _wouldCapture(
      GameEngine engine, int playerIndex, Token token, int diceValue) {
    final newPos = token.isInYard ? 0 : token.position + diceValue;
    if (newPos < 0 || newPos > 51) return false;

    final globalNew = BoardConfig.localToGlobal(playerIndex, newPos);
    if (BoardConfig.isGlobalSafe(globalNew)) return false;

    for (int pi = 0; pi < engine.state.players.length; pi++) {
      if (pi == playerIndex) continue;
      for (final t in engine.state.players[pi].tokens) {
        if (t.isInYard || t.isFinished || t.isInHomeColumn) continue;
        final opGlobal = BoardConfig.localToGlobal(pi, t.position);
        if (opGlobal == globalNew) return true;
      }
    }
    return false;
  }

  bool _isInDanger(GameEngine engine, int playerIndex, int localPos) {
    if (localPos < 0 || localPos > 51) return false;
    final globalPos = BoardConfig.localToGlobal(playerIndex, localPos);
    if (BoardConfig.isGlobalSafe(globalPos)) return false;

    for (int pi = 0; pi < engine.state.players.length; pi++) {
      if (pi == playerIndex) continue;
      for (final t in engine.state.players[pi].tokens) {
        if (t.isInYard || t.isFinished || t.isInHomeColumn) continue;
        // Opponent could roll 1-6 and land on our new position.
        for (int dice = 1; dice <= 6; dice++) {
          final opponentNext = t.position + dice;
          if (opponentNext <= 51) {
            final opGlobal = BoardConfig.localToGlobal(pi, opponentNext);
            if (opGlobal == globalPos) return true;
          }
        }
      }
    }
    return false;
  }
}
