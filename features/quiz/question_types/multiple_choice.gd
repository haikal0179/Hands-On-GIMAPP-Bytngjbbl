extends "res://features/quiz/question_types/question_type.gd"
## Jenis "quiz": pilihan ganda (boleh dengan gambar, lihat field "image" di panel).
## Tombol keyboard 1-4 memilih jawaban.

const UIKit := preload("res://core/ui_kit.gd")

var _answer := 0
var _buttons := {}   # index opsi -> Button


func validate(q: Dictionary) -> String:
	var options = q.get("options")
	if not (options is Array) or options.size() < 2:
		return "'options' harus berisi minimal 2 teks"
	var answer := int(q.get("answer", -1))
	if answer < 0 or answer >= options.size():
		return "'answer' harus index 0..%d" % (options.size() - 1)
	return ""


func build(content: Container, q: Dictionary, opts: Dictionary) -> void:
	_buttons.clear()
	var options: Array = q.get("options", [])
	_answer = int(q.get("answer", 0))
	var wrong: Array = []
	for i in options.size():
		if i != _answer:
			wrong.append(i)
	var removed := -1
	if opts.get("remove_wrong", false) and wrong.size() > 1:   # Seems About Right
		removed = wrong[randi() % wrong.size()]
	for i in options.size():
		if i == removed:
			continue
		var b := UIKit.make_button("%s. %s" % [char(65 + i), str(options[i])], 11)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 24)
		b.pressed.connect(_on_option.bind(i))
		content.add_child(b)
		_buttons[i] = b


func on_key(keycode: int) -> void:
	if keycode >= KEY_1 and keycode <= KEY_4:
		var idx: int = keycode - KEY_1
		if _buttons.has(idx):
			_on_option(idx)


func _on_option(i: int) -> void:
	resolved.emit("correct" if i == _answer else "wrong")
