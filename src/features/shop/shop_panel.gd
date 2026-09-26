class_name ShopPanel
extends CanvasLayer
## Mysterious shop modal — 3 random offers, respects unlocks/ownership.

signal closed(purchase_made: bool)
signal item_bought(item_id: StringName)

const ITEM_DIR := "res://assets/sprites/items/"

var _rs: RunState
var _upgrades: Dictionary
var _offers: Array[Dictionary] = []
var _purchase_made := false


static func modal_wrap(content: Control, dim_alpha := 0.7) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 10
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, dim_alpha)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	center.add_child(content)
	return layer


func open(rs: RunState, upgrades: Dictionary, parent: Node) -> void:
	_rs = rs
	_upgrades = upgrades
	_roll_offers()
	parent.add_child(self)
	_build()
	AudioManager.play_sfx(&"shop")


func _roll_offers() -> void:
	# Always offer usable unlocked stock before previews of locked items.
	var available: Array[Dictionary] = []
	var locked: Array[Dictionary] = []
	for item in GoblinDB.SHOP_ITEMS:
		if item.unique and _rs.purchased_items.has(item.id):
			continue
		if _is_unlocked(item.id):
			available.append(item)
		else:
			locked.append(item)
	available.shuffle()
	locked.shuffle()
	available.append_array(locked)
	_offers = available.slice(0, mini(3, available.size()))


func _is_unlocked(item_id: StringName) -> bool:
	# unlock ids look like unlockFireScroll — capitalize first letter
	var uid := StringName("unlock" + String(item_id).substr(0, 1).to_upper() + String(item_id).substr(1))
	for up in GoblinDB.PERMANENT_UPGRADES:
		if up.id == uid:
			return int(_upgrades.get(uid, 0)) > 0
	return true


func _build() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 10)
	panel.add_child(vb)

	vb.add_child(PixelUI.heading(tr(&"shopTitle"), "shop", 22, Color("a17ac5")))

	var desc := Label.new()
	desc.text = tr(&"shopDesc")
	desc.theme_type_variation = &"MutedLabel"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)
	vb.add_child(PixelUI.heading("%s: %d" % [tr(&"gold"), _rs.gold], "coin", 18))
	if _offers.any(func(item: Dictionary): return not _is_unlocked(item.id)):
		var hint := Label.new()
		hint.text = tr(&"shopUnlockHint")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_font_size_override(&"font_size", 15)
		hint.add_theme_color_override(&"font_color", Color("f5c65a"))
		vb.add_child(hint)

	if _offers.is_empty():
		var empty := Label.new()
		empty.text = tr(&"noItemsAvailable")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(empty)
	else:
		for it in _offers:
			vb.add_child(_offer_row(it))

	var close_btn := Button.new()
	close_btn.text = tr(&"continueSlaying")
	close_btn.custom_minimum_size.y = 44
	close_btn.pressed.connect(_close)
	vb.add_child(close_btn)

	var layer := modal_wrap(panel)
	add_child(layer)


func _offer_row(it: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.theme_type_variation = &"InsetPanel"
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 10)
	row.add_child(hb)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = load(ITEM_DIR + String(it.sprite))
	hb.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_l := Label.new()
	name_l.text = tr(StringName(String(it.id) + "_name"))
	name_l.add_theme_font_size_override(&"font_size", 15)
	info.add_child(name_l)
	var desc_l := Label.new()
	desc_l.text = tr(StringName(String(it.id) + "_desc"))
	desc_l.theme_type_variation = &"MutedLabel"
	desc_l.add_theme_font_size_override(&"font_size", 14)
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_l)
	hb.add_child(info)

	var buy := Button.new()
	buy.custom_minimum_size = Vector2(76, 40)
	var owned: bool = it.unique and _rs.purchased_items.has(it.id)
	var locked := not _is_unlocked(it.id)
	if owned:
		buy.text = tr(&"owned")
		buy.disabled = true
	elif locked:
		buy.text = tr(&"locked")
		buy.disabled = true
		icon.modulate.a = 0.55
	elif _rs.gold < it.cost:
		buy.text = str(it.cost)
		PixelUI.button_icon(buy, "coin")
		buy.disabled = true
	else:
		buy.text = str(it.cost)
		PixelUI.button_icon(buy, "coin")
		buy.pressed.connect(_buy.bind(it))
	hb.add_child(buy)
	return row


func _buy(it: Dictionary) -> void:
	if _rs.gold < it.cost or not _is_unlocked(it.id):
		return
	_rs.gold -= int(it.cost)
	_rs.apply_item(it.id)
	_purchase_made = true
	AudioManager.play_sfx(&"coin")
	SignalBus.haptic.emit(0.4)
	_rs.add_log(tr(&"log_purchase").format({"item": tr(StringName(String(it.id) + "_name")), "cost": it.cost}), &"gold")
	if it.id == &"healthPotion":
		_rs.add_log(tr(&"log_heal").format({"hp": 5}), &"good")
	item_bought.emit(it.id)
	# refresh buttons
	for c in get_children():
		c.queue_free()
	_build()


func _close() -> void:
	closed.emit(_purchase_made)
	queue_free()
