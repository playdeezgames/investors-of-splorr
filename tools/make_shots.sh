#!/usr/bin/env bash
# Screenshots of the real build with headless Chrome (needs a built build/web and a free port 8123).
# Writes assets/screenshots/01..05 (320x192 logical, scaled 3x). Each page replays keys from the #keys= hash.
# tools/ending_keys.txt is a scripted full run (the bot in game_test.odin); regenerate it if the rules change.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/screenshots
python3 -m http.server -d build/web 8123 >/dev/null 2>&1 &
srv=$!
trap 'kill $srv' EXIT
sleep 1
shot() { # name keys
	google-chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size=960,576 \
		--virtual-time-budget=3000 --screenshot="assets/screenshots/$1.png" "http://localhost:8123/?$1#keys=$2" >/dev/null 2>&1
}
rep() { printf "%${2}s" "" | tr ' ' "$1"; }
shot 01-made-with-ai ""
shot 02-title "C"
shot 03-quiet-room "CC$(rep R 6)"
shot 04-shopkeeper "CC$(rep R 35)UUURRRRRRRRX"
shot 05-peace-of-mind "CC$(tr -d '\n' < tools/ending_keys.txt)"
ls -l assets/screenshots
