# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## State of the repo

**This is the public repo (`playdeezgames/investors-of-splorr`, November 21, 2026), live on GitHub Pages at https://playdeezgames.github.io/investors-of-splorr/.** It was started with a fresh history from the private jam repo `tggd-1bj15` after the art was re-drawn with CC0 tiles; to update the page run `tools/pages.sh`, commit `docs/` and push (only when the user says push). The history notes below are from the jam repo.

Playable draft (tasks 105 to 114 done): the seven-room arc in `DESIGN.md`, coins, the shopkeeper's menu, tolls, dark rooms, combat that costs a coin a swing, death fees and the Peace of Mind ending all work, with 24 native tests, including a scripted player (`bot_play`) that finishes the dungeon through the real `step`. The Coxswain project `tggd-1bj15` has ten tasks (ids 105 to 114: scaffold, rules core, web layer, level design, dialogue, art, sound, screens, playtest, release prep); all ten are done; what remains is the user shipping; claim the next one with `task_next` as agent `1bit`. The concept is decided and written up in `DESIGN.md` ("Investors of SPLORR!!": a dungeon where a shopkeeper frames every charge as an investment, coins, prices that never drop, and an exit that costs more than the dungeon holds until "Peace of Mind"); read it first. The layout is the one the user's other Odin/wasm games converge on. The closest working reference is `/home/yermom/git/tggd-20seconds` (same stack, Anvil assets, Release standard layout); its `web/index.html` shim has the touch pad, bitmap-font tinting, sound loading and the `#play` QA hook to borrow when this repo needs them.

## The project

An entry for **[1-Bit Jam 15](https://itch.io/jam/1-bit-jam-15)** (hosted by MYline media), theme **"Everything Has a Price"**. Read from the jam page on October 26, 2026:

- Submissions open October 26, 2026 18:45 and **close November 2, 2026 18:45**. Voting dates are not listed. The game must be made during the jam; after close only bug fixes and new ways to play (such as a web build) are allowed, nothing radical.
- **Any two colours**, preferably black and white; post-processing and palette switching are allowed. No resolution limit.
- The page says "You are allowed to use media that is not subject to copyright." **The user's reading (October 26, 2026): this is clumsy wording for "don't use others' copyrighted work without following its licence."** So licensed assets are fine provided the licence is followed and credited (CC0, CC BY such as DINOBYTE, OFL, m5x7, and so on). No stolen IP. Record each asset's licence and credit it on the itch page.
- **Art is CC0 only (November 21, 2026).** This repo is public. The jam build used 1-Bit Kingdom by Vryell, which may not be redistributed, so it stayed in the private jam repo `tggd-1bj15`; this repo was started fresh with the art re-drawn from **Bit Bonanza** and **Bountiful Bits** by VEXED (CC0; BOK `Tech/Bit Bonanza.md`, `Tech/Bountiful Bits.md`). **Never add 1-Bit Kingdom files** (BOK `Assets/1bit-kingdom/`) or any art whose licence forbids redistribution. Credit lines: *Bit Bonanza by VEXED, https://v3x3d.itch.io/bit-bonanza* and *Bountiful Bits by VEXED, https://v3x3d.itch.io/bountiful-bits*.
- Judged on Gameplay, Sound, Art, Theme, Originality. No 18+ content. The page says nothing about AI. **The user wants the AI collaboration advertised, not just disclosed: it is the very first thing said** on the itch page (first line of `ITCH_DESCRIPTION.md`) and the title or about screen, and the tone is evangelical (see `DESIGN.md`). The CC0 art is VEXED's (credit it); Claude made additional sprites, so the page does say AI art is used; keep a list of which pieces Claude made (`ART_CREDITS.md`).
- Web build is desirable. Ship as a normal itch.io page (channel `html`).

## Stack and tooling

- **Odin compiled to `js_wasm32`** (`dev-2026-07` at `~/.local/bin/odin`), drawn on an HTML5 2D canvas through a small JS shim. No WebGL (it fails on the user's Chrome), no emscripten. Runtime is Odin's own `core/sys/wasm/js/odin.js`.
- **Anvil** (MCP server `anvil-prod`) makes sprites, tiles, maps, palettes and sounds; worlds are JSON in `/home/yermom/anvil-worlds`. Use `world_*`, `sprite_*`, `sound_*`, `render_*`, and `world_export` / `sound_export` to get assets into the build. For this jam keep the Anvil palette to two colours.
- **Coxswain** (MCP server `coxswain`) tracks tasks. The project is `tggd-1bj15`. Register as agent `1bit` (`agent_register`) and use `task_create` / `task_claim` / `task_complete` instead of TODO lists in the repo. Its tools need an `agent` argument, so pass `1bit`.
- **The BOK** is the user's knowledge base at `/home/yermom/git/bok-of-splorr/splorr` (an additional working directory, an Obsidian vault, not code). Read `Home.md` first, then `Tech/Odin wasm recipe.md`, `Tech/Release standard.md`, `Tech/Shipping to itch.io.md` and `Gotchas.md`. **Add new lessons to the BOK's `Gotchas.md`, and a `Games/<name>.md` note linked from `Home.md`, not here.**

## Commands

```bash
tools/test.sh                  # native tests of src/game, plus odin check of both packages for js_wasm32 (vet flags on)
tools/build.sh [--size]        # builds build/web (game.wasm, odin.js, index.html); --size for shipping
python3 -m http.server -d build/web 8137   # wasm must be served over http, not file://. Port 8765 is often taken; check the first response. Stop with fuser -k 8137/tcp, never pkill -f
odin test src/game -collection:tggd=src -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_NAMES=game.move_is_one_tile_per_turn   # a single test
tools/pages.sh                 # size build copied to docs/ for GitHub Pages (commit docs/ and push to publish)
tools/make_cc0_art.py          # rebuild assets/cc0/sprites_16x16.png and shop_32x32.png from the CC0 sources
tools/ship.sh [--push]         # tests, size build, zip; pushes to itch.io ONLY with --push (shippit.sh is a wrapper)
```

Packages import each other with `-collection:tggd=src` (`import "tggd:game"`). The web layer reads `e.key.key` before `e.code`, and `PAPER` / `INK` in `src/web/web.odin` are the whole palette. A synthetic `KeyboardEvent` dispatched on `window` drives the game in the browser pane; reading canvas pixels with `getImageData` returned transparent there, so use a screenshot to check the picture.

## Code map

- `src/game/game.odin`: state, `step(&g, action)` (one key press is one turn; no input is no turn), combat, doors, shop and exit phases. `prices.odin`: every price (all monotonic), offers, `total_earnable`. `rooms.odin`: the room maps as 20 by 9 strings (legend at the top), and **all the shopkeeper text** (a test pins that he never says price, cost or fee). The game says things by calling `say`, which formats into a fixed buffer; read it with `message`.
- `src/web/web.odin`: draws from `state`; `index.html` implements `fill_rect`, `blit` (sheet, cell, tinted) and `draw_text` (DINOBYTE). Sprite choices live in `tile_sprite` and the `Sprite` enum (cells of `assets/cc0/sprites_16x16.png`, built by `tools/make_cc0_art.py`, whose `CELLS` order the enum must match; sheet order must match `SHEETS` in `index.html`). Key and touch presses go through a queue; `press(action)` is the export the page's buttons call.
- Screenshots: open `index.html?x#keys=CCRRU...` (the first C leaves the AI statement; C confirm, X cancel, L R U D move); the page replays the keys and calls `qa_drain`. Change the `?x` part to force a reload. The browser pane throttles animation frames, so never rely on real-time replay there.
- `tools/make_claude_art.py` draws the Claude-made sprite sheet (`assets/claude/`, the `Claude` sheet in `web.odin`); `ART_CREDITS.md` lists every Claude-made piece, so add a row whenever one is made.
- Screens: `Intro` (the AI statement, `screens.odin`) is the first thing shown, then `Title` (Esc opens `Credits`); restarting skips the Intro. The AI wording and credits live in `src/game/screens.odin`.

## Architecture to follow

- **Pure rules package** `src/game`: no platform imports, `step(&game, input, dt)` with clock and RNG passed in, so it tests natively and is deterministic. It sets one-step event flags (sound, flash) that the web layer turns into effects.
- **Thin web package** `src/web` (`#+build js`): owns the exported `step` frame loop (save `context` from `main`, set `context = ctx` in `step` and in every event callback), key and touch input, and drawing through a few `foreign import canvas` procs implemented in `web/index.html`. Add a `qa_advance`-style export if screenshots need a deterministic state.
- Test files need `#+build !js` (`core:testing` and `core:os` panic or fail on wasm). Platform code goes in `#+build js` / `#+build !js` files, never inside a `when`.
- Text must be a bitmap font at whole-number scales (canvas `fillText` blurs pixel art). Read `e.key` before `e.code` for arrows, Enter and space (remote desktops send wrong codes).
- Seed the RNG in `main` (`rand.reset`) and cap every retry loop; an unbounded loop freezes the browser tab and the automation tools with it. Odin constant arrays cannot be indexed at runtime (declare with `:=`).
- Two colours means the whole palette is two values: draw sprites as 1-bit masks tinted at draw time (as `Turn Left at the Cow` does with `source-in`), so a palette swap is a single setting.

## Release (itch.io)

Follow the BOK's `Release standard`: `ITCH_DESCRIPTION.md` (page URL, jam, "pasted by hand" header, AI disclosure), `assets/cover.png` (630x500, regenerated by `tools/make_cover.py`), `assets/screenshots/`, `devlog/YYYYMMDD/devlog.md`, `tools/{build,test,ship}.sh`, and a one-line `shippit.sh` wrapper (`exec "$(dirname "$0")/tools/ship.sh" "$@"`). `ship.sh` tests, builds with `-o:size`, zips `build/web` with `index.html` at the zip root, and pushes to itch.io **only with `--push`**; it never runs `git add` or `git commit`.

- The itch **short description is limited to 120 characters**; count it before writing it into `ITCH_DESCRIPTION.md`.
- On itch.io and in all page copy a game is a **"Metaphor"**, never a "Game".
- **"Push" means `git push`; "ship" means itch.io.** Never do either unless the user explicitly says so, and never treat one word as the other.
- The user sets the itch project kind, pastes the page copy and posts the devlog by hand. Commit before shipping so live matches the repo.
- Do not describe or "fix" a deliberate design choice as a problem. If the ROM font 8x8 ever appears, ask the user before replacing it.
