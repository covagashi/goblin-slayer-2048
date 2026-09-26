# Pixel art source and constraints

All 155 visual PNGs are produced or normalized with Pillow. Run these commands
from the repository root:

```sh
python3 tools/generate_pixel_art.py
python3 tools/generate_goblins.py
python3 tools/generate_items.py
python3 tools/generate_vfx.py
python3 tools/generate_app_icons.py
python3 tools/verify_pixel_art.py
python3 tools/build_visual_manifest.py
godot --headless --editor --path . --quit
godot --headless --path . --script tools/build_pixel_theme.gd
```

The 8 rank portraits are 32×32. The 31 named collectible variants are 38×38,
using the filenames in `sprites/variants_manifest.json`. All 7 item sprites
are newly drawn at 32×32. UI icons and frame sources are 16×16, scrollbar
frames are 8×8, and particle sources are 4×4. Transparency is binary and
sprites use at most 48 colors. Platform icons have exact target sizes; the
iOS icons are opaque, and the Android adaptive foreground has a transparent
margin.
Each goblin also has a six-frame idle strip with a breathing pixel and blink.
Five 16×16 VFX strips have six frames each (impact, slash, gold, poison, fire).
The first idle frame matches its static portrait byte for byte.
`visual_manifest.json` records every size, frame count, color count and source.
Godot's global texture filter is nearest. UI panels and buttons use nine-slice
textures with 5 px corners, so their edges remain square at different sizes.

Visual rules: top-left light, near-black outline, green skin, warm gold for
rewards, red for damage, cyan for magic/technology and purple for rare gear.
Ranks gain equipment and increasingly strong silhouettes. Variants keep the
same face and bust scale, with distinct color and costume cues.

Rank readability: 2 has an uncovered head, 4 a deep red hood and mask,
8 an open steel helmet, 16 broad bone horns and tusks over teal skin, and
32 a closed crimson greathelm with a high crest. These are silhouette changes,
not just palette swaps. Every tile also carries a large number on an opaque
rank strip; collectible costumes retain this strip so their rank stays clear.
All updated portraits keep their six-frame idle animation and 32×32 source grid.

Artwork and UI textures: authored in this project with Pillow. The pixel font
is [VT323](https://github.com/google/fonts/tree/main/ofl/vt323), licensed
under SIL OFL 1.1; see `fonts/OFL.txt`.
