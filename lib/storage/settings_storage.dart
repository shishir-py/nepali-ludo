import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final bool reactionsEnabled;
  final double volume;
  final String animationQuality; // 'low' | 'medium' | 'high'
  final bool showAnnouncements;
  final String aiDifficulty; // 'easy' | 'normal' | 'hard'

  const AppSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.reactionsEnabled = true,
    this.volume = 0.8,
    this.animationQuality = 'high',
    this.showAnnouncements = true,
    this.aiDifficulty = 'normal',
  });

  AppSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    bool? reactionsEnabled,
    double? volume,
    String? animationQuality,
    bool? showAnnouncements,
    String? aiDifficulty,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      reactionsEnabled: reactionsEnabled ?? this.reactionsEnabled,
      volume: volume ?? this.volume,
      animationQuality: animationQuality ?? this.animationQuality,
      showAnnouncements: showAnnouncements ?? this.showAnnouncements,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
    );
  }
}

class SettingsStorage {
  static const _prefix = 'setting_';

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      soundEnabled: p.getBool('${_prefix}sound') ?? true,
      musicEnabled: p.getBool('${_prefix}music') ?? true,
      vibrationEnabled: p.getBool('${_prefix}vibration') ?? true,
      reactionsEnabled: p.getBool('${_prefix}reactions') ?? true,
      volume: p.getDouble('${_prefix}volume') ?? 0.8,
      animationQuality: p.getString('${_prefix}animQuality') ?? 'high',
      showAnnouncements: p.getBool('${_prefix}announcements') ?? true,
      aiDifficulty: p.getString('${_prefix}aiDifficulty') ?? 'normal',
    );
  }

  static Future<void> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('${_prefix}sound', s.soundEnabled);
    await p.setBool('${_prefix}music', s.musicEnabled);
    await p.setBool('${_prefix}vibration', s.vibrationEnabled);
    await p.setBool('${_prefix}reactions', s.reactionsEnabled);
    await p.setDouble('${_prefix}volume', s.volume);
    await p.setString('${_prefix}animQuality', s.animationQuality);
    await p.setBool('${_prefix}announcements', s.showAnnouncements);
    await p.setString('${_prefix}aiDifficulty', s.aiDifficulty);
  }

  static Future<void> resetStats() async {
    final p = await SharedPreferences.getInstance();
    final statsKeys = p.getKeys().where((k) => k.startsWith('stats_')).toList();
    for (final k in statsKeys) {
      await p.remove(k);
    }
  }
}
