import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../game/game_provider.dart';
import '../../l10n/strings.dart';
import '../../storage/game_storage.dart';
import '../widgets/nepali_background.dart';
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
      backgroundColor: const Color(0xFF14040A),
      body: NepaliBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  if (_hasSavedGame) ...[
                    _buildContinueCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildMenuButtons(),
                  const SizedBox(height: 22),
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
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: NepaliColors.goldLight.withValues(alpha: 0.35),
                blurRadius: 30,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
        )
            .animate()
            .scale(duration: 700.ms, curve: Curves.elasticOut)
            .then()
            .shimmer(duration: 1600.ms, color: Colors.white24),
        const SizedBox(height: 18),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [Color(0xFFFFF3B0), Color(0xFFFFC93C), Color(0xFFD39A12)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(r),
          child: const Text(
            S.appName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                    color: Colors.black87, offset: Offset(0, 4), blurRadius: 8),
              ],
            ),
          ),
        ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
        const SizedBox(height: 4),
        const Text(
          S.appTagline,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontStyle: FontStyle.italic,
          ),
        ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildContinueCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NepaliColors.goldLight.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Text('💾', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.savedGame,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('तपाईंको पुरानो खेल जारी छ',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: GlossyButton(
              label: S.continueGame,
              height: 44,
              colors: const [Color(0xFF3FBF5A), Color(0xFF1E7A33)],
              onTap: _loadSavedGame,
            ),
          ),
        ],
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

  static const _buttonColors = [
    [Color(0xFFE8394A), Color(0xFFA50F22)],
    [Color(0xFF3D8BEA), Color(0xFF1A4FA0)],
    [Color(0xFF8E5BD8), Color(0xFF55289A)],
    [Color(0xFF3FBF5A), Color(0xFF1E7A33)],
  ];

  Widget _buildMenuButton(_MenuButton btn, int index) {
    return GlossyButton(
      label: btn.label,
      emoji: btn.icon,
      colors: _buttonColors[index % _buttonColors.length],
      onTap: btn.onTap,
    )
        .animate(delay: Duration(milliseconds: 400 + index * 90))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
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
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: NepaliColors.goldLight, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black45, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
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
