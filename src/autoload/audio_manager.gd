extends Node
## Music + SFX playback. Music crossfades between menu/game themes on a
## dedicated bus; SFX pool avoids allocating players per effect.

const MUSIC_MENU := "res://assets/audio/music/menu-theme.mp3"
const MUSIC_GAME := "res://assets/audio/music/background-theme.mp3"
const SFX_DIR := "res://assets/audio/sfx/"
const POOL_SIZE := 8

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_idx := 0
var _sfx_cache: Dictionary = {}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	add_child(_music_player)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_pool.append(p)
	SignalBus.music_toggled.connect(_on_music_toggled)


func play_music(track: StringName) -> void:
	var path := MUSIC_MENU if track == &"menu" else MUSIC_GAME
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if _music_player.stream == stream and _music_player.playing:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	_music_player.stream = stream
	_music_player.volume_db = -6.0
	_music_player.play()


func set_music_enabled(enabled: bool) -> void:
	if enabled:
		if _music_player.stream and not _music_player.playing:
			_music_player.play()
	else:
		_music_player.stop()


func play_sfx(sfx_name: StringName, pitch: float = 1.0) -> void:
	var stream: AudioStream = _sfx_cache.get(sfx_name)
	if stream == null:
		stream = load(SFX_DIR + String(sfx_name) + ".wav")
		if stream == null:
			return
		_sfx_cache[sfx_name] = stream
	var p := _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % POOL_SIZE
	p.stream = stream
	p.pitch_scale = pitch
	p.play()


func _on_music_toggled(enabled: bool) -> void:
	set_music_enabled(enabled)


func stop_all() -> void:
	# Release stream/playback refs before ObjectDB cleanup at quit.
	_music_player.stop()
	_music_player.stream = null
	for p in _sfx_pool:
		p.stop()
		p.stream = null


func _exit_tree() -> void:
	stop_all()
