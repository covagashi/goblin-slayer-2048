#!/usr/bin/env python3
"""Assert every shipped visual asset uses the agreed pixel grid and palette."""

from pathlib import Path
import hashlib
import json
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets/sprites"
MANIFEST = json.loads((SPRITES / "variants_manifest.json").read_text())
expected_variants = {item["file"] for item in MANIFEST}
errors = []
files = sorted(SPRITES.rglob("*.png"))
hashes = {}
animated = list((SPRITES / "animated").glob("*.png"))
if {p.name for p in animated} != ({f"goblin-{v}.png" for v in (2, 4, 8, 16, 32, 64, 128, 256)} | expected_variants):
    errors.append("Animated goblin sheets do not match the static portrait set")
if {p.stem for p in (SPRITES / "vfx").glob("*.png")} != {"impact", "slash", "gold", "poison", "flame"}:
    errors.append("VFX sheet family is incomplete")

if len(list((SPRITES / "goblins").glob("*.png"))) != 8:
    errors.append("Goblin rank count is not 8")
if {p.name for p in (SPRITES / "variants").glob("*.png")} != expected_variants:
    errors.append("Variant filenames differ from the manifest")
if len(list((SPRITES / "items").glob("*.png"))) != 7:
    errors.append("Item count is not 7")
app_sizes = {20, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 192, 256, 432, 1024}
expected_icons = {f"icon_{size}.png" for size in app_sizes} | {
    "adaptive_foreground_432.png", "adaptive_background_432.png"}
if {p.name for p in (SPRITES / "app_icons").glob("*.png")} != expected_icons:
    errors.append("App icon family is incomplete")

for path in files:
    with Image.open(path) as loaded:
        image = loaded.convert("RGBA")
    part = path.parent.name
    if part == "goblins":
        expected_size = (32, 32)
    elif part == "variants":
        expected_size = (38, 38)
    elif part == "items":
        expected_size = (32, 32)
    elif part == "animated":
        expected_size = (228, 38) if path.name in expected_variants else (192, 32)
    elif part == "vfx":
        expected_size = (96, 16)
    elif part == "app_icons":
        size = int(path.stem.rsplit("_", 1)[-1])
        expected_size = (size, size)
    elif path.stem.startswith("particle_"):
        expected_size = (4, 4)
    elif path.stem.startswith("scroll_"):
        expected_size = (8, 8)
    elif path.stem.startswith("bar_"):
        expected_size = (16, 8)
    elif path.stem == "stone_floor":
        expected_size = (32, 32)
    else:
        expected_size = (16, 16)
    if image.size != expected_size:
        errors.append(f"{path}: {image.size}, expected {expected_size}")
    alphas = set(image.getchannel("A").getdata())
    if not alphas <= {0, 255}:
        errors.append(f"{path}: blended alpha {sorted(alphas)}")
    colors = image.getcolors(1000000)
    if colors is None or len(colors) > 48:
        errors.append(f"{path}: more than 48 colors")
    if image.getbbox() is None:
        errors.append(f"{path}: empty image")
    if part == "app_icons":
        if path.name != "adaptive_foreground_432.png" and alphas != {255}:
            errors.append(f"{path}: platform icon should be opaque")
        if path.name == "adaptive_foreground_432.png" and alphas != {0, 255}:
            errors.append(f"{path}: adaptive foreground needs transparent margin")
    if part == "animated":
        static_dir = "variants" if path.name in expected_variants else "goblins"
        static = Image.open(SPRITES / static_dir / path.name).convert("RGBA")
        if image.crop((0, 0, static.width, static.height)).tobytes() != static.tobytes():
            errors.append(f"{path}: first animation frame differs from shipped still")
        frame_width = static.width
        frame_hashes = {hashlib.sha256(image.crop((i * frame_width, 0, (i + 1) * frame_width, static.height)).tobytes()).hexdigest()
                        for i in range(6)}
        if len(frame_hashes) < 2:
            errors.append(f"{path}: no visible frame change")
    if part == "vfx":
        for i in range(6):
            if image.crop((i * 16, 0, (i + 1) * 16, 16)).getbbox() is None:
                errors.append(f"{path}: empty frame {i}")
    if part in {"goblins", "variants"}:
        hashes.setdefault(part, set()).add(hashlib.sha256(image.tobytes()).hexdigest())

if len(hashes.get("goblins", set())) != 8:
    errors.append("Rank portraits are duplicated")
if len(hashes.get("variants", set())) != 31:
    errors.append("Variant portraits are duplicated")

if errors:
    print("\n".join(errors))
    raise SystemExit(1)
print(f"PASS: {len(files)} PNGs, 39 animated goblin sheets, 5 VFX sheets, binary alpha, <=48 colors.")
