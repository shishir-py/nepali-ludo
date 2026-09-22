import 'dart:async';
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
class GameProvider extends ChangeNotifier {
  GameEngine? _engine;
  final AiEngine _ai = AiEngine();
  StreamSubscription<GameEvent>? _sub;
  AppSettings _settings = const AppSettings();

  // Latest event for announcements / reactions
  GameEvent? lastEvent;

  // Board UI state
  bool _isDiceRolling = false;
  bool get isDiceRolling => _isDiceRolling;

  bool _isTokenMoving = false;
  bool get isTokenMoving => _isTokenMoving;

  String? _announcement;
  String? get announcement => _announcement;

  // ─────────────────────────────────────────────────────────────

  GameEngine? get engine => _engine;
  GameState? get state => _engine?.state;
  bool get hasGame => _engine != null;

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
    if (state!.diceRolled) return;
    if (currentPlayerIsAi) return; // AI rolls itself

    _isDiceRolling = true;
    notifyListeners();

    await AudioManager().playDiceRoll();
    await Future.delayed(const Duration(milliseconds: 600));

    _engine!.rollDice();

    _isDiceRolling = false;
    notifyListeners();

    _scheduleAiMoveIfNeeded();
  }

  Future<void> moveToken(Token token) async {
    if (_engine == null) return;
    if (!state!.diceRolled) return;
    if (currentPlayerIsAi) return;

    _isTokenMoving = true;
    notifyListeners();

    _engine!.moveToken(state!.currentPlayerIndex, token);

    await AudioManager().playTokenMove();
    if (_settings.vibrationEnabled) {
      HapticFeedback.lightImpact();
    }

    await Future.delayed(const Duration(milliseconds: 400));
    _isTokenMoving = false;
    notifyListeners();

    await _persistGame();
    _scheduleAiMoveIfNeeded();
  }

  // ─────────────────────────────────────────────────────────────
  // AI
  // ─────────────────────────────────────────────────────────────

  bool get currentPlayerIsAi =>
      state != null && state!.currentPlayer.type == PlayerType.ai;

  void _scheduleAiMoveIfNeeded() {
    if (!currentPlayerIsAi) return;
    Future.delayed(const Duration(milliseconds: 900), _doAiTurn);
  }

  Future<void> _doAiTurn() async {
    if (_engine == null) return;
    if (!currentPlayerIsAi) return;

    // Roll dice
    _isDiceRolling = true;
    notifyListeners();
    await AudioManager().playDiceRoll();
    await Future.delayed(const Duration(milliseconds: 700));
    final value = _engine!.rollDice();
    _isDiceRolling = false;
    notifyListeners();

    if (state!.consecutiveSixes >= 3) return; // forfeit handled by engine

    await Future.delayed(const Duration(milliseconds: 600));

    // Choose and execute move
    final token = _ai.chooseMove(_engine!, state!.currentPlayerIndex, value);
    if (token != null) {
      _isTokenMoving = true;
      notifyListeners();
      _engine!.moveToken(state!.currentPlayerIndex, token);
      await AudioManager().playTokenMove();
      await Future.delayed(const Duration(milliseconds: 500));
      _isTokenMoving = false;
      notifyListeners();
    }

    await _persistGame();
    _scheduleAiMoveIfNeeded();
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
        if (_settings.vibrationEnabled) HapticFeedback.mediumImpact();
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
        break;
      case GameEventType.tokenFinished:
        AudioManager().playTokenHome();
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
    Future.delayed(const Duration(seconds: 3), () {
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
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sub?.cancel();
    _engine?.dispose();
    super.dispose();
  }
}
