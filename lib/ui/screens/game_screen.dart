import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../game/engine/game_state.dart';
import '../../game/engine/player.dart';
import '../../game/engine/token.dart';
import '../../game/game_provider.dart';
import '../../l10n/strings.dart';
import '../painters/board_painter.dart';
import '../widgets/dice_widget.dart';
import '../widgets/reaction_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _activeReaction;
  int? _reactionPlayer;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        if (!game.hasGame) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final state = game.state!;

        if (state.phase == GamePhase.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _showWinDialog(context, state));
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) _confirmQuit(context, game);
          },
          child: Scaffold(
            backgroundColor: NepaliColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, state, game),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildGameLayout(context, state, game),
                    ),
                  ),
                  if (game.announcement != null)
                    _buildAnnouncement(game.announcement!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Layout
  // ─────────────────────────────────────────────────────────────

  Widget _buildGameLayout(
      BuildContext context, GameState state, GameProvider game) {
    return Column(
      children: [
        // Top players row (player 1 + player 2 if 4-player)
        _buildPlayersRow(state, game, [0, 1]),
        const SizedBox(height: 8),
        // Board (main area)
        Expanded(child: _buildBoard(context, state, game)),
        const SizedBox(height: 8),
        // Bottom players row
        if (state.players.length > 2)
          _buildPlayersRow(state, game, [3, 2]),
        const SizedBox(height: 8),
        _buildControlBar(context, state, game),
      ],
    );
  }

  Widget _buildPlayersRow(
      GameState state, GameProvider game, List<int> indices) {
    return Row(
      children: indices.map((i) {
        if (i >= state.players.length) return const Expanded(child: SizedBox());
        return Expanded(child: _buildPlayerInfo(state, game, i));
      }).toList(),
    );
  }

  Widget _buildPlayerInfo(GameState state, GameProvider game, int i) {
    final player = state.players[i];
    final isCurrent = state.currentPlayerIndex == i;
    final color = NepaliColors.playerColor(i);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: Text(
              player.type == PlayerType.ai ? '🤖' : player.name[0],
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                    color: isCurrent ? color : NepaliColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${player.tokens.where((t) => t.isFinished).length}/4 घर',
                  style: TextStyle(
                    fontSize: 11,
                    color: NepaliColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent && !state.diceRolled && !game.currentPlayerIsAi)
            const Text('👉', style: TextStyle(fontSize: 16)),
          if (player.hasWon)
            Text('🏆', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Board
  // ─────────────────────────────────────────────────────────────

  Widget _buildBoard(
      BuildContext context, GameState state, GameProvider game) {
    final currentPlayer = state.currentPlayer;
    final highlightable = state.diceRolled && !game.currentPlayerIsAi
        ? currentPlayer.moveableTokens(state.lastDiceValue)
        : <Token>[];
    final highlightedIds = highlightable.map((t) => t.id).toSet();

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTapUp: (details) => _handleBoardTap(details, context, state, game),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: BoardPainter(
              players: state.players,
              highlightedTokenIds: highlightedIds,
              currentPlayerIndex: state.currentPlayerIndex,
            ),
          ),
        ),
      ),
    );
  }

  void _handleBoardTap(
      TapUpDetails details,
      BuildContext context,
      GameState state,
      GameProvider game) {
    if (!state.diceRolled || game.currentPlayerIsAi || game.isTokenMoving) {
      return;
    }

    // Find which token was tapped based on board cell position.
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final boardSize = renderBox.size;
    // Account for the Row/Expanded layout — find actual board bounds.
    // We'll use a simpler approach: check all highlightable tokens.
    final moveable = state.currentPlayer.moveableTokens(state.lastDiceValue);
    if (moveable.isEmpty) return;

    // If only one token can move, auto-select it.
    if (moveable.length == 1) {
      game.moveToken(moveable.first);
      return;
    }

    // Show a dialog for token selection.
    _showTokenSelectionDialog(context, moveable, game, state);
  }

  void _showTokenSelectionDialog(
      BuildContext context, List<Token> tokens, GameProvider game, GameState state) {
    final color = NepaliColors.playerColor(state.currentPlayerIndex);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('कुन token सार्नुहुन्छ?',
            style: TextStyle(color: color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tokens.map((t) {
            final posLabel = t.isInYard
                ? 'घर (बाहिर निस्कनुस्)'
                : t.isInHomeColumn
                    ? 'घर स्तम्भ ${t.position - 51}'
                    : 'स्थिति ${t.position}';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Text('${t.id + 1}',
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text('Token ${t.id + 1}'),
              subtitle: Text(posLabel),
              onTap: () {
                Navigator.pop(ctx);
                game.moveToken(t);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Control bar (dice + reaction)
  // ─────────────────────────────────────────────────────────────

  Widget _buildControlBar(
      BuildContext context, GameState state, GameProvider game) {
    final isMyTurn = !game.currentPlayerIsAi;
    final canRoll = isMyTurn && !state.diceRolled && !game.isDiceRolling;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: NepaliColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Turn indicator
          Expanded(
            child: Text(
              game.currentPlayerIsAi
                  ? S.botTurn
                  : state.diceRolled
                      ? 'Token सार्नुहोस्!'
                      : S.yourTurn,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: NepaliColors.playerColor(state.currentPlayerIndex),
              ),
            ),
          ),

          // Reaction button
          IconButton(
            icon: const Text('😊', style: TextStyle(fontSize: 24)),
            tooltip: S.react,
            onPressed: () => _showReactions(context, state),
          ),

          const SizedBox(width: 8),

          // Dice
          GestureDetector(
            onTap: canRoll ? () => game.rollDice() : null,
            child: DiceWidget(
              value: state.lastDiceValue == 0 ? 1 : state.lastDiceValue,
              isRolling: game.isDiceRolling,
              canRoll: canRoll,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Top bar
  // ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(
      BuildContext context, GameState state, GameProvider game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: NepaliColors.primary,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _confirmQuit(context, game),
          ),
          Expanded(
            child: Text(
              S.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showGameInfo(context, state),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Announcement overlay
  // ─────────────────────────────────────────────────────────────

  Widget _buildAnnouncement(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: NepaliColors.primaryDark.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.85, 0.85));
  }

  // ─────────────────────────────────────────────────────────────
  // Dialogs
  // ─────────────────────────────────────────────────────────────

  void _showWinDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🏆 बधाई छ!', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${state.players[state.winnerIndex ?? 0].name}\nले खेल जितिसके!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (state.finishedOrder.length > 1) ...[
              const Text('क्रम:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...state.finishedOrder.asMap().entries.map((e) => Text(
                    '${e.key + 1}. ${state.players[e.value].name}',
                    style: const TextStyle(fontSize: 16),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // back to home
            },
            child: Text(S.quitGame),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Restart with same players
              final provider = context.read<GameProvider>();
              provider.startNewGame(
                players: state.players.map((p) => p.copyWith(
                  tokens: null, hasWon: false, finishOrder: 0,
                )).toList(),
              );
            },
            child: Text(S.playAgain),
          ),
        ],
      ),
    );
  }

  void _confirmQuit(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('खेल छोड्ने?'),
        content: const Text('तपाईंको प्रगति बचत गरिनेछ।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await game.quitGame();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(S.quitGame),
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
            Text('खेलको जानकारी',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...state.players.map((p) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: NepaliColors.playerColor(p.index),
                    child: Text('${p.finishOrder > 0 ? "🏆" : p.tokens.where((t) => t.isFinished).length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                      '${p.tokens.where((t) => t.isActive).length} सक्रिय • ${p.tokens.where((t) => t.isInYard).length} घरमा'),
                  trailing: p.hasWon
                      ? Text('क्रम ${p.finishOrder}',
                          style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                )),
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
          setState(() {
            _activeReaction = reaction;
            _reactionPlayer = state.currentPlayerIndex;
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _activeReaction = null);
          });
        },
      ),
    );
  }
}
