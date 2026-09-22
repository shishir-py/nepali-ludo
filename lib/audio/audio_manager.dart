import 'package:audioplayers/audioplayers.dart';
import '../storage/settings_storage.dart';
import 'sound_library.dart';
import 'sound_preferences.dart';

/// Plays sound effects and background music.
///
/// Each event's sound is looked up via [SoundPreferences]: if the user has
/// assigned a specific variant (built-in or custom-uploaded), that plays;
/// otherwise the event's default variant does.
///
/// Missing files are silently skipped, so the game runs fine with only a
/// subset of sound assets present.
class AudioManager {
  static final AudioManager _instance = AudioManager._();
  factory AudioManager() => _instance;
  static AudioManager get instance => _instance;
  AudioManager._();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer(); // for the picker screen
  final AudioPlayer _musicPlayer = AudioPlayer();
  AppSettings _settings = const AppSettings();

  /// Cache of resolved options so we don't hit SharedPreferences on every play.
  /// Invalidated by [invalidateChoiceCache].
  final Map<SoundEvent, SoundOption> _choiceCache = {};

  // ─── Init / settings ────────────────────────────────────────────

  Future<void> init(AppSettings settings) async {
    _settings = settings;
    _sfxPlayer.setVolume(settings.volume);
    _musicPlayer.setVolume(settings.volume * 0.4);
    if (settings.musicEnabled) {
      await _startBackgroundMusic();
    }
  }

  /// Called from main.dart at startup.
  void setSoundEnabled(bool v) => _settings = _settings.copyWith(soundEnabled: v);
  void setMusicEnabled(bool v) {
    _settings = _settings.copyWith(musicEnabled: v);
    if (!v) _musicPlayer.stop();
    else _startBackgroundMusic();
  }
  void setVolume(double v) {
    _settings = _settings.copyWith(volume: v);
    _sfxPlayer.setVolume(v);
    _musicPlayer.setVolume(v * 0.4);
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    _sfxPlayer.setVolume(settings.volume);
    _musicPlayer.setVolume(settings.volume * 0.4);
    if (!settings.musicEnabled) {
      await _musicPlayer.stop();
    } else {
      await _startBackgroundMusic();
    }
  }

  /// Invalidate the cache — call after the user changes a sound assignment.
  void invalidateChoiceCache([SoundEvent? event]) {
    if (event == null) {
      _choiceCache.clear();
    } else {
      _choiceCache.remove(event);
    }
    // If music assignment changed, restart it.
    if ((event == null || event == SoundEvent.music) &&
        _settings.musicEnabled) {
      _startBackgroundMusic();
    }
  }

  // ─── Background music ──────────────────────────────────────────

  Future<void> _startBackgroundMusic() async {
    final option = await _resolve(SoundEvent.music);
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(_asSource(option));
    } catch (_) {
      // Music file may not exist during development — silently skip.
    }
  }

  // ─── SFX ────────────────────────────────────────────────────────

  Future<void> _playEvent(SoundEvent event) async {
    if (!_settings.soundEnabled) return;
    final option = await _resolve(event);
    if (option.source.isEmpty) return;
    try {
      await _sfxPlayer.play(_asSource(option));
    } catch (_) {
      // Assigned variant missing — try the event's built-in default.
      final fallback = SoundLibrary.defaultFor(event);
      if (fallback.source.isNotEmpty && fallback.id != option.id) {
        try {
          await _sfxPlayer.play(_asSource(fallback));
        } catch (_) {}
      }
    }
  }

  /// Play any [SoundOption] once — used by the picker for previews.
  /// Ignores the soundEnabled setting so the user can hear samples even
  /// with SFX turned off while browsing the picker.
  Future<void> preview(SoundOption option) async {
    if (option.source.isEmpty) return;
    try {
      await _previewPlayer.stop();
      await _previewPlayer.play(_asSource(option));
    } catch (_) {}
  }

  Future<void> stopPreview() async {
    try { await _previewPlayer.stop(); } catch (_) {}
  }

  Future<SoundOption> _resolve(SoundEvent event) async {
    final cached = _choiceCache[event];
    if (cached != null) return cached;
    final resolved = await SoundPreferences.resolve(event);
    _choiceCache[event] = resolved;
    return resolved;
  }

  Source _asSource(SoundOption option) {
    return option.isAsset
        ? AssetSource(option.source)
        : DeviceFileSource(option.source);
  }

  // ─── Public event triggers (called from GameProvider) ──────────

  Future<void> playDiceRoll()  => _playEvent(SoundEvent.dice);
  Future<void> playTokenMove() => _playEvent(SoundEvent.move);
  Future<void> playKill()      => _playEvent(SoundEvent.kill);
  Future<void> playCapture()   => playKill();              // legacy alias
  Future<void> playSafe()      => _playEvent(SoundEvent.safe);
  Future<void> playSix()       => _playEvent(SoundEvent.six);
  Future<void> playWin()       => _playEvent(SoundEvent.win);
  Future<void> playButtonTap() => _playEvent(SoundEvent.tap);
  Future<void> playReaction()  => _playEvent(SoundEvent.reaction);
  Future<void> playTokenHome() => _playEvent(SoundEvent.home);

  void dispose() {
    _sfxPlayer.dispose();
    _previewPlayer.dispose();
    _musicPlayer.dispose();
  }
}
