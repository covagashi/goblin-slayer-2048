class_name GameBoard
extends Control
## 4×4 board: background cells, tile views, swipe/tap input, event-driven
## animations. Owns TileView nodes — the engine owns the data.

signal swiped(dir: StringName)
signal cell_tapped(r: int, c: int)

const SLIDE := 0.11
const IMPACT_DELAY := 0.08
const SPAWN_DELAY := 0.12

var rope_mode := false
var rope_selected := Vector2i(-1, -1)
var input_enabled := true

var _grid: Array = []
var _views := {} # tile.id -> TileView
var _bg_cells := []
var _tiles_layer: Control
var _fx_layer: Control
var _rope_layer: Control
var _danger: Panel
var _touch_start := Vector2.INF
var _cell := 0.0


func _ready() -> void:
	clip_contents = true

	var bg := GridContainer.new()
	bg.columns = GameConfig.GRID_SIZE
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.add_theme_constant_override(&"h_separation", 4)
	bg.add_theme_constant_override(&"v_separation", 4)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)
	for i in GameConfig.GRID_SIZE * GameConfig.GRID_SIZE:
		var cell := Panel.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.16, 0.14, 0.13)
		st.set_corner_radius_all(6)
		cell.add_theme_stylebox_override(&"panel", st)
		cell.size_flags_horizontal = SIZE_EXPAND_FILL
		cell.size_flags_vertical = SIZE_EXPAND_FILL
		cell.mouse_filter = MOUSE_FILTER_IGNORE # decorative — board owns input
		bg.add_child(cell)
		_bg_cells.append(cell)

	_tiles_layer = Control.new()
	_tiles_layer.set_anchors_preset(PRESET_FULL_RECT)
	_tiles_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_tiles_layer)

	_fx_layer = Control.new()
	_fx_layer.set_anchors_preset(PRESET_FULL_RECT)
	_fx_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_fx_layer)

	_rope_layer = Control.new()
	_rope_layer.set_anchors_preset(PRESET_FULL_RECT)
	_rope_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_rope_layer.draw.connect(_draw_rope_hints)
	add_child(_rope_layer)

	_danger = Panel.new()
	_danger.set_anchors_preset(PRESET_FULL_RECT)
	var dst := StyleBoxFlat.new()
	dst.bg_color = Color(0, 0, 0, 0)
	dst.border_color = Color(0.85, 0.1, 0.1, 0.9)
	dst.set_border_width_all(3)
	dst.set_corner_radius_all(8)
	_danger.add_theme_stylebox_override(&"panel", dst)
	_danger.mouse_filter = MOUSE_FILTER_IGNORE
	_danger.visible = false
	add_child(_danger)

	resized.connect(_on_resized)


## Keep the board square inside its parent slot (board is centered + sized s×s).
func _fit_square() -> void:
	var p := get_parent()
	if p == null:
		return
	var s: float = minf(p.size.x, p.size.y)
	size = Vector2(s, s)
	position = (p.size - size) / 2.0
	_on_resized()


func _on_resized() -> void:
	_cell = size.x / GameConfig.GRID_SIZE
	for id in _views:
		var v: TileView = _views[id]
		v.size = Vector2(_cell - 6, _cell - 6)
		v.position = _cell_pos(v.tile.row, v.tile.col)
	_rope_layer.queue_redraw()


func _cell_pos(r: int, c: int) -> Vector2:
	return Vector2(c * _cell + 3, r * _cell + 3)


func cell_center(r: int, c: int) -> Vector2:
	return _cell_pos(r, c) + Vector2(_cell, _cell) / 2.0


func set_grid(grid: Array) -> void:
	_grid = grid
	_sync_views()


func _sync_views() -> void:
	var alive := {}
	for r in GameConfig.GRID_SIZE:
		for c in GameConfig.GRID_SIZE:
			var t: BoardTile = _grid[r][c]
			if t == null:
				continue
			alive[t.id] = true
			var v: TileView = _views.get(t.id)
			if v == null:
				v = _spawn_view(t, false)
			elif v.tile != t:
				v.tile = t
				v.refresh()
			v.position = _cell_pos(r, c)
	for id in _views.keys():
		if not alive.has(id):
			_views[id].queue_free()
			_views.erase(id)


func _spawn_view(t: BoardTile, animate := true) -> TileView:
	var v := TileView.new()
	v.setup(t, _cell - 6)
	v.position = _cell_pos(t.row, t.col)
	_tiles_layer.add_child(v)
	_views[t.id] = v
	if animate:
		Fx.pop(v)
	return v


# ---------------------------------------------------------------------------
# Input — swipe + taps (touch via InputEventScreen*, mouse via emulate_touch)
# ---------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
		elif _touch_start != Vector2.INF:
			_release(event.position)
	elif event is InputEventScreenDrag and _touch_start != Vector2.INF:
		# Commit swipe early once past threshold — feels snappier
		var d: Vector2 = event.position - _touch_start
		if d.length() > GameConfig.SWIPE_MIN_DIST_PX * 2.0:
			_commit_swipe(d)


func _release(pos: Vector2) -> void:
	var d: Vector2 = pos - _touch_start
	_touch_start = Vector2.INF
	if d.length() < GameConfig.SWIPE_MIN_DIST_PX:
		_tap(pos)
	else:
		_commit_swipe(d)


func _commit_swipe(d: Vector2) -> void:
	if _touch_start == Vector2.INF:
		return
	_touch_start = Vector2.INF
	if rope_mode:
		return
	var dir: StringName = &"left"
	if absf(d.x) > absf(d.y):
		dir = &"right" if d.x > 0 else &"left"
	else:
		dir = &"down" if d.y > 0 else &"up"
	swiped.emit(dir)


func _tap(pos: Vector2) -> void:
	var r := int(pos.y / _cell)
	var c := int(pos.x / _cell)
	if r >= 0 and r < GameConfig.GRID_SIZE and c >= 0 and c < GameConfig.GRID_SIZE:
		cell_tapped.emit(r, c)


# ---------------------------------------------------------------------------
# Rope mode visuals
# ---------------------------------------------------------------------------

func set_rope_mode(active: bool, selected := Vector2i(-1, -1)) -> void:
	rope_mode = active
	rope_selected = selected
	_rope_layer.queue_redraw()
	for id in _views:
		var v: TileView = _views[id]
		v.modulate = Color(1.4, 1.4, 0.6) if (active and v.tile.row == selected.x and v.tile.col == selected.y) else Color.WHITE


func _draw_rope_hints() -> void:
	if not rope_mode or _grid.is_empty():
		return
	for r in GameConfig.GRID_SIZE:
		for c in GameConfig.GRID_SIZE:
			if _grid[r][c] == null:
				_rope_layer.draw_rect(Rect2(_cell_pos(r, c), Vector2(_cell - 6, _cell - 6)), Color(0.3, 0.9, 0.3, 0.18), true)
				_rope_layer.draw_rect(Rect2(_cell_pos(r, c), Vector2(_cell - 6, _cell - 6)), Color(0.3, 0.9, 0.3, 0.5), false, 2.0)


# ---------------------------------------------------------------------------
# Danger border (horde incoming)
# ---------------------------------------------------------------------------

func set_danger(on: bool) -> void:
	_danger.visible = on
	if on:
		var tw := _danger.create_tween().set_loops()
		tw.tween_property(_danger, "modulate:a", 0.25, 0.4)
		tw.tween_property(_danger, "modulate:a", 1.0, 0.4)
	else:
		_danger.modulate.a = 1.0


func set_torch_lit(lit: bool) -> void:
	for id in _views:
		var v: TileView = _views[id]
		v.set_hp_visible(lit)
		# torch "fog": board reads dimmer without it (rope highlight uses modulate)
		v.self_modulate = Color.WHITE if lit else Color(0.82, 0.82, 0.88)


func view_for(id: int) -> TileView:
	return _views.get(id)


# ---------------------------------------------------------------------------
# Event application — the juice orchestration
# ---------------------------------------------------------------------------

func apply_events(events: Array, final_grid: Array) -> void:
	_grid = final_grid

	# Phase 1 — slides
	for e in events:
		match e.type:
			&"tile_move":
				var v: TileView = _views.get(e.id)
				if v:
					v.tile.row = e.to.x
					v.tile.col = e.to.y
					var tw := v.create_tween()
					tw.tween_property(v, "position", _cell_pos(e.to.x, e.to.y), SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			&"tile_consume":
				var v: TileView = _views.get(e.id)
				if v:
					var tw := v.create_tween()
					tw.tween_property(v, "position", _cell_pos(e.to.x, e.to.y), SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
					tw.tween_callback(v.queue_free)
					_views.erase(e.id)

	# Phase 2 — impacts (after tiles land)
	for e in events:
		match e.type:
			&"merge":
				_delayed(func(): Fx.burst(_fx_layer, cell_center(e.at.x, e.at.y), Color(1.0, 0.6, 0.15), 10), IMPACT_DELAY)
			&"merge_result":
				_delayed(func():
					var v := _spawn_view(e.tile)
					Fx.squash(v)
				, IMPACT_DELAY)
			&"slain":
				_delayed(func():
					_kill_view_at(e.at)
					Fx.burst(_fx_layer, cell_center(e.at.x, e.at.y), Color(0.8, 0.1, 0.1) if not e.get("fire") else Color(1.0, 0.45, 0.05), 14)
					Fx.floating_text(_fx_layer, cell_center(e.at.x, e.at.y), "+%d" % e.gold, Color(0.95, 0.75, 0.2), 16)
				, IMPACT_DELAY)
			&"chest_opened":
				_delayed(func(): Fx.burst(_fx_layer, cell_center(e.at.x, e.at.y), Color(0.95, 0.75, 0.2), 12), IMPACT_DELAY)
			&"spawn":
				_delayed(func(): _spawn_view(e.tile), SPAWN_DELAY)
			&"golden_spawn":
				_delayed(func(): Fx.burst(_fx_layer, cell_center(e.at.x, e.at.y), Color(1.0, 0.9, 0.3), 18, 90.0), SPAWN_DELAY)
			&"poison_tick":
				var v := _view_at(e.at)
				if v:
					if e.died:
						_delayed(func(): _kill_view_at(e.at), IMPACT_DELAY)
					else:
						v.flash_damage()
						v.refresh()
			&"fire_hit":
				var v := _view_at(e.at)
				if v:
					v.flash_damage()
					v.refresh()
			&"fire_trigger":
				for mc in e.cells:
					Fx.burst(_fx_layer, cell_center(mc.x, mc.y), Color(1.0, 0.45, 0.05), 16, 110.0)
			&"shop_removed", &"chest_vanished":
				_delayed(func(): _kill_view_at(e.at), SPAWN_DELAY)
			&"poisoned":
				var v := _view_at(e.at)
				if v:
					v.refresh()

	# Safety resync after animations settle
	var resync := func():
		for r in GameConfig.GRID_SIZE:
			for c in GameConfig.GRID_SIZE:
				var t: BoardTile = _grid[r][c]
				if t == null:
					continue
				var v: TileView = _views.get(t.id)
				if v != null:
					v.position = _cell_pos(r, c)
					v.refresh()
	get_tree().create_timer(SPAWN_DELAY + POP_SLACK).timeout.connect(resync)


const POP_SLACK := 0.15


func _view_at(at: Vector2i) -> TileView:
	for id in _views:
		var v: TileView = _views[id]
		if v.tile.row == at.x and v.tile.col == at.y:
			return v
	return null


func _kill_view_at(at: Vector2i) -> void:
	var v := _view_at(at)
	if v:
		_views.erase(v.tile.id)
		v.die_then_free()


func _delayed(cb: Callable, delay: float) -> void:
	get_tree().create_timer(delay).timeout.connect(cb)
