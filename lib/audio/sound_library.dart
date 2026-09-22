/// Catalog of sound events and their available built-in variants.
///
/// Each [SoundEvent] has multiple numbered built-in variants (e.g. kill_1.mp3
/// through kill_10.mp3) plus any custom sounds the user uploads. The user
/// picks one active sound per event via [SoundPreferences].
///
/// FILE NAMING CONVENTION
/// ──────────────────────
/// Drop files into `assets/sounds/` following this pattern:
///
///     <event>_<n>.mp3       ← n = 1, 2, 3, …
///
/// Examples:
///     kill_1.mp3   kill_2.mp3   …   kill_10.mp3
///     safe_1.mp3   safe_2.mp3   …   safe_10.mp3
///     dice_1.mp3   six_1.mp3    win_1.mp3
///
/// Missing files are silently skipped, so you can start with only a few
/// variants and add more over time. To change how many slots each event
/// exposes, edit [_variantCount] below.

enum SoundEvent {
  dice,        // dice roll
  move,        // token move
  kill,        // token captured
  safe,        // landed on safe cell
  six,         // rolled a 6
  home,        // token reached home column
  win,         // player won
  tap,         // button tap
  reaction,    // reaction sent
  music,       // background music
}

/// How many numbered variants each event exposes in the picker.
/// Files that don't exist on disk are simply hidden.
const Map<SoundEvent, int> _variantCount = {
  SoundEvent.dice:     6,
  SoundEvent.move:     4,
  SoundEvent.kill:    10,   // ← user asked for 10 kill sounds
  SoundEvent.safe:    10,   // ← user asked for 10 safe sounds
  SoundEvent.six:      6,
  SoundEvent.home:     4,
  SoundEvent.win:      6,
  SoundEvent.tap:      3,
  SoundEvent.reaction: 4,
  SoundEvent.music:    5,
};

extension SoundEventLabel on SoundEvent {
  /// Nepali label shown in the picker.
  String get label {
    switch (this) {
      case SoundEvent.dice:     return '🎲 पासा घुमाउँदा';
      case SoundEvent.move:     return '🚶 Token सर्दा';
      case SoundEvent.kill:     return '💥 काट्ने आवाज';
      case SoundEvent.safe:     return '🛡️ सुरक्षित सेल';
      case SoundEvent.six:      return '🎯 छक्का!';
      case SoundEvent.home:     return '🏠 घर पुग्दा';
      case SoundEvent.win:      return '🏆 जित';
      case SoundEvent.tap:      return '👆 बटन थिच्दा';
      case SoundEvent.reaction: return '😊 प्रतिक्रिया';
      case SoundEvent.music:    return '🎵 पृष्ठभूमि संगीत';
    }
  }

  /// Short lowercase prefix for asset filenames (kill → "kill", home → "home").
  String get slug => toString().split('.').last;

  /// SharedPreferences key for the user's chosen sound.
  String get prefKey => 'sound_choice_$slug';

  /// How many built-in variants this event exposes.
  int get variantCount => _variantCount[this] ?? 1;
}

/// A selectable sound — either a bundled asset or a user-uploaded file.
class SoundOption {
  /// Human-readable label shown in the picker (e.g. "काट #3").
  final String label;

  /// Either a bundled asset path (e.g. `sounds/kill_3.mp3`)
  /// or an absolute local file path (for user-uploaded custom sounds).
  final String source;

  /// True if [source] refers to a bundled asset; false for a custom file.
  final bool isAsset;

  /// True for the DEFAULT variant of an event (variant #1).
  final bool isDefault;

  const SoundOption({
    required this.label,
    required this.source,
    this.isAsset = true,
    this.isDefault = false,
  });

  /// Unique identifier persisted in SharedPreferences.
  String get id => isAsset ? 'asset:$source' : 'file:$source';

  factory SoundOption.custom({required String label, required String filePath}) {
    return SoundOption(label: label, source: filePath, isAsset: false);
  }

  /// Reconstruct a SoundOption from a persisted id string.
  factory SoundOption.fromId(String id, {String? label}) {
    if (id.startsWith('asset:')) {
      final src = id.substring(6);
      return SoundOption(label: label ?? src, source: src, isAsset: true);
    }
    final src = id.startsWith('file:') ? id.substring(5) : id;
    return SoundOption(label: label ?? 'Custom', source: src, isAsset: false);
  }
}

/// The catalog. `builtIn[event]` returns all numbered variants for that event.
class SoundLibrary {
  /// Built-in numbered variants per event, generated from [_variantCount].
  ///
  /// For [SoundEvent.kill] with variantCount = 10 this produces
  ///   [kill_1.mp3 (default), kill_2.mp3, …, kill_10.mp3]
  static final Map<SoundEvent, List<SoundOption>> builtIn = {
    for (final event in SoundEvent.values)
      event: List.generate(event.variantCount, (i) {
        final n = i + 1;
        return SoundOption(
          label: '${event._shortLabel} #$n',
          source: 'sounds/${event.slug}_$n.mp3',
          isAsset: true,
          isDefault: n == 1,
        );
      }),
  };

  /// The default option (variant #1) for [event].
  static SoundOption defaultFor(SoundEvent event) {
    final list = builtIn[event] ?? const [];
    return list.firstWhere(
      (o) => o.isDefault,
      orElse: () => list.isNotEmpty
          ? list.first
          : const SoundOption(label: 'None', source: ''),
    );
  }

  /// All built-in options for [event], useful for building a picker list.
  static List<SoundOption> variantsFor(SoundEvent event) =>
      builtIn[event] ?? const [];
}

extension _SoundEventShortLabel on SoundEvent {
  /// Shorter label used inside the variant name ("काट #3").
  String get _shortLabel {
    switch (this) {
      case SoundEvent.dice:     return 'पासा';
      case SoundEvent.move:     return 'सर्ने';
      case SoundEvent.kill:     return 'काट';
      case SoundEvent.safe:     return 'सुरक्षित';
      case SoundEvent.six:      return 'छक्का';
      case SoundEvent.home:     return 'घर';
      case SoundEvent.win:      return 'जित';
      case SoundEvent.tap:      return 'क्लिक';
      case SoundEvent.reaction: return 'प्रतिक्रिया';
      case SoundEvent.music:    return 'संगीत';
    }
  }
}
