class_name GameHud
extends VBoxContainer
## Info panel + items bar + event log. Listens to RunState signals only.

signal rope_pressed
signal how_to_pressed

const ITEM_ICONS := {
	&"sword": "item-sword.png", &"torch": "item-torch.png", &"shield": "item-shield.png",
	&"poison": "item-poison.png", &"fireScroll": "item-fire-scroll.png", &"healthPotion": "item-health-potion.png",
	&"rope": "item-rope.png",
}
const ITEM_DIR := "res://assets/sprites/items/"

var _rs: RunState
var _upgrades: Dictionary

var _hp_bar: ProgressBar
var _hp_label: Label
var _score: Label
var _gold: Label
var _level: Label
var _xp: Label
var _kills_left: Label
var _moves_left: Label
var _rope_btn: Button
var _items_row: HBoxContainer
var _dmg_badge: Label
var _dr_badge: Label
var _log_box: VBoxContainer
var _streak_banner: Label
var board_slot: Control # GameScene inserts the GameBoard here (between items and log)


func _init() -> void:
	add_theme_constant_override(&"separation", 8)


func bind(rs: RunState, upgrades: Dictionary) -> void:
	var first := _rs == null
	_rs = rs
	_upgrades = upgrades
	if first:
		rs.stats_changed.connect(refresh)
		rs.items_changed.connect(_refresh_items)
		rs.log_added.connect(add_log)
	if _log_box == null:
		_build()
	else:
		for c in _log_box.get_children():
			c.queue_free()
		_streak_banner.visible = false
	refresh()
	_refresh_items()


func _build() -> void:
	# --- Stats panel -------------------------------------------------------
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 6)
	panel.add_child(vb)

	# HP
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override(&"separation", 8)
	var heart := Label.new()
	heart.text = "❤"
	heart.add_theme_color_override(&"font_color", Color(0.85, 0.15, 0.15))
	hp_row.add_child(heart)
	_hp_bar = ProgressBar.new()
	_hp_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	_hp_bar.custom_minimum_size.y = 12
	_hp_bar.show_percentage = false
	hp_row.add_child(_hp_bar)
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override(&"font_size", 14)
	hp_row.add_child(_hp_label)
	vb.add_child(hp_row)

	# Stat cells — two rows: 4 short numbers, then 2 text cells. Separate
	# grids so long translated strings can't stretch the numeric columns.
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 6)
	vb.add_child(grid)
	_score = _stat_cell(grid, "🏆")
	_gold = _stat_cell(grid, "🪙")
	_level = _stat_cell(grid, "⭐")
	_xp = _stat_cell(grid, "✨")
	var grid2 := GridContainer.new()
	grid2.columns = 2
	grid2.add_theme_constant_override(&"h_separation", 6)
	vb.add_child(grid2)
	_kills_left = _stat_cell(grid2, "🎯", true)
	_moves_left = _stat_cell(grid2, "⚡", true)

	# streak banner
	_streak_banner = Label.new()
	_streak_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_streak_banner.add_theme_font_size_override(&"font_size", 18)
	_streak_banner.add_theme_color_override(&"font_color", Color(1.0, 0.55, 0.1))
	_streak_banner.visible = false
	vb.add_child(_streak_banner)
	add_child(panel)

	# --- Items bar -----------------------------------------------------------
	var items_panel := PanelContainer.new()
	items_panel.theme_type_variation = &"InsetPanel"
	var items_h := HBoxContainer.new()
	items_h.alignment = BoxContainer.ALIGNMENT_CENTER
	items_h.add_theme_constant_override(&"separation", 10)
	items_panel.add_child(items_h)

	var rope_lbl := Label.new()
	rope_lbl.text = "🪢"
	rope_lbl.add_theme_font_size_override(&"font_size", 20)
	items_h.add_child(rope_lbl)
	_rope_btn = Button.new()
	_rope_btn.custom_minimum_size = Vector2(90, 44)
	_rope_btn.pressed.connect(func(): rope_pressed.emit())
	items_h.add_child(_rope_btn)

	var sep := VSeparator.new()
	items_h.add_child(sep)
	_items_row = HBoxContainer.new()
	_items_row.add_theme_constant_override(&"separation", 6)
	_items_row.size_flags_horizontal = SIZE_EXPAND_FILL
	items_h.add_child(_items_row)

	_dmg_badge = Label.new()
	_dmg_badge.add_theme_font_size_override(&"font_size", 13)
	items_h.add_child(_dmg_badge)
	_dr_badge = Label.new()
	_dr_badge.add_theme_font_size_override(&"font_size", 13)
	items_h.add_child(_dr_badge)
	add_child(items_panel)

	# --- Board slot (GameScene reparents GameBoard here) ---------------------
	board_slot = Control.new()
	board_slot.custom_minimum_size = Vector2(0, 300)
	board_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_slot.size_flags_stretch_ratio = 1.7
	add_child(board_slot)

	# --- Event log -------------------------------------------------------------
	var log_panel := PanelContainer.new()
	log_panel.theme_type_variation = &"CardPanel"
	log_panel.size_flags_vertical = SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_box = VBoxContainer.new()
	_log_box.size_flags_horizontal = SIZE_EXPAND_FILL
	_log_box.add_theme_constant_override(&"separation", 2)
	scroll.add_child(_log_box)
	log_panel.add_child(scroll)
	add_child(log_panel)


func _stat_cell(parent: Control, icon: String, clip := false) -> Label:
	var cell := PanelContainer.new()
	cell.theme_type_variation = &"InsetPanel"
	cell.size_flags_horizontal = SIZE_EXPAND_FILL
	cell.clip_contents = true
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override(&"separation", 4)
	var i := Label.new()
	i.text = icon
	i.add_theme_font_size_override(&"font_size", 13)
	hb.add_child(i)
	var l := Label.new()
	l.add_theme_font_size_override(&"font_size", 14)
	l.text = "0"
	if clip:
		l.clip_text = true
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hb.add_child(l)
	cell.add_child(hb)
	parent.add_child(cell)
	return l


func refresh() -> void:
	if _rs == null:
		return
	_hp_bar.max_value = _rs.player_max_hp
	_hp_bar.value = _rs.player_hp
	_hp_label.text = "%d/%d" % [_rs.player_hp, _rs.player_max_hp]
	_score.text = str(_rs.score)
	_gold.text = str(_rs.gold)
	_level.text = str(_rs.level)
	_xp.text = str(SaveManager.total_xp)
	var mpa := GoblinDB.moves_per_attack(_rs.level, _rs.mode, _upgrades)
	var moves_left := mpa - (_rs.moves_count % mpa)
	_moves_left.text = "%d %s" % [moves_left, tr(&"movesUntilAttack")]
	_kills_left.text = "%d %s" % [GameConfig.KILLS_PER_LEVEL - _rs.kills_since_level, tr(&"killsToLevel")]
	_rope_btn.text = "%s (%d)" % [tr(&"use"), _rs.rope_count]
	_rope_btn.disabled = _rs.rope_count <= 0
	_dmg_badge.text = ("🗡+%d" % _rs.damage_bonus) if _rs.damage_bonus > 0 else ""
	_dr_badge.text = ("🛡+%d" % _rs.damage_reduction) if _rs.damage_reduction > 0 else ""


func _refresh_items() -> void:
	for c in _items_row.get_children():
		c.queue_free()
	for id in _rs.purchased_items:
		if id == &"healthPotion" or id == &"rope":
			continue
		var tex: Variant = ITEM_ICONS.get(id)
		if tex == null:
			continue
		var tr_icon := TextureRect.new()
		tr_icon.custom_minimum_size = Vector2(28, 28)
		tr_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr_icon.texture = load(ITEM_DIR + tex)
		tr_icon.tooltip_text = tr(StringName(id + "_name"))
		_items_row.add_child(tr_icon)


func add_log(message: String) -> void:
	var l := Label.new()
	l.text = message
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override(&"font_size", 12)
	l.add_theme_color_override(&"font_color", Color(0.78, 0.78, 0.78))
	l.modulate.a = 0.0
	_log_box.add_child(l)
	_log_box.move_child(l, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.25)
	# queue_free() defers removal — detach first or the while never sees the count drop
	while _log_box.get_child_count() > 50:
		var oldest := _log_box.get_child(_log_box.get_child_count() - 1)
		_log_box.remove_child(oldest)
		oldest.queue_free()


func show_streak(count: int) -> void:
	_streak_banner.text = "🔥 " + tr(&"streak_banner").format({"count": count})
	_streak_banner.visible = true
	_streak_banner.scale = Vector2.ZERO
	_streak_banner.pivot_offset = _streak_banner.size / 2.0
	var tw := _streak_banner.create_tween()
	tw.tween_property(_streak_banner, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(1.6).timeout.connect(func(): _streak_banner.visible = false)
