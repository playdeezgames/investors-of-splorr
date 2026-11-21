# DESIGN.md

Title: **Investors of SPLORR!!** (decided October 26, 2026). Jam: [1-Bit Jam 15](https://itch.io/jam/1-bit-jam-15), theme "Everything Has a Price", closes November 2, 2026 18:45.

Decided with the user on October 26, 2026 (theme interpretation 3, the satire):

| Question | Answer |
| --- | --- |
| Setting and form | A top-down dungeon with a shopkeeper, in 1-bit art (CC0 Bit Bonanza and Bountiful Bits since November 21, 2026; 1-Bit Kingdom in the jam build) |
| Currency | Coins, with abstract costs: the joke is what gets priced |
| Ending | The exit has a price you can't pay; the last line item is **Peace of Mind** |
| Title | Investors of SPLORR!! |
| Shopkeeper's voice | Never says "price" or "cost": everything is an investment or an opportunity |
| Price changes | Prices never drop, only hold or rise (no sales) |
| Longer copy font | DINOBYTE (CC BY 4.0, credit required) |

## The pitch

*You are a hero. The dungeon is a business.* Walk a short dungeon of small rooms toward the exit. Nothing is free: every door, every torch, every swing of the sword, every hint and every thing you might call a right has a line item. A shopkeeper meets you in each room with the price list. Coins come from slimes and gems, never quite as fast as the bills. The final door costs more than the dungeon holds.

Voice: deadpan and brief, like the user's other Metaphors. **The shopkeeper never calls anything a price, a cost or a fee.** Every charge is an investment, an opportunity, a stake or a premium, delivered with complete sincerity ("A door is an opportunity. Three coins."). The amount is still printed plainly and the number is never explained or apologised for.

## Core loop

1. Enter a room. The shopkeeper's price list for that room is on screen (door, light, and whatever else is priced here).
2. Move one tile per key press. Light, doors and actions are paid for from one coin counter.
3. Earn coins by defeating enemies and picking up collectibles.
4. Spend to proceed. Some prices rise each time you pay them.
5. Reach the exit, read its price, and find out how the game ends.

## What has a price (draft, tune in playtest)

- **Doors:** a toll to open each one.
- **Light:** unlit rooms are mostly black; a torch is rented per room.
- **Attacking:** a coin per swing, so fighting is a budget decision.
- **Healing and hearts**, **the map**, **a hint from a sign**, **reading a sign at all**.
- **Dying:** a respawn fee, so death is a cost, never a fail state until the coins run out.
- **Backtracking:** a door you have paid for may charge again on the way back, and a repeated charge is higher than the first. Prices never drop.

Absurd items go in as one-liners once the real ones work (a price on the shopkeeper's name, on "a moment of peace").

## The ending

The exit door costs more than all the coins the dungeon can ever give (a test pins that total earnable coins is strictly less than the exit price). The shopkeeper then offers one last opportunity to make up the difference: **Peace of Mind**, which the game earlier showed as free (the quiet of an empty room, a rest that cost nothing). Paying it opens the door. Keep the wording straight and warm; the mechanic is the message. The lines are written (task 109): the shopkeeper offers Peace of Mind instead of a sale, and the ending screen reads "You had it in the quiet rooms. It was never for sale. Thank you for investing."

## The dungeon (task 108, built)

Seven rooms, one door onward each (door r joins rooms r and r + 1; tolls 0, 0, 3, 4, 5, 6 for doors 0 to 5):

| Room | What it is |
| --- | --- |
| 1, 2 | Quiet, free and empty. Resting is free and mends a heart. No shopkeeper, no pickups, free doors |
| 3 | The first shopkeeper, four coins, and a slime standing in the only gap to the door (killing it is a forced first lesson: a coin to swing, two coins back) |
| 4 | Dark. A shopkeeper selling torches, three coins, and a gem behind an imp (optional: two swings and two hearts for 5 + 3 coins) |
| 5 | The same quiet room as room 2, but with a shopkeeper and a charge for the stillness (2 coins, rising). The echo is the joke |
| 6 | A skull holds the only gap (a forced three-swing fight from full health); two gems on the near side to earn it with |
| 7 | The exit, the shopkeeper, Peace of Mind |

Economy: the dungeon pays out 40 coins in all (6 to start, 34 on the floor and from kills); the exit costs 50 (a test pins `earnable < exit`). A scripted player that takes everything and fights everything finishes in about 220 turns holding 11 coins and two setbacks, so the numbers are generous at the door and short at the exit, as intended.

Rules added to keep it fair:

- **Resting mends one heart** and is free in the first rooms, charged later: the free peace the ending sells back.
- **Reserve:** heals, tips, torches and priced stillness never take you below the toll of the door onward ("A prudent investor keeps something in reserve").
- **Bankrupt:** if you hold too few coins for the door, nothing in the room can be earned and nothing worth fetching is behind you, the game ends with "Bankrupt" and a restart. It is a safety net for the unlucky, not a goal. The last room is never bankrupt, because Peace of Mind is not paid in coins.

## Scope (seven days, one person plus Claude)

Must have (rooms done, the rest pending): 6 to 8 rooms, one coin counter, the shopkeeper, 2 or 3 enemy kinds, doors, light, the priced actions above, the ending, title screen, keyboard and touch input, sound, a cover and screenshots. Cut first: extra enemy kinds, backtracking charges, the absurd item list, a second palette.

## Look and sound

- Two colours only. Sprites are white-on-transparent sheets tinted at draw time. Default black and white; a palette switch is allowed by the jam but optional. **Since November 21, 2026 the art is CC0** (Bit Bonanza and Bountiful Bits by VEXED, 10 px tiles centred in the game's 16 px cells, built by `tools/make_cc0_art.py`) so the repo can be public; the jam build used 1-Bit Kingdom by Vryell, which may not be redistributed, and none of it may come into this repo.
- Text: **DINOBYTE** (BOK `Tech/DINOBYTE font.md`, 6 by 8, CC BY 4.0) for the shopkeeper and all longer copy; Credit DINOBYTE (mby) in the game's about screen and on the itch page.
- Sound: made in the Anvil as PLAY-text sounds and exported to WAV, as in `tggd-20seconds`. A coin sound and a door sound do most of the work.

## Decided (was open)

- **Peace of Mind setup:** the early rooms are **quiet empty rooms**: nothing in them, no charge, the player may stand there as long as they like. Later rooms of the same kind carry a line item for the stillness, and the final opportunity is Peace of Mind. The earlier free rooms are the setup, so keep at least two before the first charge appears, and never charge for an empty room twice in a row before the ending.
- **Pacing:** turn-based, one tile per key press.
- **AI disclosure (user's call, October 26, 2026):** make it blatantly obvious that the game was developed with AI, and make it **the very first thing said**: the first line of `ITCH_DESCRIPTION.md`, before the short description if the page allows, and the first thing on the title or about screen. Evangelise: many indie developers and jams reject AI, and the user wants them to see what a partnership with an AI can make. Keep it factual and proud, not defensive: the user was product owner and QA, Claude Code wrote the code, tests, sound and text and placed the art. The art is a mix: the 1-Bit Kingdom sheets are premade (Vryell, who tagged them "No generative AI was used"), credited to Vryell and not claimed as AI-made; **Claude will also make art for this game** (extra sprites, tiles, the cover, anything the kit lacks, via the Anvil or code), so the page truthfully says AI art is used. Say which pieces are which. Keep an honest list of what Claude drew as it is made. (Since November 21, 2026 the premade art is CC0 by VEXED instead of 1-Bit Kingdom; see Look and sound.) The jam page says nothing about AI.

## Open questions

None at present.
