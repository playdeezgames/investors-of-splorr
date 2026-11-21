#!/usr/bin/env bash
# Build the wasm game into build/web. Pass --size for the shipping build.
set -euo pipefail
cd "$(dirname "$0")/.."
opt=speed
[[ "${1:-}" == "--size" ]] && opt=size
mkdir -p build/web
odin build src/web -collection:tggd=src -target:js_wasm32 -out:build/web/game.wasm -o:$opt -vet-shadowing -vet-unused
cp "$(odin root)/core/sys/wasm/js/odin.js" build/web/
cp web/index.html web/lootlocker.js build/web/
mkdir -p build/web/art
# The two sheets the game draws from (built by tools/make_cc0_art.py); the CC0 sources are not shipped.
cp assets/cc0/sprites_16x16.png assets/cc0/shop_32x32.png build/web/art/
mkdir -p build/web/claude
cp assets/claude/*.png build/web/claude/
mkdir -p build/web/sfx
cp assets/sfx/*.wav build/web/sfx/
cp assets/font/dbyte_1x.png build/web/font.png
echo "built build/web ($opt)"
