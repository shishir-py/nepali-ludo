# Contributing to Nepali Ludo

Thank you for your interest in contributing to Nepali Ludo! 🎲

## Getting Started

### Prerequisites

- Flutter SDK 3.22.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio or VS Code with Flutter extension
- Git

### Setup

```bash
# Clone the repository
git clone https://github.com/your-username/nepali-ludo.git
cd nepali-ludo

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Project Structure

```
lib/
├── main.dart               # App entry point
├── app.dart                # MaterialApp setup
├── core/
│   └── theme/              # App theme and colors
├── game/
│   ├── engine/             # Core game logic (pure Dart)
│   │   ├── board_config.dart
│   │   ├── token.dart
│   │   ├── player.dart
│   │   ├── dice.dart
│   │   ├── game_event.dart
│   │   ├── game_state.dart
│   │   └── game_engine.dart
│   ├── ai/
│   │   └── ai_engine.dart  # AI logic
│   └── game_provider.dart  # State management
├── l10n/
│   └── strings.dart        # All Nepali strings
├── storage/
│   ├── game_storage.dart
│   └── settings_storage.dart
├── audio/
│   └── audio_manager.dart
└── ui/
    ├── painters/
    │   └── board_painter.dart
    ├── widgets/
    │   ├── dice_widget.dart
    │   └── reaction_panel.dart
    └── screens/
        ├── splash_screen.dart
        ├── home_screen.dart
        ├── game_setup_screen.dart
        ├── game_screen.dart
        ├── statistics_screen.dart
        ├── achievements_screen.dart
        └── settings_screen.dart
```

## Contribution Guidelines

### Code Style

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format lib/ test/` before committing
- Run `flutter analyze` and fix all issues

### Making Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Write or update tests
5. Run `flutter test` to ensure all tests pass
6. Commit your changes: `git commit -m 'Add amazing feature'`
7. Push to the branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

### Commit Messages

Use clear, descriptive commit messages in English or Nepali:

```
feat: add leaderboard screen
fix: resolve token capture on safe cells
docs: update README with new screenshots
test: add engine tests for three consecutive sixes
```

### Adding New Strings

All UI strings go in `lib/l10n/strings.dart`. Add them to the `S` class:

```dart
static const String myNewString = 'नेपाली पाठ';
```

Never hard-code Nepali text inside widget files.

### Reporting Bugs

Please file bugs as GitHub Issues with:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Device/OS information
- Screenshots if applicable

### Feature Requests

Feature requests are welcome! Open a GitHub Issue and describe:
- The feature you'd like
- Why it would be valuable
- Any implementation ideas

## Code of Conduct

Be respectful and welcoming. We follow the [Contributor Covenant](https://www.contributor-covenant.org/).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
