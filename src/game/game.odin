// Pure rules: no platform imports, so this compiles natively (tests) and for js_wasm32.
package game

import "core:fmt"

SCREEN_W :: 320
SCREEN_H :: 192
TILE     :: 16
HUD_H    :: 16 // the top strip: hearts, coins
ROOM_W   :: 20
ROOM_H   :: 9 // the room fills y = HUD_H .. HUD_H + ROOM_H * TILE; the message box is below

MAX_ROOMS   :: 8
MAX_ENEMIES :: 6
MAX_HP      :: 3
START_COINS :: 6
LIGHT_RADIUS :: 2 // tiles you can see in a dark room you have not lit

// One key press per turn; the platform layer maps keys and touch buttons to these.
Action :: enum {
	None,
	Left,
	Right,
	Up,
	Down,
	Confirm, // stand still, buy, accept
	Cancel,
}

Phase :: enum {
	Intro, // the AI statement: the first thing shown
	Title,
	Credits,
	Playing,
	Shop, // the shopkeeper's offers are open
	Exit, // standing at the exit, being offered Peace of Mind
	Ended,
	Bankrupt, // no coins and no way to earn any; the only move is to start again
}

// One-step events for the platform layer (sound); cleared at the start of each step.
Event :: enum {
	Coin,
	Door,
	Swing,
	Hurt,
	Die,
	Buy,
	Refuse,
	Peace,
}

Enemy_Kind :: enum {
	Slime,
	Imp,
	Skull,
}

Enemy_Def :: struct {
	hp:   int,
	drop: int, // coins; always more than the swings it takes, so fighting pays a little
}

ENEMY_DEFS := [Enemy_Kind]Enemy_Def {
	.Slime = {1, 2},
	.Imp   = {2, 3},
	.Skull = {3, 5},
}

Enemy :: struct {
	kind:  Enemy_Kind,
	x, y:  int,
	hp:    int,
	alive: bool,
}

Game :: struct {
	phase:      Phase,
	turn:       int,
	room:       int,
	x, y:       int, // player tile
	respawn_x:  int,
	respawn_y:  int,
	hp:         int,
	coins:      int,
	deaths:     int,
	spent:      int,
	tiles:      [MAX_ROOMS][ROOM_H][ROOM_W]u8, // mutable copy of the room maps
	enemies:    [MAX_ROOMS][MAX_ENEMIES]Enemy,
	lit:        [MAX_ROOMS]bool,
	door_paid:  [MAX_ROOMS]int, // times door r (between rooms r and r + 1) has been paid
	rest_paid:  [MAX_ROOMS]int,
	bought:     [Offer]int,
	tips_heard: int,
	menu:       int, // shop cursor
	events:     bit_set[Event],
	msg_buf:    [160]u8,
	msg_len:    int,
}

// A fresh game on the title screen.
init :: proc() -> Game {
	g: Game
	g.phase = .Intro
	g.hp = MAX_HP
	g.coins = START_COINS
	for room in 0 ..< ROOM_COUNT {
		count := 0
		for row, y in ROOMS[room].tiles {
			for x in 0 ..< ROOM_W {
				ch := row[x]
				g.tiles[room][y][x] = ch
				if ch == '@' {
					g.tiles[room][y][x] = '.'
					if room == 0 {
						g.x, g.y = x, y
					}
				}
				if kind, ok := enemy_kind_of(ch); ok && count < MAX_ENEMIES {
					g.enemies[room][count] = Enemy{kind, x, y, ENEMY_DEFS[kind].hp, true}
					count += 1
				}
			}
		}
	}
	g.respawn_x, g.respawn_y = g.x, g.y
	return g
}

enemy_kind_of :: proc(ch: u8) -> (kind: Enemy_Kind, ok: bool) {
	switch ch {
	case 's': return .Slime, true
	case 'i': return .Imp, true
	case 'k': return .Skull, true
	}
	return {}, false
}

say :: proc(g: ^Game, format: string, args: ..any) {
	s := fmt.bprintf(g.msg_buf[:], format, ..args)
	g.msg_len = len(s)
}

message :: proc(g: ^Game) -> string {
	return string(g.msg_buf[:g.msg_len])
}

// False for tiles outside the light in a dark room that has not been lit.
visible :: proc(g: ^Game, x, y: int) -> bool {
	if !ROOMS[g.room].dark || g.lit[g.room] {
		return true
	}
	return abs(x - g.x) <= LIGHT_RADIUS && abs(y - g.y) <= LIGHT_RADIUS
}

// Advance by one key press. No input is no turn.
step :: proc(g: ^Game, action: Action) {
	g.events = {}
	if action == .None {
		return
	}
	switch g.phase {
	case .Intro:
		if action == .Confirm {
			g.phase = .Title
		}
	case .Title:
		if action == .Confirm {
			g.phase = .Playing
			say(g, "%s", ROOMS[g.room].intro)
		} else if action == .Cancel {
			g.phase = .Credits
		}
	case .Credits:
		g.phase = .Title
	case .Ended, .Bankrupt:
		if action == .Confirm {
			g^ = init()
			g.phase = .Title // the AI statement is shown once
		}
	case .Shop:
		step_shop(g, action)
	case .Exit:
		step_exit(g, action)
	case .Playing:
		step_playing(g, action)
		if g.phase == .Playing && is_stuck(g) {
			g.phase = .Bankrupt
			say(g, "%s", BANKRUPT_LINE)
		}
	}
}

// Ends a turn that used up the player's action: the enemies next to the player strike.
end_turn :: proc(g: ^Game) {
	g.turn += 1
	for &e in g.enemies[g.room] {
		if !e.alive || abs(e.x - g.x) + abs(e.y - g.y) != 1 {
			continue
		}
		g.hp -= 1
		g.events += {.Hurt}
		if g.hp <= 0 {
			die(g)
			return
		}
	}
}

// Dying is a cost, not a failure: a fee (never more than you hold), then back to the room's entry.
die :: proc(g: ^Game) {
	g.deaths += 1
	fee := min(g.coins, death_fee(g))
	g.coins -= fee
	g.spent += fee
	g.hp = MAX_HP
	g.x, g.y = g.respawn_x, g.respawn_y
	g.events += {.Die}
	say(g, "A setback is an opportunity. %d coins, and you are as good as new.", fee)
}

step_playing :: proc(g: ^Game, action: Action) {
	dx, dy := 0, 0
	switch action {
	case .Left:  dx = -1
	case .Right: dx = 1
	case .Up:    dy = -1
	case .Down:  dy = 1
	case .Confirm:
		stand_still(g)
		return
	case .Cancel, .None:
		return
	}
	nx, ny := g.x + dx, g.y + dy
	if nx < 0 || nx >= ROOM_W || ny < 0 || ny >= ROOM_H {
		return
	}
	switch ch := g.tiles[g.room][ny][nx]; ch {
	case '#':
		return
	case '$':
		take(g, nx, ny, 1)
	case 'g':
		take(g, nx, ny, GEM_VALUE)
	case 'M':
		g.phase = .Shop
		g.menu = 0
		say(g, "%s", SHOP_GREETING)
		return
	case '>':
		use_door(g, g.room, true) // a door is its own turn; the new room's enemies have not noticed you yet
		return
	case '<':
		use_door(g, g.room - 1, false)
		return
	case 'X':
		g.phase = .Exit
		say(g, "The way out is an opportunity: %d coins. You hold %d. Short, I am afraid. May I offer Peace of Mind instead? Enter, or Esc.", EXIT_PRICE, g.coins)
		return
	case 's', 'i', 'k':
		if !swing(g, nx, ny) {
			return
		}
	case:
		g.x, g.y = nx, ny
	}
	end_turn(g)
}

// Walk onto a pickup and collect it.
take :: proc(g: ^Game, x, y, value: int) {
	g.tiles[g.room][y][x] = '.'
	g.x, g.y = x, y
	g.coins += value
	g.events += {.Coin}
}

// Hitting an enemy costs a coin per swing; with none left, there is no swing and no turn.
swing :: proc(g: ^Game, x, y: int) -> bool {
	if g.coins < 1 {
		g.events += {.Refuse}
		say(g, "%s", NO_SWING)
		return false
	}
	g.coins -= 1
	g.spent += 1
	g.events += {.Swing}
	for &e in g.enemies[g.room] {
		if !e.alive || e.x != x || e.y != y {
			continue
		}
		e.hp -= 1
		if e.hp <= 0 {
			e.alive = false
			g.tiles[g.room][y][x] = '.'
			g.coins += ENEMY_DEFS[e.kind].drop
			g.events += {.Coin}
		}
		break
	}
	return true
}

// Confirm in the field: one turn of standing still, which mends one heart. A priced room charges
// for the stillness (and, like every discretionary spend, will not take your reserve).
stand_still :: proc(g: ^Game) {
	price := rest_price(g, g.room)
	if price > 0 {
		if g.coins < price {
			g.events += {.Refuse}
			say(g, "Stillness is an opportunity: %d coins. You hold %d.", price, g.coins)
			return
		}
		if g.coins - price < reserve(g) {
			g.events += {.Refuse}
			say(g, "%s", RESERVE_LINE)
			return
		}
		pay(g, price)
		g.rest_paid[g.room] += 1
		say(g, "Stillness, %d coins. A sound investment.", price)
	}
	g.hp = min(g.hp + 1, MAX_HP)
	end_turn(g)
}

pay :: proc(g: ^Game, price: int) {
	g.coins -= price
	g.spent += price
	g.events += {.Buy}
}

// Door r joins room r and room r + 1; you pay for it every time you use it, in either direction.
use_door :: proc(g: ^Game, door: int, forward: bool) {
	price := door_price(g, door)
	if g.coins < price {
		g.events += {.Refuse}
		say(g, "This door is an opportunity: %d coins. You hold %d.", price, g.coins)
		return
	}
	if price > 0 {
		pay(g, price)
		g.door_paid[door] += 1
	}
	g.events += {.Door}
	g.room += 1 if forward else -1
	place_at_entry(g, '<' if forward else '>')
	say(g, "%s", ROOMS[g.room].intro)
	g.turn += 1
}

// Stand on the first floor tile beside the door you came through; death sends you back here.
place_at_entry :: proc(g: ^Game, door: u8) {
	for row, y in g.tiles[g.room] {
		for ch, x in row {
			if ch != door {
				continue
			}
			for d in ([4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) {
				nx, ny := x + d.x, y + d.y
				if nx >= 0 && nx < ROOM_W && ny >= 0 && ny < ROOM_H && g.tiles[g.room][ny][nx] == '.' {
					g.x, g.y = nx, ny
					g.respawn_x, g.respawn_y = nx, ny
					return
				}
			}
		}
	}
}

step_shop :: proc(g: ^Game, action: Action) {
	list, n := offers_here(g)
	if n == 0 {
		g.phase = .Playing
		return
	}
	g.menu = clamp(g.menu, 0, n - 1)
	switch action {
	case .Up:
		g.menu = max(g.menu - 1, 0)
	case .Down:
		g.menu = min(g.menu + 1, n - 1)
	case .Left, .Right, .Cancel:
		g.phase = .Playing
		say(g, "%s", SHOP_FAREWELL)
	case .Confirm:
		buy(g, list[g.menu])
		if _, left := offers_here(g); left == 0 {
			g.phase = .Playing
		}
	case .None:
	}
}

buy :: proc(g: ^Game, offer: Offer) {
	price := offer_price(g, offer)
	if g.coins < price {
		g.events += {.Refuse}
		say(g, "%s", SHOP_REFUSAL)
		return
	}
	if g.coins - price < reserve(g) {
		g.events += {.Refuse}
		say(g, "%s", RESERVE_LINE)
		return
	}
	pay(g, price)
	g.bought[offer] += 1
	switch offer {
	case .Torch:
		g.lit[g.room] = true
		say(g, "%s", TORCH_LINE)
	case .Heal:
		g.hp = MAX_HP
		say(g, "%s", HEAL_LINE)
	case .Tip:
		say(g, "%s", TIPS[g.tips_heard % len(TIPS)])
		g.tips_heard += 1
	}
}

step_exit :: proc(g: ^Game, action: Action) {
	#partial switch action {
	case .Confirm:
		g.phase = .Ended
		g.events += {.Peace}
	case .Cancel, .Left, .Right, .Up, .Down:
		g.phase = .Playing
		say(g, "%s", EXIT_DECLINED)
	}
}

// True when the player can no longer make progress: nothing in reach to earn, and no coins for
// the door onward. Only the walkable part of this room counts, plus pickups left behind if the
// door back is affordable. The last room is never stuck: Peace of Mind is not paid in coins.
is_stuck :: proc(g: ^Game) -> bool {
	if g.room == ROOM_COUNT - 1 {
		return false
	}
	seen: [ROOM_H][ROOM_W]bool
	queue: [ROOM_H * ROOM_W][2]int
	head, tail := 0, 1
	queue[0] = {g.x, g.y}
	seen[g.y][g.x] = true
	for head < tail {
		p := queue[head]
		head += 1
		for d in ([4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) {
			nx, ny := p.x + d.x, p.y + d.y
			if nx < 0 || nx >= ROOM_W || ny < 0 || ny >= ROOM_H || seen[ny][nx] {
				continue
			}
			seen[ny][nx] = true
			switch g.tiles[g.room][ny][nx] {
			case '#', 'M':
			case '$', 'g':
				return false
			case '>':
				if g.coins >= door_price(g, g.room) {
					return false
				}
			case '<':
				if g.coins >= door_price(g, g.room - 1) && pickups_before(g, g.room) {
					return false
				}
			case 's', 'i', 'k':
				if g.coins >= 1 { // a kill pays more than the swing, so it counts as a way on
					queue[tail] = {nx, ny}
					tail += 1
				}
			case:
				queue[tail] = {nx, ny}
				tail += 1
			}
		}
	}
	return true
}

pickups_before :: proc(g: ^Game, room: int) -> bool {
	for r in 0 ..< room {
		for row in g.tiles[r] {
			for ch in row {
				if ch == '$' || ch == 'g' {
					return true
				}
			}
		}
	}
	return false
}
