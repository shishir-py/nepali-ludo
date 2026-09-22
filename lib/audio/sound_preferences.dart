import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_library.dart';

/// Stores the user's per-event sound choices and the registry of custom
/// sounds they've uploaded.
///
/// Layout in SharedPreferences:
///   sound_choice_<slug>     → id of the chosen SoundOption
///                             ("asset:sounds/kill_3.mp3" or "file:/path/to.mp3")
///   sound_custom_<slug>     → JSON array of {label, path} for user uploads
class SoundPreferences {
  /// Return the id of the currently chosen sound for [event], or null if none.
  static Future<String?> getChoiceId(SoundEvent event) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(event.prefKey);
  }

  /// Set the active sound for [event]. Persists across sessions.
  static Future<void> setChoice(SoundEvent event, SoundOption option) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(event.prefKey, option.id);
  }

  /// Reset [event] to its default variant.
  static Future<void> reset(SoundEvent event) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(event.prefKey);
  }

  /// Reset every event to defaults.
  static Future<void> resetAll() async {
    final p = await SharedPreferences.getInstance();
    for (final e in SoundEvent.values) {
      await p.remove(e.prefKey);
      await p.remove(_customKey(e));
    }
  }

  /// Return the resolved [SoundOption] currently chosen for [event],
  /// falling back to the built-in default if none is set.
  ///
  /// This is what [AudioManager] calls at play-time.
  static Future<SoundOption> resolve(SoundEvent event) async {
    final id = await getChoiceId(event);
    if (id == null) return SoundLibrary.defaultFor(event);

    if (id.startsWith('asset:')) {
      // Find matching built-in variant to preserve its label.
      final match = SoundLibrary.variantsFor(event).firstWhere(
        (o) => o.id == id,
        orElse: () => SoundLibrary.defaultFor(event),
      );
      return match;
    }

    if (id.startsWith('file:')) {
      // Look it up in the custom-sound registry to get the label.
      final customs = await listCustom(event);
      final match = customs.firstWhere(
        (o) => o.id == id,
        orElse: () => SoundLibrary.defaultFor(event),
      );
      return match;
    }

    return SoundLibrary.defaultFor(event);
  }

  // ─── Custom sounds ────────────────────────────────────────────

  static String _customKey(SoundEvent event) => 'sound_custom_${event.slug}';

  /// Return the list of custom-uploaded sounds registered for [event].
  static Future<List<SoundOption>> listCustom(SoundEvent event) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_customKey(event));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list
          .map((m) => SoundOption.custom(
                label: m['label'] as String,
                filePath: m['path'] as String,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Register a custom sound file for [event]. Returns the created option.
  static Future<SoundOption> addCustom({
    required SoundEvent event,
    required String label,
    required String filePath,
  }) async {
    final option = SoundOption.custom(label: label, filePath: filePath);
    final existing = await listCustom(event);
    final updated = [...existing, option];
    await _saveCustom(event, updated);
    return option;
  }

  /// Remove a custom sound. If it was the active choice, revert to default.
  static Future<void> removeCustom({
    required SoundEvent event,
    required String filePath,
  }) async {
    final existing = await listCustom(event);
    final updated =
        existing.where((o) => o.source != filePath).toList();
    await _saveCustom(event, updated);

    final activeId = await getChoiceId(event);
    if (activeId == 'file:$filePath') {
      await reset(event);
    }
  }

  static Future<void> _saveCustom(
      SoundEvent event, List<SoundOption> options) async {
    final p = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      options.map((o) => {'label': o.label, 'path': o.source}).toList(),
    );
    await p.setString(_customKey(event), encoded);
  }

  /// All selectable options (built-in + custom) for [event].
  static Future<List<SoundOption>> allOptions(SoundEvent event) async {
    final builtIn = SoundLibrary.variantsFor(event);
    final custom = await listCustom(event);
    return [...builtIn, ...custom];
  }
}
