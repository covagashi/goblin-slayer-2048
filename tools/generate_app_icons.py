#!/usr/bin/env python3
"""Build opaque platform icons and Android adaptive layers from the king sprite."""

from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/sprites/app_icons"
OUT.mkdir(parents=True, exist_ok=True)

INK = "#100e13"
STONE = "#28232a"
STONE_HI = "#4a4145"
GOLD = "#f5c65a"


def background() -> Image.Image:
    image = Image.new("RGBA", (48, 48), INK)
    draw = ImageDraw.Draw(image)
    draw.rectangle((2, 2, 45, 45), fill=STONE, outline=GOLD)
    draw.rectangle((4, 4, 43, 43), outline=STONE_HI)
    draw.rectangle((6, 6, 41, 41), fill="#211d24")
    for x, y in ((7, 7), (39, 7), (7, 39), (39, 39)):
        draw.rectangle((x, y, x + 2, y + 2), fill=GOLD)
    return image


king = Image.open(ROOT / "assets/sprites/goblins/goblin-256.png").convert("RGBA")
assert king.size == (32, 32)
base = background()
base.alpha_composite(king, (8, 8))
compact = Image.new("RGBA", (32, 32), "#211d24")
compact.alpha_composite(king)

# Apple icons must be opaque. Nearest resampling retains hard pixel edges.
for size in (20, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 192, 256, 432, 1024):
    source = compact if size <= 40 else base
    source.resize((size, size), Image.Resampling.NEAREST).convert("RGB").save(
        OUT / f"icon_{size}.png", optimize=True
    )

# The adaptive foreground leaves a 72 px inset on each side for the mask.
foreground = Image.new("RGBA", (432, 432))
foreground.alpha_composite(base.resize((288, 288), Image.Resampling.NEAREST), (72, 72))
foreground.save(OUT / "adaptive_foreground_432.png", optimize=True)
background().resize((432, 432), Image.Resampling.NEAREST).convert("RGB").save(
    OUT / "adaptive_background_432.png", optimize=True
)
print("Generated 17 exact-size pixel-art app icon PNGs.")
