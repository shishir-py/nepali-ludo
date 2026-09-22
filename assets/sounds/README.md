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
