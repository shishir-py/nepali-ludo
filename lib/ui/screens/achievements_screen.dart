import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../../storage/game_storage.dart';

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool Function(PlayerStats) isUnlocked;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  PlayerStats? _stats;

  static final List<Achievement> _achievements = [
    Achievement(
      id: 'first_win',
      emoji: '🏆',
      title: 'पहिलो जित',
      description: 'पहिलो खेल जितियो',
      isUnlocked: (s) => s.gamesWon >= 1,
    ),
    Achievement(
      id: 'ten_games',
      emoji: '🎮',
      title: 'खेल प्रेमी',
      description: '१० खेल खेलियो',
      isUnlocked: (s) => s.gamesPlayed >= 10,
    ),
    Achievement(
      id: 'fifty_games',
      emoji: '👑',
      title: 'लुडो च्याम्पियन',
      description: '५० खेल पूरा भयो',
      isUnlocked: (s) => s.gamesPlayed >= 50,
    ),
    Achievement(
      id: 'hundred_games',
      emoji: '💯',
      title: 'लुडो मास्टर',
      description: '१०० खेल पूरा भयो',
      isUnlocked: (s) => s.gamesPlayed >= 100,
    ),
    Achievement(
      id: 'six_master',
      emoji: '🎲',
      title: 'छक्का मास्टर',
      description: '१० वटा छक्का हान्नुभयो',
      isUnlocked: (s) => s.sixesRolled >= 10,
    ),
    Achievement(
      id: 'six_god',
      emoji: '🔥',
      title: 'छक्का देवता',
      description: '१०० वटा छक्का हान्नुभयो',
      isUnlocked: (s) => s.sixesRolled >= 100,
    ),
    Achievement(
      id: 'first_capture',
      emoji: '💥',
      title: 'सिकारी',
      description: 'पहिलो token काटियो',
      isUnlocked: (s) => s.tokensCaptured >= 1,
    ),
    Achievement(
      id: 'capture_king',
      emoji: '⚔️',
      title: 'काट्ने राजा',
      description: '५० वटा token काटियो',
      isUnlocked: (s) => s.tokensCaptured >= 50,
    ),
    Achievement(
      id: 'capture_legend',
      emoji: '🗡️',
      title: 'काट्ने महाराजा',
      description: '२०० वटा token काटियो',
      isUnlocked: (s) => s.tokensCaptured >= 200,
    ),
    Achievement(
      id: 'streak_3',
      emoji: '🔥',
      title: 'जित्ने क्रम',
      description: '३ खेल लगातार जित',
      isUnlocked: (s) => s.bestStreak >= 3,
    ),
    Achievement(
      id: 'streak_5',
      emoji: '⚡',
      title: 'लगातार विजेता',
      description: '५ खेल लगातार जित',
      isUnlocked: (s) => s.bestStreak >= 5,
    ),
    Achievement(
      id: 'streak_10',
      emoji: '🌟',
      title: 'अजेय योद्धा',
      description: '१० खेल लगातार जित',
      isUnlocked: (s) => s.bestStreak >= 10,
    ),
    Achievement(
      id: 'ai_games_10',
      emoji: '🤖',
      title: 'AI संग खेल्ने',
      description: '१० वटा AI खेल पूरा',
      isUnlocked: (s) => s.vsAiGames >= 10,
    ),
    Achievement(
      id: 'ai_games_50',
      emoji: '🧠',
      title: 'AI विजेता',
      description: '२५ वटा AI खेल जित्नुभयो',
      isUnlocked: (s) => s.vsAiGames >= 50,
    ),
    Achievement(
      id: 'win_rate_50',
      emoji: '📈',
      title: 'राम्रो खेलाडी',
      description: '५०% जित दर हासिल',
      isUnlocked: (s) => s.gamesPlayed >= 10 && s.winRate >= 0.5,
    ),
    Achievement(
      id: 'win_rate_75',
      emoji: '🎯',
      title: 'उत्कृष्ट खेलाडी',
      description: '७५% जित दर हासिल',
      isUnlocked: (s) => s.gamesPlayed >= 20 && s.winRate >= 0.75,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await GameStorage.loadStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _stats == null ? 0 :
        _achievements.where((a) => a.isUnlocked(_stats!)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.achievements),
        actions: [
          if (_stats != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$unlocked/${_achievements.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: NepaliColors.background,
      body: _stats == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressBar(unlocked),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _achievements.length,
                    itemBuilder: (context, i) =>
                        _buildCard(_achievements[i]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressBar(int unlocked) {
    final progress = _achievements.isEmpty
        ? 0.0
        : unlocked / _achievements.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: NepaliColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('उपलब्धि प्रगति',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${(progress * 100).toInt()}%',
                  style: TextStyle(
                      color: NepaliColors.primary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: NepaliColors.surfaceDark,
              valueColor: AlwaysStoppedAnimation(NepaliColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Achievement achievement) {
    final isUnlocked = _stats != null && achievement.isUnlocked(_stats!);

    return Card(
      elevation: isUnlocked ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnlocked
              ? NepaliColors.gold.withOpacity(0.6)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isUnlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NepaliColors.gold.withOpacity(0.12),
                    Colors.transparent,
                  ],
                )
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: isUnlocked
                  ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.saturation)
                  : const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: isUnlocked ? 36 : 28,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isUnlocked
                    ? NepaliColors.textPrimary
                    : NepaliColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 11,
                color: isUnlocked
                    ? NepaliColors.textSecondary
                    : NepaliColors.textSecondary.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 6),
              const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }
}
