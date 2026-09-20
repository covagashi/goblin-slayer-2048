class_name Fx
extends RefCounted
## Juice helpers: burst particles, floating combat text, pop tweens.
## Everything is created in code — no .tscn needed.

const FLOAT_SEC := 0.8
const POP_SEC := 0.18


static func burst(parent: Node, pos: Vector2, color: Color, count := 12, spread := 60.0) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = count
	p.lifetime = 0.55
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 6.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = spread * 0.5
	p.initial_velocity_max = spread
	p.gravity = Vector2(0, 220)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = color
	p.position = pos
	p.z_index = 50
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func floating_text(parent: Node, pos: Vector2, text: String, color: Color, size := 18) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override(&"outline_size", 4)
	l.position = pos + Vector2(-40, -10)
	l.z_index = 60
	l.pivot_offset = Vector2(40, 10)
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 46.0, FLOAT_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, FLOAT_SEC).set_delay(FLOAT_SEC * 0.45)
	tw.chain().tween_callback(l.queue_free)


static func pop(control: Control, delay := 0.0) -> void:
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2.ZERO
	var tw := control.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(control, "scale", Vector2.ONE, POP_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func squash(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	var tw := control.create_tween()
	tw.tween_property(control, "scale", Vector2(1.22, 0.78), 0.07)
	tw.tween_property(control, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


static func shake(node: CanvasItem, strength := 6.0, duration := 0.25) -> void:
	var tw := node.create_tween()
	var steps := int(duration / 0.03)
	for i in steps:
		var off := Vector2(randf_range(-strength, strength), randf_range(-strength, strength)) * (1.0 - float(i) / steps)
		tw.tween_property(node, "position", off, 0.03)
	tw.tween_property(node, "position", Vector2.ZERO, 0.03)
