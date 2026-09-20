class_name QaRunner
extends Node
## Headless e2e scenarios driven through the real UI paths.
## Run: godot --headless -- qa=<scenario>
## Prints "[E2E] PASS/FAIL <label>" lines; exit code 1 on any failure.
## Save data is snapshotted on start and restored at the end — QA runs
## never pollute the player's real user:// save.

var _main: Control
var _pass := 0
var _fail := 0
var _quiet := false # chaos mode: only failures are printed

var _bak_xp := 0
var _bak_upgrades: Dictionary = {}
var _bak_lb: Array = []
var _bak_lang: StringName = &"es"
var _bak_music := true


func run(scenario: StringName, main_ref: Control) -> void:
	_main = main_ref
	_backup_save()
	match scenario:
		&"core": await _s_core()
		&"merge_kill": await _s_merge_kill()
		&"chest": await _s_chest()
		&"golden": await _s_golden()
		&"streak": await _s_streak()
		&"shop": await _s_shop()
		&"rope": await _s_rope()
		&"fire": await _s_fire()
		&"gameover": await _s_gameover()
		&"victory": await _s_victory()
		&"endless": await _s_endless()
		&"overcrowding": await _s_overcrowding()
		&"upgrades": await _s_upgrades()
		&"leaderboard": await _s_leaderboard()
		&"persistence": _s_persistence()
		&"assets": _s_assets()
		&"i18n": _s_i18n()
		&"chaos": await _s_chaos(&"story")
		&"chaos_endless": await _s_chaos(&"endless")
		&"menu_cycle": await _s_menu_cycle()
		_:
			printerr("[E2E] unknown scenario: %s" % scenario)
			_fail += 1
	_restore_save()
	print("[E2E] %s => %d passed, %d failed" % [scenario, _pass, _fail])
	await get_tree().process_frame
	get_tree().quit(1 if _fail > 0 else 0)


# ---------------------------------------------------------------------------
# Harness helpers
# ---------------------------------------------------------------------------

func _check(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		if not _quiet:
			print("[E2E] PASS %s" % label)
	else:
		_fail += 1
		printerr("[E2E] FAIL %s" % label)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _start(mode: StringName) -> GameScene:
	_main._on_mode_selected(mode)
	var tries := 90
	while tries > 0:
		var c: Control = _main._current
		if c is GameScene and c._board != null and c._board.get_parent() != null:
			return c
		await get_tree().process_frame
		tries -= 1
	return null


func _goblin(v: int, r: int, c: int, golden := false) -> BoardTile:
	var t := BoardTile.new()
	t.id = randi_range(1000, 999999)
	t.kind = BoardTile.Kind.GOBLIN
	t.value = v
	var st := GoblinDB.goblin_stats(v, 1, &"story")
	t.hp = int(st.hp)
	t.max_hp = int(st.max_hp)
	t.row = r
	t.col = c
	t.is_golden = golden
	return t


func _special(kind: BoardTile.Kind, r: int, c: int) -> BoardTile:
	var t := BoardTile.new()
	t.id = randi_range(1000, 999999)
	t.kind = kind
	t.row = r
	t.col = c
	return t


func _set_board(g: GameScene, tiles: Array) -> void:
	var grid := GridEngine.empty_grid()
	for t in tiles:
		grid[t.row][t.col] = t
	g._grid = grid
	g._board.set_grid(grid)


func _find_panel(g: Node, type_name: String) -> Node:
	for ch in g.get_children():
		if ch.get_class() == type_name or (ch.get_script() != null and ch.is_class("CanvasLayer") and ch.get_script().get_global_name() == type_name):
			return ch
	# class_name scripts report via get_global_name
	for ch in g.get_children():
		if ch.get_script() and String(ch.get_script().get_global_name()) == type_name:
			return ch
	return null


func _backup_save() -> void:
	_bak_xp = SaveManager.total_xp
	_bak_upgrades = SaveManager.upgrades.duplicate(true)
	_bak_lb = SaveManager.leaderboard.duplicate(true)
	_bak_lang = SaveManager.language
	_bak_music = SaveManager.music_enabled


func _restore_save() -> void:
	SaveManager.total_xp = _bak_xp
	SaveManager.upgrades = _bak_upgrades
	SaveManager.leaderboard = _bak_lb
	SaveManager.language = _bak_lang
	SaveManager.music_enabled = _bak_music
	SaveManager.save()


# ---------------------------------------------------------------------------
# Scenarios
# ---------------------------------------------------------------------------

func _s_core() -> void:
	var g := await _start(&"story")
	_check(g != null, "core: game scene starts")
	if g == null:
		return
	var tiles := 0
	for r in GameConfig.GRID_SIZE:
		for c in GameConfig.GRID_SIZE:
			if g._grid[r][c] != null:
				tiles += 1
	_check(tiles >= 2, "core: initial grid spawned %d tiles" % tiles)
	_check(g._hud != null and g._hud._log_box != null, "core: HUD bound")
	g._on_swipe(&"left")
	_check(g._rs.moves_count >= 1, "core: swipe registered (moves=%d)" % g._rs.moves_count)


func _s_merge_kill() -> void:
	var g := await _start(&"story")
	if g == null: _check(false, "merge_kill: boot"); return
	_set_board(g, [_goblin(2, 0, 0), _goblin(2, 0, 1)])
	var gold0: int = g._rs.gold
	g._on_swipe(&"left")
	_check(g._rs.moves_count == 1, "merge_kill: move counted")
	_check(g._rs.kills == 1, "merge_kill: resulting Goblin(4) slain")
	_check(g._rs.gold == gold0 + 4, "merge_kill: gold +4")
	_check(g._rs.score >= 4, "merge_kill: score awarded")


func _s_chest() -> void:
	var g := await _start(&"story")
	if g == null: _check(false, "chest: boot"); return
	_set_board(g, [_goblin(2, 0, 0), _special(BoardTile.Kind.CHEST, 0, 2)])
	var gold0: int = g._rs.gold
	g._on_swipe(&"left")
	var gained := g._rs.gold - gold0
	_check(gained >= GameConfig.CHEST_GOLD_REWARD, "chest: +%d gold (want >=%d)" % [gained, GameConfig.CHEST_GOLD_REWARD])


func _s_golden() -> void:
	var g := await _start(&"story")
	if g == null: _check(false, "golden: boot"); return
	_set_board(g, [_goblin(2, 0, 0, true), _goblin(2, 0, 1)])
	var gold0: int = g._rs.gold
	g._on_swipe(&"left")
	var gained := g._rs.gold - gold0
	# Goblin(4) base gold 4 x10 = 40 (plus possible random drop; require >=40)
	_check(gained >= 40, "golden: x10 gold (got %d)" % gained)


func _s_streak() -> void:
	var g := await _start(&"story")
	if g == null: _check(false, "streak: boot"); return
	_set_board(g, [_goblin(2, 0, 0), _goblin(2, 0, 1)])
	g._on_swipe(&"left")
	_check(g._rs.kill_streak == 1, "streak: streak=1 after first kill")
	_set_board(g, [_goblin(2, 1, 0), _goblin(2, 1, 1)])
	g._on_swipe(&"left")
	_check(g._rs.kill_streak == 2, "streak: streak=2 consecutive kills")
	_check(g._hud._streak_banner.visible, "streak: banner shown")


func _s_shop() -> void:
	var g := await _start(&"story")
	if g == null: _check(false, "shop: boot"); return
	g._rs.gold = 1000
	# unlock every item for this run so all offers are buyable
	for up in GoblinDB.PERMANENT_UPGRADES:
		if String(up.id).begins_with("unlock"):
			g._upgrades[up.id] = 1
	_set_board(g, [_special(BoardTile.Kind.SHOP, 0, 0), _goblin(2, 1, 0)])
	g._on_cell_tapped(0, 0)
	await get_tree().process_frame
	var panel: ShopPanel = null
	for ch in g.get_children():
		if ch is ShopPanel:
			panel = ch
	_check(panel != null, "shop: panel opens on tap")
	if panel == null:
		return
	_check(not panel._offers.is_empty(), "shop: offers rolled (%d)" % panel._offers.size())
	var gold0: int = g._rs.gold
	var it: Dictionary = panel._offers[0]
	panel._buy(it)
	_check(g._rs.gold == gold0 - int(it.cost), "shop: gold deducted")
	_check(g._rs.purchased_items.has(it.id), "shop: item applied (%s)" % it.id)
	panel._close()
	await get_tree().process_frame
	_check(not g._modal_open, "shop: modal closed")
	_check(g._grid[0][0] == null, "shop: shopkeeper leaves after purchase")


func _s_rope() -> void:
	var g := await _start(&"story")
	if g == null: _check(false, "rope: boot"); return
	g._rs.rope_count = 1
	_set_board(g, [_goblin(8, 0, 0)])
	g._on_rope_button()
	_check(g._board.rope_mode, "rope: mode activated")
	g._on_cell_tapped(0, 0)
	_check(g._rope_selected == Vector2i(0, 0), "rope: tile selected")
	g._on_cell_tapped(2, 2)
	_check(g._grid[2][2] != null and g._grid[2][2].value == 8, "rope: tile relocated")
	_check(g._grid[0][0] == null, "rope: origin cleared")
	_check(g._rs.rope_count == 0, "rope: consumed")
	_check(not g._board.rope_mode, "rope: mode exited")
	_check(g._rs.moves_count == 0, "rope: not a move (no spawn/attack)")


func _s_fire() -> void:
	var g := await _start(&"story")
	if g == null: _check(false, "fire: boot"); return
	g._rs.fire_scroll_active = true
	var victim := _goblin(8, 0, 0)  # hp 4 -> survives 1 AoE damage
	_set_board(g, [victim, _goblin(2, 1, 0), _goblin(2, 1, 1)])
	g._on_swipe(&"left")
	var found: BoardTile = null
	for r in GameConfig.GRID_SIZE:
		for c in GameConfig.GRID_SIZE:
			var t: BoardTile = g._grid[r][c]
			if t != null and t.id == victim.id:
				found = t
	_check(found == null or found.hp < 4, "fire: AoE damaged/killed neighbor")
	_check(g._rs.fire_scroll_active, "fire: scroll stays passive")


func _s_gameover() -> void:
	var g := await _start(&"story")
	if g == null: _check(false, "gameover: boot"); return
	# tiles placed at the right edge so the swipe actually moves them
	_set_board(g, [_goblin(2, 0, 3), _goblin(4, 1, 3)])
	g._rs.player_hp = 1
	g._rs.moves_count = GoblinDB.moves_per_attack(g._rs.level, g._rs.mode, g._upgrades) - 1
	g._on_swipe(&"left")
	_check(g._rs.over, "gameover: horde kills player")
	_check(not g._rs.won, "gameover: not a win")
	await _wait(1.1)
	var panel: GameOverPanel = null
	for ch in g.get_children():
		if ch is GameOverPanel:
			panel = ch
	_check(panel != null, "gameover: panel opens")
	if panel == null:
		return
	panel.restart.emit()
	await _wait(0.5)
	_check(not g._rs.over and g._rs.moves_count == 0, "gameover: restart resets run")
	_check(g._hud.get_child_count() == 4, "gameover: HUD not duplicated (children=%d)" % g._hud.get_child_count())


func _s_victory() -> void:
	var lb0: int = SaveManager.leaderboard.size()
	var g := await _start(&"story")
	if g == null: _check(false, "victory: boot"); return
	_set_board(g, [_goblin(128, 0, 0), _goblin(128, 0, 1)])
	g._on_swipe(&"right")
	_check(g._rs.won, "victory: Goblin(256) wins story")
	_check(g._rs.over, "victory: run ends")
	_check(SaveManager.leaderboard.size() == lb0 + 1, "victory: leaderboard entry written")
	await _wait(1.1)
	var panel: GameOverPanel = null
	for ch in g.get_children():
		if ch is GameOverPanel:
			panel = ch
	_check(panel != null, "victory: summary panel opens")


func _s_endless() -> void:
	var g := await _start(&"endless")
	if g == null: _check(false, "endless: boot"); return
	_set_board(g, [_goblin(128, 0, 0), _goblin(128, 0, 1)])
	g._on_swipe(&"right")
	_check(not g._rs.won, "endless: 256 does not end the run")
	_check(not g._rs.over, "endless: run continues")


func _s_overcrowding() -> void:
	var g := await _start(&"story")
	if g == null: _check(false, "overcrowding: boot"); return
	var tiles: Array = []
	var vals := [2, 4, 8, 16]
	for r in GameConfig.GRID_SIZE:
		for c in GameConfig.GRID_SIZE:
			tiles.append(_goblin(vals[(r + c) % 4], r, c))
	# diagonal checkerboard keeps every orthogonal neighbor different -> no moves
	_set_board(g, tiles)
	var hp0: int = g._rs.player_hp
	g._on_swipe(&"left")
	_check(g._rs.player_hp == hp0 - GameConfig.OVERCROWDING_DAMAGE,
		"overcrowding: locked board costs %d hp" % GameConfig.OVERCROWDING_DAMAGE)


func _s_upgrades() -> void:
	await _wait(0.8)
	var splash: Control = _main._current
	_check(splash is SplashScreen, "upgrades: on splash")
	SaveManager.total_xp += 2000
	var panel := UpgradesPanel.new()
	panel.open(splash)
	await get_tree().process_frame
	var target: Dictionary = {}
	for up in GoblinDB.PERMANENT_UPGRADES:
		if int(up.cost) <= SaveManager.total_xp and SaveManager.upgrade_level(up.id) < int(up.max_level):
			target = up
			break
	_check(not target.is_empty(), "upgrades: affordable upgrade found")
	var xp0: int = SaveManager.total_xp
	panel._buy(target)
	_check(SaveManager.upgrade_level(target.id) == 1, "upgrades: level purchased")
	_check(SaveManager.total_xp == xp0 - int(target.cost), "upgrades: XP deducted")
	panel.queue_free()


func _s_leaderboard() -> void:
	await _wait(0.8)
	var splash: Control = _main._current
	SaveManager.add_leaderboard_entry({"score": 999, "kills": 9, "xp": 9, "time": 42, "date": "qa"})
	var panel := LeaderboardPanel.new()
	panel.open(splash)
	await get_tree().process_frame
	_check(panel.get_child_count() > 0, "leaderboard: panel builds")
	_check(SaveManager.leaderboard.size() >= 1, "leaderboard: entry stored")
	panel.queue_free()


func _s_persistence() -> void:
	SaveManager.total_xp = 777
	SaveManager.upgrades = {&"maxHp": 2}
	SaveManager.language = &"en"
	SaveManager.music_enabled = false
	SaveManager.save()
	# corrupt memory, reload from disk
	SaveManager.total_xp = 0
	SaveManager.upgrades = {}
	SaveManager.language = &"es"
	SaveManager.music_enabled = true
	SaveManager.load_all()
	_check(SaveManager.total_xp == 777, "persist: xp round-trips")
	_check(SaveManager.upgrade_level(&"maxHp") == 2, "persist: upgrades round-trip")
	_check(SaveManager.language == &"en", "persist: language round-trips")
	_check(SaveManager.music_enabled == false, "persist: music flag round-trips")


func _s_assets() -> void:
	var sfx := DirAccess.get_files_at("res://assets/audio/sfx")
	_check(sfx.size() >= 17, "assets: %d sfx files" % sfx.size())
	var bad := 0
	for f in sfx:
		if f.ends_with(".wav") and load("res://assets/audio/sfx/" + f) == null:
			bad += 1
	_check(bad == 0, "assets: all sfx wavs load")
	var vars := DirAccess.get_files_at("res://assets/sprites/variants")
	var pngs: Array = []
	for f in vars:
		if String(f).ends_with(".png"):
			pngs.append(f)
	_check(pngs.size() == 31, "assets: %d variant sprites" % pngs.size())
	bad = 0
	for f in pngs:
		if load("res://assets/sprites/variants/" + f) == null:
			bad += 1
	_check(bad == 0, "assets: all variants load")
	_check(load("res://assets/audio/music/menu-theme.mp3") != null, "assets: menu music loads")
	_check(load("res://assets/audio/music/background-theme.mp3") != null, "assets: game music loads")


func _s_menu_cycle() -> void:
	var g := await _start(&"story")
	if g == null:
		_check(false, "menu_cycle: boot")
		return
	for d in [&"left", &"right", &"up", &"down"]:
		if g._rs.moves_count > 0:
			break
		g._on_swipe(d)
	_check(g._rs.moves_count >= 1, "menu_cycle: game running")
	g.menu_requested.emit()
	await _wait(0.8)
	_check(_main._current is SplashScreen, "menu_cycle: back at splash")
	var g2 := await _start(&"endless")
	_check(g2 != null and g2 != g, "menu_cycle: second game is a fresh scene")
	if g2 != null:
		_check(g2._rs.mode == &"endless", "menu_cycle: endless mode set")
		_check(g2._rs.moves_count == 0, "menu_cycle: fresh run state")


func _s_i18n() -> void:
	TranslationServer.set_locale("en")
	var en: String = tr(&"storyMode")
	TranslationServer.set_locale("es")
	var es: String = tr(&"storyMode")
	_check(en != es, "i18n: en/es differ (%s / %s)" % [en, es])
	# Every key in the CSV must translate in both locales (missing => tr returns the key)
	var missing := 0
	var tr_en := load("res://assets/i18n/translations.en.translation") as Translation
	var tr_es := load("res://assets/i18n/translations.es.translation") as Translation
	for key in tr_en.get_message_list():
		if String(tr_en.get_message(key)).is_empty() or String(tr_es.get_message(key)).is_empty():
			missing += 1
			push_warning("i18n: empty translation for " + String(key))
	_check(missing == 0, "i18n: %d keys untranslated" % missing)
	# Every key the HowTo panel renders must resolve
	var bad := 0
	for sec in HowToPanel.SECTIONS:
		for k in [sec[0]] + sec[1]:
			if tr(k) == String(k):
				bad += 1
				push_warning("i18n: unresolved key " + String(k))
	_check(bad == 0, "i18n: %d how-to keys unresolved" % bad)
	TranslationServer.set_locale(String(_bak_lang))


# ---------------------------------------------------------------------------
# Chaos monkey — plays the game for real: random swipes, taps, shop visits,
# rope usage, restarts. Validates board/run invariants after every action.
# ---------------------------------------------------------------------------

func _s_chaos(mode: StringName) -> void:
	_quiet = true
	var g := await _start(mode)
	if g == null:
		_quiet = false
		_check(false, "chaos: boot")
		return
	var rng := RandomNumberGenerator.new()
	# deterministic by default; override with -- qa=chaos&seed=N
	rng.seed = 0xC0FFEE
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("seed="):
			rng.seed = int(String(a).trim_prefix("seed="))
	# richer runs: grant some unlocks + resources so shop buys and ropes happen
	for up in GoblinDB.PERMANENT_UPGRADES:
		if String(up.id).begins_with("unlock"):
			g._upgrades[up.id] = 1
	g._rs.gold = 400
	g._rs.rope_count = 3
	g._rs.stats_changed.emit() # direct mutations bypass engine event flow — refresh HUD
	var dirs: Array[StringName] = [&"left", &"right", &"up", &"down"]
	var restarts := 0
	var shops := 0
	var ropes := 0
	var wins := 0

	var over_streak := 0
	var t0 := Time.get_ticks_msec()
	for i in 300:
		if i % 25 == 0:
			print("[E2E] chaos step %d (hp=%d moves=%d over=%s)" % [i, g._rs.player_hp, g._rs.moves_count, g._rs.over])
		if Time.get_ticks_msec() - t0 > 180000:
			_quiet = false
			printerr("[E2E] chaos: TIME BUDGET EXCEEDED at step %d — over=%s modal=%s children=%s" %
				[i, g._rs.over, g._modal_open, g.get_children().map(func(c): return c.get_class())])
			_fail += 1
			return
		# --- modal cleanup / restart --------------------------------------
		var shop: ShopPanel = null
		var gameover: GameOverPanel = null
		for ch in g.get_children():
			if ch is ShopPanel: shop = ch
			if ch is GameOverPanel: gameover = ch
		if shop != null:
			shops += 1
			# buy the first buyable offer sometimes, then close
			for it in shop._offers:
				if rng.randf() < 0.6 and g._rs.gold >= int(it.cost):
					var gold0: int = g._rs.gold
					shop._buy(it)
					_check(g._rs.gold <= gold0, "chaos: buy never increases gold")
					break
			shop._close()
			await get_tree().process_frame
			continue
		if g._rs.over:
			over_streak += 1
			await _wait(1.0)
			for ch in g.get_children():
				if ch is GameOverPanel: gameover = ch
			if gameover == null:
				printerr("[E2E] chaos: over but no panel (streak=%d reason=%s modal=%s)" %
					[over_streak, g._rs.over_reason_key, g._modal_open])
				if over_streak > 5:
					_quiet = false
					_fail += 1
					return
				continue
			over_streak = 0
			if g._rs.won: wins += 1
			if gameover != null:
				restarts += 1
				gameover.restart.emit()
				await _wait(0.4)
				_check(not g._rs.over, "chaos: restart clears over flag")
				_check(g._rs.moves_count == 0, "chaos: restart resets moves")
				_check(g._hud.get_child_count() == 4, "chaos: HUD intact after restart #%d" % restarts)
			continue

		# --- random action ---------------------------------------------------
		var roll := rng.randf()
		if roll < 0.80:
			g._on_swipe(dirs[rng.randi() % 4])
		elif roll < 0.90:
			g._on_cell_tapped(rng.randi() % 4, rng.randi() % 4)
		elif roll < 0.97:
			if not g._board.rope_mode:
				g._on_rope_button()
				if g._board.rope_mode:
					ropes += 1
					# pick a random goblin then a random empty cell
					var src := Vector2i(-1, -1)
					for r in GameConfig.GRID_SIZE:
						for c in GameConfig.GRID_SIZE:
							var t: BoardTile = g._grid[r][c]
							if t != null and t.is_goblin() and src == Vector2i(-1, -1):
								src = Vector2i(r, c)
					if src != Vector2i(-1, -1):
						g._on_cell_tapped(src.x, src.y)
						var dst := Vector2i(rng.randi() % 4, rng.randi() % 4)
						g._on_cell_tapped(dst.x, dst.y)
			else:
				g._on_rope_button() # cancel
		else:
			pass # idle frame

		_check_invariants(g, i)
		await get_tree().process_frame

	_quiet = false
	print("[E2E] chaos summary: restarts=%d shops=%d ropes=%d wins=%d moves=%d score=%d" %
		[restarts, shops, ropes, wins, g._rs.moves_count, g._rs.score])
	_check(true, "chaos: session survived %d steps" % 300)


func _check_invariants(g: GameScene, step: int) -> void:
	var rs := g._rs
	var grid := g._grid
	# shape
	_check(grid.size() == GameConfig.GRID_SIZE, "chaos@%d: grid has %d rows" % [step, grid.size()])
	var ids := {}
	var tiles := 0
	for r in grid.size():
		var row: Array = grid[r]
		_check(row.size() == GameConfig.GRID_SIZE, "chaos@%d: row %d width %d" % [step, r, row.size()])
		for c in row.size():
			var t: BoardTile = row[c]
			if t == null:
				continue
			tiles += 1
			_check(not ids.has(t.id), "chaos@%d: duplicate tile id %d" % [step, t.id])
			ids[t.id] = true
			_check(t.row == r and t.col == c, "chaos@%d: tile@%d,%d reports %d,%d" % [step, r, c, t.row, t.col])
			if t.is_goblin():
				_check(t.value >= 2 and t.value <= 256 and (t.value & (t.value - 1)) == 0,
					"chaos@%d: invalid goblin value %d" % [step, t.value])
				_check(t.hp > 0 and t.hp <= t.max_hp, "chaos@%d: bad hp %d/%d" % [step, t.hp, t.max_hp])
	# run-state sanity
	_check(rs.gold >= 0, "chaos@%d: negative gold %d" % [step, rs.gold])
	_check(rs.score >= 0, "chaos@%d: negative score" % step)
	_check(rs.player_hp <= rs.player_max_hp, "chaos@%d: hp %d > max %d" % [step, rs.player_hp, rs.player_max_hp])
	if not rs.over:
		_check(rs.player_hp > 0, "chaos@%d: dead but not over (hp=%d)" % [step, rs.player_hp])
	# HUD reflects state
	_check(g._hud._score.text == str(rs.score), "chaos@%d: HUD score desync (%s vs %d)" % [step, g._hud._score.text, rs.score])
	_check(g._hud._gold.text == str(rs.gold), "chaos@%d: HUD gold desync" % step)
