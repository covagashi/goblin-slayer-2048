class_name HowToPanel
extends CanvasLayer
## How-to-play guide, rendered from translation keys.

signal closed

const SECTIONS: Array[Array] = [
	[&"h2pBasics", [&"basicsL1", &"basicsL2", &"basicsL3", &"basicsL4"]],
	[&"h2pCombat", [&"combatL1", &"combatL2", &"combatL3"]],
	[&"h2pPowerups", [&"powerupsL1", &"powerupsL2"]],
	[&"h2pProgression", [&"progressionL1", &"progressionL2", &"progressionL3", &"progressionL4"]],
	[&"h2pModes", [&"modesL1", &"modesL2"]],
]


func open(parent: Node) -> void:
	parent.add_child(self)
	_build()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(352, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 8)
	panel.add_child(vb)

	vb.add_child(PixelUI.heading(tr(&"h2pTitle"), "book", 20))

	var scroll := ScrollContainer.new()
	PixelUI.style_scroll(scroll)
	scroll.custom_minimum_size = Vector2(0, 480)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", 8)
	scroll.add_child(list)
	vb.add_child(scroll)

	for sec in SECTIONS:
		var h := Label.new()
		h.text = tr(sec[0])
		h.add_theme_color_override(&"font_color", Color(0.72, 0.53, 0.04))
		h.add_theme_font_size_override(&"font_size", 16)
		list.add_child(h)
		for line_key in sec[1]:
			var l := Label.new()
			l.text = "• " + tr(line_key).format({"hp": GameConfig.INITIAL_PLAYER_HP})
			l.theme_type_variation = &"MutedLabel"
			l.add_theme_font_size_override(&"font_size", 13)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			list.add_child(l)
		list.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = tr(&"h2pGotIt")
	close_btn.custom_minimum_size.y = 44
	close_btn.pressed.connect(func(): closed.emit(); queue_free())
	vb.add_child(close_btn)

	add_child(ShopPanel.modal_wrap(panel))
