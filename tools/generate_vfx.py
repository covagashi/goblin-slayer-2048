#!/usr/bin/env python3
"""Draw six-frame, 16 px impact VFX strips on an integer pixel grid."""

from pathlib import Path
from PIL import Image, ImageDraw


OUT = Path(__file__).resolve().parents[1] / "assets/sprites/vfx"
OUT.mkdir(parents=True, exist_ok=True)
INK = "#100e13"
WHITE = "#fff1c9"
GOLD = "#f5c65a"
AMBER = "#db913a"
RED = "#e65d45"
GREEN = "#8bcc55"
DARK_GREEN = "#4c8d47"


def sprite(name, painter):
    sheet = Image.new("RGBA", (96, 16))
    for frame in range(6):
        im = Image.new("RGBA", (16, 16))
        painter(ImageDraw.Draw(im), frame)
        sheet.alpha_composite(im, (frame * 16, 0))
    sheet.save(OUT / f"{name}.png", optimize=True)


def impact(d, f):
    if f == 0:
        d.rectangle((7, 7, 8, 8), fill=WHITE)
    if f in (1, 2, 3):
        r = f + 1
        d.rectangle((8-r, 8-r, 7+r, 7+r), outline=GOLD, width=1)
        d.line((8, 1+f, 8, 4+f), fill=WHITE)
        d.line((8, 11-f, 8, 14-f), fill=WHITE)
        d.line((1+f, 8, 4+f, 8), fill=AMBER)
        d.line((11-f, 8, 14-f, 8), fill=AMBER)
    if f in (4, 5):
        for x, y in ((2, 3), (13, 3), (2, 12), (13, 12)):
            d.point((x, y), fill=AMBER if f == 5 else GOLD)


def slash(d, f):
    if f < 4:
        shift = f - 1
        d.line((3+shift, 12, 12+shift, 3), fill=INK, width=3)
        d.line((3+shift, 12, 12+shift, 3), fill=RED, width=2)
        d.line((4+shift, 11, 11+shift, 4), fill=WHITE)
        if f >= 2:
            d.point((3, 4), fill=RED)
            d.point((12, 12), fill=RED)
    elif f == 4:
        for x, y in ((3, 4), (5, 12), (12, 3), (13, 10)):
            d.rectangle((x, y, x+1, y+1), fill=RED)
    else:
        d.point((4, 11), fill=RED)
        d.point((12, 4), fill=RED)


def gold(d, f):
    if f < 5:
        r = [1, 3, 5, 3, 1][f]
        d.polygon([(8, 8-r), (9, 7), (8+r, 8), (9, 9),
                   (8, 8+r), (7, 9), (8-r, 8), (7, 7)], fill=GOLD)
        d.rectangle((7, 7, 8, 8), fill=WHITE)
        if f in (2, 3):
            d.point((2, 2), fill=AMBER)
            d.point((13, 12), fill=GOLD)
    else:
        d.point((2, 2), fill=AMBER)
        d.point((13, 12), fill=GOLD)


def poison(d, f):
    if f < 5:
        d.ellipse((5, 9-f//2, 10, 13-f//2), outline=DARK_GREEN, width=1)
        d.rectangle((6, 10-f//2, 8, 11-f//2), fill=GREEN)
        if f >= 1:
            d.rectangle((2+f//2, 8-f, 3+f//2, 9-f), fill=GREEN)
        if f >= 2:
            d.point((12, 10-f), fill=GREEN)
    else:
        d.point((4, 2), fill=GREEN)
        d.point((12, 5), fill=DARK_GREEN)


def flame(d, f):
    if f < 5:
        height = [3, 6, 9, 8, 5][f]
        d.polygon([(5, 14), (3, 10), (5, 8), (6, 10), (8, 14-height),
                   (10, 9), (12, 12), (10, 14)], fill=RED)
        d.polygon([(6, 13), (7, 9), (8, 11), (9, 8), (10, 13)], fill=GOLD)
        d.point((8, 12), fill=WHITE)
    else:
        d.point((6, 6), fill=RED)
        d.point((10, 9), fill=AMBER)


for name, painter in {"impact": impact, "slash": slash, "gold": gold,
                      "poison": poison, "flame": flame}.items():
    sprite(name, painter)

print("Drew 5 six-frame VFX strips (30 source frames).")
