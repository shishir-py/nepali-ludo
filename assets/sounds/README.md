# Sound Effects — नेपाली लुडो

The app supports **multiple numbered variants per event**. Drop as many or as few `.mp3` files as you want using this naming pattern:

```
<event>_<n>.mp3     ← n starts at 1
```

Files missing at runtime are silently skipped, and the picker only shows variants whose file actually exists — so you can start with variant #1 for each event and grow from there.

## Variant slots exposed in the picker

| Event | File pattern | Slots | Notes |
|-------|--------------|-------|-------|
| Dice roll     | `dice_1.mp3` … `dice_6.mp3`   | 6  | `dice_1.mp3` = default |
| Token move    | `move_1.mp3` … `move_4.mp3`   | 4  | |
| **Kill / capture** | **`kill_1.mp3` … `kill_10.mp3`** | **10** | 10 variants – funny, dramatic, gaali etc. |
| **Safe cell** | **`safe_1.mp3` … `safe_10.mp3`** | **10** | 10 variants – shield, bell, magic etc. |
| Six rolled    | `six_1.mp3` … `six_6.mp3`     | 6  | |
| Token home    | `home_1.mp3` … `home_4.mp3`   | 4  | |
| Win           | `win_1.mp3` … `win_6.mp3`     | 6  | |
| Button tap    | `tap_1.mp3` … `tap_3.mp3`     | 3  | |
| Reaction      | `reaction_1.mp3` … `reaction_4.mp3` | 4 | |
| Background music | `music_1.mp3` … `music_5.mp3` | 5 | Loops during gameplay |

The user picks which variant plays for each event inside the app: **Settings → आवाज छान्नुहोस्**. They can also upload their own custom sound files from anywhere on their device — those live in the app's private storage and appear in the same picker.

## Getting sounds

**[myinstants.com](https://www.myinstants.com/)** is a great source — search for any short sound, click the play button to preview, then use the download button. Rename the file to match the table above.

Suggested searches:

| For | Try |
|-----|-----|
| `kill_*` | "sword slash", "punch", "boom", "काटियो", "explosion", "fatality", "gaali" |
| `safe_*` | "shield", "protect", "ding", "bell", "chime", "safe zone", "coin ding" |
| `six_*` | "छक्का", "wow", "yay", "crowd cheer", "victory jingle" |
| `win_*` | "victory", "बधाई", "celebration", "fanfare", "level complete" |
| `dice_*` | "dice roll", "rattle", "shake" |
| `home_*` | "coin", "level up", "checkpoint" |
| `music_*` | Longer clips work here — loops automatically |

Other royalty-free sources: [freesound.org](https://freesound.org), [mixkit.co](https://mixkit.co/free-sound-effects/), [pixabay.com/sound-effects](https://pixabay.com/sound-effects/).

## Tips

- Keep effect clips **short** (0.3s – 1.5s) so they don't overlap or delay gameplay
- Music clips can be any length — they loop
- All files must be `.mp3`
- Volume is controlled globally in Settings — the app plays SFX at your chosen volume and music at 40% of it
- Once files are in this folder, run `flutter pub get` to have them bundled into the APK

## Built-in sounds (included)

Every slot above ships with an original sound that was synthesised from
scratch by `tools/generate_sounds.py` (oscillators, noise and envelopes, no
samples), so they are free to distribute with this open-source project.
To regenerate or tweak them:

```bash
pip install numpy scipy        # ffmpeg must also be installed
python3 tools/generate_sounds.py
cp tools/sounds/*.mp3 assets/sounds/
```

The app icon and `assets/images/logo.png` come from `tools/generate_icon.py`.

Dropping your own file with the same name (e.g. `kill_3.mp3`) replaces the
built-in one. Clips downloaded from sites like myinstants.com are often
copyrighted, so check the licence before committing them to a public repo;
players can always add their own sounds privately from the in-app picker.
