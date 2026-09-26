#!/usr/bin/env bash
# Runs every headless e2e scenario: godot -- qa=<name>
# Usage: tools/e2e.sh [godot_binary]
set -u
cd "$(dirname "$0")/.."

GODOT="${1:-godot}"
SCENARIOS=(
  core merge_kill chest golden streak
  shop shop_expiry rope fire
  gameover victory endless overcrowding
  upgrades leaderboard persistence assets safe_area i18n
  chaos chaos_endless menu_cycle
  lang clicklang swipe_input touch_ui horde_warning info_pages continue continue_invalid
)

fail=0
for s in "${SCENARIOS[@]}"; do
  out="$("$GODOT" --headless -- "qa=$s" 2>&1)"
  code=$?
  line="$(echo "$out" | grep '^\[E2E\].*=>' | tail -1)"
  printf '%-14s %s\n' "$s" "${line:-NO RESULT (exit=$code)}"
  if [ $code -ne 0 ]; then
    fail=1
    echo "$out" | grep -E 'FAIL|SCRIPT ERROR' | sed 's/^/    /'
  fi
done

echo "---"
[ $fail -eq 0 ] && echo "ALL SCENARIOS PASSED" || { echo "FAILURES FOUND"; exit 1; }
