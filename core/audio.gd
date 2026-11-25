extends Node
## AUTOLOAD "Audio": BGM + SFX otomatis kalau file-nya ada (tidak perlu kode).
##   BGM : res://assets/audio/bgm.ogg|mp3|wav
##   SFX : res://assets/audio/sfx/<nama>.ogg|wav|mp3
##   nama SFX yang dipakai game: click, correct, wrong, hit, hurt, win, lose

const BGM_BASE := "res://assets/audio/bgm"
const SFX_DIR := "res://assets/audio/sfx/"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # supaya BGM tetap jalan saat pause
	_start_bgm()


func play_sfx(sfx_name: String) -> void:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "%s%s.%s" % [SFX_DIR, sfx_name, ext]
		if ResourceLoader.exists(path):
			var p := AudioStreamPlayer.new()
			p.stream = load(path)
			add_child(p)
			p.finished.connect(p.queue_free)
			p.play()
			return


func _start_bgm() -> void:
	for ext in ["ogg", "mp3", "wav"]:
		var path := "%s.%s" % [BGM_BASE, ext]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if "loop" in stream:
				stream.loop = true
			var p := AudioStreamPlayer.new()
			p.stream = stream
			p.volume_db = -8.0
			add_child(p)
			p.play()
			return
