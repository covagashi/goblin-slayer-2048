class_name PixelUI
extends RefCounted
## Shared 16 px icon family and tiled backdrop for every game screen.

const ICON_DIR := "res://assets/sprites/ui/"


static func icon_texture(name: String) -> Texture2D:
	return load(ICON_DIR + name + ".png") as Texture2D


static func icon(name: String, pixels := 16) -> TextureRect:
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(pixels, pixels)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.texture = icon_texture(name)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


static func button_icon(button: Button, name: String) -> void:
	button.icon = icon_texture(name)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER if button.text.is_empty() else HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = false


static func heading(text: String, name: String, pixels := 22, color := Color("f5c65a")) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 6)
	row.add_child(icon(name, pixels))
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", pixels)
	label.add_theme_color_override(&"font_color", color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row


static func backdrop() -> TextureRect:
	var image := TextureRect.new()
	image.set_anchors_preset(Control.PRESET_FULL_RECT)
	image.texture = icon_texture("stone_floor")
	image.stretch_mode = TextureRect.STRETCH_TILE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


static func style_scroll(scroll: ScrollContainer) -> void:
	scroll.scroll_deadzone = 8
	scroll.get_v_scroll_bar().custom_minimum_size.x = 10
	scroll.add_theme_constant_override(&"scrollbar_v_separation", 3)


static func pass_scroll_gestures(root: Control) -> void:
	# A row or button must let the ScrollContainer see the initial press.
	# Godot cancels button activation via NOTIFICATION_SCROLL_BEGIN on drag.
	if root.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		root.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in root.get_children():
		if child is Control:
			pass_scroll_gestures(child)


static func frame(name: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = icon_texture(name)
	style.set_texture_margin_all(5.0)
	return style
