class_name GridEngine
extends RefCounted
## Pure grid logic — no nodes, no signals. Every public op returns
## {grid, events: Array[Dictionary], moved: bool} so the presentation layer
## can animate exactly what happened.
##
## Ported 1:1 from the React App.tsx mechanics, plus variant/golden/streak
## extras. Fixes the original fire-scroll coordinate bug for 'down' swipes.

const S := GameConfig.GRID_SIZE

var rng := RandomNumberGenerator.new()
var spawn_enabled := true # test seam — QA disables to keep boards deterministic
var _id_counter := 0
var _variant_files: PackedStringArray = []


func _init() -> void:
	rng.randomize()
	_load_variant_manifest()


func new_id() -> int:
	_id_counter += 1
	return _id_counter


static func empty_grid() -> Array:
	var g: Array = []
	g.resize(S)
	for r in S:
		var row: Array = []
		row.resize(S)
		g[r] = row
	return g


func _load_variant_manifest() -> void:
	var f := FileAccess.open("res://assets/sprites/variants_manifest.json", FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Array:
		for entry in data:
			_variant_files.append(String(entry.get("file", "")))


func _roll_variant() -> String:
	if _variant_files.is_empty():
		return ""
	return _variant_files[rng.randi_range(0, _variant_files.size() - 1)]


# ---------------------------------------------------------------------------
# Grid helpers
# ---------------------------------------------------------------------------

func get_empty_cells(grid: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for r in S:
		for c in S:
			if grid[r][c] == null:
				cells.append(Vector2i(r, c))
	return cells


func is_board_locked(grid: Array) -> bool:
	if not get_empty_cells(grid).is_empty():
		return false
	for r in S:
		for c in S:
			var t: BoardTile = grid[r][c]
			if t == null:
				continue
			if c < S - 1:
				var right: BoardTile = grid[r][c + 1]
				if right == null or (right.is_goblin() and t.is_goblin() and right.value == t.value and t.value < GameConfig.WIN_VALUE):
					return false
			if r < S - 1:
				var down: BoardTile = grid[r + 1][c]
				if down == null or (down.is_goblin() and t.is_goblin() and down.value == t.value and t.value < GameConfig.WIN_VALUE):
					return false
	return true


func horde_damage(grid: Array, level: int, mode: StringName) -> int:
	var total := 0
	for row in grid:
		for t in row:
			if t != null and (t as BoardTile).is_goblin():
				total += int(GoblinDB.goblin_stats(t.value, level, mode).damage)
	return mini(total, GameConfig.HORDE_DAMAGE_CAP)


static func _reverse(grid: Array) -> Array:
	var out: Array = []
	for row in grid:
		var r2: Array = row.duplicate()
		r2.reverse()
		out.append(r2)
	return out


static func _transpose(grid: Array) -> Array:
	var out := empty_grid()
	for r in S:
		for c in S:
			out[c][r] = grid[r][c]
	return out


static func _to_work(grid: Array, dir: StringName) -> Array:
	match dir:
		&"right": return _reverse(grid)
		&"up": return _transpose(grid)
		&"down": return _reverse(_transpose(grid))
		_: return grid


static func _from_work(grid: Array, dir: StringName) -> Array:
	match dir:
		&"right": return _reverse(grid)
		&"up": return _transpose(grid)
		&"down": return _transpose(_reverse(grid))
		_: return grid


## Maps a work-space cell back to original coordinates.
static func _work_to_orig(cell: Vector2i, dir: StringName) -> Vector2i:
	match dir:
		&"right": return Vector2i(cell.x, S - 1 - cell.y)
		&"up": return Vector2i(cell.y, cell.x)
		&"down": return Vector2i(S - 1 - cell.y, cell.x)
		_: return cell


# ---------------------------------------------------------------------------
# Spawning
# ---------------------------------------------------------------------------

func spawn_tile(grid: Array, level: int, mode: StringName, events: Array) -> Array:
	var cells := get_empty_cells(grid)
	if cells.is_empty():
		return grid
	var at: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
	if rng.randf() < GameConfig.CHEST_SPAWN_CHANCE:
		var chest := BoardTile.new()
		chest.id = new_id()
		chest.kind = BoardTile.Kind.CHEST
		chest.turns_left = GameConfig.CHEST_LIFETIME
		chest.hp = 1
		chest.max_hp = 1
		chest.row = at.x
		chest.col = at.y
		grid[at.x][at.y] = chest
		events.append({"type": &"spawn", "tile": chest, "at": at, "chest": true})
		events.append({"type": &"log", "key": &"log_chest_appeared"})
	else:
		var value := GoblinDB.roll_spawn_value(level, rng)
		var stats := GoblinDB.goblin_stats(value, level, mode)
		var g := BoardTile.new()
		g.id = new_id()
		g.value = value
		g.hp = int(stats.hp)
		g.max_hp = int(stats.max_hp)
		g.row = at.x
		g.col = at.y
		if rng.randf() < GameConfig.GOLDEN_SPAWN_CHANCE:
			g.is_golden = true
			g.variant_file = "variant_26_gold_collector.png"
			events.append({"type": &"golden_spawn", "at": at})
		elif rng.randf() < GameConfig.VARIANT_SPAWN_CHANCE:
			g.variant_file = _roll_variant()
		grid[at.x][at.y] = g
		events.append({"type": &"spawn", "tile": g, "at": at})
		events.append({"type": &"log", "key": &"log_new_goblin", "args": {"value": value}})
	return grid


func spawn_shop_tile(grid: Array, events: Array) -> Array:
	var cells := get_empty_cells(grid)
	if cells.is_empty():
		events.append({"type": &"log", "key": &"log_no_room_for_shop"})
		return grid
	var at: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
	var shop := BoardTile.new()
	shop.id = new_id()
	shop.kind = BoardTile.Kind.SHOP
	shop.turns_left = GameConfig.SHOP_LIFETIME
	shop.row = at.x
	shop.col = at.y
	grid[at.x][at.y] = shop
	events.append({"type": &"spawn", "tile": shop, "at": at})
	events.append({"type": &"log", "key": &"log_shop_appeared"})
	return grid


func _remove_shops(grid: Array, events: Array) -> Array:
	# Shops tick down at move start and vanish (SHOP_LIFETIME moves)
	for r in S:
		for c in S:
			var t: BoardTile = grid[r][c]
			if t != null and t.kind == BoardTile.Kind.SHOP:
				t.turns_left -= 1
				if t.turns_left <= 0:
					grid[r][c] = null
					events.append({"type": &"shop_removed", "id": t.id, "at": Vector2i(r, c)})
					events.append({"type": &"log", "key": &"log_shop_disappeared"})
	return grid


# ---------------------------------------------------------------------------
# Slide + combine (single row, work space — always slides "left")
# ---------------------------------------------------------------------------

func _slide_row(row: Array, rs: RunState, upgrades: Dictionary, row_idx: int, dir: StringName, acc: Dictionary, events: Array) -> Array:
	var filtered: Array = []
	for t in row:
		if t != null:
			filtered.append(t)

	var out: Array = []
	out.resize(S)
	var out_idx := 0
	var skip := false

	for i in filtered.size():
		if skip:
			skip = false
			continue
		var cur: BoardTile = filtered[i]
		var nxt: BoardTile = filtered[i + 1] if i + 1 < filtered.size() else null

		# chests/shops slide but never merge
		if cur.kind != BoardTile.Kind.GOBLIN:
			out[out_idx] = cur
			acc.moves.append({"id": cur.id, "to": _work_to_orig(Vector2i(row_idx, out_idx), dir)})
			out_idx += 1
			continue

		if nxt != null and nxt.kind == BoardTile.Kind.CHEST:
			# goblin consumes the chest, keeps sliding into place
			acc.gold += GameConfig.CHEST_GOLD_REWARD
			acc.chest_opened = true
			events.append({"type": &"chest_opened", "at": _work_to_orig(Vector2i(row_idx, out_idx), dir), "gold": GameConfig.CHEST_GOLD_REWARD})
			events.append({"type": &"log", "key": &"log_chest_opened", "args": {"gold": GameConfig.CHEST_GOLD_REWARD}})
			out[out_idx] = cur
			acc.moves.append({"id": cur.id, "to": _work_to_orig(Vector2i(row_idx, out_idx), dir)})
			acc.consumes.append({"id": nxt.id, "to": _work_to_orig(Vector2i(row_idx, out_idx), dir)})
			out_idx += 1
			skip = true
		elif nxt != null and nxt.is_goblin() and cur.value == nxt.value and cur.value < GameConfig.WIN_VALUE:
			var new_value := cur.value * 2
			var merge_at := _work_to_orig(Vector2i(row_idx, out_idx), dir)

			var lvls: int = GoblinDB.MERGE_LEVELS.get(new_value, 0)
			if lvls > 0:
				acc.levels.append({"levels": lvls, "value": new_value})
			if rs.mode == &"story" and new_value == GameConfig.WIN_VALUE:
				acc.won = true

			var stats := GoblinDB.goblin_stats(new_value, rs.level, rs.mode)
			var total_damage: int = rs.combine_damage(upgrades)
			if new_value >= 8:
				total_damage = mini(total_damage, int(stats.hp) - 1)
			var new_hp: int = int(stats.hp) - total_damage

			events.append({"type": &"merge", "at": merge_at, "value": new_value, "damage": total_damage})
			acc.merge_cells.append(merge_at)
			events.append({"type": &"log", "key": &"log_goblin_combine_damage", "args": {"value": cur.value, "damage": total_damage}})
			acc.consumes.append({"id": cur.id, "to": merge_at})
			acc.consumes.append({"id": nxt.id, "to": merge_at})

			if new_hp <= 0:
				# SLAIN
				var gold_val: int = int(stats.gold) * (GameConfig.GOLDEN_GOLD_MULT if (cur.is_golden or nxt.is_golden) else 1)
				var xp_val := int(round(float(GoblinDB.XP.get(new_value, 0)) * rs.xp_multiplier(upgrades)))
				acc.points += new_value
				acc.kill_gold += gold_val
				acc.xp += xp_val
				acc.kills += 1
				events.append({"type": &"slain", "at": merge_at, "value": new_value, "gold": gold_val, "xp": xp_val, "golden": cur.is_golden or nxt.is_golden})
				events.append({"type": &"log", "key": &"log_goblin_slain", "args": {"value": new_value, "score": new_value, "gold": gold_val}})
				if rng.randf() < rs.drop_chance(upgrades):
					acc.gold += GameConfig.DROP_GOLD_REWARD
					events.append({"type": &"log", "key": &"log_goblin_drop", "args": {"gold": GameConfig.DROP_GOLD_REWARD}})
			else:
				# SURVIVES with reduced hp
				var survivor := BoardTile.new()
				survivor.id = new_id()
				survivor.value = new_value
				survivor.hp = new_hp
				survivor.max_hp = int(stats.max_hp)
				if cur.is_golden or nxt.is_golden:
					survivor.is_golden = true
					survivor.variant_file = "variant_26_gold_collector.png"
				elif rng.randf() < GameConfig.VARIANT_SPAWN_CHANCE:
					survivor.variant_file = _roll_variant()
				if rs.poison_active:
					survivor.poisoned = GameConfig.POISON_TURNS
					events.append({"type": &"poisoned", "at": merge_at})
					events.append({"type": &"log", "key": &"log_goblin_poisoned", "args": {"value": new_value}})
				out[out_idx] = survivor
				acc.merge_results.append({"tile": survivor, "at": merge_at})
				acc.points += int(new_value / 2)
				events.append({"type": &"log", "key": &"log_goblin_survived", "args": {"value": new_value, "hp": new_hp}})

			if GoblinDB.MILESTONE_REWARDS.has(new_value) and not rs.milestones.has(new_value):
				var reward: int = GoblinDB.MILESTONE_REWARDS[new_value]
				rs.milestones[new_value] = true
				acc.gold += reward
				events.append({"type": &"milestone", "at": merge_at, "value": new_value, "gold": reward})
				events.append({"type": &"log", "key": &"log_milestone", "args": {"value": new_value, "gold": reward}})
			out_idx += 1
			skip = true
		else:
			out[out_idx] = cur
			acc.moves.append({"id": cur.id, "to": _work_to_orig(Vector2i(row_idx, out_idx), dir)})
			out_idx += 1

	return out


func _row_signature(row: Array) -> Array:
	var sig: Array = []
	for t in row:
		sig.append(t.id if t != null else -1)
	return sig


# ---------------------------------------------------------------------------
# DoT / AoE passes
# ---------------------------------------------------------------------------

func _apply_poison(grid: Array, rs: RunState, upgrades: Dictionary, acc: Dictionary, events: Array) -> Array:
	for r in S:
		for c in S:
			var t: BoardTile = grid[r][c]
			if t != null and t.is_goblin() and t.poisoned > 0:
				t.hp -= 1
				t.poisoned -= 1
				var at := Vector2i(r, c)
				if t.hp <= 0:
					var stats := GoblinDB.goblin_stats(t.value, rs.level, rs.mode)
					var gold_val: int = int(stats.gold) * (GameConfig.GOLDEN_GOLD_MULT if t.is_golden else 1)
					var xp_val := int(round(float(GoblinDB.XP.get(t.value, 0)) * rs.xp_multiplier(upgrades)))
					grid[r][c] = null
					acc.points += t.value
					acc.kill_gold += gold_val
					acc.xp += xp_val
					acc.kills += 1
					events.append({"type": &"poison_tick", "at": at, "died": true, "value": t.value, "id": t.id})
					events.append({"type": &"slain", "at": at, "value": t.value, "gold": gold_val, "xp": xp_val, "golden": t.is_golden})
					events.append({"type": &"log", "key": &"log_poison_death", "args": {"value": t.value}})
				else:
					events.append({"type": &"poison_tick", "at": at, "died": false, "id": t.id})
					events.append({"type": &"log", "key": &"log_poison_damage", "args": {"value": t.value}})
	return grid


func _apply_fire(grid: Array, rs: RunState, upgrades: Dictionary, merge_cells: Array, acc: Dictionary, events: Array) -> Array:
	if merge_cells.is_empty():
		return grid
	events.append({"type": &"fire_trigger", "cells": merge_cells})
	events.append({"type": &"log", "key": &"log_fire_scroll_trigger"})
	var hit := {}
	for mc in merge_cells:
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				var at := Vector2i(mc.x + dr, mc.y + dc)
				if at.x < 0 or at.x >= S or at.y < 0 or at.y >= S or hit.has(at):
					continue
				hit[at] = true
				var t: BoardTile = grid[at.x][at.y]
				if t != null and t.is_goblin():
					t.hp -= GameConfig.FIRE_AOE_DAMAGE
					if t.hp <= 0:
						var stats := GoblinDB.goblin_stats(t.value, rs.level, rs.mode)
						var gold_val: int = int(stats.gold) * (GameConfig.GOLDEN_GOLD_MULT if t.is_golden else 1)
						var xp_val := int(round(float(GoblinDB.XP.get(t.value, 0)) * rs.xp_multiplier(upgrades)))
						grid[at.x][at.y] = null
						acc.points += t.value
						acc.kill_gold += gold_val
						acc.xp += xp_val
						acc.kills += 1
						events.append({"type": &"slain", "at": at, "value": t.value, "gold": gold_val, "xp": xp_val, "golden": t.is_golden, "fire": true})
						events.append({"type": &"log", "key": &"log_splash_death", "args": {"value": t.value}})
					else:
						events.append({"type": &"fire_hit", "at": at, "id": t.id})
						events.append({"type": &"log", "key": &"log_splash_damage", "args": {"value": t.value}})
	return grid


# ---------------------------------------------------------------------------
# Main entry: perform a move
# ---------------------------------------------------------------------------

func move(grid: Array, dir: StringName, rs: RunState, upgrades: Dictionary) -> Dictionary:
	var events: Array = []
	var acc := {"points": 0, "gold": 0, "kill_gold": 0, "xp": 0, "kills": 0,
		"levels": [], "moves": [], "consumes": [], "merge_results": [],
		"merge_cells": [], "chest_opened": false, "won": false}

	if rs.over:
		return {"grid": grid, "events": events, "moved": false}

	var original := grid
	grid = _remove_shops(grid, events)
	grid = _apply_poison(grid, rs, upgrades, acc, events)

	var work := _to_work(grid, dir)
	var moved := false
	var new_work := empty_grid()
	for r in S:
		var new_row := _slide_row(work[r], rs, upgrades, r, dir, acc, events)
		new_work[r] = new_row
		if _row_signature(new_row) != _row_signature(work[r]):
			moved = true

	if not moved:
		# Overcrowding: board locked and player tried to move
		if is_board_locked(original):
			var dmg: int = maxi(0, GameConfig.OVERCROWDING_DAMAGE - int(upgrades.get(&"overcrowdingResist", 0)))
			if dmg > 0:
				rs.player_hp -= dmg
				events.append({"type": &"overcrowding", "damage": dmg})
				events.append({"type": &"log", "key": &"log_overcrowding_damage", "args": {"damage": dmg}})
				if rs.player_hp <= 0:
					rs.over = true
					rs.over_reason_key = &"reason_crushed"
					events.append({"type": &"game_over", "reason": &"reason_crushed"})
			else:
				events.append({"type": &"log", "key": &"log_overcrowding_resist"})
		return {"grid": original, "events": events, "moved": false}

	# Collect merge cells in original space for the fire scroll
	# (all merges — even when the resulting goblin dies)
	var merge_cells: Array[Vector2i] = []
	for mc in acc.merge_cells:
		merge_cells.append(mc)

	var new_grid := _from_work(new_work, dir)

	if rs.fire_scroll_active and not merge_cells.is_empty():
		new_grid = _apply_fire(new_grid, rs, upgrades, merge_cells, acc, events)

	# Unopened chests tick down and vanish (CHEST_LIFETIME moves)
	var chest_vanished := false
	for r in S:
		for c in S:
			var t: BoardTile = new_grid[r][c]
			if t != null and t.kind == BoardTile.Kind.CHEST:
				t.turns_left -= 1
				if t.turns_left <= 0:
					new_grid[r][c] = null
					chest_vanished = true
					events.append({"type": &"chest_vanished", "id": t.id, "at": Vector2i(r, c)})
	if chest_vanished and not acc.chest_opened:
		events.append({"type": &"log", "key": &"log_chest_vanished"})

	# Update tile positions + movement events
	for m in acc.moves:
		events.append({"type": &"tile_move", "id": m.id, "to": m.to})
	for cx in acc.consumes:
		events.append({"type": &"tile_consume", "id": cx.id, "to": cx.to})
	for mr in acc.merge_results:
		mr.tile.row = mr.at.x
		mr.tile.col = mr.at.y
		events.append({"type": &"merge_result", "tile": mr.tile, "at": mr.at})

	if spawn_enabled:
		grid = spawn_tile(new_grid, rs.level, rs.mode, events)
	else:
		grid = new_grid

	# --- Rewards & streak -----------------------------------------------------
	var kills_this_move: int = acc.kills
	if kills_this_move > 0:
		rs.kill_streak += 1
	else:
		rs.kill_streak = 0
	var streak_bonus := 0
	if rs.kill_streak >= 2:
		streak_bonus = int(round(float(acc.kill_gold) * (rs.kill_streak - 1) * GameConfig.STREAK_GOLD_PCT))
		events.append({"type": &"streak", "count": rs.kill_streak, "gold": streak_bonus})

	var gold_delta: int = acc.gold + acc.kill_gold + streak_bonus
	rs.score += int(acc.points)
	rs.gold += gold_delta
	rs.kills += kills_this_move
	rs.run_xp += int(acc.xp)

	# --- Level ups -------------------------------------------------------------
	var level_ups := 0
	for lu in acc.levels:
		level_ups += int(lu.levels)
		events.append({"type": &"log", "key": &"log_level_up_combine", "args": {"levels": lu.levels, "value": lu.value}})
	if kills_this_move > 0:
		rs.kills_since_level += kills_this_move
		var from_kills := int(rs.kills_since_level / GameConfig.KILLS_PER_LEVEL)
		if from_kills > 0:
			level_ups += from_kills
			rs.kills_since_level = rs.kills_since_level % GameConfig.KILLS_PER_LEVEL
			events.append({"type": &"log", "key": &"log_level_up_kills", "args": {"levels": from_kills}})

	if level_ups > 0:
		var old_level := rs.level
		rs.level += level_ups
		events.append({"type": &"level_up", "old": old_level, "new": rs.level})
		var spawn_shop := false
		for i in range(old_level + 1, rs.level + 1):
			if i > 1 and i % GameConfig.SHOP_LEVEL_INTERVAL == 0:
				spawn_shop = true
				break
		if spawn_shop:
			grid = spawn_shop_tile(grid, events)

	# --- Horde attack -----------------------------------------------------------
	rs.moves_count += 1
	var mpa := GoblinDB.moves_per_attack(rs.level, rs.mode, upgrades)
	if rs.moves_count % mpa == 0:
		var attack_damage := horde_damage(grid, rs.level, rs.mode)
		var final_damage: int = maxi(0, attack_damage - rs.damage_reduction)
		if final_damage > 0:
			rs.player_hp -= final_damage
			events.append({"type": &"horde_attack", "damage": final_damage})
			events.append({"type": &"log", "key": &"log_horde_attack", "args": {"damage": final_damage}})
		elif attack_damage > 0:
			events.append({"type": &"log", "key": &"log_horde_blocked"})

	rs.stats_changed.emit()

	# --- End states --------------------------------------------------------------
	if rs.player_hp <= 0:
		rs.over = true
		rs.over_reason_key = &"reason_slain"
		events.append({"type": &"game_over", "reason": &"reason_slain"})
	elif acc.won:
		rs.won = true
		rs.over = true
		rs.over_reason_key = &"reason_victory"
		rs.run_xp += 750
		events.append({"type": &"victory"})
		events.append({"type": &"log", "key": &"log_milestone", "args": {"value": 256, "gold": 750}})

	# Fix positions on every remaining tile
	for r in S:
		for c in S:
			var t: BoardTile = grid[r][c]
			if t != null:
				t.row = r
				t.col = c

	# XP earned this move — the game layer persists it via SaveManager.
	var xp_delta: int = int(acc.xp) + (750 if acc.won else 0)
	return {"grid": grid, "events": events, "moved": true, "xp_delta": xp_delta}


# ---------------------------------------------------------------------------
# Rope: relocate one goblin to an empty cell (not a move — no spawn/attack)
# ---------------------------------------------------------------------------

func rope_move(grid: Array, from: Vector2i, to: Vector2i, rs: RunState) -> Dictionary:
	var events: Array = []
	var t: BoardTile = grid[from.x][from.y]
	if t == null or not t.is_goblin() or grid[to.x][to.y] != null or rs.rope_count <= 0:
		return {"grid": grid, "events": events, "moved": false}
	grid[from.x][from.y] = null
	grid[to.x][to.y] = t
	t.row = to.x
	t.col = to.y
	rs.rope_count -= 1
	events.append({"type": &"tile_move", "id": t.id, "to": to, "rope": true})
	events.append({"type": &"log", "key": &"log_rope_used"})
	rs.stats_changed.emit()
	return {"grid": grid, "events": events, "moved": true}


# ---------------------------------------------------------------------------
# New game setup
# ---------------------------------------------------------------------------

func initial_grid(rs: RunState) -> Dictionary:
	var events: Array = []
	var grid := empty_grid()
	grid = spawn_tile(grid, 1, rs.mode, events)
	grid = spawn_tile(grid, 1, rs.mode, events)
	return {"grid": grid, "events": events}
