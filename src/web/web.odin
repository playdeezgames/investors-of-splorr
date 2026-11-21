// Thin browser layer: input, drawing, and the frame loop. Everything else is in package game.
#+build js
package main

import "base:runtime"
import "core:fmt"
import "core:sys/wasm/js"
import "tggd:game"

foreign import canvas "canvas"
@(default_calling_convention = "contextless")
foreign canvas {
	// rgb is 0xRRGGBB; coordinates are logical pixels, y down.
	fill_rect :: proc(x, y, w, h: f32, rgb: u32, alpha: f32) ---
	// Draw one `size` by `size` cell of a sheet, tinted to rgb. The order of `Sheet` matches SHEETS in index.html.
	blit :: proc(sheet: i32, col, row, size: i32, x, y: f32, rgb: u32) ---
	// Bitmap text (DINOBYTE, 6 by 8 cells). x, y is the top left; scale is a whole number.
	draw_text :: proc(x, y: f32, text: string, rgb: u32, scale: i32, centered: bool) ---
	// Play a sound effect; the ids are `game.Event` (the order matches SOUND_FILES in index.html).
	play_sound :: proc(id: i32) ---
}

Sheet :: enum i32 {
	Sprites, // CC0 art (Bit Bonanza, Bountiful Bits) built by tools/make_cc0_art.py; cells are `Sprite`
	Shop, // the shopkeeper, one 32 by 32 cell
	Claude, // made by Claude; see ART_CREDITS.md. Cells: torch, potion, bubble, sun, coins
}

// Cells of the Sprites sheet, in the order of CELLS in tools/make_cc0_art.py.
Sprite :: enum i32 {
	Hero,
	Heart,
	Heart_Empty,
	Coin,
	Gem,
	Slime,
	Imp,
	Skull,
	Wall,
	Door,
	Exit,
}

sprite :: proc(s: Sprite, x, y: f32) {
	blit(i32(Sheet.Sprites), i32(s), 0, 16, x, y, INK)
}

// The whole look is two colours; change them here to swap the palette.
PAPER :: u32(0x000000)
INK   :: u32(0xffffff)

GLYPH_W :: 6
GLYPH_H :: 8
TEXT_COLS :: (game.SCREEN_W - 8) / GLYPH_W // characters per line of the message box

BOX_Y :: game.HUD_H + game.ROOM_H * game.TILE // top of the message box

// Claude sheet cell for each shop offer.
OFFER_ICON := [game.Offer]int {
	.Torch = 0,
	.Heal  = 1,
	.Tip   = 2,
}

state: game.Game
queue: [128]game.Action // key and touch presses waiting for a frame, oldest first
queue_len: int

main :: proc() {
	state = game.init()
	js.add_window_event_listener(.Key_Down, nil, on_key_down)
}

push :: proc(a: game.Action) {
	if a != .None && queue_len < len(queue) {
		queue[queue_len] = a
		queue_len += 1
	}
}

// Logical keys first (remote desktops send wrong codes), then physical codes for WASD.
action_for :: proc(e: js.Event) -> game.Action {
	switch e.key.key {
	case "ArrowLeft":  return .Left
	case "ArrowRight": return .Right
	case "ArrowUp":    return .Up
	case "ArrowDown":  return .Down
	case "Enter", " ": return .Confirm
	case "Escape":     return .Cancel
	}
	switch e.key.code {
	case "KeyA": return .Left
	case "KeyD": return .Right
	case "KeyW": return .Up
	case "KeyS": return .Down
	case "KeyZ": return .Confirm
	case "KeyX": return .Cancel
	}
	return .None
}

on_key_down :: proc(e: js.Event) {
	if e.key.repeat {
		return
	}
	if a := action_for(e); a != .None {
		push(a)
		js.event_prevent_default()
	}
}

// Called by the page for the on-screen buttons and taps (the numbers are `game.Action`), and by the
// QA hook (index.html#keys=RRDC...) to replay a run for screenshots.
@(export)
press :: proc "c" (action: i32) {
	context = runtime.default_context()
	if action >= 1 && action <= i32(game.Action.Cancel) {
		push(game.Action(action))
	}
}

// QA hook: run every queued press now, without waiting a frame each (animation frames are slow in
// background tabs and the browser pane).
@(export)
qa_drain :: proc "c" () {
	context = runtime.default_context()
	for queue_len > 0 {
		step_queue()
	}
}

step_queue :: proc() {
	a := game.Action.None
	if queue_len > 0 {
		a = queue[0]
		copy(queue[:], queue[1:queue_len])
		queue_len -= 1
	}
	game.step(&state, a)
	for e in state.events {
		play_sound(i32(e))
	}
}

@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	context = runtime.default_context()
	step_queue()
	draw()
	free_all(context.temp_allocator)
	return true
}

text :: proc(x, y: f32, s: string, scale: i32 = 1, rgb: u32 = INK) {
	draw_text(x, y, s, rgb, scale, false)
}

centered :: proc(y: f32, s: string, scale: i32 = 1) {
	draw_text(game.SCREEN_W / 2, y, s, INK, scale, true)
}

// Word-wrapped text in the message box. Returns the number of lines drawn.
wrapped :: proc(s: string, x, y: f32, cols: int) -> int {
	start, line := 0, 0
	for start < len(s) {
		end := min(start + cols, len(s))
		if end < len(s) {
			e := end
			for e > start && s[e] != ' ' {
				e -= 1
			}
			if e > start {
				end = e
			}
		}
		text(x, y + f32(line * GLYPH_H), s[start:end])
		start = end
		for start < len(s) && s[start] == ' ' {
			start += 1
		}
		line += 1
	}
	return line
}

draw :: proc() {
	fill_rect(0, 0, game.SCREEN_W, game.SCREEN_H, PAPER, 1)
	switch state.phase {
	case .Intro:
		draw_intro()
	case .Title:
		draw_title()
	case .Credits:
		draw_credits()
	case .Ended:
		draw_ended()
	case .Bankrupt:
		draw_bankrupt()
	case .Playing, .Shop, .Exit:
		draw_room()
		draw_hud()
		draw_message()
		if state.phase == .Shop {
			draw_shop()
		}
	}
}

draw_intro :: proc() {
	centered(24, game.AI_HEADLINE, 3)
	for line, i in game.AI_LINES {
		centered(f32(76 + i * 12), line)
	}
	centered(168, "Press Enter")
}

draw_title :: proc() {
	blit(i32(Sheet.Claude), 4, 0, 16, game.SCREEN_W / 2 - 8, 46, INK)
	centered(70, "INVESTORS", 3)
	centered(96, "of SPLORR!!", 2)
	centered(140, "Press Enter")
	centered(156, "Arrows move. Enter confirms. Esc backs out.")
	centered(172, "Made with AI. Esc: credits")
}

draw_credits :: proc() {
	centered(20, "CREDITS", 2)
	for line, i in game.CREDITS_LINES {
		centered(f32(56 + i * 12), line)
	}
	centered(168, "Press any key")
}

draw_ended :: proc() {
	centered(14, "You have Peace of Mind.", 2)
	blit(i32(Sheet.Claude), 3, 0, 16, game.SCREEN_W / 2 - 8, 40, INK)
	for line, i in game.PEACE_LINES {
		centered(f32(64 + i * 12), line)
	}
	centered(108, fmt.tprintf("Coins held: %d   Spent: %d", state.coins, state.spent))
	centered(120, fmt.tprintf("Turns: %d   Setbacks: %d", state.turn, state.deaths))
	centered(156, "Press Enter to invest again")
}

draw_bankrupt :: proc() {
	centered(50, "Bankrupt.", 3)
	centered(90, game.message(&state))
	centered(106, fmt.tprintf("Spent: %d. Setbacks: %d.", state.spent, state.deaths))
	centered(156, "Press Enter to invest again")
}

draw_hud :: proc() {
	for i in 0 ..< game.MAX_HP {
		sprite(.Heart if i < state.hp else .Heart_Empty, f32(i * 16), 0)
	}
	sprite(.Coin, 224, 0)
	text(244, 4, fmt.tprintf("%d", state.coins), 1)
	text(280, 4, fmt.tprintf("Room %d", state.room + 1), 1)
}

// Sprite for a map tile. Floor is empty (black).
tile_sprite :: proc(ch: u8) -> (s: Sprite, ok: bool) {
	switch ch {
	case '#': return .Wall, true
	case '>', '<': return .Door, true
	case 'X': return .Exit, true
	case '$': return .Coin, true
	case 'g': return .Gem, true
	case 's': return .Slime, true
	case 'i': return .Imp, true
	case 'k': return .Skull, true
	}
	return {}, false
}

draw_room :: proc() {
	for y in 0 ..< game.ROOM_H {
		for x in 0 ..< game.ROOM_W {
			if !game.visible(&state, x, y) {
				continue
			}
			px := f32(x * game.TILE)
			py := f32(game.HUD_H + y * game.TILE)
			ch := state.tiles[state.room][y][x]
			if ch == 'M' {
				// The shopkeeper is a 32 by 32 sprite standing on his tile.
				blit(i32(Sheet.Shop), 0, 0, 32, px - 8, py - 16, INK)
			} else if s, ok := tile_sprite(ch); ok {
				sprite(s, px, py)
			}
		}
	}
	sprite(.Hero, f32(state.x * game.TILE), f32(game.HUD_H + state.y * game.TILE))
}

draw_message :: proc() {
	fill_rect(0, BOX_Y, game.SCREEN_W, 1, INK, 1)
	wrapped(game.message(&state), 4, BOX_Y + 5, TEXT_COLS)
}

// The shopkeeper's offers, over the room. Placeholder wording until the dialogue pass.
draw_shop :: proc() {
	list, n := game.offers_here(&state)
	x, y, w := f32(64), f32(34), f32(192)
	h := f32(24 + n * 18)
	fill_rect(x - 2, y - 2, w + 4, h + 4, INK, 1)
	fill_rect(x, y, w, h, PAPER, 1)
	text(x + 8, y + 6, "Opportunities", 1)
	for i in 0 ..< n {
		oy := y + 20 + f32(i * 18)
		offer := list[i]
		if i == state.menu {
			text(x + 8, oy, ">", 2)
		}
		text(x + 28, oy, game.OFFER_NAMES[offer], 2)
		blit(i32(Sheet.Claude), i32(OFFER_ICON[offer]), 0, 16, x + 104, oy - 4, INK)
		text(x + w - 40, oy, fmt.tprintf("%d", game.offer_price(&state, offer)), 2)
	}
}
