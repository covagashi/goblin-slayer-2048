class_name LanguagePanel
extends CanvasLayer
## Choose a language by its native name; apply only after an explicit selection.

signal selected(locale: StringName)


func open(parent: Node) -> void:
	parent.add_child(self)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 340
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	panel.add_child(column)
	column.add_child(PixelUI.heading(tr(&"languageTitle"), "globe", 22))
	var hint := Label.new()
	hint.text = tr(&"languageHint")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.theme_type_variation = &"MutedLabel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(328, get_viewport().get_visible_rect().size.y - 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	PixelUI.style_scroll(scroll)
	column.add_child(scroll)
	var choices := VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override(&"separation", 6)
	scroll.add_child(choices)
	var group := ButtonGroup.new()
	for locale in GameLocale.NAMES:
		var button := Button.new()
		button.name = "Locale_" + String(locale)
		button.text = GameLocale.NAMES[locale]
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.custom_minimum_size.y = 48
		button.toggle_mode = true
		button.button_group = group
		button.set_pressed_no_signal(locale == SaveManager.language)
		button.pressed.connect(_select.bind(locale))
		choices.add_child(button)
	PixelUI.pass_scroll_gestures(choices)
	var close_button := Button.new()
	close_button.name = &"CloseButton"
	close_button.text = tr(&"close")
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(queue_free)
	column.add_child(close_button)
	add_child(ShopPanel.modal_wrap(panel))


func _select(locale: StringName) -> void:
	SaveManager.set_language(locale)
	AudioManager.play_sfx(&"ui_click")
	selected.emit(locale)
	queue_free()
