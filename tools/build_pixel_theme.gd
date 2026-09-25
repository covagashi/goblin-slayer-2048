extends SceneTree
## Regenerate the Godot theme after tools/generate_pixel_art.py.


func _initialize() -> void:
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/VT323-Regular.ttf")
	theme.default_font_size = 20
	var card := _frame("panel", 12, 10)
	var inset := _frame("inset", 10, 8)
	var normal := _frame("button", 16, 9)
	var hover := _frame("button_hover", 16, 9)
	var pressed := _frame("button_pressed", 16, 9)
	var disabled := _frame("button_disabled", 16, 9)
	var gold := _frame("gold_button", 16, 9)
	var gold_hover := _frame("gold_button_hover", 16, 9)
	var gold_pressed := _frame("gold_button_pressed", 16, 9)
	var bar_empty := _bar("bar_empty")
	var bar_hp := _bar("bar_hp")
	var separator := StyleBoxFlat.new()
	separator.bg_color = Color("4a4145")
	separator.content_margin_top = 1
	separator.content_margin_bottom = 1

	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style: StyleBox = {"normal": normal, "hover": hover, "pressed": pressed,
			"disabled": disabled, "focus": hover}[state]
		theme.set_stylebox(state, "Button", style)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style: StyleBox = {"normal": gold, "hover": gold_hover,
			"pressed": gold_pressed, "disabled": disabled, "focus": gold_hover}[state]
		theme.set_stylebox(state, "GoldButton", style)
	theme.set_type_variation("GoldButton", "Button")
	theme.set_color("font_color", "Button", Color("f4e8d0"))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color("e8cfab"))
	theme.set_color("font_disabled_color", "Button", Color("b1a49c"))
	theme.set_color("font_color", "GoldButton", Color("fff4d1"))
	theme.set_color("font_hover_color", "GoldButton", Color.WHITE)
	theme.set_color("font_color", "Label", Color("f4e8d0"))
	theme.set_type_variation("MutedLabel", "Label")
	theme.set_color("font_color", "MutedLabel", Color("b7a9a2"))
	theme.set_type_variation("AccentLabel", "Label")
	theme.set_color("font_color", "AccentLabel", Color("f5c65a"))
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_color("font_color", "TitleLabel", Color("eb6650"))
	theme.set_font_size("font_size", "TitleLabel", 32)
	theme.set_stylebox("panel", "PanelContainer", card)
	theme.set_type_variation("CardPanel", "PanelContainer")
	theme.set_stylebox("panel", "CardPanel", card)
	theme.set_type_variation("InsetPanel", "PanelContainer")
	theme.set_stylebox("panel", "InsetPanel", inset)
	theme.set_stylebox("background", "ProgressBar", bar_empty)
	theme.set_stylebox("fill", "ProgressBar", bar_hp)
	theme.set_stylebox("separator", "HSeparator", separator)
	theme.set_stylebox("separator", "VSeparator", separator)
	theme.set_stylebox("panel", "ScrollContainer", inset)
	var scroll_track := _scroll_frame("scroll_track")
	var scroll_thumb := _scroll_frame("scroll_thumb")
	var scroll_thumb_hover := _scroll_frame("scroll_thumb_hover")
	var scroll_thumb_pressed := _scroll_frame("scroll_thumb_pressed")
	for scrollbar_type in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", scrollbar_type, scroll_track)
		theme.set_stylebox("scroll_focus", scrollbar_type, scroll_track)
		theme.set_stylebox("grabber", scrollbar_type, scroll_thumb)
		theme.set_stylebox("grabber_highlight", scrollbar_type, scroll_thumb_hover)
		theme.set_stylebox("grabber_pressed", scrollbar_type, scroll_thumb_pressed)
	theme.set_color("default_color", "RichTextLabel", Color("f4e8d0"))
	var result := ResourceSaver.save(theme, "res://src/theme/game_theme.tres")
	if result != OK:
		push_error("Could not save pixel theme: %s" % result)
	quit(result)


func _frame(name: String, horizontal: int, vertical: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load("res://assets/sprites/ui/%s.png" % name)
	style.set_texture_margin_all(5)
	style.content_margin_left = horizontal
	style.content_margin_right = horizontal
	style.content_margin_top = vertical
	style.content_margin_bottom = vertical
	return style


func _bar(name: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load("res://assets/sprites/ui/%s.png" % name)
	style.texture_margin_left = 3
	style.texture_margin_right = 3
	style.texture_margin_top = 3
	style.texture_margin_bottom = 3
	return style


func _scroll_frame(name: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load("res://assets/sprites/ui/%s.png" % name)
	style.set_texture_margin_all(2)
	return style
