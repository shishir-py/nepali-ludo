import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../game/engine/game_state.dart';
import '../../game/engine/player.dart';
import '../../game/game_provider.dart';
import '../../l10n/strings.dart';
import '../../storage/settings_storage.dart';
import '../board/board_view.dart';
import '../widgets/dice_widget.dart';
import '../widgets/nepali_background.dart';
import '../widgets/reaction_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _activeReaction;
  int? _reactionPlayer;
  bool _tilted = false; // flat 2D board by default
  bool _winShown = false;
  bool _soundOn = AudioManager.instance.soundEnabled;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        if (!game.hasGame) {
          return const Scaffold(
            backgroundColor: Color(0xFF14040A),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final state = game.state!;

        if (state.phase == GamePhase.finished && !_winShown) {
          _winShown = true;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showWinDialog(context, state));
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) _confirmQuit(context, game);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF14040A),
            body: NepaliBackground(
              child: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildTopBar(context, state, game),
                        _buildPlayersRow(state, game, [0, 1]),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: BoardView(
                              players: state.players,
                              currentPlayerIndex: state.currentPlayer.index,
                              movableTokenIds: game.movableTokenIds,
                              positionOverrides: game.positionOverrides,
                              tilted: _tilted,
                              onTokenTap: (t) => game.moveToken(t),
                            ),
                          ),
                        ),
                        if (state.players.any((p) => p.index >= 2))
                          _buildPlayersRow(state, game, [3, 2]),
                        _buildControlBar(context, state, game),
                      ],
                    ),
                    if (game.announcement != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: _buildAnnouncement(game.announcement!),
                          ),
                        ),
                      ),
                    if (_activeReaction != null)
                      Positioned(
                        top: 110,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: ReactionBubble(
                            text: _activeReaction!,
                            isRight:
                                _reactionPlayer == 1 || _reactionPlayer == 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────

  Widget _buildTopBar(
      BuildContext context, GameState state, GameProvider game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 6, 2),
      child: Row(
        children: [
          _roundIcon(Icons.arrow_back_rounded, () => _confirmQuit(context, game),
              tooltip: S.back),
          const Spacer(),
          _roundIcon(
            _tilted ? Icons.grid_view_rounded : Icons.view_in_ar_rounded,
            () => setState(() => _tilted = !_tilted),
            tooltip: _tilted ? '2D view' : '3D view',
          ),
          const SizedBox(width: 8),
          _roundIcon(
            _soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            _toggleSound,
            tooltip: 'Sound',
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap, {String? tooltip}) {
    final button = InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: NepaliColors.gold.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Future<void> _toggleSound() async {
    final on = !_soundOn;
    setState(() => _soundOn = on);
    AudioManager.instance.setSoundEnabled(on);
    AudioManager.instance.setMusicEnabled(on);
    final s = await SettingsStorage.load();
    await SettingsStorage.save(s.copyWith(soundEnabled: on, musicEnabled: on));
  }

  // ─── Player cards ────────────────────────────────────────────────────

  /// A row of player cards for the given colour seats, placed next to
  /// their yards (red/green on top, blue/yellow at the bottom).
  Widget _buildPlayersRow(
      GameState state, GameProvider game, List<int> seats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: seats.map((seat) {
          final i = state.players.indexWhere((p) => p.index == seat);
          if (i < 0) return const Expanded(child: SizedBox());
          return Expanded(child: _buildPlayerCard(state, game, i));
        }).toList(),
      ),
    );
  }

  Widget _buildPlayerCard(GameState state, GameProvider game, int i) {
    final player = state.players[i];
    final isCurrent = state.currentPlayerIndex == i;
    final color = NepaliColors.playerColor(player.index);
    final finished = player.tokens.where((t) => t.isFinished).length;
    final isAi = player.type == PlayerType.ai;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: isCurrent ? 0.16 : 0.07),
            Colors.white.withValues(alpha: isCurrent ? 0.06 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? color : Colors.white.withValues(alpha: 0.12),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 18)]
            : const [],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [Color.lerp(color, Colors.white, 0.35)!, color],
              ),
              border: Border.all(color: NepaliColors.goldLight, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              isAi ? '🤖' : (player.name.isEmpty ? '?' : player.name.characters.first),
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: List.generate(
                    4,
                    (k) => Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: k < finished
                            ? color
                            : Colors.white.withValues(alpha: 0.12),
                        border: Border.all(
                            color: color.withValues(alpha: 0.8), width: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (player.hasWon)
            const Text('🏆', style: TextStyle(fontSize: 18))
          else if (isCurrent && isAi)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: NepaliColors.goldLight),
            )
          else if (isCurrent)
            const Text('👈', style: TextStyle(fontSize: 16))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: 0, end: -4, duration: 450.ms),
        ],
      ),
    );
  }

  // ─── Control bar ─────────────────────────────────────────────────────

  Widget _buildControlBar(
      BuildContext context, GameState state, GameProvider game) {
    final isAi = game.currentPlayerIsAi;
    final canRoll = !isAi &&
        !state.diceRolled &&
        !game.isDiceRolling &&
        !game.isTokenMoving &&
        state.phase != GamePhase.finished;
    final color = NepaliColors.playerColor(state.currentPlayer.index);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          _roundIcon(Icons.emoji_emotions_outlined,
              () => _showReactions(context, state),
              tooltip: S.react),
          Expanded(
            child: Center(
              // No instruction text: the glowing dice and bobbing pawns
              // already show what to do next.
              child: DiceWidget(
                value: state.lastDiceValue == 0 ? 1 : state.lastDiceValue,
                isRolling: game.isDiceRolling,
                canRoll: canRoll,
                onRoll: game.rollDice,
                size: 66,
              ),
            ),
          ),
          _roundIcon(Icons.info_outline_rounded,
              () => _showGameInfo(context, state),
              tooltip: 'Game info'),
        ],
      ),
    );
  }

  // ─── Announcement ────────────────────────────────────────────────────

  Widget _buildAnnouncement(String message) {
    return KeyedSubtree(
      key: ValueKey(message),
      child: _announcementCard(message),
    );
  }

  Widget _announcementCard(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8394A), Color(0xFF8C0D1A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NepaliColors.goldLight, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
    )
        .animate()
        .scale(
            begin: const Offset(0.4, 0.4),
            end: const Offset(1, 1),
            duration: 350.ms,
            curve: Curves.elasticOut)
        .fadeIn(duration: 150.ms)
        .then(delay: 1100.ms)
        .fadeOut(duration: 300.ms);
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────

  void _showWinDialog(BuildContext context, GameState state) {
    final winner = state.players[state.winnerIndex ?? 0];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6A1020), Color(0xFF2A0710)],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: NepaliColors.goldLight, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64))
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 6),
              const Text('Congratulations!',
                  style: TextStyle(
                      color: NepaliColors.goldLight,
                      fontSize: 30,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                '${winner.name} wins!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700),
              ),
              if (state.finishedOrder.length > 1) ...[
                const SizedBox(height: 14),
                ...state.finishedOrder.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${['🥇', '🥈', '🥉', '4.'][e.key < 3 ? e.key : 3]}  ${state.players[e.value].name}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )),
              ],
              const SizedBox(height: 20),
              GlossyButton(
                label: S.playAgain,
                emoji: '🔁',
                height: 52,
                onTap: () {
                  Navigator.pop(ctx);
                  _winShown = false;
                  context.read<GameProvider>().startNewGame(
                        players: state.players
                            .map((p) => Player(
                                  index: p.index,
                                  name: p.name,
                                  type: p.type,
                                  difficulty: p.difficulty,
                                ))
                            .toList(),
                      );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text(S.quitGame,
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmQuit(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave the game?'),
        content: const Text('Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(S.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await game.quitGame();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(S.quitGame),
          ),
        ],
      ),
    );
  }

  void _showGameInfo(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Game info',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...state.players.map((p) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: NepaliColors.playerColor(p.index),
                    child: Text(
                        '${p.finishOrder > 0 ? "🏆" : p.tokens.where((t) => t.isFinished).length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                      '${p.tokens.where((t) => t.isActive).length} on board • ${p.tokens.where((t) => t.isInYard).length} in yard'),
                  trailing: p.hasWon
                      ? Text('#${p.finishOrder}',
                          style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                )),
            const SizedBox(height: 8),
            const Text(
              'Tip: tap a glowing token to move it. The cube button at the top switches between 2D and 3D.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactions(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReactionPanel(
        onReact: (reaction) {
          AudioManager().playReaction();
          setState(() {
            _activeReaction = reaction;
            _reactionPlayer = state.currentPlayer.index;
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _activeReaction = null);
          });
        },
      ),
    );
  }
}
