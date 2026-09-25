#!/usr/bin/env python3
"""Draw the seven shop items as one 32 px hand-pixelled equipment family."""

from pathlib import Path
from PIL import Image, ImageDraw


OUT = Path(__file__).resolve().parents[1] / "assets/sprites/items"
INK = "#100e13"
WHITE = "#fff1c9"
STEEL = "#879aa3"
STEEL_LIT = "#c6d1ca"
STEEL_DARK = "#4d6674"
GOLD = "#f5c65a"
BRONZE = "#976226"
WOOD = "#704734"
WOOD_LIT = "#ad7142"
RED = "#d64d3a"
RED_LIT = "#f07856"
GREEN = "#7eb443"
GREEN_DARK = "#3e7b4c"
BLUE = "#6cc3ce"
PAPER = "#dbc694"


def item(name, draw):
    image = Image.new("RGBA", (32, 32))
    draw(ImageDraw.Draw(image))
    image.save(OUT / f"item-{name}.png", optimize=True)


def sword(d):
    d.polygon([(5, 27), (10, 27), (25, 12), (29, 3), (20, 7), (5, 22)], fill=INK)
    d.polygon([(8, 24), (22, 10), (27, 5), (24, 13), (10, 26)], fill=STEEL)
    d.line((9, 23, 25, 7), fill=STEEL_LIT, width=2)
    d.line((12, 20, 23, 9), fill=WHITE)
    d.line((5, 20, 12, 27), fill=BRONZE, width=3)
    d.line((7, 26, 4, 29), fill=WOOD, width=3)
    d.point((4, 29), fill=GOLD)


def shield(d):
    d.polygon([(16, 2), (27, 6), (26, 20), (21, 27), (16, 30),
               (11, 27), (6, 20), (5, 6)], fill=INK)
    d.polygon([(16, 4), (25, 7), (24, 19), (20, 25), (16, 28),
               (12, 25), (8, 19), (7, 7)], fill=STEEL_DARK)
    d.polygon([(16, 5), (23, 8), (22, 18), (17, 25), (16, 26),
               (10, 19), (9, 8)], fill=STEEL)
    d.polygon([(10, 9), (16, 6), (16, 25), (11, 19)], fill=STEEL_LIT)
    d.polygon([(16, 10), (20, 15), (16, 21), (12, 15)], fill=INK)
    d.polygon([(16, 12), (18, 15), (16, 19), (14, 15)], fill=BLUE)
    for x, y in ((8, 8), (24, 8), (10, 21), (22, 21)):
        d.point((x, y), fill=GOLD)


def torch(d):
    d.line((9, 27, 21, 11), fill=INK, width=6)
    d.line((10, 26, 21, 11), fill=WOOD, width=4)
    d.line((11, 24, 20, 12), fill=WOOD_LIT, width=1)
    d.line((11, 25, 15, 27), fill=GOLD, width=2)
    d.polygon([(18, 17), (14, 12), (16, 7), (20, 3), (20, 8),
               (25, 2), (27, 10), (24, 17)], fill=INK)
    d.polygon([(18, 15), (16, 11), (19, 6), (21, 11), (25, 5),
               (25, 13), (22, 17)], fill=RED)
    d.polygon([(19, 14), (21, 8), (22, 11), (24, 10), (23, 15)], fill=GOLD)
    d.point((21, 13), fill=WHITE)


def vial(d, liquid, light):
    d.rectangle((13, 2, 19, 5), fill=INK)
    d.rectangle((14, 3, 18, 4), fill=WOOD)
    d.rectangle((14, 5, 18, 9), fill=STEEL_LIT)
    d.polygon([(13, 9), (19, 9), (23, 15), (24, 25), (21, 29),
               (11, 29), (8, 25), (9, 15)], fill=INK)
    d.polygon([(13, 10), (19, 10), (22, 16), (22, 25), (20, 27),
               (12, 27), (10, 25), (10, 16)], fill=BLUE)
    d.polygon([(11, 18), (21, 18), (22, 25), (20, 27), (12, 27), (10, 25)], fill=liquid)
    d.line((11, 17, 20, 17), fill=light)
    d.rectangle((11, 13, 12, 17), fill=WHITE)
    d.point((12, 22), fill=light)
    d.point((19, 24), fill=light)


def rope(d):
    d.ellipse((4, 3, 25, 25), fill=INK)
    d.ellipse((6, 5, 23, 23), fill=BRONZE)
    d.ellipse((9, 8, 20, 20), fill=INK)
    d.ellipse((10, 9, 19, 19), fill=GOLD)
    d.ellipse((12, 11, 17, 17), fill=INK)
    d.arc((7, 6, 22, 22), 220, 35, fill=WHITE, width=2)
    d.line((23, 20, 28, 27), fill=INK, width=5)
    d.line((23, 20, 27, 26), fill=GOLD, width=3)
    d.line((25, 25, 29, 26), fill=BRONZE, width=2)


def scroll(d):
    d.polygon([(5, 8), (8, 5), (24, 5), (27, 8), (27, 23),
               (24, 26), (8, 26), (5, 23)], fill=INK)
    d.rectangle((7, 7, 25, 24), fill=PAPER)
    d.line((9, 8, 22, 8), fill=WHITE)
    d.line((8, 24, 24, 24), fill=BRONZE)
    d.rectangle((4, 5, 8, 26), fill=BRONZE)
    d.rectangle((24, 5, 28, 26), fill=BRONZE)
    d.line((5, 7, 5, 23), fill=GOLD)
    d.line((25, 7, 25, 23), fill=GOLD)
    d.polygon([(14, 21), (11, 17), (13, 13), (16, 9), (17, 14),
               (20, 11), (21, 17), (18, 22)], fill=RED)
    d.polygon([(15, 19), (16, 14), (18, 17), (17, 21)], fill=GOLD)


item("sword", sword)
item("shield", shield)
item("torch", torch)
item("health-potion", lambda d: vial(d, RED, RED_LIT))
item("poison", lambda d: vial(d, GREEN_DARK, GREEN))
item("rope", rope)
item("fire-scroll", scroll)
print("Drew 7 new 32 px item sprites.")
