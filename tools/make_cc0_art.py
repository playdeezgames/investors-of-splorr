#!/usr/bin/env python3
"""Build the game's sprite sheets from CC0 art. Needs Pillow. Run from the repo root.

Sources (CC0 1.0, by VEXED; white ink on transparent; 10 by 10 tiles) are in assets/cc0/src/:
  Bit Bonanza      https://v3x3d.itch.io/bit-bonanza    (People, Creatures, UI, Gems-Jewels-and-Money)
  Bountiful Bits   https://v3x3d.itch.io/bountiful-bits (Civilized-no-bg)

Writes:
  assets/cc0/sprites_16x16.png  one row of 16 by 16 cells, in CELLS order (the 10 px sprite centred,
                                 except the wall, which is the brick pattern repeated to fill the cell)
  assets/cc0/shop_32x32.png     the shopkeeper: a Bit Bonanza person, centred on his tile (kept in a 32 px cell so
                                 the draw call is unchanged)
The game tints both sheets at draw time, as before.
"""
from PIL import Image

SRC = "assets/cc0/src/"
T = 10

def tile(sheet, col, row):
    im = Image.open(SRC + sheet).convert("RGBA")
    return im.crop((col * T, row * T, col * T + T, row * T + T))

# (name, sheet, col, row). The order is the `Sprite` enum in src/web/web.odin.
CELLS = [
    ("hero",        "People.png",                 15, 4),
    ("heart",       "UI.png",                      9, 9),
    ("heart_empty", "UI.png",                     11, 9),
    ("coin",        "UI.png",                      3, 9),
    ("gem",         "Gems-Jewels-and-Money.png",   0, 0),
    ("slime",       "Creatures.png",               4, 4),
    ("imp",         "Creatures.png",               9, 5),
    ("skull",       "Creatures.png",               7, 15),
    ("wall",        "Civilized-no-bg.png",         5, 20),
    ("door",        "Civilized-no-bg.png",         2, 1),
    ("exit",        "Civilized-no-bg.png",        11, 13),
]
SHOP = ("People.png", 0, 2)

def wall_cell(t):
    # The brick tile has a blank last row and column; repeating its 9 by 9 core gives seamless courses.
    core = t.crop((0, 0, 9, 9))
    out = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(0, 16, 9):
        for x in range(0, 16, 9):
            out.alpha_composite(core, (x, y))
    return out

def build():
    sheet = Image.new("RGBA", (16 * len(CELLS), 16), (0, 0, 0, 0))
    for i, (name, src, c, r) in enumerate(CELLS):
        t = tile(src, c, r)
        cell = wall_cell(t) if name == "wall" else None
        if cell is None:
            cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
            cell.alpha_composite(t, (3, 3))
        sheet.alpha_composite(cell, (i * 16, 0))
    shop = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    shop.alpha_composite(tile(*SHOP), (11, 19))  # same size as everyone; on his tile (the cell is drawn 8 left, 16 up)
    return sheet, shop

if __name__ == "__main__":
    sheet, shop = build()
    sheet.save("assets/cc0/sprites_16x16.png")
    shop.save("assets/cc0/shop_32x32.png")
    print("wrote assets/cc0/sprites_16x16.png and shop_32x32.png")
