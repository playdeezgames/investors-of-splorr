package game

// Every charge. Rules for prices: they only hold or rise, never drop (a test pins it).

Offer :: enum {
	Torch, // light for the current dark room
	Heal,
	Tip,
}

OFFER_NAMES := [Offer]string {
	.Torch = "Torch",
	.Heal  = "Heal",
	.Tip   = "Tip",
}

OFFER_BASE := [Offer]int {
	.Torch = 2,
	.Heal  = 3,
	.Tip   = 1,
}

// Each time you buy an offer, the next one costs this much more.
OFFER_STEP := [Offer]int {
	.Torch = 1,
	.Heal  = 1,
	.Tip   = 1,
}

// Door r joins rooms r and r + 1. A zero toll is free for good.
DOOR_TOLLS := [MAX_ROOMS]int{0, 0, 3, 4, 5, 6, 0, 0}

DEATH_FEE_BASE :: 2
GEM_VALUE      :: 5
EXIT_PRICE     :: 50 // more than the dungeon holds; see `total_earnable`

offer_price :: proc(g: ^Game, offer: Offer) -> int {
	return OFFER_BASE[offer] + OFFER_STEP[offer] * g.bought[offer]
}

door_price :: proc(g: ^Game, door: int) -> int {
	if DOOR_TOLLS[door] == 0 {
		return 0
	}
	return DOOR_TOLLS[door] + g.door_paid[door]
}

// Zero where standing still is free.
rest_price :: proc(g: ^Game, room: int) -> int {
	if ROOMS[room].rest_base == 0 {
		return 0
	}
	return ROOMS[room].rest_base + g.rest_paid[room]
}

// What a prudent investor keeps back: the toll of the door onward. Heals, tips, torches and
// priced stillness will not take you below it, so no purchase can strand you before a door.
reserve :: proc(g: ^Game) -> int {
	if g.room >= ROOM_COUNT - 1 {
		return 0
	}
	return door_price(g, g.room)
}

death_fee :: proc(g: ^Game) -> int {
	return DEATH_FEE_BASE + g.deaths - 1
}

// What the shopkeeper offers in this room right now: a torch only in an unlit dark room,
// a heal only when hurt, a tip always. The shopkeeper has to be in the room to be asked.
offers_here :: proc(g: ^Game) -> (list: [len(Offer)]Offer, count: int) {
	if ROOMS[g.room].dark && !g.lit[g.room] {
		list[count] = .Torch
		count += 1
	}
	if g.hp < MAX_HP {
		list[count] = .Heal
		count += 1
	}
	list[count] = .Tip
	count += 1
	return
}

// Every coin the dungeon can ever pay out, including the coins you start with.
total_earnable :: proc() -> int {
	total := START_COINS
	for room in 0 ..< ROOM_COUNT {
		for row in ROOMS[room].tiles {
			for c in row {
				switch c {
				case '$': total += 1
				case 'g': total += GEM_VALUE
				}
				if kind, ok := enemy_kind_of(u8(c)); ok {
					total += ENEMY_DEFS[kind].drop
				}
			}
		}
	}
	return total
}
