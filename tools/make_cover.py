#!/usr/bin/env python3
"""Draw assets/cover.png (630x500): black and white, from the game's own sheets and font.

Sprites: the CC0 sheets (Bit Bonanza and Bountiful Bits by VEXED, built by tools/make_cc0_art.py)
and the Claude-made sheet.
Font: DINOBYTE by mby (CC BY 4.0). Needs Pillow. Run from the repo root.
"""
from PIL import Image

W, H = 630, 500
font = Image.open("assets/font/dbyte_1x.png").convert("RGBA")
GW, GH = 6, 8

def sheet(path):
    im = Image.open(path).convert("RGBA")
    solid = Image.new("RGBA", im.size, (255, 255, 255, 0))
    solid.paste(Image.new("RGBA", im.size, (255, 255, 255, 255)), mask=im.split()[3])  # tint white
    return solid

def cell(im, col, row, size=16):
    return im.crop((col * size, row * size, col * size + size, row * size + size))

def text(img, x, y, s, k, centered=True):
    w = len(s) * GW * k
    px = (W - w) // 2 if centered else x
    for ch in s:
        c = ord(ch) & 255
        g = font.crop(((c % 16) * GW, (c // 16) * GH, (c % 16) * GW + GW, (c // 16) * GH + GH))
        mask = g.split()[3]
        white = Image.new("RGBA", g.size, (255, 255, 255, 255))
        glyph = Image.new("RGBA", g.size, (0, 0, 0, 0))
        glyph.paste(white, mask=mask)
        img.alpha_composite(glyph.resize((GW * k, GH * k), Image.NEAREST), (px, y))
        px += GW * k

art = sheet("assets/cc0/sprites_16x16.png")
shop = sheet("assets/cc0/shop_32x32.png")
mine = sheet("assets/claude/claude_16x16.png")

img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
text(img, 0, 36, "INVESTORS", 9)
text(img, 0, 120, "of SPLORR!!", 5)
text(img, 0, 184, "A dungeon of opportunities.", 2)

# The cast: hero, shopkeeper, coin, gem, slime, imp, skull, door, and the Claude-made sun.
k = 3
# Cells of sprites_16x16.png: 0 hero, 3 coin, 4 gem, 5 slime, 6 imp, 7 skull, 9 door.
row = [(art, 0, 0, 16), (shop, 0, 0, 32), (art, 3, 0, 16), (art, 4, 0, 16), (art, 5, 0, 16),
       (art, 6, 0, 16), (art, 7, 0, 16), (art, 9, 0, 16), (mine, 3, 0, 16)]
sizes = [s * k for *_, s in row]
gap = 10
x = (W - (sum(sizes) + gap * (len(row) - 1))) // 2
y = 370  # bottom edge of the row
for (im, col, r, s), size in zip(row, sizes):
    spr = cell(im, col, r, s).resize((size, size), Image.NEAREST)
    img.alpha_composite(spr, (x, y - size))
    x += size + gap

text(img, 0, 394, "A Metaphor in seven rooms", 2)
text(img, 0, 424, "Made with AI", 3)
text(img, 0, 462, "1-Bit Jam 15", 2)
img.convert("RGB").save("assets/cover.png")
print("assets/cover.png", img.size)
