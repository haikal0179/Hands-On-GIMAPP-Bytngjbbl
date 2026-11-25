extends "res://features/quiz/question_types/question_type.gd"
## Jenis "match": puzzle kepingan memori. Klik 2 kepingan untuk menukar posisi sampai
## setiap kepingan berada di slot berwarna yang benar.

const UIKit := preload("res://core/ui_kit.gd")

const SLOT_COLORS: Array = [
	Color(0.85, 0.33, 0.31), Color(0.55, 0.76, 0.29), Color(0.31, 0.56, 0.91), Color(0.94, 0.75, 0.25),
]

var _content: Container
var _shards: Array = []
var _order: Array = []       # _order[p] = index kepingan yang sekarang ada di slot p
var _selected := -1
var _buttons: Array = []
var _locked := false


func validate(q: Dictionary) -> String:
	var slots = q.get("slots")
	var shards = q.get("shards")
	if not (slots is Array) or slots.is_empty():
		return "'slots' harus berisi minimal 1 nama slot"
	if not (shards is Array) or shards.size() != slots.size():
		return "jumlah 'shards' harus sama dengan jumlah 'slots'"
	var used := {}
	for s in shards:
		if not (s is Dictionary) or not s.has("text") or not s.has("slot"):
			return "tiap shard harus punya 'text' dan 'slot'"
		var slot := int(s["slot"])
		if slot < 0 or slot >= slots.size() or used.has(slot):
			return "'slot' tiap shard harus unik dan antara 0..%d" % (slots.size() - 1)
		used[slot] = true
	return ""


func build(content: Container, q: Dictionary, _opts: Dictionary) -> void:
	_content = content
	_buttons.clear()
	_selected = -1
	_locked = false
	var slots: Array = q.get("slots", [])
	_shards = q.get("shards", [])
	_order = range(_shards.size())
	if _shards.size() > 1:
		_order.shuffle()
		while _is_solved():
			_order.shuffle()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)
	for p in slots.size():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 3)
		row.add_child(col)
		# header slot berwarna (penanda slot)
		var head := ColorRect.new()
		head.color = SLOT_COLORS[p % SLOT_COLORS.size()]
		head.custom_minimum_size = Vector2(146, 22)
		col.add_child(head)
		var hl := UIKit.make_label(str(slots[p]), 10, Color.WHITE)
		hl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.add_child(hl)
		# kepingan
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 10)
		b.custom_minimum_size = Vector2(146, 70)
		b.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
		b.pressed.connect(_on_shard.bind(p))
		col.add_child(b)
		_buttons.append(b)
	_refresh()


func _refresh() -> void:
	for p in _buttons.size():
		var b: Button = _buttons[p]
		b.text = str(_shards[_order[p]]["text"])
		b.modulate = Color(1, 1, 0.5) if p == _selected else Color.WHITE


func _is_solved() -> bool:
	for p in _order.size():
		if int(_shards[_order[p]]["slot"]) != p:
			return false
	return true


func _on_shard(p: int) -> void:
	if _locked:
		return
	if _selected == -1:
		_selected = p
	elif _selected == p:
		_selected = -1
	else:
		var tmp = _order[p]
		_order[p] = _order[_selected]
		_order[_selected] = tmp
		_selected = -1
	_refresh()
	if _is_solved():
		_locked = true
		timer_stopped.emit()   # hentikan timer selagi menampilkan "benar"
		for b in _buttons:
			b.modulate = Color(0.6, 1.0, 0.6)
		await _content.get_tree().create_timer(0.5, false).timeout
		resolved.emit("correct")
