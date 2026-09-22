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

  static const _colorNames = ['रातो 🔴', 'हरियो 🟢', 'पहेँलो 🟡', 'नीलो 🔵'];
  static const _defaultNames = ['खेलाडी १', 'खेलाडी २', 'खेलाडी ३', 'खेलाडी ४'];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 4; i++) {
      _nameControllers[i].text = _defaultNames[i];
    }
    if (widget.defaultVsAi) {
      _types[1] = PlayerType.ai;
      _nameControllers[1].text = 'लाटो बोट 🤖';
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
            _sectionTitle('खेलाडी विवरण'),
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
    final color = NepaliColors.playerColor(index);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _colorNames[index],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameControllers[index],
              decoration: InputDecoration(
                labelText: S.playerName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: Text(
                  _types[index] == PlayerType.ai ? '🤖' : '👤',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Human / AI toggle
            SegmentedButton<PlayerType>(
              segments: const [
                ButtonSegment(
                    value: PlayerType.human, label: Text('👤 मान्छे')),
                ButtonSegment(value: PlayerType.ai, label: Text('🤖 AI')),
              ],
              selected: {_types[index]},
              onSelectionChanged: (s) {
                setState(() {
                  _types[index] = s.first;
                  if (s.first == PlayerType.ai &&
                      _nameControllers[index].text == _defaultNames[index]) {
                    _nameControllers[index].text = 'लाटो बोट ${index + 1} 🤖';
                  }
                });
              },
            ),
            if (_types[index] == PlayerType.ai) ...[
              const SizedBox(height: 10),
              _buildDifficultySelector(index),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector(int index) {
    return SegmentedButton<AiDifficulty>(
      segments: const [
        ButtonSegment(value: AiDifficulty.easy, label: Text('सजिलो')),
        ButtonSegment(value: AiDifficulty.normal, label: Text('सामान्य')),
        ButtonSegment(value: AiDifficulty.hard, label: Text('गाह्रो')),
      ],
      selected: {_difficulties[index]},
      onSelectionChanged: (s) => setState(() => _difficulties[index] = s.first),
    );
  }

  void _startGame() {
    final players = List.generate(_playerCount, (i) {
      return Player(
        index: i,
        name: _nameControllers[i].text.trim().isEmpty
            ? _defaultNames[i]
            : _nameControllers[i].text.trim(),
        type: _types[i],
        difficulty: _difficulties[i],
      );
    });

    final provider = context.read<GameProvider>();
    provider.startNewGame(players: players);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}
