extends Node
## Persistence for meta-progression: total XP, permanent upgrades,
## leaderboard, settings. All data lives under user:// — never res://.

const SAVE_PATH := "user://goblin_slayer_save.cfg"
const SECTION_META := "meta"
const SECTION_SETTINGS := "settings"
const SECTION_LEADERBOARD := "leaderboard"
const SECTION_RUN := "run"
const RUN_SAVE_VERSION := 1

var _cfg := ConfigFile.new()

# -- Meta state (loaded at boot) -------------------------------------------
var total_xp: int = 0
var upgrades: Dictionary = {} # upgrade_id -> level (int)
var leaderboard: Array = []   # Array[Dictionary]
var language: StringName = &"es"
var music_enabled: bool = true
var sfx_enabled: bool = true
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var saved_run: Dictionary = {} # in-progress run snapshot (empty = none)


func _ready() -> void:
	load_all()


func load_all() -> void:
	# ConfigFile.load merges keys; start fresh so missing legacy settings use defaults.
	_cfg.clear()
	if _cfg.load(SAVE_PATH) != OK:
		return # first run — defaults are fine
	total_xp = int(_cfg.get_value(SECTION_META, "total_xp", 0))
	upgrades = _cfg.get_value(SECTION_META, "upgrades", {})
	leaderboard = _cfg.get_value(SECTION_META, "leaderboard", [])
	language = StringName(_cfg.get_value(SECTION_SETTINGS, "language", "es"))
	music_enabled = bool(_cfg.get_value(SECTION_SETTINGS, "music_enabled", true))
	sfx_enabled = bool(_cfg.get_value(SECTION_SETTINGS, "sfx_enabled", true))
	music_volume = _load_volume("music_volume")
	sfx_volume = _load_volume("sfx_volume")
	var loaded_run: Variant = _cfg.get_value(SECTION_RUN, "data", {})
	if _valid_run_snapshot(loaded_run):
		saved_run = loaded_run
	else:
		saved_run = {}
		if loaded_run != {}:
			_cfg.set_value(SECTION_RUN, "data", {})
			_cfg.save(SAVE_PATH)


func save() -> void:
	_cfg.set_value(SECTION_META, "total_xp", total_xp)
	_cfg.set_value(SECTION_META, "upgrades", upgrades)
	_cfg.set_value(SECTION_META, "leaderboard", leaderboard)
	_cfg.set_value(SECTION_SETTINGS, "language", String(language))
	_cfg.set_value(SECTION_SETTINGS, "music_enabled", music_enabled)
	_cfg.set_value(SECTION_SETTINGS, "sfx_enabled", sfx_enabled)
	_cfg.set_value(SECTION_SETTINGS, "music_volume", music_volume)
	_cfg.set_value(SECTION_SETTINGS, "sfx_volume", sfx_volume)
	_cfg.set_value(SECTION_RUN, "data", saved_run)
	var err := _cfg.save(SAVE_PATH)
	if err != OK:
		push_error("SaveManager: failed to write save file (%s)" % error_string(err))


func _load_volume(key: String) -> float:
	var value: Variant = _cfg.get_value(SECTION_SETTINGS, key, 1.0)
	if typeof(value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(value)):
		return 1.0
	return clampf(float(value), 0.0, 1.0)


func set_audio_enabled(channel: StringName, enabled: bool) -> void:
	if channel == &"Music":
		music_enabled = enabled
	elif channel == &"SFX":
		sfx_enabled = enabled
	else:
		return
	SignalBus.audio_settings_changed.emit()


func set_audio_volume(channel: StringName, volume: float) -> void:
	if not is_finite(volume):
		return
	if channel == &"Music":
		music_volume = clampf(volume, 0.0, 1.0)
	elif channel == &"SFX":
		sfx_volume = clampf(volume, 0.0, 1.0)
	else:
		return
	SignalBus.audio_settings_changed.emit()


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
	return _valid_run_snapshot(saved_run)


func _valid_run_snapshot(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var run: Dictionary = data
	var version: Variant = run.get("version", RUN_SAVE_VERSION)
	if typeof(version) != TYPE_INT or version != RUN_SAVE_VERSION:
		return false
	var mode: Variant = run.get("mode", "story")
	if not (mode is String or mode is StringName) or String(mode) not in ["story", "endless"]:
		return false
	for key in ["elapsed", "score", "gold", "moves", "kills", "kills_since", "run_xp", "streak", "dmg", "dr", "ropes"]:
		if not _nonnegative_int(run.get(key, 0)):
			return false
	var level: Variant = run.get("level", 1)
	var max_hp: Variant = run.get("max_hp", GameConfig.INITIAL_PLAYER_HP)
	var hp: Variant = run.get("hp", max_hp)
	if not _nonnegative_int(level) or level < 1:
		return false
	if not _nonnegative_int(max_hp) or max_hp < 1 or not _nonnegative_int(hp) or hp < 1 or hp > max_hp:
		return false
	for key in ["torch", "poison", "fire"]:
		if typeof(run.get(key, false)) != TYPE_BOOL:
			return false
	var milestones: Variant = run.get("milestones", [])
	if not milestones is Array:
		return false
	for milestone in milestones:
		if not _nonnegative_int(milestone):
			return false
	var items: Variant = run.get("items", [])
	if not items is Array:
		return false
	for item in items:
		if not (item is String or item is StringName) or GoblinDB.item_by_id(StringName(item)).is_empty():
			return false
	var tiles: Variant = run.get("tiles", [])
	if not tiles is Array or tiles.is_empty() or tiles.size() > GameConfig.GRID_SIZE * GameConfig.GRID_SIZE:
		return false
	var occupied := {}
	for tile in tiles:
		if not tile is Dictionary:
			return false
		for key in ["kind", "row", "col"]:
			if typeof(tile.get(key)) != TYPE_INT:
				return false
		var kind: int = tile.kind
		var row: int = tile.row
		var col: int = tile.col
		if kind < BoardTile.Kind.GOBLIN or kind > BoardTile.Kind.SHOP:
			return false
		if row < 0 or row >= GameConfig.GRID_SIZE or col < 0 or col >= GameConfig.GRID_SIZE:
			return false
		var cell := row * GameConfig.GRID_SIZE + col
		if occupied.has(cell):
			return false
		occupied[cell] = true
		for key in ["value", "hp", "max_hp", "poisoned", "turns"]:
			if not _nonnegative_int(tile.get(key, 0)):
				return false
		if typeof(tile.get("golden", false)) != TYPE_BOOL:
			return false
		var variant: Variant = tile.get("variant", "")
		if not variant is String:
			return false
		if variant != "" and (not variant.begins_with("variant_") or not variant.ends_with(".png")
				or variant.get_file() != variant or not ResourceLoader.exists("res://assets/sprites/variants/" + variant, "Texture2D")):
			return false
		if kind == BoardTile.Kind.GOBLIN:
			if not GoblinDB.STATS.has(tile.get("value", 0)):
				return false
			var goblin_max_hp: int = tile.get("max_hp", 1)
			var goblin_hp: int = tile.get("hp", 1)
			if goblin_max_hp < 1 or goblin_hp < 1 or goblin_hp > goblin_max_hp:
				return false
		else:
			if tile.get("turns", 0) < 1:
				return false
	return true


func _nonnegative_int(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and value >= 0


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
				"turns": t.turns_left, "row": r, "col": c,
			})
	var ms: Array = []
	for k in rs.milestones.keys():
		ms.append(int(k))
	var items: Array = []
	for i in rs.purchased_items:
		items.append(String(i))
	saved_run = {
		"version": RUN_SAVE_VERSION,
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
