extends Control
## NORMAL STAGE - rough draft (Godot 4.x)
## This is the "intermezzo" between quizzes: the battle screen with the two characters.
##
## FLOW:  Enter Battle -> Quiz screen opens (this screen hides, HP cards shrink) ->
##          quiz reports correct & on time -> enemy takes damage -> enemy HP 0? yes: next enemy / no: next quiz
##          quiz reports wrong OR too late  -> player takes damage -> player HP 0? yes: die / no: next quiz
##
## The quiz screen (question, answers, TIME bar) is NOT in this file. It owns the timer.
## Connection points:
##   signal quiz_requested        -> "open the quiz now"
##   func   answer_quiz(correct)  -> quiz calls this when done.
##                                   true  = right answer AND on time
##                                   false = wrong answer OR not on time

signal quiz_requested
signal stage_finished(player_won: bool)

enum State { INTRO, QUIZ, RESOLVING, FINISHED }

# ---- Numbers you can tweak in the Inspector ----
@export var stage_title := "Test 1"
@export var player_name := "TheO"
@export var player_max_hp := 180
@export var player_damage := 40          # damage to enemy on a correct + on-time answer
@export var card_shrink_scale := 0.6     # size of the HP cards while the quiz is open
@export var debug_keys := true           # press 1 = correct, 2 = wrong/late (testing only)

# Enemies are fought in order. Add/remove lines to change the stage.
var enemies: Array = [
	{"name": "TyO", "hp": 220, "damage": 25},
	{"name": "Anum", "hp": 260, "damage": 30},
	{"name": "Lita", "hp": 300, "damage": 35},
]

var player_hp: int
var enemy_index := 0
var enemy_hp: int
var enemy_max_hp: int
var enemy_damage: int
var enemy_name := ""
var state: State = State.INTRO

# UI references
var battle_layer: Control                # characters + title + message (hidden during quiz)
var player_sprite: ColorRect
var enemy_sprite: ColorRect
var player_card: Panel
var player_name_label: Label
var player_bar: ProgressBar
var player_hp_label: Label
var enemy_card: Panel
var enemy_name_label: Label
var enemy_bar: ProgressBar
var enemy_hp_label: Label
var log_label: Label
var pause_overlay: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	player_hp = player_max_hp
	_build_ui()
	_enter_battle()                      # Start -> Enter Battle


# =====================================================
#  FLOWCHART STEPS
# =====================================================

# "Enter Battle": load the current enemy, show the battle screen, then open the quiz
func _enter_battle() -> void:
	state = State.INTRO
	var e: Dictionary = enemies[enemy_index]
	enemy_name = e["name"]
	enemy_hp = int(e["hp"])
	enemy_max_hp = enemy_hp
	enemy_damage = int(e["damage"])
	_update_ui()
	_log("%s appears!" % enemy_name)
	await get_tree().create_timer(1.2, false).timeout
	_start_quiz()


# Open the quiz screen: this screen steps back, cards shrink
func _start_quiz() -> void:
	state = State.QUIZ
	_set_quiz_mode(true)
	quiz_requested.emit()


# The quiz calls this when finished (true = correct AND on time, false = wrong OR late)
func answer_quiz(correct: bool) -> void:
	if state != State.QUIZ:
		return
	_resolve(correct)


# Battle screen returns -> "Deal Damage" or "Take Damage" -> HP checks
func _resolve(correct: bool) -> void:
	state = State.RESOLVING
	_set_quiz_mode(false)

	if correct:
		enemy_hp = maxi(0, enemy_hp - player_damage)
		_flash(enemy_sprite)
		_popup("-%d" % player_damage, enemy_sprite.position + Vector2(20, -10), Color("ffd166"))
		_log("Correct! %s takes %d damage." % [enemy_name, player_damage])
	else:
		player_hp = maxi(0, player_hp - enemy_damage)
		_flash(player_sprite)
		_popup("-%d" % enemy_damage, player_sprite.position + Vector2(20, -10), Color("ef476f"))
		_log("Wrong or too slow! You take %d damage." % enemy_damage)

	_update_ui()
	await get_tree().create_timer(1.5, false).timeout

	if correct:
		if enemy_hp <= 0:                # "Is Enemy HP 0?" -> Yes
			enemy_index += 1
			if enemy_index >= enemies.size():
				_finish(true)
			else:
				_enter_battle()          # "Move onto next enemy"
		else:                            # -> No
			_start_quiz()
	else:
		if player_hp <= 0:               # "Is Player HP 0?" -> Yes: Die
			_finish(false)
		else:                            # -> No
			_start_quiz()


func _finish(player_won: bool) -> void:
	state = State.FINISHED
	_log("YOU WIN!" if player_won else "You died... try again.")
	stage_finished.emit(player_won)


# Quiz open: hide characters/title/message and shrink the HP cards ("gets smaller").
# Quiz closed: bring everything back.
func _set_quiz_mode(on: bool) -> void:
	battle_layer.visible = not on
	var target := Vector2.ONE * (card_shrink_scale if on else 1.0)
	var t := create_tween().set_parallel(true)
	t.tween_property(player_card, "scale", target, 0.25)
	t.tween_property(enemy_card, "scale", target, 0.25)


# =====================================================
#  TESTING + PAUSE
# =====================================================
func _unhandled_input(event: InputEvent) -> void:
	if not debug_keys or state != State.QUIZ:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			answer_quiz(true)
		elif event.keycode == KEY_2:
			answer_quiz(false)


func _on_pause_pressed() -> void:
	get_tree().paused = not get_tree().paused
	pause_overlay.visible = get_tree().paused


# =====================================================
#  UI HELPERS (placeholders -> swap for pixel art later)
# =====================================================
func _update_ui() -> void:
	player_name_label.text = player_name
	player_bar.max_value = player_max_hp
	player_bar.value = player_hp
	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	enemy_name_label.text = enemy_name
	enemy_bar.max_value = enemy_max_hp
	enemy_bar.value = enemy_hp
	enemy_hp_label.text = "HP: %d/%d" % [enemy_hp, enemy_max_hp]


func _log(text: String) -> void:
	log_label.text = text


func _flash(node: CanvasItem) -> void:
	node.modulate = Color(3, 3, 3)
	create_tween().tween_property(node, "modulate", Color.WHITE, 0.3)


# Floating damage number like the "-40" in the sketch
func _popup(text: String, pos: Vector2, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 24)
	add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", pos.y - 30, 0.8)
	t.tween_property(l, "modulate:a", 0.0, 0.8)
	t.chain().tween_callback(l.queue_free)


func _build_ui() -> void:
	# Layout for a 640x360 viewport, matching the sketch
	var bg := ColorRect.new()
	bg.color = Color("2b2d42")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Everything in here disappears while the quiz is open
	battle_layer = Control.new()
	battle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(battle_layer)

	player_sprite = _rect(Vector2(70, 150), Vector2(64, 110), Color("4cc9f0"), battle_layer)  # bottom-left
	enemy_sprite = _rect(Vector2(470, 90), Vector2(64, 64), Color("f72585"), battle_layer)    # upper-right

	var title := _label(stage_title, Vector2(0, 12), battle_layer)
	title.size = Vector2(640, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	log_label = _label("", Vector2(120, 54), battle_layer)
	log_label.size = Vector2(400, 30)
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# HP cards stay on screen during the quiz (they just shrink)
	var pc := _card(Vector2(40, 8), Color("4cc9f0"), false)       # top-left, shrinks toward its corner
	player_name_label = pc[0]
	player_bar = pc[1]
	player_hp_label = pc[2]
	player_card = pc[3]

	var ec := _card(Vector2(400, 300), Color("f72585"), true)     # bottom-right, shrinks toward its corner
	enemy_name_label = ec[0]
	enemy_bar = ec[1]
	enemy_hp_label = ec[2]
	enemy_card = ec[3]

	# Pause overlay + pause button (top-left)
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0, 0, 0, 0.6)
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_overlay.hide()
	add_child(pause_overlay)
	var paused_text := _label("PAUSED", Vector2(0, 160), pause_overlay)
	paused_text.size = Vector2(640, 30)
	paused_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.position = Vector2(8, 8)
	pause_btn.size = Vector2(26, 26)
	pause_btn.process_mode = Node.PROCESS_MODE_ALWAYS    # still clickable while paused
	pause_btn.pressed.connect(_on_pause_pressed)
	add_child(pause_btn)

	if debug_keys:
		_label("DEBUG: 1 = correct, 2 = wrong/late", Vector2(8, 340), self)


# Info card: portrait + name + HP bar + HP text. Returns [name_label, bar, hp_label, panel]
func _card(pos: Vector2, portrait_color: Color, pivot_bottom_right: bool) -> Array:
	var panel := Panel.new()
	panel.position = pos
	panel.size = Vector2(200, 48)
	panel.pivot_offset = panel.size if pivot_bottom_right else Vector2.ZERO
	add_child(panel)
	_rect(Vector2(4, 4), Vector2(40, 40), portrait_color, panel)
	var n := _label("", Vector2(50, 2), panel)
	var b := _bar(Vector2(50, 22), Vector2(144, 8), panel)
	var h := _label("", Vector2(50, 30), panel)
	return [n, b, h, panel]


func _rect(pos: Vector2, sz: Vector2, col: Color, parent: Node) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = col
	parent.add_child(r)
	return r


func _label(text: String, pos: Vector2, parent: Node) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	parent.add_child(l)
	return l


func _bar(pos: Vector2, sz: Vector2, parent: Node) -> ProgressBar:
	var b := ProgressBar.new()
	b.position = pos
	b.size = sz
	b.show_percentage = false
	parent.add_child(b)
	return b
