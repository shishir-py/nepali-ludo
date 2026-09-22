import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/engine/game_engine.dart';
import '../game/engine/game_state.dart';
import '../game/engine/player.dart';
import '../game/engine/token.dart';

/// Persists and restores game state using SharedPreferences (JSON).
class GameStorage {
  static const _gameKey = 'saved_game';
  static const _statsKey = 'player_stats';

  // ─────────────────────────────────────────────────────────────
  // Game state
  // ─────────────────────────────────────────────────────────────

  static Future<void> saveGame(GameEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(engine.toJson());
    await prefs.setString(_gameKey, json);
  }

  static Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameKey);
  }

  static Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_gameKey);
  }

  static Future<GameEngine?> loadSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gameKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final players = (map['players'] as List).map((p) {
        final tokens = (p['tokens'] as List)
            .map((t) => Token(id: t['id'] as int, position: t['position'] as int))
            .toList();
        return Player(
          index: p['index'] as int,
          name: p['name'] as String,
          type: PlayerType.values.byName(p['type'] as String),
          difficulty: AiDifficulty.values.byName(p['difficulty'] as String),
          tokens: tokens,
          hasWon: p['hasWon'] as bool,
          finishOrder: p['finishOrder'] as int,
        );
      }).toList();

      final state = GameState(
        players: players,
        currentPlayerIndex: map['currentPlayerIndex'] as int,
        lastDiceValue: map['lastDiceValue'] as int,
        diceRolled: map['diceRolled'] as bool,
        phase: GamePhase.values.byName(map['phase'] as String),
        winnerIndex: map['winnerIndex'] as int?,
        finishedOrder: List<int>.from(map['finishedOrder'] as List),
        consecutiveSixes: map['consecutiveSixes'] as int,
        startedAt: DateTime.parse(map['startedAt'] as String),
      );

      return GameEngine(state: state);
    } catch (e) {
      await clearSavedGame();
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Statistics
  // ─────────────────────────────────────────────────────────────

  static Future<PlayerStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey);
    if (raw == null) return PlayerStats();
    try {
      return PlayerStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerStats();
    }
  }

  static Future<void> saveStats(PlayerStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }
}

class PlayerStats {
  int gamesPlayed;
  int gamesWon;
  int gamesLost;
  int tokensCaptured;
  int sixesRolled;
  int vsAiGames;
  int vsHumanGames;
  int currentStreak;
  int bestStreak;

  PlayerStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.tokensCaptured = 0,
    this.sixesRolled = 0,
    this.vsAiGames = 0,
    this.vsHumanGames = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  double get winRate => gamesPlayed == 0 ? 0 : gamesWon / gamesPlayed;

  void recordWin({bool vsAi = false}) {
    gamesPlayed++;
    gamesWon++;
    currentStreak++;
    if (currentStreak > bestStreak) bestStreak = currentStreak;
    if (vsAi) vsAiGames++; else vsHumanGames++;
  }

  void recordLoss({bool vsAi = false}) {
    gamesPlayed++;
    gamesLost++;
    currentStreak = 0;
    if (vsAi) vsAiGames++; else vsHumanGames++;
  }

  Map<String, dynamic> toJson() => {
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
    'gamesLost': gamesLost,
    'tokensCaptured': tokensCaptured,
    'sixesRolled': sixesRolled,
    'vsAiGames': vsAiGames,
    'vsHumanGames': vsHumanGames,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    gamesPlayed: json['gamesPlayed'] ?? 0,
    gamesWon: json['gamesWon'] ?? 0,
    gamesLost: json['gamesLost'] ?? 0,
    tokensCaptured: json['tokensCaptured'] ?? 0,
    sixesRolled: json['sixesRolled'] ?? 0,
    vsAiGames: json['vsAiGames'] ?? 0,
    vsHumanGames: json['vsHumanGames'] ?? 0,
    currentStreak: json['currentStreak'] ?? 0,
    bestStreak: json['bestStreak'] ?? 0,
  );
}
