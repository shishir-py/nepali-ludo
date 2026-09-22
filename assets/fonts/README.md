# Fonts

Devanagari text is rendered with `google_fonts`
(`GoogleFonts.notoSansDevanagari*` in `lib/core/theme/app_theme.dart`), which
fetches the family at runtime — no font file is bundled here.

To bundle Noto Sans Devanagari instead (works offline, larger APK):

1. Drop `NotoSansDevanagari-Regular.ttf` and `NotoSansDevanagari-Bold.ttf` here.
2. Re-add the `fonts:` block to `pubspec.yaml`.
3. Replace the `GoogleFonts.*` calls with `fontFamily: 'NotoSansDevanagari'`.

This file also keeps the directory in git, since `pubspec.yaml` lists
`assets/fonts/` and the build fails if the directory is missing.
