extends Node
## AUTOLOAD "GameState": data SATU run (level, upgrade yang dimiliki) + perpindahan scene.
## Angka/path ada di Config, level di Levels, soal di QuestionBank, suara di Audio.
## File ini sengaja kecil: hanya alur run.

const Registry := preload("res://features/upgrades/registry.gd")

var level := 0                 # index level sekarang (0-based)
var owned: Array = []          # id upgrade yang dimiliki di run ini
var kept := ""                 # upgrade yang dibawa ke run berikutnya (Deja Vu)
var result := ""               # "victory" / "defeat" (untuk end screen)
var notice := ""               # pesan singkat yang ditampilkan di awal battle berikutnya
var run_count := 0


func _ready() -> void:
	randomize()


# ---------- alur run ----------

## Game baru dari menu: buang upgrade yang dibawa, mulai dari nol.
func new_game() -> void:
	kept = ""
	run_count = 0
	start_run()


func start_run() -> void:
	level = 0
	owned.clear()
	if kept != "":
		owned.append(kept)
	for id in Config.DEBUG_START_UPGRADES:
		if not owned.has(id):
			owned.append(id)
	kept = ""
	notice = ""
	result = ""
	QuestionBank.reset_pools()
	run_count += 1
	goto(Config.SCENE_BATTLE)


func current_level() -> Dictionary:
	return Levels.ALL[level]


## Dipanggil battle saat level selesai.
func finish_level(won: bool) -> void:
	var last := level >= Levels.count() - 1
	if won:
		if last:
			result = "victory"
			goto(Config.SCENE_END)
		else:
			goto(Config.SCENE_UPGRADE)   # pilih upgrade, lalu level += 1 di sana
	else:
		if last:
			result = "defeat"
			goto(Config.SCENE_END)
		else:
			# Kalah = tidak mengulang level, tapi upgrade tier ini hilang.
			notice = "Gagal di %s. Upgrade tier %d terlewat..." % [Levels.ALL[level]["title"], level + 1]
			level += 1
			goto(Config.SCENE_BATTLE)


func goto(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


# ---------- upgrade (jembatan ke registry) ----------

func has_upgrade(id: String) -> bool:
	return owned.has(id)


func upgrades_of_tier(tier: int) -> Array:
	return Registry.ids_of_tier(tier)


func get_upgrade(id: String):
	return Registry.get_upgrade(id)


## Objek upgrade yang dimiliki di run ini (urut sesuai pengambilan).
func owned_upgrades() -> Array:
	var out: Array = []
	for id in owned:
		var u = Registry.get_upgrade(id)
		if u != null:
			out.append(u)
	return out
