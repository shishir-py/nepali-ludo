import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/audio_manager.dart';
import '../storage/game_storage.dart';
import '../storage/settings_storage.dart';
import 'ai/ai_engine.dart';
import 'engine/game_engine.dart';
import 'engine/game_event.dart';
import 'engine/game_state.dart';
import 'engine/player.dart';
import 'engine/token.dart';

/// ChangeNotifier that owns the GameEngine and drives the UI.
///
/// Moves are animated: before the engine applies a move, the token is
/// walked cell-by-cell through [positionOverrides] so the board can hop it
/// along the track, with a sound on every step.
class GameProvider extends ChangeNotifier {
  GameEngine? _engine;
  final AiEngine _ai = AiEngine();
  StreamSubscription<GameEvent>? _sub;
  AppSettings _settings = const AppSettings();

  /// Delay between hops when a pawn walks along the track.
  static const Duration hopDelay = Duration(milliseconds: 190);

  // Latest event for announcements / reactions
  GameEvent? lastEvent;

  // Board UI state
  bool _isDiceRolling = false;
  bool get isDiceRolling => _isDiceRolling;

  bool _isTokenMoving = false;
  bool get isTokenMoving => _isTokenMoving;

  bool _aiBusy = false;

  String? _announcement;
  String? get announcement => _announcement;
  Timer? _announcementTimer;

  final Map<String, int> _positionOverrides = {};

  /// Positions to display while a move is being animated,
  /// keyed by `'$playerIndex:$tokenId'`.
  Map<String, int> get positionOverrides =>
      Map.unmodifiable(_positionOverrides);

  // ─────────────────────────────────────────────────────────────

  GameEngine? get engine => _engine;
  GameState? get state => _engine?.state;
  bool get hasGame => _engine != null;

  /// Tokens of the current player that the human may tap right now.
  Set<int> get movableTokenIds {
    final s = state;
    if (s == null ||
        !s.diceRolled ||
        currentPlayerIsAi ||
        _isTokenMoving ||
        s.phase == GamePhase.finished) {
      return const {};
    }
    return s.currentPlayer
        .moveableTokens(s.lastDiceValue)
        .map((t) => t.id)
        .toSet();
  }

  // ─────────────────────────────────────────────────────────────
  // Initialisation
  // ─────────────────────────────────────────────────────────────

  Future<void> init(AppSettings settings) async {
    _settings = settings;
  }

  void startNewGame({
    required List<Player> players,
  }) {
    _sub?.cancel();
    _engine?.dispose();
    _positionOverrides.clear();
    _isTokenMoving = false;
    _isDiceRolling = false;

    final state = GameState(players: players);
    _engine = GameEngine(state: state);
    _sub = _engine!.events.listen(_onEvent);

    notifyListeners();
    _scheduleAiMoveIfNeeded();
  }

  Future<void> loadSavedGame() async {
    final engine = await GameStorage.loadSavedGame();
    if (engine == null) return;
    _sub?.cancel();
    _engine?.dispose();
    _positionOverrides.clear();
    _engine = engine;
    _sub = _engine!.events.listen(_onEvent);
    notifyListeners();
    _scheduleAiMoveIfNeeded();
  }

  // ─────────────────────────────────────────────────────────────
  // Player actions
  // ─────────────────────────────────────────────────────────────

  Future<void> rollDice() async {
    if (_engine == null) return;
    if (state!.diceRolled || _isDiceRolling || _isTokenMoving) return;
    if (currentPlayerIsAi) return; // AI rolls itself

    _isDiceRolling = true;
    notifyListeners();

    unawaited(AudioManager().playDiceRoll());
    await Future.delayed(const Duration(milliseconds: 750));
    if (_engine == null) return;

    _engine!.rollDice();

    _isDiceRolling = false;
    notifyListeners();

    // Auto-move when there is effectively only one choice
    // (e.g. one movable token, or several identical tokens in the yard).
    final s = state!;
    if (s.diceRolled && !currentPlayerIsAi) {
      final options = s.currentPlayer.moveableTokens(s.lastDiceValue);
      final distinct = options.map((t) => t.position).toSet();
      if (options.isNotEmpty && distinct.length == 1) {
        await Future.delayed(const Duration(milliseconds: 380));
        if (_engine != null && state!.diceRolled && !_isTokenMoving) {
          await moveToken(options.first);
          return;
        }
      }
    }

    _scheduleAiMoveIfNeeded();
  }

  Future<void> moveToken(Token token) async {
    if (_engine == null) return;
    if (!state!.diceRolled || _isTokenMoving) return;
    if (currentPlayerIsAi) return;
    if (!token.canMove(state!.lastDiceValue)) return;

    await _animateAndMove(state!.currentPlayerIndex, token);

    await _persistGame();
    _scheduleAiMoveIfNeeded();
  }

  /// Walk [token] cell by cell, then let the engine apply the move
  /// (captures, extra turns, wins, …).
  Future<void> _animateAndMove(int playerIndex, Token token) async {
    _isTokenMoving = true;
    final key = '$playerIndex:${token.id}';
    final dice = state!.lastDiceValue;
    final from = token.position;

    final steps = <int>[];
    if (from == -1) {
      steps.add(0);
    } else {
      for (var i = 1; i <= dice; i++) {
        steps.add(math.min(from + i, 57));
      }
    }

    for (final pos in steps) {
      _positionOverrides[key] = pos;
      notifyListeners();
      unawaited(from == -1
          ? AudioManager().playTokenEnter()
          : AudioManager().playTokenMove());
      if (_settings.vibrationEnabled) HapticFeedback.selectionClick();
      await Future.delayed(hopDelay);
      if (_engine == null) return;
    }

    _positionOverrides.remove(key);
    _engine!.moveToken(playerIndex, token);
    _isTokenMoving = false;
    notifyListeners();
    // Give capture / finish animations a moment before the next turn.
    await Future.delayed(const Duration(milliseconds: 250));
  }

  // ─────────────────────────────────────────────────────────────
  // AI
  // ─────────────────────────────────────────────────────────────

  bool get currentPlayerIsAi =>
      state != null && state!.currentPlayer.type == PlayerType.ai;

  void _scheduleAiMoveIfNeeded() {
    if (_aiBusy || !currentPlayerIsAi) return;
    if (state!.phase == GamePhase.finished) return;
    _aiBusy = true;
    Future.delayed(const Duration(milliseconds: 800), () async {
      try {
        await _doAiTurn();
      } finally {
        _aiBusy = false;
      }
      _scheduleAiMoveIfNeeded();
    });
  }

  Future<void> _doAiTurn() async {
    if (_engine == null) return;
    if (!currentPlayerIsAi || state!.phase == GamePhase.finished) return;
    final aiIndex = state!.currentPlayerIndex;

    // Roll dice (unless a restored game already has this turn's roll).
    final int value;
    if (state!.diceRolled) {
      value = state!.lastDiceValue;
    } else {
      _isDiceRolling = true;
      notifyListeners();
      unawaited(AudioManager().playDiceRoll());
      await Future.delayed(const Duration(milliseconds: 750));
      if (_engine == null) return;
      value = _engine!.rollDice();
      _isDiceRolling = false;
      notifyListeners();
    }

    // If the roll forfeited the turn or had no moves, the engine has
    // already moved on.
    if (state!.currentPlayerIndex != aiIndex || !state!.diceRolled) {
      await _persistGame();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 550));
    if (_engine == null) return;

    final token = _ai.chooseMove(_engine!, aiIndex, value);
    if (token != null) {
      await _animateAndMove(aiIndex, token);
    }

    await _persistGame();
  }

  // ─────────────────────────────────────────────────────────────
  // Events
  // ─────────────────────────────────────────────────────────────

  void _onEvent(GameEvent event) {
    lastEvent = event;
    _showAnnouncement(event.message);

    switch (event.type) {
      case GameEventType.tokenCaptured:
        AudioManager().playKill();
        if (_settings.vibrationEnabled) HapticFeedback.heavyImpact();
        break;
      case GameEventType.landedOnSafe:
        AudioManager().playSafe();
        if (_settings.vibrationEnabled) HapticFeedback.lightImpact();
        break;
      case GameEventType.sixRolled:
        AudioManager().playSix();
        break;
      case GameEventType.playerWon:
        AudioManager().playWin();
        if (_settings.vibrationEnabled) HapticFeedback.heavyImpact();
        break;
      case GameEventType.tokenFinished:
        // Only when a pawn actually reaches the centre, not when it merely
        // turns into its home column.
        AudioManager().playTokenHome();
        break;
      case GameEventType.noValidMove:
        _showAnnouncement('😅 चाल छैन — अर्को पालो');
        break;
      default:
        break;
    }

    notifyListeners();
  }

  void _showAnnouncement(String? message) {
    if (message == null) return;
    _announcement = message;
    notifyListeners();
    _announcementTimer?.cancel();
    _announcementTimer = Timer(const Duration(milliseconds: 1800), () {
      _announcement = null;
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Persistence
  // ─────────────────────────────────────────────────────────────

  Future<void> _persistGame() async {
    if (_engine == null) return;
    if (state!.isOver) {
      await GameStorage.clearSavedGame();
    } else {
      await GameStorage.saveGame(_engine!);
    }
  }

  Future<void> quitGame() async {
    await _persistGame();
    _sub?.cancel();
    _engine?.dispose();
    _engine = null;
    _positionOverrides.clear();
    _isTokenMoving = false;
    _isDiceRolling = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _announcementTimer?.cancel();
    _sub?.cancel();
    _engine?.dispose();
    super.dispose();
  }
}
