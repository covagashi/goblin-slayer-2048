class_name AudioPanel
extends CanvasLayer
## Independent music/effects controls, applied live and saved locally.

signal closed

var _save_timer: Timer
var _dirty := false
var _preview: Button
var _toggles: Dictionary = {}
var _sliders: Dictionary = {}


func open(parent: Node) -> void:
	parent.add_child(self)
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.3
	_save_timer.timeout.connect(_flush_save)
	add_child(_save_timer)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 340
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	panel.add_child(column)
	column.add_child(PixelUI.heading(tr(&"soundSettings"), "volume", 22))
	column.add_child(_channel_controls(&"Music", &"backgroundMusic", SaveManager.music_enabled, SaveManager.music_volume))
	column.add_child(HSeparator.new())
	column.add_child(_channel_controls(&"SFX", &"soundEffects", SaveManager.sfx_enabled, SaveManager.sfx_volume))
	_preview = Button.new()
	_preview.name = &"PreviewSound"
	_preview.text = tr(&"testSound")
	_preview.custom_minimum_size.y = 44
	_preview.pressed.connect(func(): AudioManager.play_sfx(&"coin"))
	column.add_child(_preview)
	_refresh_preview()
	var close_button := Button.new()
	close_button.name = &"CloseButton"
	close_button.text = tr(&"close")
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(_close)
	column.add_child(close_button)
	add_child(ShopPanel.modal_wrap(panel))


func _channel_controls(channel: StringName, label_key: StringName, enabled: bool, volume: float) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override(&"separation", 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	var label := Label.new()
	label.text = tr(label_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", 20)
	row.add_child(label)
	var toggle := Button.new()
	toggle.name = String(channel) + "Toggle"
	toggle.toggle_mode = true
	toggle.set_pressed_no_signal(enabled)
	toggle.custom_minimum_size = Vector2(96, 44)
	toggle.add_theme_font_size_override(&"font_size", 18)
	_toggle_label(toggle, enabled)
	row.add_child(toggle)
	section.add_child(row)
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override(&"separation", 12)
	var slider := HSlider.new()
	slider.name = String(channel) + "Volume"
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = roundf(volume * 100.0)
	slider.editable = enabled
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 48
	slider.scrollable = false
	slider.tooltip_text = tr(label_key)
	_style_slider(slider)
	volume_row.add_child(slider)
	var percentage := Label.new()
	percentage.custom_minimum_size.x = 44
	percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percentage.text = "%d%%" % slider.value
	percentage.add_theme_font_size_override(&"font_size", 18)
	percentage.add_theme_color_override(&"font_color", Color("f5c65a"))
	volume_row.add_child(percentage)
	section.add_child(volume_row)
	_toggles[channel] = toggle
	_sliders[channel] = slider
	toggle.toggled.connect(func(on: bool):
		SaveManager.set_audio_enabled(channel, on)
		_toggle_label(toggle, on)
		slider.editable = on
		_changed()
	)
	slider.value_changed.connect(func(value: float):
		percentage.text = "%d%%" % value
		SaveManager.set_audio_volume(channel, value / 100.0)
		_changed()
	)
	slider.drag_ended.connect(func(_changed_value: bool): _flush_save())
	return section


func _toggle_label(button: Button, enabled: bool) -> void:
	button.text = tr(&"audioOn" if enabled else &"audioOff")
	PixelUI.button_icon(button, "volume" if enabled else "mute")


func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxTexture.new()
	track.texture = PixelUI.icon_texture("bar_empty")
	track.set_texture_margin_all(3)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var fill := track.duplicate() as StyleBoxTexture
	fill.texture = PixelUI.icon_texture("bar_hp")
	slider.add_theme_stylebox_override(&"slider", track)
	slider.add_theme_stylebox_override(&"grabber_area", fill)
	slider.add_theme_stylebox_override(&"grabber_area_highlight", fill)
	slider.add_theme_icon_override(&"grabber", PixelUI.icon_texture("gold_button"))
	slider.add_theme_icon_override(&"grabber_highlight", PixelUI.icon_texture("gold_button_hover"))
	slider.add_theme_icon_override(&"grabber_disabled", PixelUI.icon_texture("button_disabled"))


func _changed() -> void:
	_dirty = true
	_save_timer.start()
	_refresh_preview()


func _refresh_preview() -> void:
	if _preview:
		_preview.disabled = not SaveManager.sfx_enabled or SaveManager.sfx_volume <= 0.0


func _flush_save() -> void:
	if _dirty:
		SaveManager.save()
		_dirty = false


func _close() -> void:
	_flush_save()
	closed.emit()
	queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_flush_save()


func _exit_tree() -> void:
	_flush_save()
