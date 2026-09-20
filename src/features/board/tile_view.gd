class_name TileView
extends Control
## Visual representation of one BoardTile. Stateless — renders its `tile`.

const GOBLIN_TEX := "res://assets/sprites/goblins/goblin-%d.png"
const VARIANT_DIR := "res://assets/sprites/variants/"
const TWEEN_SLIDE := 0.11

var tile: BoardTile

var _sprite: TextureRect
var _hp_bar: ColorRect
var _hp_bg: ColorRect
var _badge: Label
var _border: Panel


func setup(t: BoardTile, cell_size: float) -> void:
	tile = t
	custom_minimum_size = Vector2(cell_size, cell_size)
	size = Vector2(cell_size, cell_size)
	_build()


func _build() -> void:
	_border = Panel.new()
	_border.set_anchors_preset(PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	match tile.kind:
		BoardTile.Kind.CHEST:
			style.bg_color = Color(0.35, 0.24, 0.08)
			style.border_color = Color(0.85, 0.65, 0.1)
		BoardTile.Kind.SHOP:
			style.bg_color = Color(0.28, 0.14, 0.38)
			style.border_color = Color(0.62, 0.4, 0.9)
		_:
			style.bg_color = Color(0.13, 0.11, 0.1)
			style.border_color = Color(0.28, 0.24, 0.22)
	if tile.is_golden:
		style.border_color = Color(1.0, 0.84, 0.0)
		style.bg_color = Color(0.3, 0.24, 0.05)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	_border.add_theme_stylebox_override(&"panel", style)
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
	else:
		var icon := Label.new()
		icon.set_anchors_preset(PRESET_FULL_RECT)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override(&"font_size", 30)
		icon.text = "📦" if tile.kind == BoardTile.Kind.CHEST else "🏪"
		add_child(icon)

	# Poison / golden badge
	_badge = Label.new()
	_badge.set_anchors_preset(PRESET_TOP_RIGHT)
	_badge.offset_left = -22
	_badge.offset_top = 1
	_badge.offset_right = -2
	_badge.offset_bottom = 20
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.add_theme_font_size_override(&"font_size", 13)
	add_child(_badge)
	_update_badge()


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


func _update_badge() -> void:
	if tile.poisoned > 0:
		_badge.text = "🤢"
	elif tile.is_golden:
		_badge.text = "✨"
	else:
		_badge.text = ""


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
