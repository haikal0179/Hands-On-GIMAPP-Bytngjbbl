extends Control
## QUIZ / PUZZLE: panel yang muncul di tengah layar saat soal aktif. File ini hanya
## KOORDINATOR: kerangka panel, timer, tombol tambahan dari upgrade, dan QTE.
##   - isi soal           -> question_types/ (satu file per jenis soal)
##   - mini-game tebak    -> qte.gd
##
## Pemakaian (dari battle.gd):
##     quiz.start(soal, detik, opsi)     ->  quiz.answered(hasil) dipancarkan saat selesai
## Hasil: "correct" | "wrong" | "timeout" | "skip" | "gamble_green" | "gamble_orange" | "gamble_red"
## (hasil selain correct/wrong/timeout datang dari tombol tambahan upgrade, lihat opts["actions"])

const UIKit := preload("res://core/ui_kit.gd")
const Qte := preload("res://features/quiz/qte.gd")
const QuestionTypes := preload("res://features/quiz/question_types/registry.gd")

signal answered(result: String)

var q: Dictionary = {}
var opts: Dictionary = {}
var done := true            # true = tidak ada soal aktif
var running := false        # timer jalan
var time_left := 0.0

var handler = null          # jenis soal yang aktif (question_type.gd)
var qte = null              # QTE yang aktif (qte.gd), null kalau tidak sedang QTE

var panel: Panel
var content: VBoxContainer
var time_bar: ProgressBar


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # supaya tombol pause di bawah tetap bisa diklik

	panel = Panel.new()
	panel.position = Vector2(70, 80)
	panel.size = Vector2(500, 196)
	add_child(panel)

	content = VBoxContainer.new()
	content.position = Vector2(12, 8)
	content.size = Vector2(476, 180)
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)

	var tl := UIKit.make_label("TIME", 12)
	tl.position = Vector2(70, 279)
	add_child(tl)

	time_bar = ProgressBar.new()
	time_bar.show_percentage = false
	time_bar.custom_minimum_size = Vector2(430, 12)
	time_bar.size = Vector2(430, 12)
	time_bar.position = Vector2(120, 282)
	add_child(time_bar)


# ---------- mulai soal ----------

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
		tag += "   [STUN: waktu separuh]"
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


# ---------- tombol tambahan dari upgrade ----------
# Upgrade menambah tombol lewat add_action() -> opts["actions"] = [{label, result}, ...]

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


# ---------- QTE ----------

func _start_qte() -> void:
	for c in content.get_children():
		c.queue_free()
	qte = Qte.new()          # timer soal berhenti selama QTE (lihat _process)
	qte.stopped.connect(_on_qte_stopped)
	qte.build(content)


func _on_qte_stopped(outcome: String) -> void:
	running = false
	await get_tree().create_timer(0.6, false).timeout
	_finish(outcome)


# ---------- loop & input ----------

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
