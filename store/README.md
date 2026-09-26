# Goblin Shift — store materials

`listings.json` contains the title, subtitle, short description and full description
for English, Spanish, Brazilian Portuguese, French, German and Italian. The intended
launch model is a single €1.99 purchase with no ads or in-app purchases; pricing is
configured in the store console, not in the game or translated copy.

The fields are bounded to 30 / 30 / 80 / 4,000 characters respectively. Text was
translated in context and checked against the game's features. No native-speaker
review has been performed yet.

## Screenshots

Run from the project root with a graphical Godot session:

```sh
godot -- qa=locale_visuals
```

This captures 14 actual game screens per language under
`exports/store/screenshots/{en,es,pt_BR,fr,de,it}/`. QA uses a separate save file,
so interrupted captures cannot overwrite player progress. Use `menu.png`, `gameplay.png` and `upgrades.png` as the initial
store selection; the remaining images support localization review. Images contain
the localized interface itself, with no additional promotional text overlays.

The captures are game-viewport previews; final device-specific App Store media
must be captured on the target Apple device or simulator. Generated captures and
APKs stay under the gitignored `exports/` directory.

## Distribution notes

The displayed app name is **Goblin Shift**. The existing internal mobile identifier
`com.covagashi.goblinslayer2048` and save filename are retained so a debug update
preserves the current installation's progress. The GitHub repository URL is unchanged.

These materials are prepared locally, not published. Release signing, store-account
setup and music-license confirmation remain part of the separate publishing step.
