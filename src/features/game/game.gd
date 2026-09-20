class_name GameScene
extends Control
## Orchestrates a run: owns RunState + GridEngine, wires board input to
## engine results, routes events to HUD/FX/audio, opens modals.

signal menu_requested

var _rs := RunState.new()
var _engine := GridEngine.new()
var _grid: Array = []
var _mode: StringName = &"story"

var _board: GameBoard
var _hud: GameHud

var _rope_selected := Vector2i(-1, -1)
var _modal_open := false
var _upgrades: Dictionary


func start(mode: StringName) -> void:
	_mode = mode
	if is_inside_tree():
		_ready_run.call_deferred()
	else:
		ready.connect(func(): _ready_run.call_deferred(), CONNECT_ONE_SHOT)


func _ready() -> void:
	_build_layout()


func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.14, 0.12, 0.11)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var safe := MarginContainer.new()
	safe.set_anchors_preset(PRESET_FULL_RECT)
	safe.add_theme_constant_override(&"margin_left", 8)
	safe.add_theme_constant_override(&"margin_top", 8)
	safe.add_theme_constant_override(&"margin_right", 8)
	safe.add_theme_constant_override(&"margin_bottom", 8)
	add_child(safe)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(PRESET_FULL_RECT)
	vb.add_theme_constant_override(&"separation", 8)
	safe.add_child(vb)

	# Header
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = tr(&"headerTitle")
	title.add_theme_font_size_override(&"font_size", 20)
	title.add_theme_color_override(&"font_color", Color(0.541, 0.0, 0.0))
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	var music := Button.new()
	music.text = "🔊" if SaveManager.music_enabled else "🔇"
	music.custom_minimum_size = Vector2(44, 36)
	music.pressed.connect(func():
		SaveManager.music_enabled = not SaveManager.music_enabled
		SaveManager.save()
		SignalBus.music_toggled.emit(SaveManager.music_enabled)
		music.text = "🔊" if SaveManager.music_enabled else "🔇"
	)
	header.add_child(music)
	var menu := Button.new()
	menu.text = "☰"
	menu.custom_minimum_size = Vector2(44, 36)
	menu.pressed.connect(func(): AudioManager.play_sfx(&"ui_click"); menu_requested.emit())
	header.add_child(menu)
	vb.add_child(header)

	# HUD
	_hud = GameHud.new()
	_hud.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hud.rope_pressed.connect(_on_rope_button)
	vb.add_child(_hud)

	# Board — inserted into the HUD's slot once bound (between items and log)
	_board = GameBoard.new()
	_board.swiped.connect(_on_swipe)
	_board.cell_tapped.connect(_on_cell_tapped)


func _ready_run() -> void:
	_upgrades = SaveManager.upgrades.duplicate()
	_rs.reset(_mode, _upgrades)
	_hud.bind(_rs, _upgrades)
	_hud.board_slot.add_child(_board)
	_hud.board_slot.resized.connect(_board._fit_square)
	_board._fit_square()
	_rs.add_log(tr(&"log_game_start").format({"gameMode": tr(&"storyMode") if _mode == &"story" else tr(&"endlessMode")}))
	var res := _engine.initial_grid(_rs)
	_grid = res.grid
	_board.set_grid(_grid)
	for e in res.events:
		_handle_event(e)
	_board.set_torch_lit(false)
	AudioManager.play_music(&"game")

	# QA hook: godot -- auto_moves → scripted swipes for screenshots
	if OS.get_cmdline_user_args().has(&"auto_moves"):
		_auto_moves()


func _auto_moves() -> void:
	var dirs: Array[StringName] = [&"left", &"up", &"left", &"down", &"right", &"up",
		&"left", &"down", &"right", &"down", &"up", &"left", &"right", &"up", &"down", &"left"]
	for i in dirs.size():
		await get_tree().create_timer(0.28).timeout
		_on_swipe(dirs[i])


func _on_swipe(dir: StringName) -> void:
	if _rs.over or _modal_open or _board.rope_mode:
		return
	var res: Dictionary = _engine.move(_grid, dir, _rs, _upgrades)
	if not res.moved and res.events.is_empty():
		return
	_grid = res.grid
	if res.get("xp_delta", 0) > 0:
		SaveManager.total_xp += int(res.xp_delta)
		SaveManager.save()
	_board.apply_events(res.events, _grid)
	for e in res.events:
		_handle_event(e)
	_post_move()


func _post_move() -> void:
	_hud.refresh()
	# Danger glow when horde is close
	var mpa := GoblinDB.moves_per_attack(_rs.level, _rs.mode, _upgrades)
	var left := mpa - (_rs.moves_count % mpa)
	_board.set_danger(left <= GameConfig.HORDE_WARNING_MOVES)
	if _rs.torch_active:
		_board.set_torch_lit(true)


func _handle_event(e: Dictionary) -> void:
	match e.type:
		&"log":
			_rs.add_log(tr(e.key).format(e.get("args", {})))
		&"merge":
			AudioManager.play_sfx(&"merge")
			SignalBus.haptic.emit(0.3)
		&"slain":
			AudioManager.play_sfx(&"kill")
			SignalBus.haptic.emit(0.5)
		&"spawn":
			if e.get("chest"):
				AudioManager.play_sfx(&"chest")
			else:
				AudioManager.play_sfx(&"spawn")
		&"golden_spawn":
			AudioManager.play_sfx(&"golden")
			_rs.add_log(tr(&"log_golden_appeared"))
		&"chest_opened":
			AudioManager.play_sfx(&"coin")
		&"horde_attack":
			AudioManager.play_sfx(&"horde_attack")
			AudioManager.play_sfx(&"hurt", 0.9)
			Fx.shake(_board, 7.0, 0.3)
			SignalBus.haptic.emit(1.0)
		&"overcrowding":
			AudioManager.play_sfx(&"hurt")
			Fx.shake(_board, 4.0, 0.2)
			SignalBus.haptic.emit(0.8)
		&"level_up":
			AudioManager.play_sfx(&"levelup")
		&"milestone":
			AudioManager.play_sfx(&"coin", 1.2)
		&"streak":
			_hud.show_streak(e.count)
			AudioManager.play_sfx(&"streak")
		&"fire_trigger":
			AudioManager.play_sfx(&"fire")
		&"poisoned", &"poison_tick":
			AudioManager.play_sfx(&"poison", 1.1)
		&"victory":
			_on_victory()
		&"game_over":
			_on_game_over()


func _on_victory() -> void:
	AudioManager.play_sfx(&"victory")
	SignalBus.haptic.emit(1.0)
	SaveManager.add_leaderboard_entry({
		"score": _rs.score, "kills": _rs.kills, "xp": _rs.run_xp,
		"time": _rs.elapsed_seconds(), "date": Time.get_date_string_from_system(),
	})
	_open_game_over()


func _on_game_over() -> void:
	AudioManager.play_sfx(&"gameover")
	_open_game_over()


func _open_game_over() -> void:
	_modal_open = true
	await get_tree().create_timer(0.8).timeout
	var p := GameOverPanel.new()
	p.restart.connect(func(): _modal_open = false; _ready_run())
	p.menu.connect(func(): _modal_open = false; menu_requested.emit())
	p.open(_rs, self)


# ---------------------------------------------------------------------------
# Taps: rope mode + shop tiles
# ---------------------------------------------------------------------------

func _on_cell_tapped(r: int, c: int) -> void:
	if _rs.over or _modal_open:
		return
	var t: BoardTile = _grid[r][c]

	if _board.rope_mode:
		if _rope_selected == Vector2i(-1, -1):
			if t != null and t.is_goblin():
				_rope_selected = Vector2i(r, c)
				_board.set_rope_mode(true, _rope_selected)
				_rs.add_log(tr(&"log_rope_selected").format({"value": t.value}))
				AudioManager.play_sfx(&"ui_click")
		else:
			if t == null:
				var res := _engine.rope_move(_grid, _rope_selected, Vector2i(r, c), _rs)
				if res.moved:
					_grid = res.grid
					_board.apply_events(res.events, _grid)
					for e in res.events:
						_handle_event(e)
					AudioManager.play_sfx(&"rope")
					SignalBus.haptic.emit(0.4)
				_exit_rope()
			else:
				_rope_selected = Vector2i(-1, -1)
				_board.set_rope_mode(true)
				_rs.add_log(tr(&"log_rope_cancelled_selection"))
		return

	if t != null and t.kind == BoardTile.Kind.SHOP:
		_open_shop()


func _open_shop() -> void:
	_modal_open = true
	_rs.add_log(tr(&"log_enter_shop"))
	var p := ShopPanel.new()
	p.closed.connect(func(made: bool):
		_modal_open = false
		if made:
			# shopkeeper leaves after a purchase — clear the tile
			for r in GameConfig.GRID_SIZE:
				for c in GameConfig.GRID_SIZE:
					var t: BoardTile = _grid[r][c]
					if t != null and t.kind == BoardTile.Kind.SHOP:
						_grid[r][c] = null
						_board.set_grid(_grid)
						_rs.add_log(tr(&"log_shop_purchase_leaves"))
						return
		else:
			_rs.add_log(tr(&"log_leave_shop"))
	)
	p.open(_rs, _upgrades, self)


func _exit_rope() -> void:
	_rope_selected = Vector2i(-1, -1)
	_board.set_rope_mode(false)


func _on_rope_button() -> void:
	if _rs.rope_count <= 0:
		_hud.add_log("🪢 " + tr(&"toast_no_ropes"))
		return
	if _board.rope_mode:
		_exit_rope()
		_rs.add_log(tr(&"log_rope_cancelled"))
	else:
		_board.set_rope_mode(true)
		_rs.add_log(tr(&"log_rope_activated"))
		AudioManager.play_sfx(&"ui_click")
