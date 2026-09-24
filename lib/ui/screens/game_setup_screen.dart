import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../game/engine/player.dart';
import '../../game/game_provider.dart';
import '../../l10n/strings.dart';
import 'game_screen.dart';

class GameSetupScreen extends StatefulWidget {
  final bool defaultVsAi;
  final bool defaultLocalMulti;

  const GameSetupScreen({
    super.key,
    this.defaultVsAi = false,
    this.defaultLocalMulti = false,
  });

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _playerCount = 2;
  final List<TextEditingController> _nameControllers =
      List.generate(4, (i) => TextEditingController());
  final List<PlayerType> _types = List.filled(4, PlayerType.human);
  final List<AiDifficulty> _difficulties = List.filled(4, AiDifficulty.normal);

  /// Colour seat chosen by each player slot. Always a permutation of
  /// 0-3 (red, green, yellow, blue) so two players never share a colour.
  final List<int> _colors = [0, 1, 2, 3];

  static const _colorNames = ['Red', 'Green', 'Yellow', 'Blue'];
  static const _defaultNames = ['Player 1', 'Player 2', 'Player 3', 'Player 4'];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 4; i++) {
      _nameControllers[i].text = _defaultNames[i];
    }
    if (widget.defaultVsAi) {
      _types[1] = PlayerType.ai;
      _nameControllers[1].text = 'Lato Bot';
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.gameSetup)),
      backgroundColor: NepaliColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(S.playerCount),
            _buildPlayerCountSelector(),
            const SizedBox(height: 24),
            _sectionTitle('Players'),
            ...List.generate(
              _playerCount,
              (i) => _buildPlayerCard(i),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                child: const Text(S.startGame, style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPlayerCountSelector() {
    return Row(
      children: [2, 3, 4].map((n) {
        final selected = _playerCount == n;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => _playerCount = n),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    selected ? NepaliColors.primary : NepaliColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      selected ? NepaliColors.primaryDark : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : NepaliColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerCard(int index) {
    final color = NepaliColors.playerColor(_colors[index]);
    final isAi = _types[index] == PlayerType.ai;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Player ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                _buildColorPicker(index),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameControllers[index],
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                labelText: S.playerName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                // A real icon, sized and centred by the input decorator.
                prefixIcon: Icon(
                  isAi ? Icons.smart_toy_rounded : Icons.person_rounded,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Human / AI toggle
            SegmentedButton<PlayerType>(
              segments: const [
                ButtonSegment(
                    value: PlayerType.human,
                    icon: Icon(Icons.person_rounded),
                    label: Text('Human')),
                ButtonSegment(
                    value: PlayerType.ai,
                    icon: Icon(Icons.smart_toy_rounded),
                    label: Text('AI')),
              ],
              selected: {_types[index]},
              onSelectionChanged: (s) {
                setState(() {
                  _types[index] = s.first;
                  if (s.first == PlayerType.ai &&
                      _nameControllers[index].text == _defaultNames[index]) {
                    _nameControllers[index].text = 'Lato Bot ${index + 1}';
                  }
                });
              },
            ),
            if (isAi) ...[
              const SizedBox(height: 10),
              _buildDifficultySelector(index),
            ],
          ],
        ),
      ),
    );
  }

  /// Four colour dots. Picking a colour another player already has swaps
  /// the two players' colours, so every player always has a unique colour.
  Widget _buildColorPicker(int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (c) {
        final selected = _colors[index] == c;
        final ownerSlot = _colors.indexOf(c);
        final takenByOther =
            !selected && ownerSlot >= 0 && ownerSlot < _playerCount;
        return Tooltip(
          message: _colorNames[c],
          child: GestureDetector(
            onTap: () => setState(() {
              final other = _colors.indexOf(c);
              _colors[other] = _colors[index];
              _colors[index] = c;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(left: 8),
              width: selected ? 34 : 28,
              height: selected ? 34 : 28,
              decoration: BoxDecoration(
                color: NepaliColors.playerColor(c)
                    .withValues(alpha: takenByOther ? 0.35 : 1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? NepaliColors.textPrimary : Colors.white,
                  width: selected ? 3 : 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: NepaliColors.playerColor(c)
                              .withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: Colors.white)
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDifficultySelector(int index) {
    return SegmentedButton<AiDifficulty>(
      segments: const [
        ButtonSegment(value: AiDifficulty.easy, label: Text('Easy')),
        ButtonSegment(value: AiDifficulty.normal, label: Text('Normal')),
        ButtonSegment(value: AiDifficulty.hard, label: Text('Hard')),
      ],
      selected: {_difficulties[index]},
      onSelectionChanged: (s) => setState(() => _difficulties[index] = s.first),
    );
  }

  void _startGame() {
    final players = List.generate(_playerCount, (i) {
      return Player(
        index: _colors[i], // board seat = chosen colour
        name: _nameControllers[i].text.trim().isEmpty
            ? _defaultNames[i]
            : _nameControllers[i].text.trim(),
        type: _types[i],
        difficulty: _difficulties[i],
      );
    })
      // Turn order goes clockwise around the board: red, green, yellow, blue.
      ..sort((a, b) => a.index.compareTo(b.index));

    final provider = context.read<GameProvider>();
    provider.startNewGame(players: players);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}
