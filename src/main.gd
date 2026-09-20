extends Control
## Root: swaps Splash <-> Game with a fade. Applies safe-area margins.

var _current: Control
var _fade: ColorRect


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_fit_desktop_window()
	_apply_safe_area()

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(PRESET_FULL_RECT)
	_fade.z_index = 100

	TranslationServer.set_locale(String(SaveManager.language))
	AudioManager.set_music_enabled(SaveManager.music_enabled)
	_show_splash()

	# QA hook: godot -- auto_story → skip splash (used by tools/screenshot.sh)
	var qa := OS.get_cmdline_user_args()
	for a in qa:
		if String(a).begins_with("qa="):
			var runner := QaRunner.new()
			add_child(runner)
			runner.run.call_deferred(StringName(String(a).trim_prefix("qa=")), self)
	if qa.has(&"auto_story"):
		get_tree().create_timer(0.6).timeout.connect(func(): _on_mode_selected(&"story"))
	# QA hooks: open a panel over the splash for screenshot coverage
	if qa.has(&"shot_upgrades"):
		get_tree().create_timer(0.9).timeout.connect(func(): UpgradesPanel.new().open(_current))
	if qa.has(&"shot_leaderboard"):
		get_tree().create_timer(0.9).timeout.connect(func(): LeaderboardPanel.new().open(_current))
	if qa.has(&"shot_howto"):
		get_tree().create_timer(0.9).timeout.connect(func(): HowToPanel.new().open(_current))
	if qa.has(&"auto_shot"):
		var dir := "/tmp/gs2048_shots"
		for a in qa:
			if String(a).begins_with("shot_dir="):
				dir = String(a).trim_prefix("shot_dir=")
		var t := 0.4
		var i := 0
		while t <= 12.0:
			i += 1
			var name := "%s/shot_%02d.png" % [dir, i]
			get_tree().create_timer(t).timeout.connect(func(): _save_shot(name))
			t += 1.5
	if qa.has(&"auto_quit"):
		get_tree().create_timer(12.6).timeout.connect(func(): AudioManager.stop_all())
		get_tree().create_timer(13.0).timeout.connect(func(): get_tree().quit())


func _save_shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	if err != OK:
		push_error("shot failed: %s" % path)


func _fit_desktop_window() -> void:
	# Desktop preview only: show the 393x852 iPhone-16 viewport at up to 2x,
	# clamped so the window fits the screen. Mobile ignores this (fullscreen).
	if OS.has_feature(&"mobile") or OS.has_feature(&"web"):
		return
	var win := get_window()
	var screen := DisplayServer.screen_get_usable_rect(win.current_screen).size
	if screen.x <= 0 or screen.y <= 0:
		return
	var scale := minf(2.0, minf(screen.x * 0.9 / 393.0, screen.y * 0.9 / 852.0))
	win.size = Vector2i(int(393.0 * scale), int(852.0 * scale))
	win.move_to_center()


func _apply_safe_area() -> void:
	# Notch / dynamic island / gesture bar margins (mobile)
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if safe.size == Vector2i.ZERO:
		return
	var top := safe.position.y
	var bottom := win.y - (safe.position.y + safe.size.y)
	var left := safe.position.x
	var right := win.x - (safe.position.x + safe.size.x)
	add_theme_constant_override(&"margin_top", maxi(top, 0))
	add_theme_constant_override(&"margin_bottom", maxi(bottom, 0))
	add_theme_constant_override(&"margin_left", maxi(left, 0))
	add_theme_constant_override(&"margin_right", maxi(right, 0))


func _swap(next: Control) -> void:
	if _fade.get_parent() == null:
		add_child(_fade)
	var tw := _fade.create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.2)
	tw.tween_callback(func():
		if _current:
			_current.queue_free()
		_current = next
		next.set_anchors_preset(PRESET_FULL_RECT)
		add_child(next)
		move_child(next, 0)
	)
	tw.tween_property(_fade, "modulate:a", 0.0, 0.25)


func _show_splash() -> void:
	var s := SplashScreen.new()
	s.mode_selected.connect(_on_mode_selected)
	_swap(s)


func _on_mode_selected(mode: StringName) -> void:
	var g := GameScene.new()
	g.menu_requested.connect(_show_splash)
	g.start(mode)
	_swap(g)
