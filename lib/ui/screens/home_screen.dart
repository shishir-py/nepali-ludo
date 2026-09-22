import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../game/game_provider.dart';
import '../../l10n/strings.dart';
import '../../storage/game_storage.dart';
import 'game_setup_screen.dart';
import 'game_screen.dart';
import 'statistics_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  Future<void> _checkSavedGame() async {
    final has = await GameStorage.hasSavedGame();
    if (mounted) setState(() => _hasSavedGame = has);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8DC),
              Color(0xFFFDF6E3),
              Color(0xFFF5EDD5),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  if (_hasSavedGame) ...[
                    _buildContinueCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildMenuButtons(),
                  const SizedBox(height: 24),
                  _buildBottomLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: NepaliColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: NepaliColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('🎲', style: TextStyle(fontSize: 56)),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

        const SizedBox(height: 16),

        Text(
          S.appName,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: NepaliColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),

        Text(
          S.appTagline,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: NepaliColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
        ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildContinueCard() {
    return Card(
      color: NepaliColors.primaryLight.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: NepaliColors.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: ListTile(
        leading: const Text('💾', style: TextStyle(fontSize: 32)),
        title: const Text(S.savedGame,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: const Text('तपाईंको पुरानो खेल जारी छ'),
        trailing: ElevatedButton(
          onPressed: _loadSavedGame,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(S.continueGame, style: TextStyle(fontSize: 13)),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
  }

  Future<void> _loadSavedGame() async {
    final provider = context.read<GameProvider>();
    await provider.loadSavedGame();
    if (mounted && provider.hasGame) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }

  Widget _buildMenuButtons() {
    final buttons = [
      _MenuButton(icon: '🎮', label: S.newGame, onTap: _openSetup),
      _MenuButton(
          icon: '🤖', label: S.vsComputer, onTap: () => _openSetup(vsAi: true)),
      _MenuButton(icon: '🌐', label: S.onlineGame, onTap: _openOnlineComing),
      _MenuButton(
          icon: '👥',
          label: S.withFriends,
          onTap: () => _openSetup(localMulti: true)),
    ];

    return Column(
      children: buttons.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMenuButton(entry.value, entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildMenuButton(_MenuButton btn, int index) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: btn.onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(btn.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Text(btn.label, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 400 + index * 80))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.08, end: 0);
  }

  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconLink('🏆', S.achievements, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()));
        }),
        _iconLink('📊', S.statistics, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()));
        }),
        _iconLink('⚙️', S.settings, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }),
      ],
    );
  }

  Widget _iconLink(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: NepaliColors.textSecondary)),
        ],
      ),
    );
  }

  void _openSetup({bool vsAi = false, bool localMulti = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameSetupScreen(
          defaultVsAi: vsAi,
          defaultLocalMulti: localMulti,
        ),
      ),
    ).then((_) => _checkSavedGame());
  }

  void _openOnlineComing() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🌐 अनलाइन खेल'),
        content: const Text(S.comingSoon, style: TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(S.ok),
          ),
        ],
      ),
    );
  }
}

class _MenuButton {
  final String icon;
  final String label;
  final VoidCallback onTap;
  _MenuButton({required this.icon, required this.label, required this.onTap});
}
