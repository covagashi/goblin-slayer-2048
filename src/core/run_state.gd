class_name RunState
extends Resource
## Owns all per-run data. Emits signals — presentation listens, never writes.

signal stats_changed
signal items_changed
signal log_added(message: String)

var mode: StringName = &"story"
var over: bool = false
var won: bool = false
var over_reason_key: StringName = &""

var score: int = 0
var gold: int = 0
var player_hp: int = GameConfig.INITIAL_PLAYER_HP
var player_max_hp: int = GameConfig.INITIAL_PLAYER_HP
var moves_count: int = 0
var level: int = 1
var kills: int = 0
var kills_since_level: int = 0
var run_xp: int = 0
var kill_streak: int = 0
var milestones: Dictionary = {}
var start_msec: int = 0

# Run items
var purchased_items: Array[StringName] = []
var damage_bonus: int = 0
var damage_reduction: int = 0
var torch_active: bool = false
var poison_active: bool = false
var fire_scroll_active: bool = false
var rope_count: int = 0


func reset(new_mode: StringName, upgrades: Dictionary) -> void:
	mode = new_mode
	over = false
	won = false
	over_reason_key = &""
	score = 0
	gold = GameConfig.INITIAL_GOLD + int(upgrades.get(&"startGold", 0)) * 100
	player_max_hp = GameConfig.INITIAL_PLAYER_HP + int(upgrades.get(&"maxHp", 0)) * 5
	player_hp = player_max_hp
	moves_count = 0
	level = 1
	kills = 0
	kills_since_level = 0
	run_xp = 0
	kill_streak = 0
	milestones = {}
	start_msec = Time.get_ticks_msec()
	purchased_items = []
	damage_bonus = 0
	damage_reduction = 0
	torch_active = false
	poison_active = false
	fire_scroll_active = false
	rope_count = 0
	stats_changed.emit()
	items_changed.emit()


func xp_multiplier(upgrades: Dictionary) -> float:
	return 1.25 if int(upgrades.get(&"xpBonus", 0)) > 0 else 1.0


func drop_chance(upgrades: Dictionary) -> float:
	return GameConfig.POWERUP_DROP_CHANCE + int(upgrades.get(&"powerupFreq", 0)) * 0.15


func combine_damage(upgrades: Dictionary) -> int:
	return GameConfig.COMBINE_BASE_DAMAGE + damage_bonus + int(upgrades.get(&"baseDamage", 0))


func apply_item(id: StringName) -> void:
	match id:
		&"healthPotion":
			player_hp = mini(player_max_hp, player_hp + 5)
		&"sword":
			damage_bonus += 1
		&"torch":
			torch_active = true
		&"shield":
			damage_reduction += 1
		&"poison":
			poison_active = true
		&"fireScroll":
			fire_scroll_active = true
		&"rope":
			rope_count += 1
	purchased_items.append(id)
	stats_changed.emit()
	items_changed.emit()


func add_log(message: String) -> void:
	log_added.emit(message)


func elapsed_seconds() -> int:
	return int((Time.get_ticks_msec() - start_msec) / 1000.0)


func _touch() -> void:
	stats_changed.emit()
