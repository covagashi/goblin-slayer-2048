class_name UpgradesPanel
extends CanvasLayer
## Permanent upgrades shop — spend meta XP (persists via SaveManager).

signal closed


func open(parent: Node) -> void:
	parent.add_child(self)
	_build()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(352, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 8)
	panel.add_child(vb)

	var head := HBoxContainer.new()
	var title := Label.new()
	title.text = "✨ " + tr(&"permUpgradesTitle")
	title.add_theme_font_size_override(&"font_size", 20)
	title.add_theme_color_override(&"font_color", Color(0.72, 0.53, 0.04))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var xp := Label.new()
	xp.text = "%s %d" % [tr(&"totalXpLabel"), SaveManager.total_xp]
	xp.add_theme_color_override(&"font_color", Color(0.72, 0.53, 0.04))
	head.add_child(xp)
	vb.add_child(head)

	var sub := Label.new()
	sub.text = tr(&"permUpgradesDesc")
	sub.theme_type_variation = &"MutedLabel"
	sub.add_theme_font_size_override(&"font_size", 12)
	vb.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", 6)
	scroll.add_child(list)
	vb.add_child(scroll)

	for up in GoblinDB.PERMANENT_UPGRADES:
		list.add_child(_upgrade_row(up))

	var close_btn := Button.new()
	close_btn.text = tr(&"close")
	close_btn.custom_minimum_size.y = 44
	close_btn.pressed.connect(func(): closed.emit(); queue_free())
	vb.add_child(close_btn)

	add_child(ShopPanel.modal_wrap(panel))


func _upgrade_row(up: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.theme_type_variation = &"InsetPanel"
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 10)
	row.add_child(hb)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_l := Label.new()
	var uid: StringName = up.id
	name_l.text = tr(StringName(String(uid) + "_name"))
	name_l.add_theme_font_size_override(&"font_size", 14)
	info.add_child(name_l)
	var desc_l := Label.new()
	desc_l.text = tr(StringName(String(uid) + "_desc"))
	desc_l.theme_type_variation = &"MutedLabel"
	desc_l.add_theme_font_size_override(&"font_size", 11)
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_l)
	var lvl_l := Label.new()
	var cur := SaveManager.upgrade_level(uid)
	lvl_l.text = "Lv %d/%d" % [cur, up.max_level]
	lvl_l.theme_type_variation = &"MutedLabel"
	lvl_l.add_theme_font_size_override(&"font_size", 11)
	info.add_child(lvl_l)
	hb.add_child(info)

	var buy := Button.new()
	buy.custom_minimum_size = Vector2(80, 40)
	if cur >= up.max_level:
		buy.text = tr(&"maxLevel")
		buy.disabled = true
	elif SaveManager.total_xp < up.cost:
		buy.text = "✨%d" % up.cost
		buy.disabled = true
	else:
		buy.text = "✨%d" % up.cost
		buy.pressed.connect(_buy.bind(up))
	hb.add_child(buy)
	return row


func _buy(up: Dictionary) -> void:
	if not SaveManager.buy_upgrade(up.id, up.cost, up.max_level):
		return
	AudioManager.play_sfx(&"levelup")
	SignalBus.haptic.emit(0.5)
	for c in get_children():
		c.queue_free()
	_build()
