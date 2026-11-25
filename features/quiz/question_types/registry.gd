extends RefCounted
## DAFTAR JENIS SOAL. Jenis baru: buat file di question_types/ (extends question_type.gd),
## lalu tambahkan 1 baris di TYPES. Nilai "type" di JSON = kunci di bawah ini.

const TYPES := {
	"quiz": preload("res://features/quiz/question_types/multiple_choice.gd"),
	"match": preload("res://features/quiz/question_types/memory_puzzle.gd"),
}


## Buat handler baru untuk satu soal. null kalau jenisnya tidak dikenal.
static func create(type_name: String):
	var script = TYPES.get(type_name)
	return script.new() if script != null else null


## "" kalau soal valid, selain itu pesan kesalahan (dipakai QuestionBank).
static func validate(q: Dictionary) -> String:
	var type_name := str(q.get("type", "quiz"))
	var handler = create(type_name)
	if handler == null:
		return "jenis soal '%s' tidak dikenal (pilihan: %s)" % [type_name, ", ".join(TYPES.keys())]
	if str(q.get("question", "")) == "":
		return "field 'question' kosong"
	return handler.validate(q)
