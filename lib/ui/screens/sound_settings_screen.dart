import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../audio/audio_manager.dart';
import '../../audio/sound_library.dart';
import '../../audio/sound_preferences.dart';
import '../../core/theme/app_theme.dart';

/// Top-level list of every sound event. Tap one → picker for that event.
class SoundSettingsScreen extends StatelessWidget {
  const SoundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sounds')),
      backgroundColor: NepaliColors.background,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: SoundEvent.values.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == SoundEvent.values.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Reset all sounds to default'),
                onPressed: () => _confirmResetAll(context),
              ),
            );
          }
          final event = SoundEvent.values[i];
          return _EventRow(event: event);
        },
      ),
    );
  }

  Future<void> _confirmResetAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all sounds?'),
        content:
            const Text('Every event goes back to its default sound. '
                'Custom sounds you added will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) {
      await SoundPreferences.resetAll();
      AudioManager.instance.invalidateChoiceCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All sounds reset.')),
        );
      }
    }
  }
}

// ─── Row: one event with its current assignment ──────────────────

class _EventRow extends StatefulWidget {
  final SoundEvent event;
  const _EventRow({required this.event});
  @override
  State<_EventRow> createState() => _EventRowState();
}

class _EventRowState extends State<_EventRow> {
  SoundOption? _current;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final opt = await SoundPreferences.resolve(widget.event);
    if (mounted) setState(() => _current = opt);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.event.label,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        _current == null
            ? 'Loading…'
            : 'Selected: ${_current!.label}${_current!.isAsset ? "" : "  (custom)"}',
        style: const TextStyle(fontSize: 12, color: NepaliColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SoundPickerScreen(event: widget.event),
          ),
        );
        _load();
      },
    );
  }
}

// ─── Picker: choose variant for one event, upload custom ─────────

class SoundPickerScreen extends StatefulWidget {
  final SoundEvent event;
  const SoundPickerScreen({super.key, required this.event});

  @override
  State<SoundPickerScreen> createState() => _SoundPickerScreenState();
}

class _SoundPickerScreenState extends State<SoundPickerScreen> {
  List<SoundOption> _options = [];
  String? _selectedId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final options = await SoundPreferences.allOptions(widget.event);
    final choice = await SoundPreferences.resolve(widget.event);
    if (mounted) {
      setState(() {
        _options = options;
        _selectedId = choice.id;
      });
    }
  }

  @override
  void dispose() {
    AudioManager.instance.stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builtIn = _options.where((o) => o.isAsset).toList();
    final custom = _options.where((o) => !o.isAsset).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.event.label)),
      backgroundColor: NepaliColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _sectionHeader('Built-in (${builtIn.length})'),
          ...builtIn.map((o) => _optionTile(o)),
          const SizedBox(height: 8),
          _sectionHeader('Custom (${custom.length})'),
          if (custom.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No custom sounds yet. Add one with the button below.',
                style: TextStyle(color: NepaliColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...custom.map((o) => _optionTile(o, deletable: true)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add custom'),
        onPressed: _busy ? null : _pickCustom,
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          text,
          style: const TextStyle(
            color: NepaliColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _optionTile(SoundOption option, {bool deletable = false}) {
    final isSelected = option.id == _selectedId;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? NepaliColors.primary.withValues(alpha: 0.08)
            : NepaliColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? NepaliColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: IconButton(
          icon: const Icon(Icons.play_arrow_rounded,
              color: NepaliColors.primary, size: 32),
          tooltip: 'Preview',
          onPressed: () => AudioManager.instance.preview(option),
        ),
        title: Text(option.label,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          option.isAsset ? option.source : p.basename(option.source),
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: NepaliColors.primary),
            if (deletable)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteCustom(option),
              ),
          ],
        ),
        onTap: () => _select(option),
      ),
    );
  }

  Future<void> _select(SoundOption option) async {
    setState(() => _selectedId = option.id);
    await SoundPreferences.setChoice(widget.event, option);
    AudioManager.instance.invalidateChoiceCache(widget.event);
    AudioManager.instance.preview(option);
  }

  Future<void> _pickCustom() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) return;

      final sourcePath = result.files.single.path!;
      // Copy the file into the app's documents directory so it survives
      // even if the user deletes the original.
      final docsDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory(p.join(docsDir.path, 'custom_sounds'));
      if (!soundsDir.existsSync()) soundsDir.createSync(recursive: true);

      final origName = p.basename(sourcePath);
      final targetPath = _uniquePath(soundsDir.path, origName);
      await File(sourcePath).copy(targetPath);

      final label = origName.replaceAll(RegExp(r'\.[^.]+$'), '');
      await SoundPreferences.addCustom(
        event: widget.event,
        label: label,
        filePath: targetPath,
      );
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added: $label')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _uniquePath(String dir, String filename) {
    final base = p.basenameWithoutExtension(filename);
    final ext = p.extension(filename);
    var candidate = p.join(dir, filename);
    var i = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(dir, '${base}_$i$ext');
      i++;
    }
    return candidate;
  }

  Future<void> _deleteCustom(SoundOption option) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete custom sound?'),
        content: Text('"${option.label}" will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    // Best-effort file removal.
    try {
      await File(option.source).delete();
    } catch (_) {}
    await SoundPreferences.removeCustom(
      event: widget.event,
      filePath: option.source,
    );
    AudioManager.instance.invalidateChoiceCache(widget.event);
    await _reload();
  }
}
