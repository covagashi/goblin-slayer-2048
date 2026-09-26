class_name LeaderboardPanel
extends CanvasLayer
## Top-10 fastest story victories.

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

	vb.add_child(PixelUI.heading(tr(&"leaderboardTitle"), "trophy", 20))

	var desc := Label.new()
	desc.text = tr(&"leaderboardDesc")
	desc.theme_type_variation = &"MutedLabel"
	desc.add_theme_font_size_override(&"font_size", 14)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)

	if SaveManager.leaderboard.is_empty():
		var empty := Label.new()
		empty.text = tr(&"noVictories")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size.y = 60
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(empty)
	else:
		var i := 0
		for entry in SaveManager.leaderboard:
			i += 1
			vb.add_child(_row(i, entry))

	var close_btn := Button.new()
	close_btn.text = tr(&"close")
	close_btn.custom_minimum_size.y = 44
	close_btn.pressed.connect(func(): closed.emit(); queue_free())
	vb.add_child(close_btn)

	add_child(ShopPanel.modal_wrap(panel))


func _row(rank: int, e: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.theme_type_variation = &"InsetPanel"
	var hb := HBoxContainer.new()
	row.add_child(hb)
	if rank <= 3:
		hb.add_child(PixelUI.icon(["crown", "trophy", "star"][rank - 1], 24))
	else:
		var r := Label.new()
		r.text = "#%d" % rank
		r.custom_minimum_size.x = 34
		hb.add_child(r)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = "%s  ·  %d" % [_fmt_time(int(e.get("time", 0))), int(e.get("score", 0))]
	t.add_theme_font_size_override(&"font_size", 14)
	mid.add_child(t)
	var d := Label.new()
	d.text = "%s · %s %d · XP %d" % [str(e.get("date", "")), tr(&"kills"), int(e.get("kills", 0)), int(e.get("xp", 0))]
	d.theme_type_variation = &"MutedLabel"
	d.add_theme_font_size_override(&"font_size", 14)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(d)
	hb.add_child(mid)
	return row


func _fmt_time(sec: int) -> String:
	return "%02d:%02d" % [sec / 60, sec % 60]
