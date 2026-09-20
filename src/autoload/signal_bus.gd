extends Node
## Global lifecycle signal bus. Keep under 15 events — scoped/direct signals
## handle everything inside a feature.

signal run_started(mode: StringName)
signal run_ended(victory: bool)
signal language_changed(lang: StringName)
signal music_toggled(enabled: bool)
signal haptic(strength: float)
signal screen_shake(strength: float)
signal floating_text(world_pos: Vector2, text: String, color: Color)

func _ready() -> void:
	haptic.connect(_on_haptic)
	screen_shake.connect(_on_screen_shake)


func _on_haptic(strength: float) -> void:
	# iOS/Android haptics. Godot maps strength to vibration ms on Android.
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(int(20.0 + strength * 80.0))


func _on_screen_shake(_strength: float) -> void:
	# Consumed by the camera in the active Game scene; bus just relays it.
	pass
