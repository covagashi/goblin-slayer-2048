#!/usr/bin/env bash
# Run all isolated scenarios in one Godot process to avoid repeated engine startup.
# Usage: tools/e2e.sh [godot_binary]
set -u
cd "$(dirname "$0")/.."
GODOT="${1:-godot}"
out="$("$GODOT" --headless -- qa=all 2>&1)"
code=$?
printf '%s\n' "$out" | rg '^\[E2E\].*=>'
if [ "$code" -ne 0 ] || printf '%s\n' "$out" | rg -q 'FAIL|SCRIPT ERROR|Parse Error|^ERROR:' || ! printf '%s\n' "$out" | rg -q '^\[E2E\] all => .* 0 failed across [0-9]+ scenarios$'; then
  printf '%s\n' "$out" | rg 'FAIL|SCRIPT ERROR|Parse Error|^ERROR:' || printf '%s\n' "$out"
  echo "FAILURES FOUND"
  exit 1
fi
echo "ALL SCENARIOS PASSED"
