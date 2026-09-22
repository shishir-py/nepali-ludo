// Smoke test for the app shell: the splash screen is the first thing the
// app shows, so rendering it exercises the theme, fonts and l10n strings.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nepali_ludo/core/theme/app_theme.dart';
import 'package:nepali_ludo/l10n/strings.dart';
import 'package:nepali_ludo/ui/screens/splash_screen.dart';

void main() {
  testWidgets('splash screen shows the app name and tagline',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const SplashScreen(),
    ));
    await tester.pump();

    expect(find.text(S.appName), findsOneWidget);
    expect(find.text(S.appTagline), findsOneWidget);

    // The splash schedules a 3s timer that navigates to the home screen.
    // Tear the tree down first so it fires against an unmounted state
    // (the home screen needs Hive, which isn't initialised in tests),
    // then let it elapse so no timer is left pending.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
  });
}
