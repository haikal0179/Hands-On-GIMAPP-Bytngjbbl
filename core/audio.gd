extends Node
## AUTOLOAD "Audio": musik per layar (crossfade) + SFX otomatis.
##   Musik : Audio.play_music("main")  -> res://assets/audio/music/main.mp3
##   SFX   : Audio.play_sfx("hit")     -> res://assets/audio/sfx/hit.ogg|wav|mp3
##   SFX yang dipakai game: click, correct, wrong, hit, hurt, win, lose

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_VOLUME_DB := 5.0   # makin kecil = makin pelan
const FADE_TIME := 0.8

var _music: AudioStreamPlayer
var _current := ""
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # supaya musik tetap jalan saat pause
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)

func play_music(track: String) -> void:
	if track == _current and _music.playing:
		return   # lagu sama, jangan restart
	var stream = _find_stream(MUSIC_DIR + track)
	if stream == null:
		push_warning("Audio: musik '%s' tidak ditemukan di %s" % [track, MUSIC_DIR])
		return
	_current = track
	if "loop" in stream:
		stream.loop = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _music.playing:
		_tween.tween_property(_music, "volume_db", -60.0, FADE_TIME * 0.5)
	_tween.tween_callback(func() -> void:
		_music.stream = stream
		_music.volume_db = -60.0
		_music.play())
	_tween.tween_property(_music, "volume_db", MUSIC_VOLUME_DB, FADE_TIME)

func stop_music() -> void:
	_current = ""
	if _tween:
		_tween.kill()
	_music.stop()


func play_sfx(sfx_name: String) -> void:
	var stream = _find_stream(SFX_DIR + sfx_name)
	if stream == null:
		return   # SFX belum ada -> dilewati
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _find_stream(base_path: String):
	for ext in ["ogg", "mp3", "wav"]:
		var path := "%s.%s" % [base_path, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null