#!/usr/bin/env python3
"""Record all visual assets, technical constraints and provenance."""

from pathlib import Path
import hashlib
import json
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
entries = []
for path in sorted((ROOT / "assets/sprites").rglob("*.png")):
    with Image.open(path) as image:
        size = list(image.size)
        colors = len(image.convert("RGBA").getcolors(1000000) or [])
    family = path.parent.name
    frames = 6 if family in {"animated", "vfx"} else 1
    if family == "animated":
        source = "tools/generate_goblins.py"
    elif family == "vfx":
        source = "tools/generate_vfx.py"
    elif family in {"goblins", "variants"}:
        source = "tools/generate_goblins.py"
    elif family == "items":
        source = "tools/generate_items.py"
    elif family == "app_icons":
        source = "tools/generate_app_icons.py"
    else:
        source = "tools/generate_pixel_art.py"
    entries.append({
        "path": str(path.relative_to(ROOT)),
        "family": family,
        "size": size,
        "frames": frames,
        "frame_size": [size[0] // frames, size[1]],
        "colors": colors,
        "alpha": "binary",
        "source": source,
        "rights": "project-authored Pillow art",
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    })

document = {
    "version": 1,
    "engine": "Godot 4.7",
    "viewport": [393, 852],
    "texture_filter": "nearest",
    "font": {"path": "assets/fonts/VT323-Regular.ttf", "license": "SIL OFL 1.1",
             "license_file": "assets/fonts/OFL.txt",
             "source": "https://github.com/google/fonts/tree/main/ofl/vt323"},
    "assets": entries,
}
(ROOT / "assets/visual_manifest.json").write_text(json.dumps(document, indent=2) + "\n")
print(f"Recorded {len(entries)} visual PNGs in assets/visual_manifest.json.")
