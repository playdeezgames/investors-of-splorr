package game

// Room maps: 20 by 9. '#' wall, '.' floor, '@' start, '$' coin, 'g' gem, 'M' shopkeeper,
// 's' slime, 'i' imp, 'k' skull, '>' door onward, '<' door back, 'X' the exit.
//
// The arc (task 108): two free, empty, quiet rooms; then the first shopkeeper and the first toll;
// a dark room with a guarded gem; the same quiet room again, now charging for stillness; a forced
// fight; and the exit. Each toll in DOOR_TOLLS sits on the door leaving the room of that number.

Room_Def :: struct {
	tiles:     [ROOM_H]string,
	dark:      bool,
	rest_base: int, // 0: standing still is free here
	intro:     string,
}

ROOM_COUNT :: 7

ROOMS := [ROOM_COUNT]Room_Def {
	{ // 0: quiet and free
		tiles = {
			"####################",
			"#..................#",
			"#..................#",
			"#..................#",
			"#.@................>",
			"#..................#",
			"#..................#",
			"#..................#",
			"####################",
		},
		intro = "A quiet room. Nobody wants anything from you.",
	},
	{ // 1: quiet and free
		tiles = {
			"####################",
			"#..................#",
			"#....##......##....#",
			"#..................#",
			"<..................>",
			"#..................#",
			"#....##......##....#",
			"#..................#",
			"####################",
		},
		intro = "Another quiet room. You may stay as long as you like.",
	},
	{ // 2: the first shopkeeper; a slime holds the gap to the door
		tiles = {
			"####################",
			"#........M....#....#",
			"#..$..........#..$.#",
			"#.............#....#",
			"<.............s....>",
			"#.......$.....#....#",
			"#.............#....#",
			"#...........$.#....#",
			"####################",
		},
		intro = "A shopkeeper. He has opportunities.",
	},
	{ // 3: dark; an imp guards a gem
		tiles = {
			"####################",
			"#M.....#...........#",
			"#......#...###.....#",
			"#..........#g#..$..#",
			"<....#.....#i#.....>",
			"#....#.....#.#.....#",
			"#..$.#.............#",
			"#....#.......$.....#",
			"####################",
		},
		dark = true,
		intro = "It is dark in here.",
	},
	{ // 4: quiet again, but stillness has a price now
		tiles = {
			"####################",
			"#..................#",
			"#....##......##....#",
			"#..................#",
			"<.........M........>",
			"#..................#",
			"#....##......##....#",
			"#..................#",
			"####################",
		},
		rest_base = 2,
		intro = "A quiet room. You have been here before.",
	},
	{ // 5: a skull holds the only gap; gems on the near side
		tiles = {
			"####################",
			"#.........#........#",
			"#...g.....#........#",
			"#.........#.....$..#",
			"<.........k........>",
			"#.........#........#",
			"#...g.....#.$......#",
			"#.........#........#",
			"####################",
		},
		intro = "Something is guarding the way on.",
	},
	{ // 6: the exit
		tiles = {
			"####################",
			"#..................#",
			"#................M.#",
			"#..................#",
			"<..................X",
			"#..................#",
			"#..................#",
			"#..................#",
			"####################",
		},
		intro = "The last room.",
	},
}

// The shopkeeper's voice. He never says "price", "cost" or "fee" (a test pins it): every charge is an
// investment or an opportunity, said with complete sincerity, the amount printed plainly. A line must
// fit the message box: three rows of 52 characters.
SHOP_GREETING   :: "Welcome, valued investor. I have opportunities."
SHOP_FAREWELL   :: "Your portfolio thanks you. Do return."
SHOP_REFUSAL    :: "A fine opportunity, a little out of reach. It will keep."
RESERVE_LINE    :: "A prudent investor keeps something in reserve."
NO_SWING        :: "A swing is an investment. You have nothing to invest."
TORCH_LINE      :: "Light. An excellent position to hold."
HEAL_LINE       :: "As good as new. Your best holding, I always say."
EXIT_DECLINED   :: "Of course. Peace of Mind will keep. It always has."
BANKRUPT_LINE   :: "You have nothing left to invest. I am sorry. Truly."

// Shown with the Peace of Mind ending: straight, and warm.
PEACE_LINES := [?]string {
	"You had it in the quiet rooms.",
	"It was never for sale.",
	"Thank you for investing.",
}

TIPS := [?]string {
	"Doors are an opportunity. They renew every time you pass.",
	"A slime is worth more than the swing it takes.",
	"Empty rooms are for resting. For now.",
	"Gems keep their value. So do I.",
}
