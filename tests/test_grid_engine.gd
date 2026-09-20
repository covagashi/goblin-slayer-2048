extends SceneTree
## Headless engine tests: godot --headless -s tests/test_grid_engine.gd

var _passed := 0
var _failed := 0
var engine: GridEngine
var rs: RunState
var upgrades := {}


func _check(cond: bool, name: String) -> void:
	if cond:
		_passed += 1
		print("  PASS ", name)
	else:
		_failed += 1
		printerr("  FAIL ", name)


func _goblin(v: int, hp: int = 1) -> BoardTile:
	var t := BoardTile.new()
	t.id = engine.new_id()
	t.value = v
	t.hp = hp
	t.max_hp = hp
	return t


func _grid_with(cells: Dictionary) -> Array:
	var g := GridEngine.empty_grid()
	for key in cells:
		var t: BoardTile = cells[key]
		t.row = key.x
		t.col = key.y
		g[key.x][key.y] = t
	return g


func _events_of_type(events: Array, t: StringName) -> Array:
	return events.filter(func(e): return e.get("type") == t)


func _init() -> void:
	engine = GridEngine.new()
	engine.rng.seed = 42
	rs = RunState.new()
	rs.reset(&"story", upgrades)

	# --- Test 1: initial grid spawns 2 tiles ---------------------------------
	var res := engine.initial_grid(rs)
	var g: Array = res.grid
	var count := 0
	for row in g:
		for t in row:
			if t != null:
				count += 1
	_check(count == 2, "initial grid spawns 2 tiles")

	# --- Test 2: merge two goblin(2) -> damaged goblin(4) survives -----------
	# goblin(4) hp=2, combine damage=2 -> new_hp=0 -> slain actually!
	# value 4 < 8 so no survival cap. Slain gives points=4, gold=4.
	rs.reset(&"story", upgrades)
	g = _grid_with({Vector2i(0, 0): _goblin(2), Vector2i(0, 1): _goblin(2)})
	res = engine.move(g, &"left", rs, upgrades)
	var slain := _events_of_type(res.events, &"slain")
	_check(slain.size() == 1, "merge 2+2 slays goblin(4)")
	_check(rs.score == 4, "score += 4 after slaying")
	_check(rs.kills == 1, "kill counted")

	# --- Test 3: 8+8 -> 16 always survives (hp8 - min(dmg,7)) ----------------
	rs.reset(&"story", upgrades)
	g = _grid_with({Vector2i(0, 0): _goblin(8), Vector2i(0, 1): _goblin(8)})
	res = engine.move(g, &"left", rs, upgrades)
	var mr := _events_of_type(res.events, &"merge_result")
	_check(mr.size() == 1 and mr[0].tile.value == 16 and mr[0].tile.hp > 0, "merge 8+8 -> surviving 16")

	# --- Test 4: goblin slides into chest -> +20 gold -------------------------
	rs.reset(&"story", upgrades)
	var chest := BoardTile.new()
	chest.id = engine.new_id()
	chest.kind = BoardTile.Kind.CHEST
	g = _grid_with({Vector2i(0, 0): _goblin(2), Vector2i(0, 2): chest})
	var gold_before := rs.gold
	res = engine.move(g, &"left", rs, upgrades)
	_check(_events_of_type(res.events, &"chest_opened").size() == 1, "chest opened on slide")
	_check(rs.gold == gold_before + 20, "chest gives +20 gold")

	# --- Test 5: board locked detection ---------------------------------------
	g = _grid_with({
		Vector2i(0,0): _goblin(2), Vector2i(0,1): _goblin(4), Vector2i(0,2): _goblin(8), Vector2i(0,3): _goblin(16),
		Vector2i(1,0): _goblin(4), Vector2i(1,1): _goblin(2), Vector2i(1,2): _goblin(16), Vector2i(1,3): _goblin(8),
		Vector2i(2,0): _goblin(8), Vector2i(2,1): _goblin(16), Vector2i(2,2): _goblin(2), Vector2i(2,3): _goblin(4),
		Vector2i(3,0): _goblin(16), Vector2i(3,1): _goblin(8), Vector2i(3,2): _goblin(4), Vector2i(3,3): _goblin(2),
	})
	_check(engine.is_board_locked(g), "checkerboard board is locked")

	# --- Test 6: overcrowding damage on locked move attempt -------------------
	rs.reset(&"story", upgrades)
	rs.player_hp = 5
	res = engine.move(g, &"left", rs, upgrades)
	_check(res.moved == false, "locked move does not move")
	_check(rs.player_hp == 4, "overcrowding deals 1 damage")

	# --- Test 7: horde damage cap ----------------------------------------------
	var big := _grid_with({Vector2i(0,0): _goblin(256), Vector2i(0,1): _goblin(128), Vector2i(1,0): _goblin(64)})
	_check(engine.horde_damage(big, 1, &"story") == 8, "horde damage capped at 8")

	# --- Test 8: story victory at 256 -------------------------------------------
	rs.reset(&"story", upgrades)
	g = _grid_with({Vector2i(0, 0): _goblin(128), Vector2i(0, 1): _goblin(128)})
	res = engine.move(g, &"left", rs, upgrades)
	_check(_events_of_type(res.events, &"victory").size() == 1, "story mode victory at 256")
	_check(rs.won, "run marked won")

	# --- Test 9: endless does not win at 256 -------------------------------------
	rs.reset(&"endless", upgrades)
	g = _grid_with({Vector2i(0, 0): _goblin(128), Vector2i(0, 1): _goblin(128)})
	res = engine.move(g, &"left", rs, upgrades)
	_check(_events_of_type(res.events, &"victory").is_empty(), "endless no victory at 256")

	# --- Test 10: rope move ------------------------------------------------------
	rs.reset(&"story", upgrades)
	rs.rope_count = 1
	g = _grid_with({Vector2i(0, 0): _goblin(2)})
	res = engine.rope_move(g, Vector2i(0, 0), Vector2i(3, 3), rs)
	_check(res.moved and res.grid[3][3] != null and res.grid[0][0] == null, "rope relocates goblin")
	_check(rs.rope_count == 0, "rope consumed")

	# --- Test 11: horde attack every 15 moves -------------------------------------
	rs.reset(&"story", upgrades)
	rs.moves_count = 14  # next move is #15
	g = _grid_with({Vector2i(0,0): _goblin(2), Vector2i(0,1): _goblin(2), Vector2i(1,0): _goblin(8)})
	rs.player_hp = 20
	res = engine.move(g, &"left", rs, upgrades)
	# merge kills the goblin(4); remaining: goblin(8) slides + spawn. damage = dmg of remaining goblins
	var horde := _events_of_type(res.events, &"horde_attack")
	_check(horde.size() == 1, "horde attacks on move 15")

	# --- Test 12: level up at kills milestone -------------------------------------
	rs.reset(&"story", upgrades)
	rs.kills_since_level = 9
	g = _grid_with({Vector2i(0, 0): _goblin(2), Vector2i(0, 1): _goblin(2)})
	res = engine.move(g, &"left", rs, upgrades)
	_check(rs.level == 2, "level up after 10th kill")

	# --- Test 13: down swipe works (fire-scroll coord bug regression) --------------
	rs.reset(&"story", upgrades)
	g = _grid_with({Vector2i(0, 0): _goblin(2), Vector2i(2, 0): _goblin(2)})
	res = engine.move(g, &"down", rs, upgrades)
	var merged := _events_of_type(res.events, &"slain")
	_check(merged.size() == 1 and merged[0].at == Vector2i(3, 0), "down swipe merges at bottom")

	# --- Test 14: shop tiles tick down and vanish after SHOP_LIFETIME ---------------
	rs.reset(&"story", upgrades)
	engine.spawn_enabled = false # deterministic: no random spawns
	var shop := BoardTile.new()
	shop.id = engine.new_id()
	shop.kind = BoardTile.Kind.SHOP
	shop.turns_left = GameConfig.SHOP_LIFETIME
	g = _grid_with({Vector2i(0, 0): _goblin(2), Vector2i(0, 3): shop})
	for i in GameConfig.SHOP_LIFETIME - 1:
		g = engine.move(g, &"down" if i % 2 == 0 else &"up", rs, upgrades).grid
		_check(_count_kind(g, BoardTile.Kind.SHOP) == 1, "shop alive after %d move(s)" % (i + 1))
	g = engine.move(g, &"down", rs, upgrades).grid
	_check(_count_kind(g, BoardTile.Kind.SHOP) == 0, "shop gone after %d moves" % GameConfig.SHOP_LIFETIME)

	# --- Test 15: chests tick down and vanish after CHEST_LIFETIME ------------------
	rs.reset(&"story", upgrades)
	var ch := BoardTile.new()
	ch.id = engine.new_id()
	ch.kind = BoardTile.Kind.CHEST
	ch.turns_left = GameConfig.CHEST_LIFETIME
	g = _grid_with({Vector2i(0, 0): _goblin(2), Vector2i(0, 3): ch})
	for i in GameConfig.CHEST_LIFETIME - 1:
		g = engine.move(g, &"down" if i % 2 == 0 else &"up", rs, upgrades).grid
		_check(_count_kind(g, BoardTile.Kind.CHEST) == 1, "chest alive after %d move(s)" % (i + 1))
	g = engine.move(g, &"down", rs, upgrades).grid
	_check(_count_kind(g, BoardTile.Kind.CHEST) == 0, "chest gone after %d moves" % GameConfig.CHEST_LIFETIME)
	engine.spawn_enabled = true

	print("\n%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _count_kind(grid: Array, kind: BoardTile.Kind) -> int:
	var n := 0
	for r in GameConfig.GRID_SIZE:
		for c in GameConfig.GRID_SIZE:
			var t: BoardTile = grid[r][c]
			if t != null and t.kind == kind:
				n += 1
	return n
