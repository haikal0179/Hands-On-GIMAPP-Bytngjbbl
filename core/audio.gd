extends Node
## AUTOLOAD "Audio": musik per layar (crossfade) + SFX otomatis.
##   Musik : Audio.play_music("main")  -> res://assets/audio/music/main.mp3
##   SFX   : Audio.play_sfx("Attack SFX") -> res://assets/audio/sfx/Attack SFX.mp3

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const SFX_ALIASES := {"click": "Click SFX."}
const MUSIC_VOLUME_DB := -15.0
const SFX_VOLUME_DB := 3.0
const CLICK_SFX_VOLUME_DB := -8.0
const FADE_TIME := 0.8
const PAUSED_MUSIC_VOLUME_DB := -22.0
const MUSIC_DUCK_FADE_TIME := 0.25
const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_MASTER_VOLUME := 1.0

var _music: AudioStreamPlayer
var _current := ""
var _tween: Tween
var _pending_music_stream: AudioStream
var _music_ducked := false
var _master_volume := DEFAULT_MASTER_VOLUME

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # supaya musik tetap jalan saat pause
	_master_volume = _load_master_volume()
	_apply_master_volume()
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)


func get_master_volume() -> float:
	return _master_volume


func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()

	var settings := ConfigFile.new()
	var load_error := settings.load(SETTINGS_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_error("Audio: couldn't load settings at %s (error %d)" % [SETTINGS_PATH, load_error])
		return

	settings.set_value("audio", "master_volume", _master_volume)
	var save_error := settings.save(SETTINGS_PATH)
	if save_error != OK:
		push_error("Audio: couldn't save settings at %s (error %d)" % [SETTINGS_PATH, save_error])


func _load_master_volume() -> float:
	var settings := ConfigFile.new()
	var load_error := settings.load(SETTINGS_PATH)
	if load_error == ERR_FILE_NOT_FOUND:
		return DEFAULT_MASTER_VOLUME
	if load_error != OK:
		push_error("Audio: couldn't load settings at %s (error %d)" % [SETTINGS_PATH, load_error])
		return DEFAULT_MASTER_VOLUME

	var value: Variant = settings.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		push_warning("Audio: invalid master volume in %s; using the default" % SETTINGS_PATH)
		return DEFAULT_MASTER_VOLUME
	return clampf(float(value), 0.0, 1.0)


func _apply_master_volume() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		push_error("Audio: Master bus not found")
		return
	var volume_db := -80.0 if _master_volume == 0.0 else linear_to_db(_master_volume)
	AudioServer.set_bus_volume_db(master_bus, volume_db)


func set_music_ducked(ducked: bool) -> void:
	if _music_ducked == ducked:
		return
	_music_ducked = ducked

	if _pending_music_stream != null:
		_start_music_transition()
	elif _music.playing:
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_music, "volume_db", _music_target_volume_db(), MUSIC_DUCK_FADE_TIME)


func play_music(track: String) -> void:
	if track == _current and (_music.playing or _pending_music_stream != null):
		return   # lagu sama, jangan restart
	var stream = _find_stream(MUSIC_DIR + track)
	if stream == null:
		push_warning("Audio: musik '%s' tidak ditemukan di %s" % [track, MUSIC_DIR])
		return
	_current = track
	if "loop" in stream:
		stream.loop = true
	_pending_music_stream = stream
	_start_music_transition()


func _start_music_transition() -> void:
	if _tween:
		_tween.kill()
	if _music.playing:
		_tween = create_tween()
		_tween.tween_property(_music, "volume_db", -60.0, FADE_TIME * 0.5)
		_tween.tween_callback(_start_pending_music)
	else:
		_start_pending_music()


func _start_pending_music() -> void:
	if _pending_music_stream == null:
		return
	_music.stream = _pending_music_stream
	_pending_music_stream = null
	_music.volume_db = -60.0
	_music.play()
	_tween = create_tween()
	_tween.tween_property(_music, "volume_db", _music_target_volume_db(), FADE_TIME)


func _music_target_volume_db() -> float:
	return PAUSED_MUSIC_VOLUME_DB if _music_ducked else MUSIC_VOLUME_DB

func stop_music() -> void:
	_current = ""
	_pending_music_stream = null
	if _tween:
		_tween.kill()
	_music.stop()


func play_sfx(sfx_name: String) -> void:
	var is_click := sfx_name == "click"
	var stream_name: String = str(SFX_ALIASES.get(sfx_name, sfx_name))
	var stream = _find_stream(SFX_DIR + stream_name)
	if stream == null:
		return   # SFX belum ada -> dilewati
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = CLICK_SFX_VOLUME_DB if is_click else SFX_VOLUME_DB
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _find_stream(base_path: String):
	for ext in ["ogg", "mp3", "wav"]:
		var path := "%s.%s" % [base_path, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null