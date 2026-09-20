extends Node
## Persistence for meta-progression: total XP, permanent upgrades,
## leaderboard, settings. All data lives under user:// — never res://.

const SAVE_PATH := "user://goblin_slayer_save.cfg"
const SECTION_META := "meta"
const SECTION_SETTINGS := "settings"
const SECTION_LEADERBOARD := "leaderboard"
const SECTION_RUN := "run"

var _cfg := ConfigFile.new()

# -- Meta state (loaded at boot) -------------------------------------------
var total_xp: int = 0
var upgrades: Dictionary = {} # upgrade_id -> level (int)
var leaderboard: Array = []   # Array[Dictionary]
var language: StringName = &"es"
var music_enabled: bool = true
var saved_run: Dictionary = {} # in-progress run snapshot (empty = none)


func _ready() -> void:
	load_all()


func load_all() -> void:
	if _cfg.load(SAVE_PATH) != OK:
		return # first run — defaults are fine
	total_xp = int(_cfg.get_value(SECTION_META, "total_xp", 0))
	upgrades = _cfg.get_value(SECTION_META, "upgrades", {})
	leaderboard = _cfg.get_value(SECTION_META, "leaderboard", [])
	language = StringName(_cfg.get_value(SECTION_SETTINGS, "language", "es"))
	music_enabled = bool(_cfg.get_value(SECTION_SETTINGS, "music_enabled", true))
	saved_run = _cfg.get_value(SECTION_RUN, "data", {})


func save() -> void:
	_cfg.set_value(SECTION_META, "total_xp", total_xp)
	_cfg.set_value(SECTION_META, "upgrades", upgrades)
	_cfg.set_value(SECTION_META, "leaderboard", leaderboard)
	_cfg.set_value(SECTION_SETTINGS, "language", String(language))
	_cfg.set_value(SECTION_SETTINGS, "music_enabled", music_enabled)
	_cfg.set_value(SECTION_RUN, "data", saved_run)
	var err := _cfg.save(SAVE_PATH)
	if err != OK:
		push_error("SaveManager: failed to write save file (%s)" % error_string(err))


func upgrade_level(id: StringName) -> int:
	return int(upgrades.get(id, 0))


func buy_upgrade(id: StringName, cost: int, max_level: int) -> bool:
	if total_xp < cost or upgrade_level(id) >= max_level:
		return false
	total_xp -= cost
	upgrades[id] = upgrade_level(id) + 1
	save()
	return true


func has_saved_run() -> bool:
	return not saved_run.is_empty() and not saved_run.get("tiles", []).is_empty()


## Snapshot the whole run (grid + state) so it survives app restarts.
func save_run(grid: Array, rs: RunState) -> void:
	var tiles: Array = []
	for r in GameConfig.GRID_SIZE:
		for c in GameConfig.GRID_SIZE:
			var t: BoardTile = grid[r][c]
			if t == null:
				continue
			tiles.append({
				"kind": int(t.kind), "value": t.value, "hp": t.hp, "max_hp": t.max_hp,
				"poisoned": t.poisoned, "golden": t.is_golden, "variant": t.variant_file,
				"row": r, "col": c,
			})
	var ms: Array = []
	for k in rs.milestones.keys():
		ms.append(int(k))
	var items: Array = []
	for i in rs.purchased_items:
		items.append(String(i))
	saved_run = {
		"mode": String(rs.mode), "elapsed": rs.elapsed_seconds(), "tiles": tiles,
		"score": rs.score, "gold": rs.gold, "hp": rs.player_hp, "max_hp": rs.player_max_hp,
		"moves": rs.moves_count, "level": rs.level, "kills": rs.kills,
		"kills_since": rs.kills_since_level, "run_xp": rs.run_xp, "streak": rs.kill_streak,
		"milestones": ms, "items": items,
		"dmg": rs.damage_bonus, "dr": rs.damage_reduction, "torch": rs.torch_active,
		"poison": rs.poison_active, "fire": rs.fire_scroll_active, "ropes": rs.rope_count,
	}
	save()


func clear_run() -> void:
	saved_run = {}
	save()


func add_leaderboard_entry(entry: Dictionary) -> void:
	leaderboard.append(entry)
	leaderboard.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("time", 0)) < int(b.get("time", 0)))
	leaderboard = leaderboard.slice(0, 10)
	save()
