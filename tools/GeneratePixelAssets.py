from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"

BG = "#16161a"
PANEL = "#1f1f27"
ACCENT = "#7f77dd"
FIRE = "#e2503a"
ICE = "#37c4dd"
LIGHTNING = "#efc127"
CURSE = "#7a3aa0"
COMMON = "#b4b2a9"
RARE = "#378add"
EPIC = "#7f77dd"
UNIQUE = "#ef9f27"
LEGENDARY = "#e24b4a"
INK = "#0a0a0d"
HILITE = "#f3ead2"


def rgba(color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    color = color.lstrip("#")
    return int(color[0:2], 16), int(color[2:4], 16), int(color[4:6], 16), alpha


def canvas(w: int, h: int, transparent: bool = True) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    fill = (0, 0, 0, 0) if transparent else rgba(BG)
    image = Image.new("RGBA", (w, h), fill)
    return image, ImageDraw.Draw(image)


def save(image: Image.Image, kind: str, name: str) -> None:
    if kind == "ui":
        image.putalpha(255)
    path = SPRITES / kind / f"{name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def rect(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], color: str, alpha: int = 255) -> None:
    draw.rectangle(xy, fill=rgba(color, alpha))


def polygon(draw: ImageDraw.ImageDraw, points: Iterable[tuple[int, int]], color: str, alpha: int = 255) -> None:
    draw.polygon(list(points), fill=rgba(color, alpha))


def line(draw: ImageDraw.ImageDraw, points: Iterable[tuple[int, int]], color: str, width: int = 1) -> None:
    draw.line(list(points), fill=rgba(color), width=width)


def bordered_rect(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], fill: str, border: str = INK) -> None:
    rect(draw, xy, border)
    x1, y1, x2, y2 = xy
    rect(draw, (x1 + 1, y1 + 1, x2 - 1, y2 - 1), fill)


def make_goblin() -> None:
    image, d = canvas(48, 48)
    rect(d, (18, 34, 31, 39), INK)
    rect(d, (16, 38, 21, 42), INK)
    rect(d, (28, 38, 33, 42), INK)
    polygon(d, [(14, 18), (9, 13), (15, 25)], INK)
    polygon(d, [(34, 18), (39, 13), (33, 25)], INK)
    polygon(d, [(14, 19), (10, 15), (15, 24)], "#5b8f38")
    polygon(d, [(34, 19), (38, 15), (33, 24)], "#5b8f38")
    bordered_rect(d, (15, 18, 33, 35), "#6fa944")
    rect(d, (16, 16, 32, 19), "#4c7134")
    rect(d, (16, 23, 20, 25), HILITE)
    rect(d, (28, 23, 32, 25), HILITE)
    rect(d, (18, 24, 20, 26), INK)
    rect(d, (28, 24, 30, 26), INK)
    rect(d, (22, 29, 26, 30), "#2d1a12")
    rect(d, (18, 34, 30, 38), "#6a3d24")
    rect(d, (15, 21, 16, 32), "#9dd36a")
    save(image, "enemies", "goblin")


def make_cave_bat() -> None:
    image, d = canvas(48, 48)
    polygon(d, [(4, 22), (17, 14), (22, 26), (14, 25), (9, 32)], INK)
    polygon(d, [(44, 22), (31, 14), (26, 26), (34, 25), (39, 32)], INK)
    polygon(d, [(6, 22), (17, 16), (21, 25), (14, 24), (10, 29)], "#543668")
    polygon(d, [(42, 22), (31, 16), (27, 25), (34, 24), (38, 29)], "#543668")
    bordered_rect(d, (19, 20, 29, 33), "#6d487e")
    rect(d, (19, 20, 22, 23), "#8a5aa0")
    rect(d, (26, 20, 29, 23), "#8a5aa0")
    rect(d, (20, 25, 21, 26), FIRE)
    rect(d, (27, 25, 28, 26), FIRE)
    rect(d, (23, 29, 25, 30), HILITE)
    save(image, "enemies", "cave_bat")


def make_orc_elite() -> None:
    image, d = canvas(64, 64)
    rect(d, (14, 16, 49, 50), ACCENT, 120)
    rect(d, (19, 47, 27, 55), INK)
    rect(d, (37, 47, 45, 55), INK)
    bordered_rect(d, (16, 26, 48, 48), "#466e35")
    bordered_rect(d, (20, 12, 44, 31), "#638d45")
    polygon(d, [(20, 18), (12, 13), (17, 24)], INK)
    polygon(d, [(44, 18), (52, 13), (47, 24)], INK)
    polygon(d, [(20, 18), (14, 15), (18, 23)], "#789e55")
    polygon(d, [(44, 18), (50, 15), (46, 23)], "#789e55")
    rect(d, (18, 7, 46, 13), "#4f4539")
    rect(d, (21, 6, 43, 8), COMMON)
    rect(d, (23, 21, 28, 23), HILITE)
    rect(d, (36, 21, 41, 23), HILITE)
    rect(d, (25, 22, 27, 24), INK)
    rect(d, (37, 22, 39, 24), INK)
    rect(d, (27, 36, 38, 38), INK)
    rect(d, (12, 31, 18, 43), "#7c5b38")
    rect(d, (46, 28, 52, 43), "#7c5b38")
    rect(d, (11, 30, 13, 45), COMMON)
    save(image, "enemies", "orc_elite")


def make_dragon_boss() -> None:
    image, d = canvas(96, 96)
    polygon(d, [(7, 31), (28, 14), (39, 48), (20, 45), (10, 62)], INK)
    polygon(d, [(89, 31), (68, 14), (57, 48), (76, 45), (86, 62)], INK)
    polygon(d, [(10, 32), (28, 17), (36, 45), (21, 42), (12, 55)], "#552d3d")
    polygon(d, [(86, 32), (68, 17), (60, 45), (75, 42), (84, 55)], "#552d3d")
    bordered_rect(d, (29, 34, 67, 74), "#7f2c28")
    bordered_rect(d, (34, 19, 62, 45), "#9a332c")
    polygon(d, [(38, 18), (42, 8), (46, 19)], LEGENDARY)
    polygon(d, [(50, 19), (55, 7), (58, 21)], LEGENDARY)
    rect(d, (38, 29, 44, 31), LIGHTNING)
    rect(d, (52, 29, 58, 31), LIGHTNING)
    rect(d, (40, 30, 43, 33), INK)
    rect(d, (53, 30, 56, 33), INK)
    rect(d, (42, 38, 54, 40), INK)
    for y in range(48, 70, 7):
        rect(d, (36, y, 42, y + 3), "#b94a3c")
        rect(d, (47, y, 53, y + 3), "#b94a3c")
        rect(d, (58, y, 62, y + 3), "#b94a3c")
    polygon(d, [(66, 65), (88, 78), (75, 82)], INK)
    polygon(d, [(67, 65), (84, 77), (74, 79)], "#8a302c")
    rect(d, (31, 75, 40, 83), INK)
    rect(d, (55, 75, 64, 83), INK)
    save(image, "enemies", "dragon_boss")


def make_relics() -> None:
    specs = [
        ("reroll_charm", RARE, [(10, 8, 22, 20), (8, 18, 24, 26)]),
        ("steel_scale", COMMON, [(9, 6, 23, 25)]),
        ("ember_core", FIRE, [(8, 7, 24, 25)]),
        ("life_rune", "#58bd70", [(8, 6, 24, 25)]),
    ]
    for name, color, boxes in specs:
        image, d = canvas(32, 32)
        for box in boxes:
            bordered_rect(d, box, color)
        if name == "reroll_charm":
            rect(d, (14, 4, 17, 8), COMMON)
            line(d, [(12, 15), (16, 11), (21, 14)], HILITE)
            line(d, [(21, 14), (19, 11)], HILITE)
            line(d, [(20, 18), (16, 22), (11, 19)], HILITE)
            line(d, [(11, 19), (13, 22)], HILITE)
        elif name == "steel_scale":
            rect(d, (12, 10, 20, 20), "#727a82")
            line(d, [(11, 12), (20, 21)], HILITE)
            line(d, [(22, 9), (24, 6)], ICE)
        elif name == "ember_core":
            rect(d, (12, 11, 20, 21), UNIQUE)
            rect(d, (14, 13, 18, 19), LIGHTNING)
            rect(d, (10, 6, 12, 9), FIRE, 180)
        elif name == "life_rune":
            line(d, [(16, 9), (16, 22)], HILITE)
            line(d, [(11, 16), (21, 16)], HILITE)
            rect(d, (13, 13, 19, 19), "#8ff0a1", 180)
        save(image, "relics", name)


def make_intents() -> None:
    for name in ["charge", "snipe", "explode", "reinforce", "summon"]:
        image, d = canvas(16, 16)
        if name == "charge":
            polygon(d, [(8, 1), (11, 11), (8, 14), (5, 11)], INK)
            polygon(d, [(8, 2), (10, 10), (8, 13), (6, 10)], HILITE)
            rect(d, (7, 4, 9, 11), FIRE)
        elif name == "snipe":
            rect(d, (2, 7, 13, 8), UNIQUE)
            rect(d, (7, 2, 8, 13), UNIQUE)
            rect(d, (5, 5, 10, 10), INK)
            rect(d, (6, 6, 9, 9), HILITE)
        elif name == "explode":
            polygon(d, [(8, 1), (10, 6), (15, 7), (11, 10), (12, 15), (8, 12), (4, 15), (5, 10), (1, 7), (6, 6)], FIRE)
            rect(d, (7, 6, 9, 9), LIGHTNING)
        elif name == "reinforce":
            polygon(d, [(3, 3), (13, 3), (12, 10), (8, 14), (4, 10)], INK)
            polygon(d, [(4, 4), (12, 4), (11, 9), (8, 12), (5, 9)], RARE)
            rect(d, (7, 5, 8, 10), HILITE)
        elif name == "summon":
            rect(d, (3, 11, 12, 13), CURSE)
            rect(d, (4, 8, 5, 10), ACCENT)
            rect(d, (8, 5, 9, 10), ACCENT)
            rect(d, (11, 8, 12, 10), ACCENT)
            rect(d, (6, 3, 10, 4), HILITE)
        save(image, "intents", name)


def make_faces() -> None:
    for name in ["fire", "ice", "lightning", "curse", "reroll"]:
        image, d = canvas(16, 16)
        if name == "fire":
            polygon(d, [(8, 1), (12, 6), (11, 13), (5, 14), (3, 8), (6, 5)], FIRE)
            polygon(d, [(8, 5), (10, 9), (8, 12), (6, 9)], LIGHTNING)
        elif name == "ice":
            polygon(d, [(8, 1), (13, 8), (8, 15), (3, 8)], ICE)
            line(d, [(8, 3), (8, 13)], HILITE)
            line(d, [(5, 8), (11, 8)], HILITE)
        elif name == "lightning":
            polygon(d, [(9, 1), (4, 9), (8, 9), (6, 15), (13, 6), (9, 6)], LIGHTNING)
            rect(d, (8, 2, 9, 4), HILITE)
        elif name == "curse":
            rect(d, (5, 3, 10, 12), CURSE)
            rect(d, (4, 5, 11, 10), CURSE)
            rect(d, (6, 6, 7, 7), HILITE)
            rect(d, (9, 8, 10, 9), HILITE)
        elif name == "reroll":
            line(d, [(4, 5), (7, 2), (11, 4), (12, 8)], ACCENT, 2)
            line(d, [(12, 8), (10, 7)], ACCENT)
            line(d, [(12, 11), (9, 14), (5, 12), (4, 8)], ACCENT, 2)
            line(d, [(4, 8), (6, 9)], ACCENT)
        save(image, "faces", name)


def make_dice() -> None:
    for name, color in [("basic_attack", UNIQUE), ("basic_defense", RARE), ("basic_skill", EPIC)]:
        image, d = canvas(32, 32)
        polygon(d, [(7, 5), (24, 5), (28, 10), (28, 25), (23, 28), (7, 28), (4, 24), (4, 10)], INK)
        polygon(d, [(8, 6), (23, 6), (27, 11), (27, 24), (22, 27), (8, 27), (5, 23), (5, 11)], color)
        rect(d, (8, 8, 22, 11), HILITE, 120)
        rect(d, (22, 12, 25, 23), "#000000", 45)
        if name == "basic_attack":
            polygon(d, [(16, 10), (20, 16), (18, 22), (12, 22), (10, 16)], FIRE)
        elif name == "basic_defense":
            polygon(d, [(10, 10), (22, 10), (21, 19), (16, 24), (11, 19)], ICE)
        else:
            rect(d, (11, 11, 21, 21), ACCENT)
            rect(d, (13, 13, 19, 19), "#a69cff")
            rect(d, (6, 6, 25, 25), ACCENT, 60)
        save(image, "dice", name)


def make_map_icons() -> None:
    image, d = canvas(32, 32)
    polygon(d, [(18, 3), (22, 7), (17, 20), (21, 24), (18, 27), (14, 23), (8, 27), (5, 24), (12, 18)], INK)
    polygon(d, [(18, 5), (20, 7), (15, 21), (12, 18)], HILITE)
    rect(d, (10, 19, 19, 22), UNIQUE)
    rect(d, (7, 23, 12, 25), COMMON)
    save(image, "map", "node_battle")

    image, d = canvas(32, 32)
    bordered_rect(d, (7, 7, 24, 22), COMMON)
    rect(d, (5, 11, 8, 17), INK)
    rect(d, (23, 11, 26, 17), INK)
    rect(d, (10, 12, 13, 15), INK)
    rect(d, (18, 12, 21, 15), INK)
    polygon(d, [(13, 18), (16, 16), (19, 18), (18, 21), (14, 21)], INK)
    rect(d, (9, 22, 22, 26), INK)
    rect(d, (11, 22, 13, 24), HILITE)
    rect(d, (15, 22, 17, 24), HILITE)
    rect(d, (19, 22, 21, 24), HILITE)
    save(image, "map", "node_elite")

    image, d = canvas(32, 32)
    rect(d, (7, 24, 24, 27), INK)
    line(d, [(8, 25), (23, 20)], "#6a3d24", 3)
    line(d, [(9, 20), (23, 25)], "#7c4a2d", 3)
    polygon(d, [(16, 4), (23, 13), (21, 23), (10, 23), (7, 15), (12, 10)], INK)
    polygon(d, [(16, 6), (21, 14), (19, 21), (12, 21), (9, 15), (13, 11)], FIRE)
    polygon(d, [(16, 11), (19, 16), (17, 21), (13, 20), (12, 16)], LIGHTNING)
    save(image, "map", "node_rest")

    image, d = canvas(32, 32)
    rect(d, (6, 6, 25, 20), INK)
    rect(d, (8, 8, 23, 18), UNIQUE)
    rect(d, (10, 10, 21, 12), HILITE)
    rect(d, (14, 20, 17, 28), INK)
    rect(d, (15, 20, 16, 27), COMMON)
    polygon(d, [(9, 19), (23, 19), (21, 25), (11, 25)], INK)
    polygon(d, [(11, 20), (21, 20), (19, 23), (13, 23)], "#8f6b32")
    save(image, "map", "node_shop")

    image, d = canvas(32, 32)
    polygon(d, [(4, 9), (10, 15), (15, 7), (21, 15), (27, 9), (24, 24), (7, 24)], INK)
    polygon(d, [(6, 11), (11, 17), (15, 10), (20, 17), (25, 11), (22, 22), (9, 22)], LIGHTNING)
    rect(d, (9, 18, 22, 21), UNIQUE)
    rect(d, (13, 13, 17, 17), HILITE)
    save(image, "map", "node_boss")

    image, d = canvas(40, 40)
    d.ellipse((3, 3, 36, 36), fill=rgba(INK))
    d.ellipse((6, 6, 33, 33), fill=rgba("#343440"))
    d.ellipse((10, 10, 29, 29), fill=rgba(PANEL))
    save(image, "map", "node_frame")

    image, d = canvas(48, 48)
    d.ellipse((3, 3, 44, 44), outline=rgba(INK), width=3)
    d.ellipse((6, 6, 41, 41), outline=rgba(ACCENT), width=2)
    for x, y in [(22, 1), (22, 44), (1, 22), (44, 22), (7, 7), (38, 7), (7, 38), (38, 38)]:
        rect(d, (x, y, x + 3, y + 3), HILITE)
    save(image, "map", "node_ring")

    image, d = canvas(8, 8)
    rect(d, (1, 1, 6, 6), INK)
    rect(d, (2, 2, 5, 5), ACCENT)
    save(image, "map", "path_dot")


def make_backgrounds() -> None:
    for name in ["bg_battle", "bg_map", "bg_menu"]:
        image, d = canvas(320, 180, transparent=False)
        for y in range(180):
            shade = 22 + y // 18
            d.line([(0, y), (319, y)], fill=(shade, shade, shade + 7, 255))
        if name == "bg_battle":
            rect(d, (0, 124, 319, 179), PANEL)
            for x in range(0, 320, 28):
                rect(d, (x, 128 + (x // 28) % 3, x + 21, 133 + (x // 28) % 3), "#2b2730")
            polygon(d, [(20, 121), (92, 74), (145, 122)], "#24222b")
            polygon(d, [(130, 122), (216, 59), (300, 123)], "#292632")
            rect(d, (0, 122, 319, 124), ACCENT, 90)
        elif name == "bg_map":
            polygon(d, [(0, 134), (48, 91), (91, 127), (142, 69), (196, 126), (255, 82), (319, 128), (319, 179), (0, 179)], "#20202a")
            polygon(d, [(0, 151), (68, 112), (121, 151), (184, 102), (238, 147), (287, 115), (319, 139), (319, 179), (0, 179)], "#292834")
            for x, y in [(28, 31), (76, 54), (126, 24), (181, 45), (235, 27), (286, 59)]:
                rect(d, (x, y, x + 1, y + 1), ACCENT, 110)
            rect(d, (0, 153, 319, 179), PANEL)
        elif name == "bg_menu":
            rect(d, (98, 45, 221, 124), PANEL)
            rect(d, (103, 50, 216, 119), "#272633")
            for x, y, c in [(130, 68, UNIQUE), (166, 59, RARE), (188, 88, EPIC)]:
                polygon(d, [(x, y), (x + 18, y + 6), (x + 14, y + 24), (x - 4, y + 20)], c)
            rect(d, (0, 143, 319, 179), "#141418")
        save(image, "ui", name)


def main() -> None:
    make_goblin()
    make_cave_bat()
    make_orc_elite()
    make_dragon_boss()
    make_relics()
    make_intents()
    make_faces()
    make_dice()
    make_map_icons()
    make_backgrounds()


if __name__ == "__main__":
    main()
