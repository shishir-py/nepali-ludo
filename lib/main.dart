import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'audio/audio_manager.dart';
import 'storage/settings_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize audio
  final settings = await SettingsStorage.load();
  final audio = AudioManager.instance;
  audio.setSoundEnabled(settings.soundEnabled);
  audio.setMusicEnabled(settings.musicEnabled);
  audio.setVolume(settings.volume);

  runApp(const NepaliLudoApp());
}
