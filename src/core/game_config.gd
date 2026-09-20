class_name GameConfig
extends RefCounted
## Balance constants — single source of truth, ported 1:1 from the React
## version plus the new extras (variants, golden goblin, streaks).

const GRID_SIZE := 4
const INITIAL_PLAYER_HP := 20
const INITIAL_GOLD := 10
const COMBINE_BASE_DAMAGE := 2
const OVERCROWDING_DAMAGE := 1
const CHEST_SPAWN_CHANCE := 0.05
const POWERUP_DROP_CHANCE := 0.15
const CHEST_GOLD_REWARD := 20
const DROP_GOLD_REWARD := 10
const WIN_VALUE := 256
const KILLS_PER_LEVEL := 10
const HORDE_DAMAGE_CAP := 8
const SHOP_LEVEL_INTERVAL := 5
const POISON_TURNS := 3
const FIRE_AOE_DAMAGE := 1
const HORDE_WARNING_MOVES := 3
const SWIPE_MIN_DIST_PX := 24.0

# --- Extras ----------------------------------------------------------------
const VARIANT_SPAWN_CHANCE := 0.05   # cosmetic variant skin on new goblins
const GOLDEN_SPAWN_CHANCE := 0.01    # ultra-rare golden goblin
const GOLDEN_GOLD_MULT := 10
const STREAK_GOLD_PCT := 0.10        # +10% kill gold per streak level beyond 1

# --- Input actions (desktop/testing) ---------------------------------------
const DIR_VECTORS := {
	&"left": Vector2i(-1, 0),
	&"right": Vector2i(1, 0),
	&"up": Vector2i(0, -1),
	&"down": Vector2i(0, 1),
}
