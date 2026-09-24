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
          _sectionHeader('🔊 Sound'),
          _switchTile(
            icon: Icons.volume_up_rounded,
            title: S.soundEffects,
            subtitle: 'Dice, moves and captures',
            value: _settings.soundEnabled,
            onChanged: (v) {
              setState(() => _settings = _settings.copyWith(soundEnabled: v));
              _save();
            },
          ),
          _switchTile(
            icon: Icons.music_note_rounded,
            title: S.music,
            subtitle: 'Background music',
            value: _settings.musicEnabled,
            onChanged: (v) {
              setState(() => _settings = _settings.copyWith(musicEnabled: v));
              _save();
            },
          ),
          _switchTile(
            icon: Icons.emoji_emotions_rounded,
            title: 'Reaction sounds',
            subtitle: 'Play a sound when reacting',
            value: _settings.reactionsEnabled,
            onChanged: (v) {
              setState(
                  () => _settings = _settings.copyWith(reactionsEnabled: v));
              _save();
            },
          ),
          _sliderTile(
            icon: Icons.tune_rounded,
            title: 'Volume',
            value: _settings.volume,
            onChanged: (v) {
              setState(() => _settings = _settings.copyWith(volume: v));
              _save();
            },
          ),
          _infoTile(
            icon: Icons.library_music_rounded,
            title: 'Choose sounds',
            subtitle: 'Pick a sound for each game event',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SoundSettingsScreen()));
            },
          ),
          const SizedBox(height: 8),
          _sectionHeader('📳 Feedback'),
          _switchTile(
            icon: Icons.vibration_rounded,
            title: S.vibration,
            subtitle: 'Vibrate on important moments',
            value: _settings.vibrationEnabled,
            onChanged: (v) {
              setState(
                  () => _settings = _settings.copyWith(vibrationEnabled: v));
              _save();
            },
          ),
          _switchTile(
            icon: Icons.campaign_rounded,
            title: 'Game announcements',
            subtitle: 'Pop-ups like Captured! and Home!',
            value: _settings.showAnnouncements,
            onChanged: (v) {
              setState(
                  () => _settings = _settings.copyWith(showAnnouncements: v));
              _save();
            },
          ),
          const SizedBox(height: 8),
          _sectionHeader('🎮 Game'),
          _dropdownTile(
            icon: Icons.smart_toy_rounded,
            title: 'Default AI difficulty',
            value: _settings.aiDifficulty,
            items: const {
              'easy': 'Easy',
              'normal': 'Normal',
              'hard': 'Hard',
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
            title: 'Animation quality',
            value: _settings.animationQuality,
            items: const {
              'low': 'Low',
              'medium': 'Medium',
              'high': 'High',
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
          _sectionHeader('ℹ️ About'),
          _infoTile(
            icon: Icons.info_outline_rounded,
            title: S.about,
            subtitle: 'Nepali Ludo v1.0.0',
            onTap: _showAboutDialog,
          ),
          _infoTile(
            icon: Icons.delete_outline_rounded,
            title: 'Reset statistics',
            subtitle: 'Delete all game statistics',
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
        // NOTE: stays `activeColor` (not `activeThumbColor`, which needs
        // Flutter 3.32+) so this builds on the 3.27.4 the workflows pin.
        // ignore: deprecated_member_use
        activeColor: NepaliColors.primary,
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
          'Nepali Ludo is a classic Ludo game with a Nepali-inspired look.\n\n'
          'It works fully offline.\n\n'
          'GitHub: github.com/nepali-ludo',
        ),
      ],
    );
  }

  Future<void> _confirmResetStats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset statistics?'),
        content: const Text(
            'This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SettingsStorage.resetStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statistics reset.')),
        );
      }
    }
  }
}
