#!/usr/bin/env python3
"""Build the game's small, palette-locked pixel UI with Pillow.

Run from the repository root: python3 tools/generate_pixel_art.py
The 16 px icons and 16 px nine-slice frames are source-resolution art; Godot
uses nearest filtering and never resamples them with interpolation.
"""

from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/sprites/ui"
OUT.mkdir(parents=True, exist_ok=True)

INK = "#100e13"
STONE = "#28232a"
STONE_HI = "#4a4145"
STONE_LO = "#1b1921"
PARCHMENT = "#ead6ac"
GOLD = "#f5c65a"
GOLD_DARK = "#976226"
RED = "#b93b37"
RED_HI = "#eb6650"
RED_DARK = "#72292e"
GREEN = "#7eb443"
BLUE = "#6cc3ce"
PURPLE = "#a17ac5"


def save(img: Image.Image, name: str) -> None:
    img.save(OUT / f"{name}.png", optimize=True)


def frame(name: str, fill: str, light: str, dark: str) -> None:
    im = Image.new("RGBA", (16, 16))
    d = ImageDraw.Draw(im)
    # Stepped corners and an asymmetric 1 px highlight make the frame read
    # as a hand-cut stone/metal bezel. 5 px margins protect corners in Godot.
    d.rectangle((2, 0, 13, 15), fill=INK)
    d.rectangle((0, 2, 15, 13), fill=INK)
    d.rectangle((2, 1, 13, 14), fill=light)
    d.rectangle((1, 2, 14, 13), fill=light)
    d.rectangle((3, 3, 12, 12), fill=fill)
    d.line((2, 13, 13, 13, 13, 2), fill=dark, width=1)
    d.point((1, 2), fill=PARCHMENT)
    d.point((2, 1), fill=PARCHMENT)
    d.point((13, 14), fill=INK)
    save(im, name)


for data in (
    ("panel", STONE, STONE_HI, STONE_LO),
    ("inset", STONE_LO, STONE_HI, INK),
    ("button", RED, RED_HI, RED_DARK),
    ("button_hover", RED_HI, GOLD, RED),
    ("button_pressed", RED_DARK, RED, INK),
    ("button_disabled", "#3a3438", "#51474a", STONE_LO),
    ("gold_button", GOLD_DARK, GOLD, "#5c3d22"),
    ("gold_button_hover", "#bd8230", PARCHMENT, GOLD_DARK),
    ("gold_button_pressed", "#6d4928", GOLD_DARK, INK),
    ("cell", STONE_LO, "#373139", INK),
    ("tile", STONE, STONE_HI, STONE_LO),
    ("tile_chest", "#514024", GOLD, GOLD_DARK),
    ("tile_shop", "#3f2f53", PURPLE, STONE_LO),
    ("tile_gold", "#59421e", GOLD, GOLD_DARK),
):
    frame(*data)


def scroll_frame(name: str, fill: str, border: str) -> None:
    im = Image.new("RGBA", (8, 8), fill)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 7, 7), outline=INK)
    d.line((1, 1, 6, 1), fill=border)
    d.line((1, 1, 1, 6), fill=border)
    d.line((1, 6, 6, 6), fill=STONE_LO)
    d.line((6, 1, 6, 6), fill=STONE_LO)
    save(im, name)


for data in (
    ("scroll_track", STONE_LO, STONE_HI),
    ("scroll_thumb", STONE_HI, PARCHMENT),
    ("scroll_thumb_hover", "#6b5d63", GOLD),
    ("scroll_thumb_pressed", GOLD_DARK, GOLD),
):
    scroll_frame(*data)


def bar(name: str, fill: str, edge: str) -> None:
    im = Image.new("RGBA", (16, 8), INK)
    d = ImageDraw.Draw(im)
    d.rectangle((1, 1, 14, 6), fill=edge)
    d.rectangle((2, 2, 13, 5), fill=fill)
    save(im, name)


bar("bar_empty", STONE_LO, STONE_HI)
bar("bar_hp", RED, RED_HI)

# Repeating stone floor; deterministic, low-contrast and safe behind text.
floor = Image.new("RGBA", (32, 32), "#211d24")
d = ImageDraw.Draw(floor)
for y in range(0, 32, 8):
    shift = 0 if (y // 8) % 2 == 0 else 8
    d.line((0, y, 31, y), fill="#16141b")
    for x in range(shift, 32, 16):
        d.line((x, y + 1, x, min(y + 7, 31)), fill="#16141b")
for x, y in ((3, 3), (21, 5), (12, 12), (28, 15), (6, 22), (19, 27)):
    d.rectangle((x, y, x + 2, y), fill="#302a32")
save(floor, "stone_floor")


def icon(name: str, draw) -> None:
    im = Image.new("RGBA", (16, 16))
    draw(ImageDraw.Draw(im))
    save(im, name)


def sword(d):
    d.polygon([(2, 13), (4, 13), (11, 6), (13, 2), (10, 3), (3, 10)], fill="#a9bec4")
    d.line((3, 12, 12, 3), fill=PARCHMENT, width=1)
    d.line((2, 9, 6, 13), fill=GOLD_DARK, width=2)
    d.rectangle((1, 13, 3, 14), fill=INK)


def shield(d):
    d.polygon([(8, 1), (14, 4), (13, 11), (8, 15), (3, 11), (2, 4)], fill=INK)
    d.polygon([(8, 2), (13, 5), (12, 10), (8, 13), (4, 10), (3, 5)], fill="#72878e")
    d.polygon([(8, 3), (8, 12), (4, 9), (4, 5)], fill=PARCHMENT)
    d.line((4, 5, 12, 5), fill=GOLD, width=1)


def skull(d):
    d.rectangle((4, 2, 11, 10), fill=INK)
    d.rectangle((3, 4, 12, 8), fill=PARCHMENT)
    d.rectangle((5, 2, 10, 10), fill=PARCHMENT)
    d.rectangle((5, 6, 6, 7), fill=INK)
    d.rectangle((9, 6, 10, 7), fill=INK)
    d.rectangle((7, 8, 8, 9), fill=INK)
    d.rectangle((5, 11, 10, 13), fill=PARCHMENT)
    d.point((7, 12), fill=INK)


def coin(d):
    d.ellipse((2, 2, 13, 13), fill=INK)
    d.ellipse((3, 3, 12, 12), fill=GOLD_DARK)
    d.ellipse((4, 4, 11, 10), fill=GOLD)
    d.line((7, 5, 9, 5, 9, 7, 6, 7, 6, 9, 9, 9), fill=GOLD_DARK)


def star(d):
    d.polygon([(8, 1), (10, 5), (14, 6), (11, 9), (12, 14), (8, 11), (4, 14), (5, 9), (2, 6), (6, 5)], fill=GOLD)
    d.point((8, 4), fill=PARCHMENT)


def heart(d):
    d.polygon([(2, 3), (5, 2), (8, 4), (11, 2), (14, 3), (14, 8), (8, 14), (2, 8)], fill=INK)
    d.polygon([(3, 4), (5, 3), (8, 5), (11, 3), (13, 4), (13, 8), (8, 12), (3, 8)], fill=RED)
    d.point((5, 4), fill=RED_HI)


def chest(d):
    d.rectangle((2, 4, 13, 12), fill=INK)
    d.rectangle((3, 5, 12, 11), fill=GOLD_DARK)
    d.rectangle((3, 6, 12, 7), fill=PARCHMENT)
    d.rectangle((7, 6, 8, 9), fill=GOLD)
    d.rectangle((4, 9, 11, 10), fill="#6b3d25")


def shop(d):
    d.rectangle((3, 6, 12, 13), fill=INK)
    d.rectangle((4, 7, 11, 12), fill=STONE_HI)
    d.rectangle((6, 9, 9, 12), fill=GOLD_DARK)
    d.polygon([(2, 5), (4, 2), (11, 2), (14, 5)], fill=PURPLE)
    d.rectangle((2, 5, 13, 6), fill=PARCHMENT)


def rope(d):
    d.ellipse((2, 2, 11, 11), outline=GOLD_DARK, width=2)
    d.ellipse((4, 4, 9, 9), outline=PARCHMENT, width=1)
    d.line((11, 9, 14, 13), fill=GOLD, width=2)


def book(d):
    d.rectangle((2, 2, 13, 13), fill=INK)
    d.rectangle((3, 3, 7, 12), fill=PURPLE)
    d.rectangle((8, 3, 12, 12), fill=PARCHMENT)
    d.line((8, 4, 8, 12), fill=INK)


def crown(d):
    d.polygon([(2, 4), (5, 7), (8, 2), (11, 7), (14, 4), (12, 12), (4, 12)], fill=GOLD)
    d.rectangle((4, 11, 12, 13), fill=GOLD_DARK)
    d.point((8, 7), fill=RED)


def trophy(d):
    d.rectangle((4, 2, 11, 8), fill=GOLD)
    d.line((2, 3, 2, 6, 5, 8), fill=GOLD_DARK, width=1)
    d.line((13, 3, 13, 6, 10, 8), fill=GOLD_DARK, width=1)
    d.rectangle((7, 8, 8, 12), fill=GOLD_DARK)
    d.rectangle((5, 13, 10, 14), fill=GOLD)


def clock(d):
    d.ellipse((2, 2, 13, 13), fill=INK)
    d.ellipse((3, 3, 12, 12), fill=PARCHMENT)
    d.line((8, 4, 8, 8, 10, 10), fill=INK, width=1)


def globe(d):
    d.ellipse((2, 2, 13, 13), outline=BLUE, width=2)
    d.line((2, 8, 13, 8), fill=BLUE)
    d.line((8, 2, 8, 13), fill=BLUE)
    d.arc((5, 2, 11, 13), 80, 280, fill=BLUE)


def volume(d):
    d.polygon([(2, 6), (5, 6), (9, 3), (9, 13), (5, 10), (2, 10)], fill=PARCHMENT)
    d.arc((5, 3, 14, 13), -65, 65, fill=GOLD, width=2)


def mute(d):
    volume(d)
    d.line((11, 5, 14, 10), fill=RED, width=2)
    d.line((14, 5, 11, 10), fill=RED, width=2)


def menu(d):
    for y in (4, 8, 12):
        d.rectangle((2, y, 13, y + 1), fill=PARCHMENT)


def play(d):
    d.polygon([(4, 2), (13, 8), (4, 14)], fill=GOLD)


def target(d):
    d.ellipse((2, 2, 13, 13), outline=RED_HI, width=2)
    d.ellipse((5, 5, 10, 10), outline=PARCHMENT, width=1)
    d.point((8, 8), fill=RED_HI)


def bolt(d):
    d.polygon([(9, 1), (4, 8), (7, 8), (5, 15), (13, 6), (9, 6)], fill=GOLD)


def sparkle(d):
    d.polygon([(8, 1), (10, 6), (15, 8), (10, 10), (8, 15), (6, 10), (1, 8), (6, 6)], fill=GOLD)
    d.point((8, 8), fill=PARCHMENT)


def poison(d):
    d.ellipse((3, 3, 12, 12), fill=GREEN)
    d.rectangle((5, 6, 6, 7), fill=INK)
    d.rectangle((9, 6, 10, 7), fill=INK)
    d.line((6, 10, 9, 10), fill=INK)
    d.point((12, 2), fill=GREEN)


def fire(d):
    d.polygon([(8, 1), (12, 6), (11, 10), (8, 14), (4, 12), (3, 8), (6, 5), (6, 9)], fill=RED_HI)
    d.polygon([(8, 6), (10, 9), (8, 13), (6, 11)], fill=GOLD)


for name, draw in {
    "sword": sword, "shield": shield, "skull": skull, "coin": coin,
    "star": star, "heart": heart, "chest": chest, "shop": shop,
    "rope": rope, "book": book, "crown": crown, "trophy": trophy,
    "clock": clock, "globe": globe, "volume": volume, "mute": mute,
    "menu": menu, "play": play, "target": target, "bolt": bolt,
    "sparkle": sparkle, "poison": poison, "fire": fire,
}.items():
    icon(name, draw)

for name, pixels in {
    "particle_spark": [(1, 0), (1, 1), (0, 1), (2, 1), (1, 2)],
    "particle_chunk": [(0, 0), (1, 0), (0, 1), (1, 1), (2, 2)],
    "particle_ember": [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2), (1, 3)],
    "particle_poison": [(0, 0), (1, 0), (0, 1), (1, 1), (2, 1), (1, 2)],
}.items():
    particle = Image.new("RGBA", (4, 4))
    for x, y in pixels:
        particle.putpixel((x, y), (255, 255, 255, 255))
    save(particle, name)


print("Generated pixel UI frames, scrollbars, bars, floor, icons and VFX particles.")
