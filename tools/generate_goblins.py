#!/usr/bin/env python3
"""Draw the eight goblin ranks and 31 collectible portraits with Pillow.

Every mark is placed directly on an integer pixel grid. No resize, blur,
antialiasing, or color quantization is used to make the shipped PNGs.
"""

from pathlib import Path
import json
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
GOBLINS = ROOT / "assets/sprites/goblins"
VARIANTS = ROOT / "assets/sprites/variants"
ANIMATED = ROOT / "assets/sprites/animated"
ANIMATED.mkdir(exist_ok=True)
MANIFEST = json.loads((ROOT / "assets/sprites/variants_manifest.json").read_text())

INK = "#100e13"
WHITE = "#f1dfb3"
GOLD = "#f5c65a"
BRONZE = "#96602d"
IRON = "#75838b"
IRON_LIT = "#b0c0ba"
RED = "#d64d3a"
BLUE = "#48afc1"
VIOLET = "#9e6bc4"


def tone(color: str, mul: float) -> tuple[int, int, int]:
    rgb = tuple(bytes.fromhex(color.lstrip("#")))
    return tuple(max(0, min(255, round(c * mul))) for c in rgb)


def portrait(skin: str, cloth: str, accent: str, role: str, *,
             eye: str = GOLD, small: bool = False) -> Image.Image:
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    dark_skin = tone(skin, .55)
    shadow_skin = tone(skin, .75)
    lit_skin = tone(skin, 1.25)
    dark_cloth = tone(cloth, .55)
    light_cloth = tone(cloth, 1.2)

    # Stable bust anchor; equipment changes the silhouette of each rank.
    d.polygon([(0, 31), (2, 27), (8, 25), (12, 24), (20, 24), (24, 25), (29, 27), (31, 31)], fill=INK)
    d.polygon([(2, 31), (4, 28), (10, 26), (22, 26), (28, 28), (30, 31)], fill=dark_cloth)
    d.polygon([(4, 31), (7, 27), (14, 25), (18, 25), (25, 27), (28, 31)], fill=cloth)
    d.line((4, 30, 9, 27, 12, 27), fill=light_cloth)
    d.line((23, 27, 27, 30), fill=INK)
    d.rectangle((13, 25, 18, 29), fill=dark_skin)
    d.polygon([(1, 14), (9, 13), (9, 21), (4, 20)], fill=INK)
    d.polygon([(2, 15), (8, 15), (8, 20), (4, 19)], fill=shadow_skin)
    d.line((3, 16, 7, 17), fill=lit_skin)
    d.polygon([(23, 13), (30, 14), (28, 20), (23, 21)], fill=INK)
    d.polygon([(24, 15), (29, 15), (27, 19), (24, 20)], fill=shadow_skin)
    d.line((25, 17, 28, 16), fill=lit_skin)

    # Angular face, fixed 3/4 top-left light and clustered shadow planes.
    d.polygon([(9, 5), (14, 3), (21, 4), (25, 8), (26, 17), (23, 24),
               (19, 28), (13, 28), (9, 24), (6, 17), (7, 9)], fill=INK)
    d.polygon([(10, 6), (14, 5), (20, 5), (24, 9), (24, 17), (21, 24),
               (18, 26), (13, 26), (10, 23), (8, 17), (9, 9)], fill=skin)
    d.polygon([(20, 6), (24, 9), (24, 17), (21, 24), (18, 26),
               (17, 22), (21, 16)], fill=shadow_skin)
    d.line((9, 10, 12, 7, 17, 6), fill=lit_skin)
    d.line((9, 12, 8, 17, 10, 21), fill=lit_skin)
    d.rectangle((11, 7, 13, 8), fill=lit_skin)
    d.rectangle((16, 7, 19, 8), fill=lit_skin)
    d.point((22, 12), fill=dark_skin)

    # Bold brow and bright eyes remain legible at the 4x4 board size.
    d.line((9, 13, 13, 12), fill=dark_skin, width=2)
    d.line((18, 12, 22, 13), fill=dark_skin, width=2)
    d.rectangle((10, 14, 13, 16), fill=INK)
    d.rectangle((18, 14, 21, 16), fill=INK)
    d.rectangle((11, 14, 12, 15), fill=eye)
    d.rectangle((19, 14, 20, 15), fill=eye)
    d.point((11, 14), fill=WHITE)
    d.point((19, 14), fill=WHITE)
    d.polygon([(14, 17), (17, 17), (19, 21), (14, 21)], fill=dark_skin)
    d.line((14, 18, 16, 18), fill=lit_skin)
    d.rectangle((12, 22, 20, 24), fill=INK)
    d.line((13, 22, 19, 22), fill=WHITE)
    d.point((15, 23), fill=WHITE)
    d.point((18, 23), fill=WHITE)

    # Equipment is composed as hand-placed clusters; no filtering or scaled
    # source portraits. Each role changes a recognisable area of the silhouette.
    if role in {"raider", "bandit", "dancer", "psycho"}:
        d.polygon([(8, 9), (10, 6), (22, 6), (24, 9), (23, 11), (9, 11)], fill=INK)
        d.line((9, 9, 22, 9), fill=accent, width=2)
        d.point((15, 8), fill=WHITE)
    if role in {"guard", "knight", "champion", "mechanical", "postapoc"}:
        d.polygon([(7, 12), (7, 7), (11, 3), (20, 2), (24, 6), (25, 12),
                   (22, 11), (21, 7), (11, 7), (10, 11)], fill=INK)
        d.polygon([(9, 8), (12, 4), (20, 4), (23, 7), (22, 10), (20, 7),
                   (11, 7), (10, 10)], fill=IRON)
        d.line((11, 5, 19, 5), fill=IRON_LIT)
        d.rectangle((15, 3, 17, 8), fill=accent)
        d.rectangle((3, 27, 8, 31), fill=IRON)
        d.rectangle((23, 27, 28, 31), fill=IRON)
    if role in {"brute", "monstrous", "werewolf"}:
        d.polygon([(8, 7), (4, 1), (5, 10), (8, 12)], fill=INK)
        d.polygon([(7, 8), (5, 4), (6, 9)], fill=WHITE)
        d.polygon([(23, 7), (28, 1), (27, 10), (24, 12)], fill=INK)
        d.polygon([(25, 8), (27, 4), (26, 9)], fill=WHITE)
        d.rectangle((3, 27, 9, 30), fill=cloth)
        d.rectangle((22, 27, 28, 30), fill=cloth)
    if role in {"shaman", "mystical", "ritual", "posessed"}:
        d.polygon([(5, 9), (13, 1), (20, 1), (27, 9), (23, 10), (9, 10)], fill=INK)
        d.polygon([(8, 8), (14, 2), (19, 2), (24, 8)], fill=cloth)
        d.rectangle((15, 3, 17, 6), fill=accent)
        d.point((16, 4), fill=WHITE)
        d.line((3, 29, 5, 19), fill=BRONZE, width=2)
        d.ellipse((3, 17, 6, 20), fill=accent)
    if role in {"warlord", "king", "valkyrie", "gold"}:
        d.polygon([(4, 9), (6, 3), (9, 7), (15, 2), (19, 7), (26, 3),
                   (28, 9), (23, 11), (8, 11)], fill=INK)
        d.polygon([(6, 8), (7, 5), (10, 9), (15, 4), (19, 9), (25, 5),
                   (26, 8), (23, 10), (8, 10)], fill=accent)
        d.rectangle((14, 7, 17, 9), fill=RED)
        d.point((15, 7), fill=WHITE)
    if role in {"hood", "traveler", "sneaky", "cave", "undead"}:
        d.polygon([(5, 18), (6, 7), (13, 2), (20, 2), (26, 8), (27, 19),
                   (24, 18), (23, 9), (20, 5), (13, 5), (9, 10), (8, 18)], fill=INK)
        d.line((6, 16, 8, 8, 13, 4, 19, 4), fill=cloth, width=2)
        d.line((24, 9, 26, 17), fill=dark_cloth, width=2)
    if role in {"merchant", "barman", "houndmaster"}:
        d.polygon([(6, 7), (10, 3), (21, 3), (26, 7), (24, 9), (7, 9)], fill=INK)
        d.polygon([(8, 7), (11, 4), (20, 4), (24, 7)], fill=cloth)
        d.line((4, 27, 8, 26), fill=accent, width=2)
        d.ellipse((3, 26, 7, 30), fill=accent)
    if role in {"bard", "cosplay", "fanart", "oc"}:
        d.polygon([(6, 8), (10, 4), (22, 4), (26, 8), (23, 10), (8, 10)], fill=INK)
        d.polygon([(9, 7), (11, 5), (21, 5), (24, 8), (22, 9), (9, 9)], fill=cloth)
        d.line((22, 6, 26, 1), fill=accent, width=2)
        d.point((27, 1), fill=WHITE)
    if role in {"fire", "halloween"}:
        d.polygon([(6, 9), (8, 3), (10, 6), (15, 1), (19, 6), (23, 2),
                   (26, 9), (23, 11), (8, 11)], fill=INK)
        d.polygon([(8, 8), (9, 5), (11, 8), (15, 3), (18, 8), (22, 5),
                   (24, 8), (22, 10), (9, 10)], fill=accent)
        d.point((15, 5), fill=GOLD)
    if role in {"mutant", "dangerous"}:
        d.line((10, 18, 13, 20), fill=RED, width=2)
        d.line((20, 18, 22, 21), fill=RED, width=2)
        d.rectangle((15, 9, 17, 10), fill=eye)
    if role == "mechanical":
        d.rectangle((18, 14, 22, 17), fill=BLUE)
        d.line((20, 12, 26, 12), fill=IRON_LIT)
    if role == "sneaky":
        d.rectangle((9, 17, 22, 19), fill=cloth)
        d.line((10, 17, 21, 17), fill=accent)
    if role == "undead":
        d.point((11, 14), fill=RED)
        d.line((10, 20, 13, 21), fill=dark_skin)
    if role == "werewolf":
        d.rectangle((12, 23, 13, 25), fill=WHITE)
        d.rectangle((19, 23, 20, 25), fill=WHITE)
    if role == "barman":
        d.rectangle((11, 27, 21, 31), fill=WHITE)
        d.rectangle((13, 29, 19, 31), fill=cloth)
    if role == "houndmaster":
        d.line((19, 24, 23, 25), fill=GOLD, width=2)
    if role == "postapoc":
        d.rectangle((9, 13, 22, 17), fill=INK)
        d.rectangle((10, 14, 14, 16), fill=BLUE)
        d.rectangle((18, 14, 21, 16), fill=BLUE)
    if role == "halloween":
        d.ellipse((8, 10, 24, 26), fill=INK)
        d.ellipse((9, 11, 23, 25), fill="#cf7a2a")
        d.line((15, 12, 15, 24), fill="#ab5728")
        d.polygon([(11, 16), (14, 14), (14, 18)], fill=INK)
        d.polygon([(21, 16), (18, 14), (18, 18)], fill=INK)
        d.line((12, 21, 15, 23, 18, 21, 21, 22), fill=INK, width=2)
    if role == "psycho":
        d.line((10, 21, 21, 21), fill=RED)
    if role == "gold":
        d.point((5, 27), fill=GOLD)
        d.point((26, 27), fill=GOLD)

    # Rank costumes deliberately use large clusters rather than small recolors.
    if role == "rank_bandit":
        # Deep red hood, pointed crown and face wrap: clearly unlike the bare 2.
        d.polygon([(4, 19), (5, 8), (12, 1), (20, 1), (27, 8), (28, 21),
                   (23, 25), (22, 10), (18, 6), (13, 6), (9, 11), (9, 24)], fill=INK)
        d.polygon([(6, 18), (7, 8), (13, 2), (19, 2), (25, 8), (26, 19),
                   (24, 20), (22, 9), (18, 5), (13, 5), (9, 10), (8, 19)], fill=RED)
        d.line((8, 8, 13, 3, 18, 3), fill="#f18a57")
        d.polygon([(9, 20), (14, 22), (22, 19), (21, 25), (16, 28), (11, 25)], fill=INK)
        d.polygon([(10, 21), (15, 23), (21, 21), (20, 25), (16, 26), (12, 24)], fill=RED)
    if role == "rank_brute":
        # Broad bone horns, massive tusks and orange hide, no metal helmet.
        d.polygon([(8, 11), (3, 8), (1, 2), (4, 3), (7, 6), (11, 7)], fill=INK)
        d.polygon([(7, 9), (4, 7), (3, 4), (7, 7), (9, 8)], fill=WHITE)
        d.polygon([(22, 11), (28, 8), (30, 2), (27, 3), (23, 6), (20, 7)], fill=INK)
        d.polygon([(24, 9), (27, 7), (28, 4), (24, 7), (22, 8)], fill=WHITE)
        d.rectangle((11, 21, 13, 26), fill=INK)
        d.rectangle((19, 21, 21, 26), fill=INK)
        d.rectangle((12, 21, 13, 24), fill=WHITE)
        d.rectangle((19, 21, 20, 24), fill=WHITE)
        d.polygon([(1, 30), (4, 24), (10, 25), (12, 31)], fill=INK)
        d.polygon([(3, 30), (5, 26), (9, 27), (10, 31)], fill=cloth)
        d.polygon([(20, 31), (22, 25), (28, 24), (31, 30)], fill=INK)
        d.polygon([(22, 31), (23, 27), (27, 26), (29, 30)], fill=cloth)
    if role == "rank_champion":
        # Closed crimson greathelm and high crest: a solid, square silhouette.
        d.polygon([(12, 6), (12, 2), (16, 0), (20, 2), (20, 7)], fill=INK)
        d.rectangle((14, 2, 18, 6), fill=RED)
        d.line((14, 2, 17, 1), fill="#f18a57")
        d.polygon([(7, 7), (11, 5), (22, 5), (25, 8), (25, 23),
                   (21, 27), (11, 27), (7, 23)], fill=INK)
        d.polygon([(9, 8), (12, 7), (21, 7), (23, 9), (23, 22),
                   (20, 25), (12, 25), (9, 22)], fill="#9b363f")
        d.rectangle((10, 8, 13, 22), fill=RED)
        d.line((11, 8, 20, 8), fill="#f18a57")
        d.rectangle((9, 13, 23, 17), fill=INK)
        d.line((10, 14, 13, 14), fill=GOLD)
        d.line((19, 14, 22, 14), fill=GOLD)
        d.rectangle((15, 8, 17, 23), fill=BRONZE)
        d.point((16, 9), fill=GOLD)
        d.rectangle((3, 26, 9, 31), fill=INK)
        d.rectangle((22, 26, 28, 31), fill=INK)
        d.rectangle((4, 27, 8, 31), fill=RED)
        d.rectangle((23, 27, 27, 31), fill=RED)

    if small:
        # Pixel size stays 1: the tiny variant is drawn on the same grid.
        # Remove outer shoulder fragments to make its bust more compact.
        for x in range(0, 5):
            for y in range(27, 32):
                im.putpixel((x, y), (0, 0, 0, 0))
        for x in range(27, 32):
            for y in range(27, 32):
                im.putpixel((x, y), (0, 0, 0, 0))
    return im


RANKS = [
    (2,   "#a1c958", "#5c4634", BRONZE, "scout", GOLD),
    (4,   "#76a34b", "#973d39", RED, "rank_bandit", GOLD),
    (8,   "#6fa342", "#69747c", IRON_LIT, "guard", GOLD),
    (16,  "#53a18a", "#bd783e", WHITE, "rank_brute", RED),
    (32,  "#7b9a3e", "#722e39", RED, "rank_champion", RED),
    (64,  "#71ad75", "#463959", VIOLET, "shaman", BLUE),
    (128, "#497e3c", "#5b3740", RED, "warlord", RED),
    (256, "#8aba48", "#735a2e", GOLD, "king", GOLD),
]


def idle_frames(sprite: Image.Image, skin: str, role: str) -> list[Image.Image]:
    # Six source-grid frames: rest, rest, one-pixel breath, rest, blink, rest.
    breath = Image.new("RGBA", (32, 32))
    breath.alpha_composite(sprite, (0, -1))
    blink = sprite.copy()
    if role == "rank_champion":
        d = ImageDraw.Draw(blink)
        d.line((10, 14, 13, 14), fill=BRONZE)
        d.line((19, 14, 22, 14), fill=BRONZE)
    elif role not in {"halloween", "postapoc"}:
        d = ImageDraw.Draw(blink)
        d.rectangle((10, 14, 13, 16), fill=tone(skin, .55))
        d.rectangle((18, 14, 21, 16), fill=tone(skin, .55))
        d.line((10, 15, 13, 15), fill=GOLD)
        d.line((18, 15, 21, 15), fill=GOLD)
    return [sprite, sprite.copy(), breath, sprite.copy(), blink, sprite.copy()]


def save_sheet(frames: list[Image.Image], path: Path) -> None:
    width, height = frames[0].size
    sheet = Image.new("RGBA", (width * len(frames), height))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * width, 0))
    sheet.save(path, optimize=True)


for value, skin, cloth, accent, role, eye in RANKS:
    sprite = portrait(skin, cloth, accent, role, eye=eye)
    sprite.save(GOBLINS / f"goblin-{value}.png", optimize=True)
    save_sheet(idle_frames(sprite, skin, role), ANIMATED / f"goblin-{value}.png")


# Named variants keep their source filenames and gameplay metadata. Color and
# equipment describe the name; the stone frame belongs to the same UI family.
DESIGNS = [
    ("#79ae42", "#5b453b", GOLD, "raider"),
    ("#75a346", "#697983", IRON_LIT, "knight"),
    ("#92ad49", "#754e34", GOLD, "merchant"),
    ("#80a951", "#765078", VIOLET, "bard"),
    ("#90a894", "#484450", BLUE, "undead"),
    ("#6c9b4a", "#6e3545", RED, "psycho"),
    ("#8eb96d", "#656e86", WHITE, "valkyrie"),
    ("#709d54", "#6c6048", GOLD, "traveler"),
    ("#598b45", "#343746", BLUE, "sneaky"),
    ("#678b3c", "#613a40", RED, "dangerous"),
    ("#7b9c5b", "#6a7781", BLUE, "mechanical"),
    ("#79a74a", "#677683", IRON_LIT, "guard"),
    ("#b5d472", "#8d603d", GOLD, "raider"),
    ("#7da886", "#4b406e", VIOLET, "mystical"),
    ("#92b252", "#715e9d", GOLD, "cosplay"),
    ("#64934a", "#624947", RED, "bandit"),
    ("#57833e", "#4f3b42", RED, "monstrous"),
    ("#80a941", "#7c3b2d", RED, "fire"),
    ("#87a759", "#6f583c", GOLD, "barman"),
    ("#668c4b", "#4e463f", BRONZE, "cave"),
    ("#8c8f5b", "#5e483e", WHITE, "werewolf"),
    ("#69a04e", "#513b62", VIOLET, "mutant"),
    ("#758a4b", "#756047", RED, "postapoc"),
    ("#8cb55a", "#824c72", GOLD, "dancer"),
    ("#6b8a62", "#342d4b", VIOLET, "ritual"),
    ("#a4b35b", "#715335", GOLD, "gold"),
    ("#6d9c53", "#6a5143", GOLD, "houndmaster"),
    ("#789a79", "#443754", BLUE, "posessed"),
    ("#8dad60", "#6d4375", VIOLET, "fanart"),
    ("#6daa96", "#514776", BLUE, "oc"),
    ("#b2a04f", "#68452c", RED, "halloween"),
]
assert len(DESIGNS) == len(MANIFEST) == 31


def variant_card(sprite: Image.Image, accent: str, index: int) -> Image.Image:
    canvas = Image.new("RGBA", (38, 38))
    d = ImageDraw.Draw(canvas)
    d.rectangle((0, 0, 37, 37), fill=INK)
    d.rectangle((1, 1, 36, 36), outline=accent)
    d.rectangle((2, 2, 35, 35), fill="#211d24")
    d.line((3, 3, 33, 3), fill="#4a4145")
    if index == 13:
        canvas.alpha_composite(sprite.resize((22, 22), Image.Resampling.NEAREST), (8, 13))
    else:
        canvas.alpha_composite(sprite, (3, 3))
    return canvas


for index, (meta, (skin, cloth, accent, role)) in enumerate(zip(MANIFEST, DESIGNS), 1):
    sprite = portrait(skin, cloth, accent, role, eye=RED if role in {"undead", "psycho", "posessed"} else GOLD,
                      small=index == 13)
    card_frames = [variant_card(frame, accent, index) for frame in idle_frames(sprite, skin, role)]
    card_frames[0].save(VARIANTS / meta["file"], optimize=True)
    save_sheet(card_frames, ANIMATED / meta["file"])

print("Drew 8 ranks, 31 variants and six-frame idle sheets for all 39 goblins.")
