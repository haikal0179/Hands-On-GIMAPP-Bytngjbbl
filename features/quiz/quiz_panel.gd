extends Control

const UIKit := preload("res://core/ui_kit.gd")
const Qte := preload("res://features/quiz/qte.gd")
const QuestionTypes := preload("res://features/quiz/question_types/registry.gd")

const TIMER_FRAME_PATH := "res://assets/art/ui/timer/Timer_bar.png"
const TIMER_FILL_PATH := "res://assets/art/ui/timer/Timer_filling.png"
const TIMER_SCALE := 0.42
const TIMER_POS := Vector2(116,284)
const TIMER_LABEL_X := 70.0

# Area teks di papan soal (layar 640x360). Papan digambar battle_ui: x 96-550, y 46-310.
# Bar jawaban dari artist mulai di y=112, jadi teks soal harus muat di y 50-110.
const TEXT_X := 117.0
const TEXT_W := 412.0
const QUESTION_FONT_SIZE := 12
const QUESTION_MIN_FONT_SIZE := 8
const QUESTION_MAX_HEIGHT := 44.0
const ACTIONS_POS := Vector2(130, 261)   # tombol upgrade (skip, tebak) di bawah bar jawaban
const ACTIONS_MAX_W := 320.0             # jangan sampai menabrak namecard musuh di kanan-bawah

signal answered(result: String)

var q: Dictionary = {}
var opts: Dictionary = {}
var done := true
var running := false
var time_left := 0.0

var handler = null
var qte = null

var header: VBoxContainer   # tag subtes + teks soal
var body: Control           # tempat bar jawaban / kartu / QTE / tombol aksi (posisi absolut, seukuran layar)
var time_bar: Range


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Papannya sendiri digambar battle_ui (quiz_board). Di sini hanya isinya.
	header = VBoxContainer.new()
	header.position = Vector2(TEXT_X, 50)
	header.size = Vector2(TEXT_W, 60)
	header.clip_contents = true
	header.add_theme_constant_override("separation", 2)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	body = Control.new()
	body.position = Vector2.ZERO
	body.size = Vector2(640, 360)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	_build_timer_bar()


func _build_timer_bar() -> void:
	var frame_tex := load(TIMER_FRAME_PATH) as Texture2D if ResourceLoader.exists(TIMER_FRAME_PATH) else null
	var fill_tex := load(TIMER_FILL_PATH) as Texture2D if ResourceLoader.exists(TIMER_FILL_PATH) else null
	var parts := {}
	if frame_tex != null and fill_tex != null:
		parts = _crop_timer_textures(frame_tex, fill_tex)

	var tl := UIKit.make_label("TIME", 12)
	add_child(tl)

	if parts.is_empty():
		# PNG tidak ada / gagal dibaca -> bar polos
		var fallback_bar := ProgressBar.new()
		fallback_bar.show_percentage = false
		fallback_bar.step = 0.01
		fallback_bar.custom_minimum_size = Vector2(320, 12)
		fallback_bar.size = Vector2(320, 12)
		fallback_bar.position = Vector2(122, 297)
		add_child(fallback_bar)
		tl.position = Vector2(TIMER_LABEL_X, 293)
		time_bar = fallback_bar
		return

	var fill: Texture2D = parts["fill"]
	var fill_pos: Vector2 = parts["fill_pos"]

	# Root dibuat seukuran gambar ASLI, lalu di-skala seragam. Anak-anaknya tidak perlu tahu skala.
	var timer_root := Control.new()
	timer_root.position = TIMER_POS
	timer_root.size = parts["size"]
	timer_root.scale = Vector2.ONE * TIMER_SCALE
	timer_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(timer_root)

	# Lapisan bawah: isi teal (tanpa nine-patch, ukuran asli, diletakkan di slot track)
	var tex_bar := TextureProgressBar.new()
	tex_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_bar.position = fill_pos
	tex_bar.step = 0.01
	tex_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	tex_bar.texture_progress = fill
	timer_root.add_child(tex_bar)

	# Lapisan atas: bingkai + kepala jam
	var frame_rect := TextureRect.new()
	frame_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame_rect.texture = parts["frame"]
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_root.add_child(frame_rect)

	# Label "TIME" sejajar dengan tengah track
	var track_mid_y := TIMER_POS.y + (fill_pos.y + fill.get_height() * 0.5) * TIMER_SCALE
	tl.position = Vector2(TIMER_LABEL_X, track_mid_y - 9.0)

	time_bar = tex_bar


## Potong PNG timer (kanvas 1280x720) jadi bagian yang ada gambarnya saja.
## frame = kepala jam + kotak track. fill = isi teal SAJA (dipotong sendiri), fill_pos = posisinya
## di dalam frame -> persen isi pas dengan panjang track (50% = tepat separuh track).
func _crop_timer_textures(frame_tex: Texture2D, fill_tex: Texture2D) -> Dictionary:
	var f_img := frame_tex.get_image()
	var b_img := fill_tex.get_image()
	if f_img == null or b_img == null or f_img.is_empty() or b_img.is_empty():
		return {}

	if f_img.is_compressed():
		f_img.decompress()
	if b_img.is_compressed():
		b_img.decompress()

	var rect_f := f_img.get_used_rect()
	var rect_b := b_img.get_used_rect()
	if rect_f.size.x <= 0 or rect_b.size.x <= 0:
		return {}
	var used := rect_f.merge(rect_b)

	return {
		"frame": ImageTexture.create_from_image(f_img.get_region(used)),
		"fill": ImageTexture.create_from_image(b_img.get_region(rect_b)),
		"size": Vector2(used.size),
		"fill_pos": Vector2(rect_b.position - used.position),
	}


func start(question: Dictionary, time: float, options: Dictionary) -> void:
	q = question
	opts = options
	time_left = time
	time_bar.max_value = time
	time_bar.value = time
	done = false
	running = true
	qte = null
	handler = null
	_clear_ui()

	var tag := str(q.get("tag", ""))
	if opts.get("stunned", false):
		tag += "   [STUN: half time]"
	var tag_label := UIKit.make_label(tag, 10, Color(1, 0.8, 0.3))
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_child(tag_label)

	# Kalau soal punya gambar, gambarnya di kanan-atas papan dan teks soal dipersempit
	var has_image := _add_image()
	var question_text := str(q.get("question", ""))
	var question_width := TEXT_W - (76.0 if has_image else 0.0)
	var ql := UIKit.make_label(question_text, QUESTION_FONT_SIZE, Color.WHITE, question_width)
	ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_child(ql)
	_fit_question_label(ql, question_width)

	handler = QuestionTypes.create(str(q.get("type", "quiz")))
	if handler == null:
		push_error("quiz_panel: jenis soal tidak dikenal: " + str(q.get("type")))
		_finish("wrong")
		return
	handler.resolved.connect(_on_handler_resolved)
	handler.timer_stopped.connect(func() -> void: running = false)
	handler.build(body, q, opts)
	_build_actions()


func _fit_question_label(label: Label, width: float) -> void:
	label.custom_minimum_size = Vector2(width, QUESTION_MAX_HEIGHT)
	label.clip_text = true
	_fit_question_label_after_layout.call_deferred(label)


func _fit_question_label_after_layout(label: Label) -> void:
	await get_tree().process_frame
	var font_size := label.get_theme_font_size("font_size")
	while label.get_visible_line_count() < label.get_line_count() and font_size > QUESTION_MIN_FONT_SIZE:
		font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)
		await get_tree().process_frame

	if label.get_visible_line_count() < label.get_line_count():
		push_warning("Quiz prompt still clipped at minimum font size: " + label.text)


func _clear_ui() -> void:
	for c in header.get_children():
		c.queue_free()
	for c in body.get_children():
		c.queue_free()


func _add_image() -> bool:
	var path := str(q.get("image", ""))
	if path == "" or not ResourceLoader.exists(path):
		return false
	var img := TextureRect.new()
	img.texture = load(path)
	img.position = Vector2(TEXT_X + TEXT_W - 68.0, 50)
	img.size = Vector2(68, 56)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(img)
	return true


func _on_handler_resolved(outcome: String) -> void:
	if done or (qte != null and qte.active):
		return
	_finish(outcome)


func _build_actions() -> void:
	var actions: Array = opts.get("actions", [])
	if actions.is_empty():
		return
	var row := HBoxContainer.new()
	row.position = ACTIONS_POS
	row.size = Vector2(ACTIONS_MAX_W, 22)
	row.add_theme_constant_override("separation", 6)
	body.add_child(row)
	for a in actions:
		var b := UIKit.make_button(str(a.get("label", "?")), 10)
		b.pressed.connect(_on_action.bind(str(a.get("result", ""))))
		row.add_child(b)


func _on_action(outcome: String) -> void:
	if done or (qte != null and qte.active):
		return
	if outcome == "qte":
		Audio.play_sfx("Haven_t picked C in a while SFX")
		_start_qte()
	else:
		_finish(outcome)


func _start_qte() -> void:
	_clear_ui()
	qte = Qte.new()
	qte.stopped.connect(_on_qte_stopped)
	var box := VBoxContainer.new()
	box.position = Vector2(TEXT_X, 70)
	box.size = Vector2(TEXT_W, 170)
	box.add_theme_constant_override("separation", 6)
	body.add_child(box)
	qte.build(box)


func _on_qte_stopped(outcome: String) -> void:
	running = false
	await get_tree().create_timer(0.6, false).timeout
	_finish(outcome)


func _process(delta: float) -> void:
	if done:
		return
	if qte != null and qte.active:
		qte.tick(delta)
	elif running:
		time_left -= delta
		time_bar.value = maxf(time_left, 0.0)
		if time_left <= 0.0:
			_finish("timeout")


func _unhandled_input(event: InputEvent) -> void:
	if done or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if qte != null and qte.active:
			qte.on_key(event.keycode)
		elif running and handler != null:
			handler.on_key(event.keycode)


func _finish(result: String) -> void:
	if done:
		return
	done = true
	running = false
	if qte != null:
		qte.active = false
	answered.emit(result)
