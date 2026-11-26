extends Control
## NORMAL STAGE = ATURAN battle (giliran, damage, cek HP). Tampilan ada di battle_ui.
## Quiz/puzzle ada di quiz_panel.gd; battle cuma memanggilnya dan menerima hasilnya.
##
## Alur (sesuai flowchart):
##   Enter Battle -> quiz mulai -> hasil: correct / wrong / timeout (+ skip, gamble)
##   -> damage ke musuh ATAU damage ke player -> cek HP -> soal berikutnya / level selesai

const UIKit := preload("res://core/ui_kit.gd")
const QuizPanel := preload("res://features/quiz/quiz_panel.gd")
const DialogueScene := preload("res://features/story/dialogue.tscn")
const SettingsScene := preload("res://features/settings/settings.tscn")
const EXIT_BUTTON_ICON := preload("res://assets/art/button/Exit button.png")
const SETTINGS_BUTTON_ICON := preload("res://assets/art/button/Settings button.png")
const RESUME_BUTTON_ICON := preload("res://assets/art/button/Play button.png")

@export var intro_pause := 1.3      # jeda "musuh muncul" sebelum soal pertama
@export var resolve_pause := 1.4    # jeda layar battle setelah jawaban (intermezzo)

# "Inner thoughts" TheO (tema lore): muncul sebagai pesan saat gagal.
const THOUGHTS := {
	"wrong": ["...I know this. Why did I forget?", "That's not it... that's not the answer.", "My memory's a mess."],
	"timeout": ["Blank. My mind's gone empty.", "Time's up...", "I'm taking too long to think."],
	"gamble_red": ["I guessed... and got it wrong. My head's pounding."],
}

@onready var ui = $BattleUI

var level_data: Dictionary
var player_hp := 0
var player_max := 0
var enemy_hp := 0
var enemy_max := 0
var enemy_dmg := 0
var stunned := false       # kena stun (gamble gagal): soal berikutnya waktunya separuh
var finished := false
var quiz
var pause_layer: ColorRect
var pause_canvas: CanvasLayer
var pause_settings: Control
var story_ui: CanvasLayer


func _ready() -> void:
	Audio.play_music("main") #BGM
	level_data = GameState.current_level()
	player_max = Config.PLAYER_MAX_HP
	player_hp = player_max
	enemy_max = int(level_data["hp"])
	enemy_hp = enemy_max
	enemy_dmg = int(level_data["dmg"])
	ui.setup(level_data["title"], Config.PLAYER_NAME, player_hp, player_max,
			level_data["enemy"], enemy_hp, enemy_max)
	ui.pause_pressed.connect(_on_pause)

	quiz = QuizPanel.new()
	add_child(quiz)
	quiz.visible = false
	quiz.answered.connect(_on_quiz_answered)

	_build_pause_layer()
	pause_canvas.get_node("PauseButton").escape_pressed.connect(_on_escape_pressed)
	
	story_ui = DialogueScene.instantiate()
	add_child(story_ui)
	
	for u in GameState.owned_upgrades():
		u.on_battle_start(self)
	_intro()


# ---------- alur ----------

func _intro() -> void:
	ui.set_quiz_mode(false)
	var msg := "%s appears!" % level_data["enemy"]
	if GameState.notice != "":
		msg = GameState.notice + "\n" + msg
		GameState.notice = ""
	ui.show_message(msg)
	await _wait(intro_pause)
	await story_ui.play_story("level_%d_pre" % (GameState.level + 1))
	_start_quiz()


func _start_quiz() -> void:
	ui.set_quiz_mode(true)
	var q: Dictionary = QuestionBank.get_question(GameState.level)
	q["tag"] = level_data["subtest"]
	var time: float = float(q.get("time", level_data["time"]))
	for u in GameState.owned_upgrades():
		time = u.modify_time(time)
	var was_stunned := stunned
	if stunned:
		time *= 0.5
		stunned = false
	var options := {"stunned": was_stunned}
	for u in GameState.owned_upgrades():
		u.modify_quiz_options(options)
	quiz.visible = true
	quiz.start(q, time, options)


## Hasil dari quiz_panel: "correct", "wrong", "timeout", "skip",
## "gamble_green", "gamble_orange", "gamble_red".
## Upgrade boleh menangani hasil lebih dulu (on_quiz_result); kalau tidak, pakai aturan bawaan.
func _on_quiz_answered(result: String) -> void:
	quiz.visible = false
	ui.set_quiz_mode(false)
	await _wait(0.4)   # beri waktu kartu membesar lagi
	var handled := false
	for u in GameState.owned_upgrades():
		if await u.on_quiz_result(result, self):
			handled = true
			break
	if not handled:
		if result == "correct":
			await attack_enemy(1, 1.0, "Correct answer! The attack lands.")
		else:
			await hurt_player(result)
	await _wait(resolve_pause)
	if enemy_hp <= 0:
		_end_level(true)
	elif player_hp <= 0:
		_end_level(false)
	else:
		_start_quiz()


## API untuk upgrade: player menyerang musuh `hits` kali, damage = dasar x mult x modifier upgrade.
func attack_enemy(hits: int, mult: float, msg: String) -> void:
	ui.show_message(msg)
	for i in hits:
		var dmg := _calc_damage(mult)
		enemy_hp = maxi(0, enemy_hp - dmg)
		Audio.play_sfx("Attack SFX")
		ui.hit("enemy", dmg)
		ui.set_enemy_hp(enemy_hp, enemy_max)
		await _wait(0.5)
		if enemy_hp <= 0:
			break


## API untuk upgrade: musuh menyerang player. thought_key = kunci di THOUGHTS.
## allow_dodge = false kalau serangan ini tidak boleh dihindari.
func hurt_player(thought_key: String, allow_dodge: bool = true, extra: String = "") -> void:
	var lines: Array = THOUGHTS.get(thought_key, THOUGHTS["wrong"])
	var thought: String = lines[randi() % lines.size()]
	if extra != "":
		thought += "\n" + extra
	if allow_dodge:
		for u in GameState.owned_upgrades():
			if u.should_dodge():
				ui.show_message(thought + "\n" + u.display_name + ": TheO dodges!")
				ui.float_text("player", "DODGE!", Color(0.5, 1.0, 0.6))
				await _wait(0.3)
				return
	ui.show_message(thought)
	player_hp = maxi(0, player_hp - enemy_dmg)
	Audio.play_sfx("Hurt SFX")
	ui.hit("player", enemy_dmg)
	ui.set_player_hp(player_hp, player_max)
	await _wait(0.5)


func _calc_damage(mult: float) -> int:
	var d := float(Config.BASE_DAMAGE) * mult
	for u in GameState.owned_upgrades():
		d = u.modify_damage(d)
	return int(round(d))


func _end_level(won: bool) -> void:
	finished = true
	if won:
		Audio.play_sfx("Enemy die SFX")
		ui.show_message("%s is defeated! Level complete." % level_data["enemy"])
		await _wait(1.6)
		await story_ui.play_story("level_%d_post" % (GameState.level + 1))
	else:
		Audio.play_sfx("Player die SFX")
		ui.show_message("TheO has run out of energy...")
		await _wait(1.6)
	GameState.finish_level(won)


func _wait(t: float) -> void:
	await get_tree().create_timer(t, false).timeout   # false = ikut berhenti saat pause


# ---------- pause ----------

func _on_pause() -> void:
	if finished:
		return
	Audio.set_music_ducked(true)
	get_tree().paused = true
	pause_layer.visible = true


func _on_resume() -> void:
	pause_layer.visible = false
	Audio.set_music_ducked(false)
	get_tree().paused = false


func _on_escape_pressed() -> void:
	if pause_settings != null:
		_on_pause_settings_closed()
	elif get_tree().paused:
		_on_resume()
	else:
		_on_pause()


func _on_pause_settings() -> void:
	if pause_settings != null:
		return

	pause_layer.hide()
	pause_settings = SettingsScene.instantiate()
	pause_settings.set("close_to_main_menu", false)
	pause_settings.connect("closed", _on_pause_settings_closed)
	pause_canvas.add_child(pause_settings)


func _on_pause_settings_closed() -> void:
	if pause_settings != null:
		pause_settings.queue_free()
		pause_settings = null
	pause_layer.show()


func _on_quit() -> void:
	get_tree().paused = false
	Audio.set_music_ducked(false)
	GameState.goto(Config.SCENE_TITLE)


func _build_pause_layer() -> void:
	pause_canvas = CanvasLayer.new()
	pause_canvas.layer = 30
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_canvas)
	
	for btn in ui.find_children("*", "BaseButton", true, false):
		btn.reparent(pause_canvas)
		if not btn.pressed.is_connected(_on_pause):
			btn.pressed.connect(_on_pause)
	
	pause_layer = ColorRect.new()
	pause_layer.color = Color(0, 0, 0, 0.75)
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.visible = false
	pause_canvas.add_child(pause_layer)
	pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	pause_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	box.add_child(UIKit.make_label("PAUSED", 22))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)

	var quit := UIKit.make_texture_button(EXIT_BUTTON_ICON, Vector2(56, 56))
	quit.tooltip_text = "Exit to Main Menu"
	quit.pressed.connect(_on_quit)
	buttons.add_child(quit)

	var settings := UIKit.make_texture_button(SETTINGS_BUTTON_ICON, Vector2(56, 56))
	settings.tooltip_text = "Settings"
	settings.pressed.connect(_on_pause_settings)
	buttons.add_child(settings)

	var resume := UIKit.make_texture_button(RESUME_BUTTON_ICON, Vector2(56, 56))
	resume.tooltip_text = "Resume"
	resume.pressed.connect(_on_resume)
	buttons.add_child(resume)
