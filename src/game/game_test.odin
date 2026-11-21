#+build !js
package game

import "core:fmt"
import "core:strings"
import "core:testing"

playing :: proc() -> Game {
	g := init()
	step(&g, .Confirm)
	step(&g, .Confirm)
	return g
}

// Put the player in a room, beside its tile `ch` (first floor neighbour), as if they had walked there.
stand_beside :: proc(g: ^Game, room: int, ch: u8) -> (dx, dy: int, found: bool) {
	g.room = room
	for row, y in g.tiles[room] {
		for c, x in row {
			if c != ch {
				continue
			}
			for d in ([4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) {
				nx, ny := x + d.x, y + d.y
				if nx >= 0 && nx < ROOM_W && ny >= 0 && ny < ROOM_H && g.tiles[room][ny][nx] == '.' {
					g.x, g.y = nx, ny
					g.respawn_x, g.respawn_y = nx, ny
					return -d.x, -d.y, true
				}
			}
		}
	}
	return 0, 0, false
}

move_toward :: proc(dx, dy: int) -> Action {
	switch {
	case dx > 0: return .Right
	case dx < 0: return .Left
	case dy > 0: return .Down
	}
	return .Up
}

@(test)
move_is_one_tile_per_turn :: proc(t: ^testing.T) {
	g := playing()
	x := g.x
	step(&g, .Right)
	testing.expect_value(t, g.x, x + 1)
	testing.expect_value(t, g.turn, 1)
}

@(test)
no_input_is_not_a_turn :: proc(t: ^testing.T) {
	g := playing()
	step(&g, .None)
	testing.expect_value(t, g.turn, 0)
}

@(test)
walls_block_and_cost_no_turn :: proc(t: ^testing.T) {
	g := playing()
	for _ in 0 ..< 100 {
		step(&g, .Left)
	}
	testing.expect_value(t, g.x, 1)
	turns := g.turn
	step(&g, .Left)
	testing.expect_value(t, g.turn, turns)
}

@(test)
rooms_are_well_formed :: proc(t: ^testing.T) {
	starts := 0
	for room in 0 ..< ROOM_COUNT {
		def := ROOMS[room]
		for row in def.tiles {
			testing.expectf(t, len(row) == ROOM_W, "room %d has a row of width %d", room, len(row))
		}
		has := proc(def: Room_Def, ch: u8) -> bool {
			for row in def.tiles {
				for c in row {
					if c == rune(ch) {
						return true
					}
				}
			}
			return false
		}
		testing.expectf(t, has(def, '<') == (room > 0), "room %d back door", room)
		testing.expectf(t, has(def, '>') == (room < ROOM_COUNT - 1), "room %d forward door", room)
		testing.expectf(t, has(def, 'X') == (room == ROOM_COUNT - 1), "room %d exit", room)
		for row in def.tiles {
			for c in row {
				if c == '@' {
					starts += 1
				}
			}
		}
	}
	testing.expect_value(t, starts, 1)
	testing.expect(t, ROOM_COUNT <= MAX_ROOMS)
}

// The design rule: at least two free, empty, quiet rooms before the first charge.
@(test)
first_two_rooms_are_free_and_empty :: proc(t: ^testing.T) {
	for room in 0 ..< 2 {
		g := init()
		testing.expect_value(t, door_price(&g, room), 0)
		testing.expect_value(t, rest_price(&g, room), 0)
		testing.expect(t, !ROOMS[room].dark)
		for row in ROOMS[room].tiles {
			for c in row {
				switch c {
				case '$', 'g', 'M', 's', 'i', 'k':
					testing.expectf(t, false, "room %d has a '%c'", room, c)
				}
			}
		}
	}
	g := init()
	testing.expect(t, door_price(&g, 2) > 0)
}

@(test)
exit_costs_more_than_the_dungeon_holds :: proc(t: ^testing.T) {
	testing.expectf(t, total_earnable() < EXIT_PRICE, "earnable %d, exit %d", total_earnable(), EXIT_PRICE)
}

@(test)
door_charges_and_the_next_use_costs_more :: proc(t: ^testing.T) {
	g := playing()
	dx, dy, ok := stand_beside(&g, 2, '>')
	testing.expect(t, ok)
	g.coins = 20
	first := door_price(&g, 2)
	step(&g, move_toward(dx, dy))
	testing.expect_value(t, g.room, 3)
	testing.expect_value(t, g.coins, 20 - first)
	// And back again: the same door, dearer.
	dx, dy, ok = stand_beside(&g, 3, '<')
	testing.expect(t, ok)
	second := door_price(&g, 2)
	testing.expect(t, second > first)
	step(&g, move_toward(dx, dy))
	testing.expect_value(t, g.room, 2)
	testing.expect_value(t, g.coins, 20 - first - second)
}

@(test)
door_stays_shut_without_the_coins :: proc(t: ^testing.T) {
	g := playing()
	dx, dy, _ := stand_beside(&g, 2, '>')
	g.coins = door_price(&g, 2) - 1
	coins := g.coins
	step(&g, move_toward(dx, dy))
	testing.expect_value(t, g.room, 2)
	testing.expect_value(t, g.coins, coins)
	testing.expect(t, .Refuse in g.events)
	testing.expect_value(t, g.turn, 0)
}

@(test)
walking_through_the_free_rooms_costs_nothing :: proc(t: ^testing.T) {
	g := playing()
	for room in 0 ..< 2 {
		dx, dy, _ := stand_beside(&g, room, '>')
		step(&g, move_toward(dx, dy))
		testing.expect_value(t, g.room, room + 1)
	}
	testing.expect_value(t, g.coins, START_COINS)
}

@(test)
swing_costs_a_coin_and_a_kill_pays :: proc(t: ^testing.T) {
	g := playing()
	dx, dy, ok := stand_beside(&g, 2, 's')
	testing.expect(t, ok)
	g.coins = 3
	step(&g, move_toward(dx, dy)) // slime has one hit point
	testing.expect_value(t, g.coins, 3 - 1 + ENEMY_DEFS[.Slime].drop)
	testing.expect(t, !g.enemies[2][0].alive)
	testing.expect_value(t, g.tiles[2][g.enemies[2][0].y][g.enemies[2][0].x], u8('.'))
}

@(test)
no_coin_no_swing :: proc(t: ^testing.T) {
	g := playing()
	dx, dy, _ := stand_beside(&g, 2, 's')
	g.coins = 0
	turns := g.turn
	step(&g, move_toward(dx, dy))
	testing.expect(t, g.enemies[2][0].alive)
	testing.expect_value(t, g.turn, turns)
}

@(test)
dying_costs_a_fee_and_sends_you_to_the_entry :: proc(t: ^testing.T) {
	g := playing()
	// Stand beside the slime without attacking: each turn it strikes.
	stand_beside(&g, 2, 's')
	entry_x, entry_y := g.respawn_x, g.respawn_y
	g.coins = 10
	for _ in 0 ..< MAX_HP {
		end_turn(&g) // the slime strikes each turn the player ends beside it
	}
	testing.expect_value(t, g.deaths, 1)
	testing.expect_value(t, g.coins, 10 - DEATH_FEE_BASE)
	testing.expect_value(t, g.hp, MAX_HP)
	testing.expect_value(t, g.x, entry_x)
	testing.expect_value(t, g.y, entry_y)
}

@(test)
death_never_takes_more_than_you_hold :: proc(t: ^testing.T) {
	g := playing()
	stand_beside(&g, 2, 's')
	g.coins = 1
	for _ in 0 ..< MAX_HP {
		end_turn(&g)
	}
	testing.expect_value(t, g.coins, 0)
}

@(test)
dark_rooms_hide_what_is_far_until_a_torch :: proc(t: ^testing.T) {
	g := playing()
	g.room = 3
	g.x, g.y = 3, 4
	testing.expect(t, visible(&g, 4, 4))
	testing.expect(t, !visible(&g, 15, 4))
	g.lit[3] = true
	testing.expect(t, visible(&g, 15, 4))
	g.room = 2
	testing.expect(t, visible(&g, 15, 4))
}

@(test)
shop_sells_a_torch_and_raises_the_next_price :: proc(t: ^testing.T) {
	g := playing()
	dx, dy, ok := stand_beside(&g, 3, 'M')
	testing.expect(t, ok)
	g.coins = 10
	step(&g, move_toward(dx, dy))
	testing.expect_value(t, g.phase, Phase.Shop)
	list, _ := offers_here(&g)
	testing.expect_value(t, list[0], Offer.Torch)
	before := offer_price(&g, .Torch)
	step(&g, .Confirm)
	testing.expect(t, g.lit[3])
	testing.expect_value(t, g.coins, 10 - before)
	testing.expect(t, offer_price(&g, .Torch) > before)
}

@(test)
stillness_is_free_early_and_charged_later :: proc(t: ^testing.T) {
	g := playing()
	g.hp = 1
	step(&g, .Confirm)
	testing.expect_value(t, g.coins, START_COINS)
	testing.expect_value(t, g.hp, 2) // resting mends a heart
	g.room = 4
	g.coins = 20
	step(&g, .Confirm)
	testing.expect_value(t, g.coins, 20 - 2)
	step(&g, .Confirm)
	testing.expect_value(t, g.coins, 20 - 2 - 3)
	testing.expect_value(t, g.hp, MAX_HP)
}

@(test)
purchases_never_take_the_reserve :: proc(t: ^testing.T) {
	g := playing()
	g.room = 4
	toll := door_price(&g, 4)
	g.coins = toll + rest_price(&g, 4) - 1 // one coin short of stillness that leaves the toll
	step(&g, .Confirm)
	testing.expect_value(t, g.coins, toll + rest_price(&g, 4) - 1)
	testing.expect(t, .Refuse in g.events)
	// The shop refuses too.
	dx, dy, _ := stand_beside(&g, 4, 'M')
	step(&g, move_toward(dx, dy))
	g.coins = toll + offer_price(&g, .Tip) - 1
	coins := g.coins
	step(&g, .Confirm)
	testing.expect_value(t, g.coins, coins)
	g.coins = toll + offer_price(&g, .Tip)
	step(&g, .Confirm)
	testing.expect_value(t, g.coins, toll)
}

@(test)
broke_with_nothing_to_earn_is_bankrupt :: proc(t: ^testing.T) {
	g := playing()
	g.room = 4 // nothing to pick up here, nothing left behind, and the way on costs coins
	for r in 0 ..< 4 {
		for &row in g.tiles[r] {
			for &ch in row {
				if ch == '$' || ch == 'g' {
					ch = '.'
				}
			}
		}
	}
	g.x, g.y = 10, 2
	g.coins = door_price(&g, 4) - 1
	step(&g, .Left)
	testing.expect_value(t, g.phase, Phase.Bankrupt)
	step(&g, .Confirm)
	testing.expect_value(t, g.phase, Phase.Title)
}

@(test)
not_bankrupt_while_a_coin_is_in_reach_or_the_door_is_paid :: proc(t: ^testing.T) {
	g := playing()
	stand_beside(&g, 2, 'M')
	g.coins = 0
	testing.expect(t, !is_stuck(&g)) // coins on the floor of the room
	g = playing()
	stand_beside(&g, 4, 'M')
	g.coins = door_price(&g, 4)
	testing.expect(t, !is_stuck(&g))
	g.room = ROOM_COUNT - 1
	g.coins = 0
	testing.expect(t, !is_stuck(&g)) // the last room never strands you
}

@(test)
peace_of_mind_opens_the_exit :: proc(t: ^testing.T) {
	g := playing()
	dx, dy, ok := stand_beside(&g, ROOM_COUNT - 1, 'X')
	testing.expect(t, ok)
	step(&g, move_toward(dx, dy))
	testing.expect_value(t, g.phase, Phase.Exit)
	step(&g, .Cancel)
	testing.expect_value(t, g.phase, Phase.Playing)
	step(&g, move_toward(dx, dy))
	step(&g, .Confirm)
	testing.expect_value(t, g.phase, Phase.Ended)
	testing.expect(t, .Peace in g.events)
	step(&g, .Confirm)
	testing.expect_value(t, g.phase, Phase.Title)
}

// The invariant behind the whole joke: nothing ever gets cheaper. A long scripted wander, with
// coins topped up so every purchase happens, must never see any price fall.
@(test)
prices_never_drop :: proc(t: ^testing.T) {
	Prices :: struct {
		offers: [Offer]int,
		doors:  [MAX_ROOMS]int,
		rests:  [MAX_ROOMS]int,
		fee:    int,
	}
	snapshot :: proc(g: ^Game) -> (p: Prices) {
		for o in Offer {
			p.offers[o] = offer_price(g, o)
		}
		for r in 0 ..< MAX_ROOMS {
			p.doors[r] = door_price(g, r)
		}
		for r in 0 ..< ROOM_COUNT {
			p.rests[r] = rest_price(g, r)
		}
		p.fee = death_fee(g)
		return
	}
	g := playing()
	prev := snapshot(&g)
	seed := u32(12345)
	for _ in 0 ..< 20000 {
		seed = seed * 1664525 + 1013904223
		a := Action(1 + (seed >> 16) % 6)
		if g.phase == .Ended {
			g.phase = .Playing
		}
		if g.coins < 30 {
			g.coins += 30
		}
		step(&g, a)
		now := snapshot(&g)
		for o in Offer {
			testing.expect(t, now.offers[o] >= prev.offers[o])
		}
		for r in 0 ..< MAX_ROOMS {
			testing.expect(t, now.doors[r] >= prev.doors[r])
		}
		for r in 0 ..< ROOM_COUNT {
			testing.expect(t, now.rests[r] >= prev.rests[r])
		}
		testing.expect(t, now.fee >= prev.fee)
		testing.expect(t, g.coins >= 0)
		testing.expect(t, g.hp >= 1 && g.hp <= MAX_HP)
		prev = now
	}
}

// A scripted player that plays the real rules: it collects every pickup it can reach, kills
// everything in its way, goes through each door, and accepts Peace of Mind at the exit.
// BFS over the room; `targets` are the tile characters it is looking for. Returns the first
// step of the shortest way to stand beside the nearest target (bumping it).
bot_toward :: proc(g: ^Game, targets: string) -> (Action, bool) {
	seen: [ROOM_H][ROOM_W]bool
	first: [ROOM_H][ROOM_W]Action
	queue: [ROOM_H * ROOM_W][2]int
	head, tail := 0, 1
	queue[0] = {g.x, g.y}
	seen[g.y][g.x] = true
	dirs := [4]struct {
		dx, dy: int,
		a:      Action,
	}{{1, 0, .Right}, {-1, 0, .Left}, {0, 1, .Down}, {0, -1, .Up}}
	for head < tail {
		p := queue[head]
		head += 1
		for d in dirs {
			nx, ny := p.x + d.dx, p.y + d.dy
			if nx < 0 || nx >= ROOM_W || ny < 0 || ny >= ROOM_H || seen[ny][nx] {
				continue
			}
			ch := g.tiles[g.room][ny][nx]
			act := first[p.y][p.x] if (p.x != g.x || p.y != g.y) else d.a
			is_target := false
			for c in targets {
				if rune(ch) == c {
					is_target = true
				}
			}
			if is_target {
				return d.a if (p.x == g.x && p.y == g.y) else first[p.y][p.x], true
			}
			if ch == '.' {
				seen[ny][nx] = true
				first[ny][nx] = act
				queue[tail] = {nx, ny}
				tail += 1
			}
		}
	}
	return .None, false
}

bot_play :: proc(g: ^Game, max_steps: int) -> int {
	for i in 0 ..< max_steps {
		#partial switch g.phase {
		case .Ended, .Bankrupt:
			return i
		case .Exit:
			step(g, .Confirm)
			continue
		case .Shop:
			step(g, .Cancel)
			continue
		}
		a: Action
		ok: bool
		if g.room == ROOM_COUNT - 1 {
			a, ok = bot_toward(g, "X")
		} else {
			if a, ok = bot_toward(g, "$g"); !ok {
				if a, ok = bot_toward(g, "sik"); !ok {
					a, ok = bot_toward(g, ">")
				}
			}
		}
		if !ok {
			return -1
		}
		step(g, a)
		check_voice(g)
	}
	return -1
}

@(test)
the_dungeon_can_be_finished_and_the_exit_stays_out_of_reach :: proc(t: ^testing.T) {
	g := playing()
	steps := bot_play(&g, 5000)
	testing.expectf(t, steps >= 0, "the bot got stuck in room %d at (%d, %d) holding %d", g.room, g.x, g.y, g.coins)
	testing.expect_value(t, g.phase, Phase.Ended)
	testing.expectf(t, g.coins < EXIT_PRICE, "held %d at the exit, which costs %d", g.coins, EXIT_PRICE)
	fmt.printfln("bot finished in %d steps, %d turns, holding %d coins, %d setbacks", steps, g.turn, g.coins, g.deaths)
}

// The shopkeeper never says price, cost or fee, and every line fits the message box.
BANNED_WORDS :: [?]string{"price", "cost", "fee"}
MAX_LINE :: 150

voice_bad: string

check_voice :: proc(g: ^Game) {
	m := message(g)
	lower := strings.to_lower(m, context.temp_allocator)
	for w in BANNED_WORDS {
		if strings.contains(lower, w) && voice_bad == "" {
			voice_bad = strings.clone(m, context.temp_allocator)
		}
	}
	if len(m) > MAX_LINE && voice_bad == "" {
		voice_bad = strings.clone(m, context.temp_allocator)
	}
}

@(test)
the_shopkeeper_never_says_price_cost_or_fee :: proc(t: ^testing.T) {
	voice_bad = ""
	// Fixed lines.
	lines: [dynamic]string
	defer delete(lines)
	append(&lines, SHOP_GREETING, SHOP_FAREWELL, SHOP_REFUSAL, RESERVE_LINE, NO_SWING, TORCH_LINE, HEAL_LINE, EXIT_DECLINED, BANKRUPT_LINE)
	for l in PEACE_LINES { append(&lines, l) }
	for l in TIPS { append(&lines, l) }
	for r in ROOMS { append(&lines, r.intro) }
	for l in lines {
		lower := strings.to_lower(l, context.temp_allocator)
		for w in BANNED_WORDS {
			testing.expectf(t, !strings.contains(lower, w), "%q says %q", l, w)
		}
		testing.expectf(t, len(l) <= MAX_LINE, "%q is too long", l)
	}
	// Formatted lines: shop, refusals, door, stillness, death, exit, bankrupt, along a full run.
	g := playing()
	g.coins = 0
	for a in ([?]Action{.Right, .Right, .Confirm, .Down, .Confirm, .Cancel}) {
		step(&g, a)
		check_voice(&g)
	}
	g = playing()
	g.room = 2
	place_at_entry(&g, '<')
	g.coins = 1
	for _ in 0 ..< 20 {
		step(&g, .Confirm)
		check_voice(&g)
		step(&g, .Right)
		check_voice(&g)
	}
	g = playing()
	steps := bot_play(&g, 5000)
	testing.expect(t, steps >= 0)
	testing.expectf(t, voice_bad == "", "bad line: %q", voice_bad)
}

@(test)
the_ai_statement_comes_first_then_title_then_credits :: proc(t: ^testing.T) {
	g := init()
	testing.expect_value(t, g.phase, Phase.Intro)
	step(&g, .Left)
	testing.expect_value(t, g.phase, Phase.Intro)
	step(&g, .Confirm)
	testing.expect_value(t, g.phase, Phase.Title)
	step(&g, .Cancel)
	testing.expect_value(t, g.phase, Phase.Credits)
	step(&g, .Down)
	testing.expect_value(t, g.phase, Phase.Title)
	step(&g, .Confirm)
	testing.expect_value(t, g.phase, Phase.Playing)
	for l in AI_LINES {
		testing.expectf(t, len(l) <= 52, "%q is too long", l)
	}
	for l in CREDITS_LINES {
		testing.expectf(t, len(l) <= 52, "%q is too long", l)
	}
}
