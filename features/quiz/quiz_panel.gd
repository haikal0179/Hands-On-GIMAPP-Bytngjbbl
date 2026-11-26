extends Control

const UIKit := preload("res://core/ui_kit.gd")
const Qte := preload("res://features/quiz/qte.gd")
const QuestionTypes := preload("res://features/quiz/question_types/registry.gd")

const TIMER_FRAME_PATH := "res://assets/art/ui/timer/Timer_bar.png"
const TIMER_FILL_PATH := "res://assets/art/ui/timer/Timer_filling.png"
const TIMER_SCALE := 0.45
const TIMER_POS := Vector2(116,284)
const TIMER_LABEL_X := 70.0

signal answered(result: String)

var q: Dictionary = {}
var opts: Dictionary = {}
var done := true
var running := false
var time_left := 0.0

var handler = null
var qte = null

var panel: Panel
var content: VBoxContainer
var time_bar: Range


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel = Panel.new()
	panel.position = Vector2(70, 76)
	panel.size = Vector2(500, 196)
	add_child(panel)

	content = VBoxContainer.new()
	content.position = Vector2(12, 8)
	content.size = Vector2(476, 180)
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)

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
	for c in content.get_children():
		c.queue_free()

	var tag := str(q.get("tag", ""))
	if opts.get("stunned", false):
		tag += "   [STUN: half time]"
	var tag_label := UIKit.make_label(tag, 10, Color(1, 0.8, 0.3))
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	content.add_child(tag_label)

	var ql := UIKit.make_label(str(q.get("question", "")), 12, Color.WHITE, 470.0)
	ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	content.add_child(ql)

	_add_image()

	handler = QuestionTypes.create(str(q.get("type", "quiz")))
	if handler == null:
		push_error("quiz_panel: jenis soal tidak dikenal: " + str(q.get("type")))
		_finish("wrong")
		return
	handler.resolved.connect(_on_handler_resolved)
	handler.timer_stopped.connect(func() -> void: running = false)
	handler.build(content, q, opts)
	_build_actions()


func _add_image() -> void:
	var path := str(q.get("image", ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	var img := TextureRect.new()
	img.texture = load(path)
	img.custom_minimum_size = Vector2(0, 64)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(img)


func _on_handler_resolved(outcome: String) -> void:
	if done or (qte != null and qte.active):
		return
	_finish(outcome)


func _build_actions() -> void:
	var actions: Array = opts.get("actions", [])
	if actions.is_empty():
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)
	for a in actions:
		var b := UIKit.make_button(str(a.get("label", "?")), 10)
		b.pressed.connect(_on_action.bind(str(a.get("result", ""))))
		row.add_child(b)


func _on_action(outcome: String) -> void:
	if done or (qte != null and qte.active):
		return
	if outcome == "qte":
		_start_qte()
	else:
		_finish(outcome)


func _start_qte() -> void:
	for c in content.get_children():
		c.queue_free()
	qte = Qte.new()
	qte.stopped.connect(_on_qte_stopped)
	qte.build(content)


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
