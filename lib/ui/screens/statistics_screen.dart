import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../../storage/game_storage.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  PlayerStats? _stats;

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
    return Scaffold(
      appBar: AppBar(title: Text(S.myStats)),
      backgroundColor: NepaliColors.background,
      body: _stats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _statCard('🎮', S.gamesPlayed, '${_stats!.gamesPlayed}'),
                  _statCard('🏆', S.gamesWon, '${_stats!.gamesWon}'),
                  _statCard('💔', S.gamesLost, '${_stats!.gamesLost}'),
                  _statCard('📈', S.winRate,
                      '${(_stats!.winRate * 100).toStringAsFixed(1)}%'),
                  _statCard('💥', S.tokensCaptured, '${_stats!.tokensCaptured}'),
                  _statCard('🎲', S.sixesRolled, '${_stats!.sixesRolled}'),
                  _statCard('🔥', S.bestStreak, '${_stats!.bestStreak}'),
                  _statCard('🤖', S.vsAiGames, '${_stats!.vsAiGames}'),
                  _statCard('👥', S.vsHumanGames, '${_stats!.vsHumanGames}'),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String emoji, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 32)),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: NepaliColors.primary,
          ),
        ),
      ),
    );
  }
}
