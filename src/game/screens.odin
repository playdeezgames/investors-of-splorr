package game

// Words for the screens around the game. The AI statement is the very first thing the player sees
// (the Intro phase); keep every line under 52 characters so it fits at scale 1.

AI_HEADLINE :: "MADE WITH AI"

AI_LINES := [?]string {
	"A human and an AI made this game together.",
	"The human was product owner and tester.",
	"Claude Code wrote the code, the tests, the sound,",
	"the words, and drew some of the art.",
	"",
	"Not a fan of AI? Play first. Then imagine what",
	"you could build with a partner like this.",
}

CREDITS_LINES := [?]string {
	"Art: Bit Bonanza, Bountiful Bits by VEXED (CC0)",
	"v3x3d.itch.io",
	"Extra sprites, sound, code and words:",
	"Claude Code, an AI",
	"Font: DINOBYTE by mby (CC BY 4.0)",
	"",
	"Made for 1-Bit Jam 15: Everything Has a Price",
}
