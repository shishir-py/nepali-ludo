import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'game/game_provider.dart';
import 'ui/screens/splash_screen.dart';

class NepaliLudoApp extends StatelessWidget {
  const NepaliLudoApp({super.key});

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
          // Apply Noto Sans Devanagari as default font
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
