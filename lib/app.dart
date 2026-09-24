import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio/audio_manager.dart';
import 'core/theme/app_theme.dart';
import 'game/game_provider.dart';
import 'ui/screens/splash_screen.dart';

class NepaliLudoApp extends StatefulWidget {
  const NepaliLudoApp({super.key});

  @override
  State<NepaliLudoApp> createState() => _NepaliLudoAppState();
}

class _NepaliLudoAppState extends State<NepaliLudoApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't keep playing music when the app is in the background.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      AudioManager.instance.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      AudioManager.instance.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'नेपाली लुडो',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.textScalerOf(context)
                  .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.3),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
