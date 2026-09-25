class_name TileView
extends Control
## Visual representation of one BoardTile. Stateless — renders its `tile`.

const GOBLIN_TEX := "res://assets/sprites/goblins/goblin-%d.png"
const VARIANT_DIR := "res://assets/sprites/variants/"
const ANIM_DIR := "res://assets/sprites/animated/"
const TWEEN_SLIDE := 0.11

var tile: BoardTile

var _sprite: TextureRect
var _idle_frames: Array[AtlasTexture] = []
var _idle_frame := 0
var _hp_bar: ColorRect
var _hp_bg: ColorRect
var _border: Panel
var _badge_icon: TextureRect


func setup(t: BoardTile, cell_size: float) -> void:
	tile = t
	custom_minimum_size = Vector2(cell_size, cell_size)
	size = Vector2(cell_size, cell_size)
	_build()
	_ignore_mouse(self)


## Tiles are pure presentation — the board owns all input. Without this every
## child (border panel, sprite, labels) eats swipes/taps before _gui_input.
func _ignore_mouse(n: Node) -> void:
	if n is Control:
		n.mouse_filter = MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_mouse(c)


func _build() -> void:
	_border = Panel.new()
	_border.set_anchors_preset(PRESET_FULL_RECT)
	var frame_name := "tile"
	match tile.kind:
		BoardTile.Kind.CHEST:
			frame_name = "tile_chest"
		BoardTile.Kind.SHOP:
			frame_name = "tile_shop"
	if tile.is_golden:
		frame_name = "tile_gold"
	_border.add_theme_stylebox_override(&"panel", PixelUI.frame(frame_name))
	add_child(_border)

	if tile.kind == BoardTile.Kind.GOBLIN:
		_sprite = TextureRect.new()
		_sprite.set_anchors_preset(PRESET_FULL_RECT)
		_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var path := VARIANT_DIR + tile.variant_file if tile.variant_file != "" else GOBLIN_TEX % tile.value
		_sprite.texture = load(path)
		add_child(_sprite)
		var sheet_name := tile.variant_file if tile.variant_file != "" else "goblin-%d.png" % tile.value
		var sheet := load(ANIM_DIR + sheet_name) as Texture2D
		if sheet != null:
			var frame_size := 38 if tile.variant_file != "" else 32
			for index in 6:
				var frame := AtlasTexture.new()
				frame.atlas = sheet
				frame.region = Rect2(index * frame_size, 0, frame_size, frame_size)
				_idle_frames.append(frame)
			_sprite.texture = _idle_frames[0]
			var idle_timer := Timer.new()
			idle_timer.wait_time = 0.19
			idle_timer.autostart = true
			idle_timer.timeout.connect(_advance_idle)
			add_child(idle_timer)

		# HP bar (torch reveals it)
		_hp_bg = ColorRect.new()
		_hp_bg.color = Color(0, 0, 0, 0.55)
		_hp_bg.set_anchors_preset(PRESET_BOTTOM_WIDE)
		_hp_bg.offset_top = -7
		_hp_bg.offset_left = 3
		_hp_bg.offset_right = -3
		_hp_bg.offset_bottom = -3
		_hp_bar = ColorRect.new()
		_hp_bar.color = Color(0.85, 0.12, 0.12)
		_hp_bar.set_anchors_preset(PRESET_FULL_RECT)
		_hp_bg.add_child(_hp_bar)
		add_child(_hp_bg)
		_update_hp_bar()

		# Level value — needed to tell tiers apart at a glance
		var lvl := Label.new()
		lvl.set_anchors_preset(PRESET_BOTTOM_WIDE)
		lvl.offset_top = -19
		lvl.offset_bottom = -8
		lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lvl.add_theme_font_size_override(&"font_size", 14)
		lvl.add_theme_constant_override(&"outline_size", 5)
		lvl.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
		lvl.text = str(tile.value)
		lvl.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(lvl)
	else:
		var icon := PixelUI.icon("chest" if tile.kind == BoardTile.Kind.CHEST else "shop", 36)
		icon.set_anchors_preset(PRESET_FULL_RECT)
		add_child(icon)
		# Lifetime countdown — expires in `turns_left` moves
		var ttl := Label.new()
		ttl.set_anchors_preset(PRESET_TOP_WIDE)
		ttl.offset_top = 2
		ttl.offset_bottom = 18
		ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ttl.add_theme_font_size_override(&"font_size", 13)
		ttl.add_theme_constant_override(&"outline_size", 4)
		ttl.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
		ttl.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.45))
		ttl.name = &"TtlLabel"
		add_child(ttl)

	# Poison / golden badge
	_badge_icon = PixelUI.icon("sparkle", 16)
	_badge_icon.set_anchors_preset(PRESET_TOP_RIGHT)
	_badge_icon.offset_left = -20
	_badge_icon.offset_top = 3
	_badge_icon.offset_right = -4
	_badge_icon.offset_bottom = 19
	add_child(_badge_icon)
	_update_badge()


func _advance_idle() -> void:
	_idle_frame = (_idle_frame + 1) % _idle_frames.size()
	_sprite.texture = _idle_frames[_idle_frame]


func _update_hp_bar() -> void:
	if _hp_bar == null:
		return
	var pct := clampf(float(tile.hp) / float(maxi(tile.max_hp, 1)), 0.0, 1.0)
	_hp_bar.anchor_right = pct
	_hp_bg.visible = _show_hp


var _show_hp := false


func set_hp_visible(v: bool) -> void:
	_show_hp = v
	_update_hp_bar()


func refresh() -> void:
	_update_hp_bar()
	_update_badge()
	# Last-turn urgency: chests/shops throb when about to vanish
	if tile.kind != BoardTile.Kind.GOBLIN and tile.turns_left <= 1:
		var tw := create_tween()
		tw.tween_property(_border, "modulate", Color(1.7, 0.6, 0.4), 0.15)
		tw.tween_property(_border, "modulate", Color.WHITE, 0.15)


func _update_badge() -> void:
	if tile.kind != BoardTile.Kind.GOBLIN:
		var ttl := get_node_or_null(^"TtlLabel") as Label
		if ttl:
			ttl.text = str(tile.turns_left)
		return
	if tile.poisoned > 0:
		_badge_icon.texture = PixelUI.icon_texture("poison")
		_badge_icon.visible = true
	elif tile.is_golden:
		_badge_icon.texture = PixelUI.icon_texture("sparkle")
		_badge_icon.visible = true
	else:
		_badge_icon.visible = false


func flash_damage() -> void:
	modulate = Color(2.5, 2.5, 2.5)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)


func die_then_free() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.3, 0.1), 0.18).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)
