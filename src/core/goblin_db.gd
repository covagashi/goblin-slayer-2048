class_name GoblinDB
extends RefCounted
## Static data tables — goblin stats, XP, shop catalog, permanent upgrades.

const STATS := {
	2: {"hp": 1, "gold": 2, "damage": 1},
	4: {"hp": 2, "gold": 4, "damage": 1},
	8: {"hp": 4, "gold": 8, "damage": 2},
	16: {"hp": 8, "gold": 15, "damage": 2},
	32: {"hp": 15, "gold": 25, "damage": 3},
	64: {"hp": 25, "gold": 40, "damage": 3},
	128: {"hp": 40, "gold": 60, "damage": 4},
	256: {"hp": 60, "gold": 100, "damage": 4},
}

const XP := {2: 1, 4: 3, 8: 8, 16: 20, 32: 50, 64: 125, 128: 300, 256: 750}

const MILESTONE_REWARDS := {32: 50, 128: 200}

## newValue -> levels gained when that merge result is created
const MERGE_LEVELS := {8: 1, 16: 2, 32: 3}

const SHOP_ITEMS: Array[Dictionary] = [
	{"id": &"healthPotion", "cost": 60, "sprite": "item-health-potion.png", "unique": false},
	{"id": &"torch", "cost": 50, "sprite": "item-torch.png", "unique": true},
	{"id": &"sword", "cost": 120, "sprite": "item-sword.png", "unique": true},
	{"id": &"shield", "cost": 150, "sprite": "item-shield.png", "unique": true},
	{"id": &"poison", "cost": 180, "sprite": "item-poison.png", "unique": true},
	{"id": &"rope", "cost": 200, "sprite": "item-rope.png", "unique": false},
	{"id": &"fireScroll", "cost": 250, "sprite": "item-fire-scroll.png", "unique": true},
]

const PERMANENT_UPGRADES: Array[Dictionary] = [
	{"id": &"maxHp", "cost": 200, "max_level": 4},
	{"id": &"baseDamage", "cost": 500, "max_level": 3},
	{"id": &"powerupFreq", "cost": 400, "max_level": 2},
	{"id": &"attackTimer", "cost": 800, "max_level": 2},
	{"id": &"xpBonus", "cost": 1000, "max_level": 1},
	{"id": &"startGold", "cost": 600, "max_level": 3},
	{"id": &"overcrowdingResist", "cost": 700, "max_level": 1},
	{"id": &"unlockSword", "cost": 300, "max_level": 1},
	{"id": &"unlockTorch", "cost": 300, "max_level": 1},
	{"id": &"unlockShield", "cost": 300, "max_level": 1},
	{"id": &"unlockHealthPotion", "cost": 600, "max_level": 1},
	{"id": &"unlockPoison", "cost": 600, "max_level": 1},
	{"id": &"unlockRope", "cost": 600, "max_level": 1},
	{"id": &"unlockFireScroll", "cost": 1200, "max_level": 1},
]


static func goblin_stats(value: int, level: int, mode: StringName) -> Dictionary:
	var base: Dictionary = STATS.get(value, {"hp": 1, "gold": 1, "damage": 1})
	var final_hp: int = base.hp + hp_bonus(level, mode)
	return {"hp": final_hp, "max_hp": final_hp, "gold": base.gold, "damage": base.damage}


static func hp_bonus(level: int, mode: StringName) -> int:
	if mode != &"endless":
		return 0
	if level >= 21: return 4
	if level >= 16: return 3
	if level >= 11: return 2
	if level >= 6: return 1
	return 0


static func moves_per_attack(level: int, mode: StringName, upgrades: Dictionary) -> int:
	var base_moves := 15
	if mode == &"endless":
		if level >= 21: base_moves = 11
		elif level >= 16: base_moves = 12
		elif level >= 11: base_moves = 13
		elif level >= 6: base_moves = 14
	return base_moves + int(upgrades.get(&"attackTimer", 0)) * 2


static func spawn_config(level: int) -> Array[Dictionary]:
	if level >= 16:
		return [{"v": 2, "w": 0.30}, {"v": 4, "w": 0.30}, {"v": 8, "w": 0.25}, {"v": 16, "w": 0.10}, {"v": 32, "w": 0.05}]
	if level >= 11:
		return [{"v": 2, "w": 0.50}, {"v": 4, "w": 0.30}, {"v": 8, "w": 0.15}, {"v": 16, "w": 0.05}]
	if level >= 6:
		return [{"v": 2, "w": 0.70}, {"v": 4, "w": 0.25}, {"v": 8, "w": 0.05}]
	return [{"v": 2, "w": 0.85}, {"v": 4, "w": 0.15}]


static func roll_spawn_value(level: int, rng: RandomNumberGenerator) -> int:
	var cfg := spawn_config(level)
	var total := 0.0
	for item in cfg:
		total += item.w
	var roll := rng.randf() * total
	for item in cfg:
		if roll < item.w:
			return int(item.v)
		roll -= item.w
	return 2


static func item_by_id(id: StringName) -> Dictionary:
	for it in SHOP_ITEMS:
		if it.id == id:
			return it
	return {}
