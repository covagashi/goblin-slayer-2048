class_name GameOverPanel
extends CanvasLayer
## Victory / defeat screen with run summary.

signal restart
signal menu


func open(rs: RunState, parent: Node) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(330, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 10)
	panel.add_child(vb)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 30)
	if rs.won:
		title.text = "👑 " + tr(&"victory")
		title.add_theme_color_override(&"font_color", Color(0.95, 0.75, 0.2))
	else:
		title.text = "💀 " + tr(&"gameOver")
		title.add_theme_color_override(&"font_color", Color(0.85, 0.15, 0.15))
	vb.add_child(title)

	var reason := Label.new()
	reason.text = tr(rs.over_reason_key)
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.theme_type_variation = &"MutedLabel"
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(reason)

	var stats := PanelContainer.new()
	stats.theme_type_variation = &"InsetPanel"
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override(&"separation", 6)
	stats.add_child(sv)
	var stitle := Label.new()
	stitle.text = tr(&"runSummary")
	stitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stitle.add_theme_color_override(&"font_color", Color(0.72, 0.53, 0.04))
	sv.add_child(stitle)
	sv.add_child(_stat_row("🏆", tr(&"finalScore"), str(rs.score)))
	sv.add_child(_stat_row("⚔", tr(&"goblinsSlain"), str(rs.kills)))
	sv.add_child(_stat_row("⏱", tr(&"time"), _fmt_time(rs.elapsed_seconds())))
	sv.add_child(_stat_row("✨", tr(&"xpEarned"), str(rs.run_xp)))
	vb.add_child(stats)

	var again := Button.new()
	again.theme_type_variation = &"GoldButton"
	again.text = tr(&"slayAgain") if rs.won else tr(&"playAgain")
	again.custom_minimum_size.y = 48
	again.pressed.connect(func(): restart.emit(); queue_free())
	vb.add_child(again)

	var back := Button.new()
	back.text = tr(&"back_to_menu")
	back.custom_minimum_size.y = 44
	back.pressed.connect(func(): menu.emit(); queue_free())
	vb.add_child(back)

	parent.add_child(self)
	add_child(ShopPanel.modal_wrap(panel))


func _stat_row(icon: String, label: String, value: String) -> Control:
	var hb := HBoxContainer.new()
	var i := Label.new()
	i.text = icon
	hb.add_child(i)
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override(&"font_size", 14)
	hb.add_child(l)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override(&"font_size", 14)
	v.add_theme_color_override(&"font_color", Color(0.72, 0.53, 0.04))
	hb.add_child(v)
	return hb


func _fmt_time(sec: int) -> String:
	return "%02d:%02d" % [sec / 60, sec % 60]
