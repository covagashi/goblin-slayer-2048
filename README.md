# Goblin Shift

**Swipe. Merge. Survive.** A tactical fantasy puzzle inspired by 2048.
Combine goblins to slay them — now built with **Godot 4.7** for **iOS & Android** (iPhone 16 portrait layout, expandable to other screens).

## Game Features

- **Story Mode**: create a Goblin(256) to win
- **Endless Mode**: survive infinite goblin waves
- **Combat layer**: merging damages goblins — kills earn score, gold & XP
- **Horde attacks**: goblins strike back every N moves — watch the warning glow
- **Shop**: mysterious shop tiles sell potions, torch, sword, shield, poison, rope & fire scroll
- **Meta progression**: persistent XP buys 14 permanent upgrades
- **Extras**: cosmetic rare goblin variants (31 skins), ultra-rare **Golden Goblin** (10× gold), kill-streak **MASSACRE** bonuses, haptics, particles, screen shake, danger vignette
- **Leaderboard** (top-10 fastest story wins), **EN / ES / PT-BR / FR / DE / IT** translations, music + generated chiptune SFX

## 🛠️ Tech Stack

- **Engine**: Godot 4.7.1 (Compatibility/GLES3 renderer — required for wide iOS/Android support)
- **Language**: GDScript (typed)
- **Viewport**: 393×852 (iPhone 16 logical), `canvas_items` + `expand`, portrait
- **Persistence**: `user://` ConfigFile (XP, upgrades, leaderboard, settings)

## 📁 Project Structure

```
project.godot              # 4.7 config: renderer, viewport, autoloads
export_presets.cfg         # iOS + Android presets
src/
  main.tscn / main.gd      # root scene: splash↔game swap, safe area, QA hooks
  autoload/                # SignalBus, SaveManager (user:// saves), AudioManager
  core/                    # pure logic: grid_engine, run_state, board_tile,
                           #   goblin_db (balance tables), game_config
  features/
    board/                 # GameBoard (swipe/tap, event-driven anims) + TileView
    hud/                   # stats panel, items bar, event log, streak banner
    game/                  # GameScene orchestrator
    menu/                  # SplashScreen (modes, meta, language, music)
    shop/ upgrades/ gameover/ leaderboard/ howto/   # modals
  fx/                      # particles, floating text, squash/shake helpers
assets/
  sprites/                 # pixel goblins (8 tiers), variants (31), items,
                           # 39 idle strips, five VFX strips and pixel GUI
  audio/                   # music (mp3) + sfx (generated wavs)
  i18n/                    # translations.csv (6 languages)
tests/                     # headless engine tests
tools/                     # generate_sfx.py, screenshot.sh
```

## 🚀 Running

Open the project in **Godot 4.7.1+** and press Play (F5). On desktop, swipes are
emulated from mouse drags (`emulate_touch_from_mouse`).

### Headless engine tests

```bash
godot --headless -s tests/test_grid_engine.gd   # 25 assertions on game rules
```

### Headless e2e scenarios

```bash
tools/e2e.sh    # 32 scenarios driving the real UI (shop, rope, fire scroll,
                # game over + restart, victory + leaderboard, endless,
                # overcrowding, upgrades, persistence, assets, safe area, i18n,
                # native touch scrolling, audio controls, horde warnings, About/Privacy,
                # menu cycle, and 2 chaos runs with random played moves)

# extra chaos seeds: godot --headless -- qa=chaos seed=<n>
```

QA uses a separate save file and fresh progress for each scenario. It does not
modify the player's save, even if a test is interrupted.

### Visual QA snapshots

```bash
tools/screenshot.sh /tmp/shots   # boots the game, self-captures viewport PNGs
godot -- qa=visual_review       # touch UI/rank review in /tmp/gs2048_mobile_review
godot -- qa=locale_visuals      # 6-language screenshots in exports/store/screenshots/
```

## 📱 Exporting

Presets are configured in `export_presets.cfg` (portrait-locked, arm64,
`com.covagashi.goblinslayer2048`, retained as the internal ID for updates that preserve existing saves):

- **Android**: install export templates + Android SDK, then `Project → Export → Android`
  (set your release keystore in the preset).
- **iOS**: export from macOS with Xcode installed — `Project → Export → iOS`
  (iOS 15+, fill in your Team ID / provisioning profile).

### Install a debug build on Android over USB

Configure the Java and Android SDK paths in Godot's Editor Settings. The preset
uses the editor's debug keystore; leave all three debug signing fields empty
unless supplying a complete custom keystore configuration.

Enable USB debugging on the phone and accept its authorization prompt, then run:

```bash
mkdir -p exports
godot --headless --path . --export-debug Android exports/goblin-shift.apk
adb -d install -r exports/goblin-shift.apk
adb -d shell am start -W -n com.covagashi.goblinslayer2048/com.godot.game.GodotAppLauncher
```

## 🎯 How to Play

1. **Swipe** to slide goblins; equal levels merge.
2. Merging **damages** the result — goblins ≥ Lv.8 always survive the first merge.
3. Slain goblins drop gold, score & XP; kill streaks multiply gold.
4. Every ~15 moves the horde attacks — manage your HP.
5. Chests give gold (merge a goblin into them); shops appear every 5 levels.
6. Spend gold on items mid-run and XP on permanent upgrades between runs.

## Languages and store materials

The first launch detects the device language (English fallback). The language picker
uses native language names and persists the player's choice. Portuguese devices
use the Brazilian Portuguese translation. Existing language preferences are preserved.
Desktop saves from the previous project title are imported without deleting the original.

All 211 translation keys live in `assets/i18n/translations.csv`. QA checks coverage,
format placeholders, accented glyphs, locale selection and the layout of 14 screens
in each language. Store copy and screenshot instructions are in [store/README.md](store/README.md).

## Artwork and license

The goblin portraits, item sprites, UI art, animations, VFX, and app icons are
original pixel art created for this project with Pillow. Their sources and
technical details are in [assets/PIXEL_ART.md](assets/PIXEL_ART.md). The VT323
font is licensed under SIL OFL 1.1; see [assets/fonts/OFL.txt](assets/fonts/OFL.txt).

Project code is MIT licensed; see [LICENSE](LICENSE).
