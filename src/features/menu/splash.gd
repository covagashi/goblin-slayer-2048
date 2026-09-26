class_name SplashScreen
extends Control
## Title screen: mode select, meta progression, settings.

signal mode_selected(mode: StringName)


func _ready() -> void:
	_build()
	AudioManager.play_music(&"menu")


func _build() -> void:
	for c in get_children():
		c.queue_free()
	add_child(PixelUI.backdrop())

	var outer := MarginContainer.new()
	outer.set_anchors_preset(PRESET_FULL_RECT)
	outer.add_theme_constant_override(&"margin_left", 16)
	outer.add_theme_constant_override(&"margin_right", 16)
	outer.add_theme_constant_override(&"margin_top", 12)
	outer.add_theme_constant_override(&"margin_bottom", 12)
	add_child(outer)

	var scroll := ScrollContainer.new()
	scroll.name = &"MenuScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	PixelUI.style_scroll(scroll)
	outer.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(340, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 12)
	card.add_child(vb)
	center.add_child(card)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = load("res://assets/sprites/goblins/goblin-256.png")
	icon.size_flags_horizontal = SIZE_SHRINK_CENTER
	vb.add_child(icon)

	var title := Label.new()
	title.text = tr(&"splashTitle")
	title.add_theme_font_size_override(&"font_size", 26)
	title.add_theme_color_override(&"font_color", Color("eb6650"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(title)

	var sub := Label.new()
	sub.text = tr(&"splashDescription")
	sub.theme_type_variation = &"MutedLabel"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(sub)

	# Resume in-progress run (auto-saved after every move)
	if SaveManager.has_saved_run():
		var cont := Button.new()
		cont.name = &"ContinueButton"
		cont.theme_type_variation = &"GoldButton"
		cont.text = tr(&"continueRun")
		PixelUI.button_icon(cont, "play")
		cont.custom_minimum_size.y = 52
		cont.pressed.connect(func(): AudioManager.play_sfx(&"ui_click"); mode_selected.emit(&"continue"))
		vb.add_child(cont)
		vb.add_child(_mode_desc(tr(&"continueRunDesc")))

	var story := Button.new()
	story.theme_type_variation = &"GoldButton"
	story.text = tr(&"storyMode")
	PixelUI.button_icon(story, "sword")
	story.custom_minimum_size.y = 52
	story.pressed.connect(func(): AudioManager.play_sfx(&"ui_click"); mode_selected.emit(&"story"))
	vb.add_child(story)
	var story_d := _mode_desc(tr(&"storyModeDesc"))
	vb.add_child(story_d)

	var endless := Button.new()
	endless.text = tr(&"endlessMode")
	PixelUI.button_icon(endless, "skull")
	endless.custom_minimum_size.y = 52
	endless.pressed.connect(func(): AudioManager.play_sfx(&"ui_click"); mode_selected.emit(&"endless"))
	vb.add_child(endless)
	vb.add_child(_mode_desc(tr(&"endlessModeDesc")))

	vb.add_child(HSeparator.new())

	# Meta buttons — stacked full-width (long translated labels don't wrap in Buttons)
	var meta := VBoxContainer.new()
	meta.add_theme_constant_override(&"separation", 6)
	vb.add_child(meta)
	var up_btn := _meta_btn(meta, tr(&"upgradesAndProgress"), "sparkle")
	up_btn.pressed.connect(func(): AudioManager.play_sfx(&"ui_click"); UpgradesPanel.new().open(self))
	var lb_btn := _meta_btn(meta, tr(&"leaderboardTitle"), "trophy")
	lb_btn.pressed.connect(func(): AudioManager.play_sfx(&"ui_click"); LeaderboardPanel.new().open(self))
	var h2p_btn := _meta_btn(meta, tr(&"howToPlay"), "book")
	h2p_btn.pressed.connect(func(): AudioManager.play_sfx(&"ui_click"); HowToPanel.new().open(self))

	vb.add_child(HSeparator.new())

	# Settings row
	var settings := HBoxContainer.new()
	settings.alignment = BoxContainer.ALIGNMENT_CENTER
	settings.add_theme_constant_override(&"separation", 12)
	vb.add_child(settings)

	var lang := Button.new()
	lang.name = &"LanguageButton"
	lang.text = String(SaveManager.language).to_upper()
	PixelUI.button_icon(lang, "globe")
	lang.custom_minimum_size = Vector2(80, 40)
	lang.pressed.connect(func():
		var nl := &"en" if SaveManager.language == &"es" else &"es"
		SaveManager.language = nl
		SaveManager.save()
		TranslationServer.set_locale(String(nl))
		SignalBus.language_changed.emit(nl)
		AudioManager.play_sfx(&"ui_click")
		_build()
	)
	settings.add_child(lang)

	var music := Button.new()
	music.name = &"SoundButton"
	PixelUI.button_icon(music, "mute" if AudioManager.is_silent() else "volume")
	music.tooltip_text = tr(&"soundSettings")
	music.custom_minimum_size = Vector2(56, 40)
	music.pressed.connect(func():
		AudioManager.play_sfx(&"ui_click")
		var audio := AudioPanel.new()
		audio.closed.connect(func(): PixelUI.button_icon(music, "mute" if AudioManager.is_silent() else "volume"))
		audio.open(self)
	)
	settings.add_child(music)

	var links := HBoxContainer.new()
	links.add_theme_constant_override(&"separation", 8)
	for page in [&"about", &"privacy"]:
		var link := Button.new()
		link.name = String(page).capitalize() + "Button"
		link.text = tr(page)
		link.custom_minimum_size.y = 44
		link.size_flags_horizontal = SIZE_EXPAND_FILL
		PixelUI.button_icon(link, "book" if page == &"about" else "shield")
		link.pressed.connect(func():
			AudioManager.play_sfx(&"ui_click")
			InfoPanel.new().open(page, self)
		)
		links.add_child(link)
	vb.add_child(links)

	PixelUI.pass_scroll_gestures(center)

	# Entrance animation
	card.modulate.a = 0.0
	card.position.y += 24
	var tw := card.create_tween().set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.4)
	tw.tween_property(card, "position:y", card.position.y - 24, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _mode_desc(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"MutedLabel"
	l.add_theme_font_size_override(&"font_size", 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _meta_btn(parent: Control, text: String, icon_name: String) -> Button:
	var b := Button.new()
	b.text = text
	PixelUI.button_icon(b, icon_name)
	b.add_theme_font_size_override(&"font_size", 16)
	b.custom_minimum_size = Vector2(104, 44)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(b)
	return b
