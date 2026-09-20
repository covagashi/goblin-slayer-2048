#!/bin/bash
# Visual QA: boots the game windowed; the game saves viewport PNGs itself.
# Usage: tools/screenshot.sh [out_dir]
set -u
OUT="${1:-/tmp/gs2048_shots}"
mkdir -p "$OUT"
cd "$(dirname "$0")/.."

godot -- auto_story auto_moves auto_shot "shot_dir=$OUT" auto_quit &
wait $!
echo "shots in $OUT"
ls -la "$OUT"
