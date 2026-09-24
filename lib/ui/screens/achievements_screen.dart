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
      title: 'First Win',
      description: 'Win your first game',
      isUnlocked: (s) => s.gamesWon >= 1,
    ),
    Achievement(
      id: 'ten_games',
      emoji: '🎮',
      title: 'Game Lover',
      description: 'Play 10 games',
      isUnlocked: (s) => s.gamesPlayed >= 10,
    ),
    Achievement(
      id: 'fifty_games',
      emoji: '👑',
      title: 'Ludo Champion',
      description: 'Finish 50 games',
      isUnlocked: (s) => s.gamesPlayed >= 50,
    ),
    Achievement(
      id: 'hundred_games',
      emoji: '💯',
      title: 'Ludo Master',
      description: 'Finish 100 games',
      isUnlocked: (s) => s.gamesPlayed >= 100,
    ),
    Achievement(
      id: 'six_master',
      emoji: '🎲',
      title: 'Six Master',
      description: 'Roll 10 sixes',
      isUnlocked: (s) => s.sixesRolled >= 10,
    ),
    Achievement(
      id: 'six_god',
      emoji: '🔥',
      title: 'Six God',
      description: 'Roll 100 sixes',
      isUnlocked: (s) => s.sixesRolled >= 100,
    ),
    Achievement(
      id: 'first_capture',
      emoji: '💥',
      title: 'Hunter',
      description: 'Capture your first token',
      isUnlocked: (s) => s.tokensCaptured >= 1,
    ),
    Achievement(
      id: 'capture_king',
      emoji: '⚔️',
      title: 'Capture King',
      description: 'Capture 50 tokens',
      isUnlocked: (s) => s.tokensCaptured >= 50,
    ),
    Achievement(
      id: 'capture_legend',
      emoji: '🗡️',
      title: 'Capture Emperor',
      description: 'Capture 200 tokens',
      isUnlocked: (s) => s.tokensCaptured >= 200,
    ),
    Achievement(
      id: 'streak_3',
      emoji: '🔥',
      title: 'On a Roll',
      description: 'Win 3 games in a row',
      isUnlocked: (s) => s.bestStreak >= 3,
    ),
    Achievement(
      id: 'streak_5',
      emoji: '⚡',
      title: 'Streak Winner',
      description: 'Win 5 games in a row',
      isUnlocked: (s) => s.bestStreak >= 5,
    ),
    Achievement(
      id: 'streak_10',
      emoji: '🌟',
      title: 'Unstoppable',
      description: 'Win 10 games in a row',
      isUnlocked: (s) => s.bestStreak >= 10,
    ),
    Achievement(
      id: 'ai_games_10',
      emoji: '🤖',
      title: 'Bot Buddy',
      description: 'Play 10 games vs AI',
      isUnlocked: (s) => s.vsAiGames >= 10,
    ),
    Achievement(
      id: 'ai_games_50',
      emoji: '🧠',
      title: 'Bot Beater',
      description: 'Play 50 games vs AI',
      isUnlocked: (s) => s.vsAiGames >= 50,
    ),
    Achievement(
      id: 'win_rate_50',
      emoji: '📈',
      title: 'Good Player',
      description: 'Reach a 50% win rate',
      isUnlocked: (s) => s.gamesPlayed >= 10 && s.winRate >= 0.5,
    ),
    Achievement(
      id: 'win_rate_75',
      emoji: '🎯',
      title: 'Great Player',
      description: 'Reach a 75% win rate',
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
    final unlocked = _stats == null
        ? 0
        : _achievements.where((a) => a.isUnlocked(_stats!)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.achievements),
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
                    itemBuilder: (context, i) => _buildCard(_achievements[i]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressBar(int unlocked) {
    final progress =
        _achievements.isEmpty ? 0.0 : unlocked / _achievements.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: NepaliColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
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
              valueColor: const AlwaysStoppedAnimation(NepaliColors.primary),
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
              ? NepaliColors.gold.withValues(alpha: 0.6)
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
                    NepaliColors.gold.withValues(alpha: 0.12),
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
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
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
                    : NepaliColors.textSecondary.withValues(alpha: 0.5),
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
