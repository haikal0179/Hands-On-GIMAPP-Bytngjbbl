extends "res://features/quiz/question_types/question_type.gd"
## Jenis "match": puzzle kepingan memori. Klik 2 kepingan untuk menukar posisi sampai
## setiap kepingan berada di slot berwarna yang benar.
## Tampilan: 3 kartu dari aset artist (assets/art/ui/quiz/) kalau jumlah slot = 3 dan PNG ada.
## Selain itu otomatis memakai tampilan tombol biasa (_build_plain).

const UIKit := preload("res://core/ui_kit.gd")

const SLOT_COLORS: Array = [
	Color(0.85, 0.33, 0.31), Color(0.55, 0.76, 0.29), Color(0.31, 0.56, 0.91), Color(0.94, 0.75, 0.25),
]

const ART_DIR := "res://assets/art/ui/quiz/"
const ART_SCALE := 0.5                       # PNG kanvas 1280x720 -> layar 640x360
const TEXT_COLOR := Color(0.17, 0.16, 0.14)
const HOVER_FILES: Array = ["3Options_hover left.png", "3Options_hover middle.png", "3Options_hover right.png"]
# Posisi kartu di PNG (kanvas 1280x720)
const CARD_X: Array = [325.0, 555.0, 785.0]
const CARD_Y := 203.0
const CARD_W := 212.0
const CARD_H := 305.0
const HEADER_H := 62.0       # bagian atas kartu yang berwarna (nama slot)

var _content: Control
var _shards: Array = []
var _order: Array = []       # _order[p] = index kepingan yang sekarang ada di slot p
var _selected := -1
var _hovered := -1
var _buttons: Array = []     # mode tombol biasa: Button per slot
var _cards: Array = []       # mode bergambar: Button (area klik) per slot
var _texts: Array = []       # mode bergambar: Label isi kepingan per slot
var _use_art := false
var _idle_full: TextureRect
var _hover_full: Array = []
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


func build(content: Control, q: Dictionary, _opts: Dictionary) -> void:
	_content = content
	_buttons.clear()
	_cards.clear()
	_texts.clear()
	_hover_full.clear()
	_selected = -1
	_hovered = -1
	_locked = false
	var slots: Array = q.get("slots", [])
	_shards = q.get("shards", [])
	_order = range(_shards.size())
	if _shards.size() > 1:
		_order.shuffle()
		while _is_solved():
			_order.shuffle()

	_use_art = slots.size() == 3 and _art_ready()
	if _use_art:
		_build_art(slots)
	else:
		_build_plain(slots)
	_refresh()


# ---------- tampilan bergambar ----------

func _art_ready() -> bool:
	if not ResourceLoader.exists(ART_DIR + "3Options_idle.png"):
		return false
	for f in HOVER_FILES:
		if not ResourceLoader.exists(ART_DIR + str(f)):
			return false
	return true


func _build_art(slots: Array) -> void:
	# Lapisan gambar penuh (kanvas 1280x720 -> layar penuh). Hover = gambar idle diganti gambar hover.
	_idle_full = _full_rect(load(ART_DIR + "3Options_idle.png") as Texture2D)
	_content.add_child(_idle_full)
	for f in HOVER_FILES:
		var h := _full_rect(load(ART_DIR + str(f)) as Texture2D)
		h.visible = false
		_content.add_child(h)
		_hover_full.append(h)

	for p in 3:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		b.position = _scaled(Vector2(float(CARD_X[p]), CARD_Y))
		b.size = _scaled(Vector2(CARD_W, CARD_H))
		b.pressed.connect(_on_shard.bind(p))
		b.mouse_entered.connect(_set_hover.bind(p))
		b.mouse_exited.connect(_set_hover.bind(-1))
		_content.add_child(b)
		_cards.append(b)

		# Nama slot di bagian atas kartu (yang berwarna)
		# Nama slot di bagian atas kartu (yang berwarna). Nama panjang dibungkus 2 baris.
		# Nama slot di bagian atas kartu. Nama panjang dipecah 2 baris, dan kotaknya memotong sisa yang keluar.
		var name_text := str(slots[p])
		if name_text.length() > 12:
			var mid := int(name_text.length() / 2)
			var cut := name_text.rfind(" ", mid)
			if cut == -1:
				cut = name_text.find(" ", mid)
			if cut != -1:
				name_text = name_text.substr(0, cut) + "\n" + name_text.substr(cut + 1)

		var head_box := Control.new()
		head_box.position = Vector2(4, 4)
		head_box.size = Vector2(b.size.x - 8.0, 26.0)
		head_box.clip_contents = true
		head_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(head_box)

		var head_center := CenterContainer.new()
		head_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head_box.add_child(head_center)
		head_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var head := Label.new()
		head.text = name_text
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.add_theme_font_size_override("font_size", 8)
		head.add_theme_color_override("font_color", TEXT_COLOR)
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head_center.add_child(head)

		# Isi kepingan di badan kartu
		var body := Label.new()
		var top := roundf(HEADER_H * ART_SCALE) + 4.0
		body.position = Vector2(7, top)
		body.size = Vector2(b.size.x - 14.0, b.size.y - top - 8.0)
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.clip_text = true
		body.add_theme_font_size_override("font_size", 10)
		body.add_theme_color_override("font_color", TEXT_COLOR)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(body)
		_texts.append(body)


func _full_rect(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel-art: jangan di-blur
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = Vector2.ZERO
	r.size = Vector2(640, 360)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _scaled(v: Vector2) -> Vector2:
	return Vector2(roundf(v.x * ART_SCALE), roundf(v.y * ART_SCALE))


func _set_hover(p: int) -> void:
	_hovered = p
	_update_art_state()


## Gambar hover dipakai untuk kartu yang sedang di-hover; kalau tidak ada, untuk kartu yang dipilih.
func _update_art_state() -> void:
	if not _use_art or _locked:
		return
	var shown := _hovered if _hovered != -1 else _selected
	_idle_full.visible = shown == -1
	for p in _hover_full.size():
		_hover_full[p].visible = (p == shown)


# ---------- cadangan: tombol biasa (kalau PNG belum ada / slot bukan 3) ----------

func _build_plain(slots: Array) -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(117, 108)
	row.size = Vector2(412, 130)
	row.add_theme_constant_override("separation", 8)
	_content.add_child(row)
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


func _refresh() -> void:
	if _use_art:
		for p in _texts.size():
			(_texts[p] as Label).text = str(_shards[_order[p]]["text"])
		_update_art_state()
		return
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
		if _use_art:
			_idle_full.visible = true
			for h in _hover_full:
				h.visible = false
			_idle_full.modulate = Color(0.7, 1.0, 0.7)
		else:
			for b in _buttons:
				b.modulate = Color(0.6, 1.0, 0.6)
		await _content.get_tree().create_timer(0.5, false).timeout
		resolved.emit("correct")
