class_name InfoPanel
extends CanvasLayer
## Offline About and Privacy pages. No consent toggles for absent services.

signal closed

var page: StringName

const SECTIONS := {
	&"about": [
		[&"aboutGameTitle", &"aboutGameBody"],
		[&"aboutArtTitle", &"aboutArtBody"],
		[&"aboutTechTitle", &"aboutTechBody"],
	],
	&"privacy": [
		[&"privacyOfflineTitle", &"privacyOfflineBody"],
		[&"privacyLocalTitle", &"privacyLocalBody"],
		[&"privacyPermissionsTitle", &"privacyPermissionsBody"],
	],
}


func open(which: StringName, parent: Node) -> void:
	page = which
	parent.add_child(self)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 352
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	panel.add_child(column)
	column.add_child(PixelUI.heading(tr(page), "book" if page == &"about" else "shield", 22))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(420, get_viewport().get_visible_rect().size.y - 190)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	PixelUI.style_scroll(scroll)
	column.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 10)
	scroll.add_child(body)
	for section in SECTIONS[page]:
		var heading := Label.new()
		heading.text = tr(section[0])
		heading.add_theme_color_override(&"font_color", Color("f5c65a"))
		heading.add_theme_font_size_override(&"font_size", 18)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(heading)
		var paragraph := Label.new()
		paragraph.text = tr(section[1])
		paragraph.add_theme_font_size_override(&"font_size", 16)
		paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(paragraph)
	if page == &"about":
		var version := Label.new()
		version.text = tr(&"versionLabel").format({"version": ProjectSettings.get_setting("application/config/version", "1.0.0")})
		version.theme_type_variation = &"MutedLabel"
		body.add_child(version)
	PixelUI.pass_scroll_gestures(body)
	var close_button := Button.new()
	close_button.name = &"CloseButton"
	close_button.text = tr(&"close")
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(func(): closed.emit(); queue_free())
	column.add_child(close_button)
	add_child(ShopPanel.modal_wrap(panel))
