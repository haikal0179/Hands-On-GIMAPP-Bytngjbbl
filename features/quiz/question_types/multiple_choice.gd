extends "res://features/quiz/question_types/question_type.gd"
## Jenis "quiz": pilihan ganda (boleh dengan gambar, lihat field "image" di panel).
## Tombol keyboard 1-4 memilih jawaban.
## Tampilan: bar A/B/C/D dari aset artist (assets/art/ui/quiz/). Kalau PNG-nya tidak ada,
## otomatis memakai tombol biasa (_build_plain).

const UIKit := preload("res://core/ui_kit.gd")

const ART_DIR := "res://assets/art/ui/quiz/"
const ART_SCALE := 0.5                       # PNG kanvas 1280x720 -> layar 640x360
const TEXT_COLOR := Color(0.17, 0.16, 0.14)  # teks gelap di atas bar berwarna cerah

# Posisi tiap bar di PNG (kanvas 1280x720). Urutan: y atas bar, y bawah bar, y bawah bayangan hover.
const BAR_X := 233.0         # x kiri semua bar
const BAR_W := 829.0         # lebar bar
const REGION_W := 842.0      # bar + bayangan merah di kanan (area yang dipotong dari PNG)
const BARS: Array = [
	[224.0, 284.0, 293.0],
	[296.0, 357.0, 361.0],
	[363.0, 423.0, 430.0],
	[436.0, 496.0, 502.0],
]

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


func build(content: Control, q: Dictionary, opts: Dictionary) -> void:
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

	if _art_ready(options.size()):
		_build_art(content, options, removed)
	else:
		_build_plain(content, options, removed)


# ---------- tampilan bergambar ----------

func _art_ready(n: int) -> bool:
	if n > BARS.size():
		return false
	if not ResourceLoader.exists(ART_DIR + "Multiplechoice_idle.png"):
		return false
	for i in n:
		if not ResourceLoader.exists(ART_DIR + "Multiplechoice_hover %d.png" % (i + 1)):
			return false
	return true


func _build_art(content: Control, options: Array, removed: int) -> void:
	var idle_tex := load(ART_DIR + "Multiplechoice_idle.png") as Texture2D
	for i in options.size():
		if i == removed:
			continue   # slotnya dibiarkan kosong (posisi bar lain tidak bergeser)
		var hover_tex := load(ART_DIR + "Multiplechoice_hover %d.png" % (i + 1)) as Texture2D
		var bar := _make_bar(i, str(options[i]), idle_tex, hover_tex)
		content.add_child(bar)
		_buttons[i] = bar


func _make_bar(i: int, text: String, idle_tex: Texture2D, hover_tex: Texture2D) -> Button:
	var y0: float = BARS[i][0]
	var y1: float = BARS[i][1]
	var y_shadow: float = BARS[i][2]
	var region := Rect2(BAR_X, y0, REGION_W, y_shadow - y0 + 1.0)   # bar + bayangan, tidak menyentuh bar lain

	# Tombol transparan = area klik seukuran bar
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.position = _scaled(Vector2(BAR_X, y0))
	b.size = _scaled(Vector2(BAR_W, y1 - y0 + 1.0))

	var idle_rect := _atlas_rect(idle_tex, region)
	var hover_rect := _atlas_rect(hover_tex, region)
	hover_rect.visible = false
	b.add_child(idle_rect)
	b.add_child(hover_rect)

	var label := Label.new()
	label.text = "%s. %s" % [char(65 + i), text]
	label.position = Vector2(10, 0)
	label.size = Vector2(b.size.x - 20.0, b.size.y)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(label)

	b.mouse_entered.connect(func() -> void: hover_rect.visible = true)
	b.mouse_exited.connect(func() -> void: hover_rect.visible = false)
	b.pressed.connect(_on_option.bind(i))
	return b


func _atlas_rect(tex: Texture2D, region: Rect2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region
	var r := TextureRect.new()
	r.texture = atlas
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel-art: jangan di-blur
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = _scaled(region.size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _scaled(v: Vector2) -> Vector2:
	return Vector2(roundf(v.x * ART_SCALE), roundf(v.y * ART_SCALE))


# ---------- cadangan: tombol biasa (kalau PNG belum ada) ----------

func _build_plain(content: Control, options: Array, removed: int) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(117, 112)
	box.size = Vector2(412, 130)
	box.add_theme_constant_override("separation", 4)
	content.add_child(box)
	for i in options.size():
		if i == removed:
			continue
		var b := UIKit.make_button("%s. %s" % [char(65 + i), str(options[i])], 11)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 24)
		b.pressed.connect(_on_option.bind(i))
		box.add_child(b)
		_buttons[i] = b


func on_key(keycode: int) -> void:
	if keycode >= KEY_1 and keycode <= KEY_4:
		var idx: int = keycode - KEY_1
		if _buttons.has(idx):
			_on_option(idx)


func _on_option(i: int) -> void:
	resolved.emit("correct" if i == _answer else "wrong")
