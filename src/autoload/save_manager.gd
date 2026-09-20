extends Node
## Persistence for meta-progression: total XP, permanent upgrades,
## leaderboard, settings. All data lives under user:// — never res://.

const SAVE_PATH := "user://goblin_slayer_save.cfg"
const SECTION_META := "meta"
const SECTION_SETTINGS := "settings"
const SECTION_LEADERBOARD := "leaderboard"

var _cfg := ConfigFile.new()

# -- Meta state (loaded at boot) -------------------------------------------
var total_xp: int = 0
var upgrades: Dictionary = {} # upgrade_id -> level (int)
var leaderboard: Array = []   # Array[Dictionary]
var language: StringName = &"es"
var music_enabled: bool = true


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


func save() -> void:
	_cfg.set_value(SECTION_META, "total_xp", total_xp)
	_cfg.set_value(SECTION_META, "upgrades", upgrades)
	_cfg.set_value(SECTION_META, "leaderboard", leaderboard)
	_cfg.set_value(SECTION_SETTINGS, "language", String(language))
	_cfg.set_value(SECTION_SETTINGS, "music_enabled", music_enabled)
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


func add_leaderboard_entry(entry: Dictionary) -> void:
	leaderboard.append(entry)
	leaderboard.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("time", 0)) < int(b.get("time", 0)))
	leaderboard = leaderboard.slice(0, 10)
	save()
