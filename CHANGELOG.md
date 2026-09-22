# Changelog

All notable changes to Nepali Ludo are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-01

### पहिलो संस्करण 🎉

#### Added
- 🎲 Complete classic Ludo game with all standard rules
- 🤖 AI opponent "लाटो बोट" with three difficulty levels (Easy/Normal/Hard)
- 👥 Local multiplayer for 2–4 players
- 🇳🇵 Full Nepali language UI with Devanagari typography
- 😂 Nepali reactions and expressions panel
- 🔊 Sound effects (dice roll, token move, capture, six, win)
- 🏆 Statistics tracking (games played, wins, losses, tokens captured, sixes rolled)
- 🏅 16 achievements with Nepali names and descriptions
- 💾 Save/resume game functionality
- 📱 Full offline support
- ⚙️ Settings screen (sound, music, vibration, AI difficulty, animation quality)
- 🎨 Nepali-themed visual design (Dhaka-inspired patterns, crimson colors)
- 📊 Statistics screen with emoji-labeled stat cards
- 🔔 Nepali game announcements (छक्का!, काटियो!, घर पुग्यो!, बधाई छ!)
- 🤖 GitHub Actions CI/CD with auto APK building

#### Technical
- Pure Dart game engine (no Flutter dependencies in core logic)
- Provider state management
- SharedPreferences for game persistence
- Custom board painter with 15×15 grid
- AI scoring heuristics for Hard difficulty
- Comprehensive unit tests for game engine, dice, tokens, and AI

## [Unreleased]

### Planned for v1.1
- Online multiplayer rooms
- Friend system with room codes
- Improved AI with deeper lookahead
- More avatar options
- More reaction expressions
- Match history

### Planned for v1.2
- User accounts
- Online leaderboards
- Cloud statistics sync
- Online match history

### Future
- Tournaments
- Private rooms
- Voice reactions
- Custom board themes
- Seasonal Nepali festival themes
