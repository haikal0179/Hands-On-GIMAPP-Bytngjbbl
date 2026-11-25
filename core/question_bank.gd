extends Node
## AUTOLOAD "QuestionBank": baca soal dari data/questions/level_N.json dan bagikan tanpa
## pengulangan sampai semua habis. Soal yang formatnya salah dilewati + diberi peringatan
## di panel Output Godot (jadi teman yang mengisi soal langsung tahu salahnya di mana).
##
## Format file (level diambil dari nama file, tidak perlu field "level"):
##   {"questions": [ {"type": "quiz", ...}, {"type": "match", ...} ]}
## Detail tiap jenis soal: docs/QUESTIONS.md

const QuestionTypes := preload("res://features/quiz/question_types/registry.gd")

var _by_level := {}    # index level (0-based) -> Array soal
var _pools := {}       # index level -> sisa soal yang belum keluar
var _loaded := false


## Ambil soal acak untuk level (index 0-based).
func get_question(level_index: int) -> Dictionary:
	_ensure_loaded()
	var pool: Array = _pools.get(level_index, [])
	if pool.is_empty():
		pool = (_by_level.get(level_index, []) as Array).duplicate()
		pool.shuffle()
	if pool.is_empty():
		return {"type": "quiz", "question": "(Belum ada soal. Isi data/questions/level_%d.json)" % (level_index + 1),
				"options": ["A", "B", "C", "D"], "answer": 0}
	var picked: Dictionary = pool.pop_back()
	_pools[level_index] = pool
	return picked.duplicate(true)


## Dipanggil saat run baru supaya semua soal tersedia lagi.
func reset_pools() -> void:
	_pools.clear()


## Baca ulang semua file soal (berguna saat tes).
func reload() -> void:
	_loaded = false
	_ensure_loaded()


func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_by_level.clear()
	_pools.clear()
	for i in Levels.count():
		_by_level[i] = _read_file("%s/level_%d.json" % [Config.QUESTIONS_DIR, i + 1])


func _read_file(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_warning("QuestionBank: file tidak ada: " + path)
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary) or not (data.get("questions") is Array):
		push_error("QuestionBank: %s harus berbentuk {\"questions\": [...]} dan JSON-nya valid" % path)
		return []
	var out: Array = []
	var idx := 0
	for item in data["questions"]:
		idx += 1
		if not (item is Dictionary):
			push_warning("QuestionBank: %s soal #%d bukan objek, dilewati" % [path, idx])
			continue
		var err := QuestionTypes.validate(item)
		if err != "":
			push_warning("QuestionBank: %s soal #%d dilewati: %s" % [path, idx, err])
			continue
		out.append(item)
	return out
