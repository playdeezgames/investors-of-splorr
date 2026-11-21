# Art credits

Which art is whose. The itch page and the in-game credits (task 112) draw from this list.

## Made by Claude (AI-made)

Drawn as ASCII pixel maps in [`tools/make_claude_art.py`](tools/make_claude_art.py), which writes `assets/claude/claude_16x16.png` (white on transparent, tinted at draw time like the CC0 sheets). Cell order is the order below.

| Cell | Sprite | Where it appears |
|---|---|---|
| 0 | Torch | Shop menu, next to the Torch opportunity |
| 1 | Potion | Shop menu, next to the Heal opportunity |
| 2 | Speech bubble | Shop menu, next to the Tip opportunity |
| 3 | Sun | Ending screen (Peace of Mind) |
| 4 | Stack of coins | Title screen |

Add a row here whenever Claude makes another piece (title art, the cover, screenshots' framing, extra tiles).

All code, level design, dialogue and sound are also Claude's work, directed by the human developer.

## Not Claude's

- **Bit Bonanza by VEXED**, https://v3x3d.itch.io/bit-bonanza, CC0 1.0: the hero (People 15,4), the shopkeeper (People 0,2), the slime (Creatures 4,4), the imp (Creatures 9,5), the skull (Creatures 7,15), the hearts (UI 9,9 and 11,9), the coin (UI 3,9) and the gem (Gems-Jewels-and-Money 0,0).
- **Bountiful Bits by VEXED**, https://v3x3d.itch.io/bountiful-bits, CC0 1.0: the wall (Civilized 5,20, its brick pattern repeated to fill a 16 px cell), the door (Civilized 2,1) and the exit ladder (Civilized 11,13).
- `tools/make_cc0_art.py` builds the game's two sheets from the copies in `assets/cc0/src/`; licence record: `assets/cc0/LICENSE-RECORD.txt`. Tinted to two colours at draw time.
- **DINOBYTE by mby**, CC BY 4.0: the text font. Licence: `assets/font/dbyte-LICENSE.txt`.

Until November 21, 2026 (the jam build) the non-Claude sprites were 1-Bit Kingdom by Vryell, which may not be redistributed; they were replaced by the CC0 tiles above so the source could be public.
