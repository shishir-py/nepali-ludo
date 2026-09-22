import 'package:flutter/material.dart';
import '../../audio/audio_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../../storage/settings_storage.dart';
import 'sound_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings _settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsStorage.load();
    if (mounted) setState(() => _settings = s);
  }

  Future<void> _save() async {
    await SettingsStorage.save(_settings);
    // Apply audio settings immediately
    final audio = AudioManager.instance;
    audio.setSoundEnabled(_settings.soundEnabled);
    audio.setMusicEnabled(_settings.musicEnabled);
    audio.setVolume(_settings.volume);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.settings)),
      backgroundColor: NepaliColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('🔊 आवाज'),
          _switchTile(
            icon: Icons.volume_up_rounded,
            title: S.soundEffects,
            subtitle: 'पासा, token र कब्जाका आवाजहरू',
            value: _settings.soundEnabled,
            onChanged: (v) {
              setState(() => _settings = _settings.copyWith(soundEnabled: v));
              _save();
            },
          ),
          _switchTile(
            icon: Icons.music_note_rounded,
            title: S.music,
            subtitle: 'पृष्ठभूमि संगीत',
            value: _settings.musicEnabled,
            onChanged: (v) {
              setState(() => _settings = _settings.copyWith(musicEnabled: v));
              _save();
            },
          ),
          _switchTile(
            icon: Icons.emoji_emotions_rounded,
            title: 'प्रतिक्रिया आवाज',
            subtitle: 'प्रतिक्रिया पठाउँदा आवाज',
            value: _settings.reactionsEnabled,
            onChanged: (v) {
              setState(
                  () => _settings = _settings.copyWith(reactionsEnabled: v));
              _save();
            },
          ),
          _sliderTile(
            icon: Icons.tune_rounded,
            title: 'आवाजको मात्रा',
            value: _settings.volume,
            onChanged: (v) {
              setState(() => _settings = _settings.copyWith(volume: v));
              _save();
            },
          ),
          _infoTile(
            icon: Icons.library_music_rounded,
            title: 'आवाज छान्नुहोस्',
            subtitle: 'प्रत्येक घटनाको लागि आफ्नै आवाज तोक्नुहोस्',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SoundSettingsScreen()));
            },
          ),
          const SizedBox(height: 8),
          _sectionHeader('📳 सूचना'),
          _switchTile(
            icon: Icons.vibration_rounded,
            title: S.vibration,
            subtitle: 'खेलका महत्त्वपूर्ण क्षणहरूमा कम्पन',
            value: _settings.vibrationEnabled,
            onChanged: (v) {
              setState(
                  () => _settings = _settings.copyWith(vibrationEnabled: v));
              _save();
            },
          ),
          _switchTile(
            icon: Icons.campaign_rounded,
            title: 'खेल घोषणाहरू',
            subtitle: 'छक्का!, काटियो!, घर पुग्यो! जस्ता सन्देश',
            value: _settings.showAnnouncements,
            onChanged: (v) {
              setState(
                  () => _settings = _settings.copyWith(showAnnouncements: v));
              _save();
            },
          ),
          const SizedBox(height: 8),
          _sectionHeader('🎮 खेल'),
          _dropdownTile(
            icon: Icons.smart_toy_rounded,
            title: 'AI कठिनाइ (पूर्वनिर्धारित)',
            value: _settings.aiDifficulty,
            items: const {
              'easy': 'सजिलो',
              'normal': 'सामान्य',
              'hard': 'गाह्रो',
            },
            onChanged: (v) {
              if (v != null) {
                setState(() => _settings = _settings.copyWith(aiDifficulty: v));
                _save();
              }
            },
          ),
          _dropdownTile(
            icon: Icons.animation_rounded,
            title: 'एनिमेसन गुणस्तर',
            value: _settings.animationQuality,
            items: const {
              'low': 'कम',
              'medium': 'मध्यम',
              'high': 'उच्च',
            },
            onChanged: (v) {
              if (v != null) {
                setState(
                    () => _settings = _settings.copyWith(animationQuality: v));
                _save();
              }
            },
          ),
          const SizedBox(height: 8),
          _sectionHeader('ℹ️ बारेमा'),
          _infoTile(
            icon: Icons.info_outline_rounded,
            title: S.about,
            subtitle: 'नेपाली लुडो v1.0.0',
            onTap: _showAboutDialog,
          ),
          _infoTile(
            icon: Icons.delete_outline_rounded,
            title: 'तथ्याङ्क मेटाउनुहोस्',
            subtitle: 'सबै खेल तथ्याङ्क हटाउनुहोस्',
            onTap: _confirmResetStats,
            textColor: Colors.red,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: NepaliColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: NepaliColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: NepaliColors.textSecondary)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: NepaliColors.primary,
      ),
    );
  }

  Widget _sliderTile({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: NepaliColors.primary, size: 22),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('${(value * 100).round()}%',
                    style: const TextStyle(
                        color: NepaliColors.primary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: value,
              onChanged: onChanged,
              activeColor: NepaliColors.primary,
              inactiveColor: NepaliColors.surfaceDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: NepaliColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          items: items.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? NepaliColors.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: NepaliColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: S.appName,
      applicationVersion: 'v1.0.0',
      applicationIcon: const Text('🎲', style: TextStyle(fontSize: 48)),
      children: [
        const Text(
          'नेपाली लुडो एक नेपाली भाषा र संस्कृतिमा आधारित लुडो खेल हो।\n\n'
          'यो खेल पूर्ण रूपमा अफलाइन खेल्न सकिन्छ।\n\n'
          'GitHub: github.com/nepali-ludo',
        ),
      ],
    );
  }

  Future<void> _confirmResetStats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('तथ्याङ्क मेटाउने?'),
        content: const Text(
            'यो कार्य पूर्ववत गर्न सकिँदैन। के तपाईं निश्चित हुनुहुन्छ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('मेटाउनुहोस्'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SettingsStorage.resetStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('तथ्याङ्क मेटाइयो।')),
        );
      }
    }
  }
}
