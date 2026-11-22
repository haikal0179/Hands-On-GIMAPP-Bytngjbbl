extends CanvasLayer

signal dialogue_finished

# Referensi node UI
@onready var root_ui: Control = $RootUI
@onready var main_margin: MarginContainer = $RootUI/MainMargin
@onready var main_vbox: VBoxContainer = $RootUI/MainMargin/MainVBox
@onready var left_frame: PanelContainer = $RootUI/MainMargin/MainVBox/TopSection/LeftPortraitFrame
@onready var right_frame: PanelContainer = $RootUI/MainMargin/MainVBox/TopSection/RightPortraitFrame
@onready var left_portrait: TextureRect = $RootUI/MainMargin/MainVBox/TopSection/LeftPortraitFrame/LeftPortrait
@onready var right_portrait: TextureRect = $RootUI/MainMargin/MainVBox/TopSection/RightPortraitFrame/RightPortrait
@onready var thought_title: Label = $RootUI/MainMargin/MainVBox/TopSection/CenterThoughtBox/ThoughtTitle
@onready var thought_frame: PanelContainer = $RootUI/MainMargin/MainVBox/TopSection/CenterThoughtBox/ThoughtImageFrame
@onready var thought_image: TextureRect = $RootUI/MainMargin/MainVBox/TopSection/CenterThoughtBox/ThoughtImageFrame/ThoughtImage
@onready var dialogue_text: RichTextLabel = $RootUI/MainMargin/MainVBox/BottomSection/DialogueText
@onready var pause_button: Button = %PauseButton

@export var typing_speed: float = 0.03

const COLOR_SPEAKING := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_SILENT := Color(0.35, 0.35, 0.35, 1.0)
const BORDER_ACTIVE := Color(0.3, 1.0, 0.55, 1.0)
const BORDER_INACTIVE := Color(0.25, 0.25, 0.25, 1.0)

var left_style: StyleBoxFlat
var right_style: StyleBoxFlat
var dialogue_lines: Array = []
var current_index: int = 0
var typing_tween: Tween
var shake_tweens: Dictionary = {}
var orig_positions: Dictionary = {}
var is_active: bool = false
var is_paused: bool = false


func _ready() -> void:
	main_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_button.focus_mode = Control.FOCUS_NONE
	
	# Duplikasi StyleBox agar border kiri & kanan bisa berubah warna secara terpisah
	left_style = left_frame.get_theme_stylebox("panel").duplicate()
	right_style = right_frame.get_theme_stylebox("panel").duplicate()
	left_frame.add_theme_stylebox_override("panel", left_style)
	right_frame.add_theme_stylebox_override("panel", right_style)
	
	pause_button.pressed.connect(_on_pause_pressed)
	
	# Muat skrip dari skrip_dialog.json
	start_dialogue_from_json("res://skrip_dialog.json", "intro_utbk")


func start_dialogue_from_json(json_path: String, dialogue_id: String) -> void:
	if not FileAccess.file_exists(json_path):
		push_error("File JSON tidak ditemukan: " + json_path)
		return
	
	var file := FileAccess.open(json_path, FileAccess.READ)
	var json_text := file.get_as_text()
	
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("Format JSON salah di baris %d: %s" % [json.get_error_line(), json.get_error_message()])
		return
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY or not data.has(dialogue_id):
		push_error("ID dialog '%s' tidak ditemukan di dalam %s" % [dialogue_id, json_path])
		return
	
	var scene_data: Dictionary = data[dialogue_id]
	
	var left_tex: Texture2D = null
	var right_tex: Texture2D = null
	if scene_data.has("left_portrait") and scene_data["left_portrait"] != "":
		left_tex = load(scene_data["left_portrait"])
	if scene_data.has("right_portrait") and scene_data["right_portrait"] != "":
		right_tex = load(scene_data["right_portrait"])
	
	var lines: Array = scene_data.get("lines", [])
	start_dialogue(lines, left_tex, right_tex)


func start_dialogue(lines: Array, left_tex: Texture2D = null, right_tex: Texture2D = null) -> void:
	if lines.is_empty():
		return
	
	if left_tex != null:
		left_portrait.texture = left_tex
	if right_tex != null:
		right_portrait.texture = right_tex
		
	dialogue_lines = lines
	current_index = 0
	is_active = true
	is_paused = false
	pause_button.text = "||"
	
	root_ui.modulate.a = 0.0
	show()
	var open_tween := create_tween()
	open_tween.tween_property(root_ui, "modulate:a", 1.0, 0.25)
	
	_show_current_line()


func _show_current_line() -> void:
	var line: Dictionary = dialogue_lines[current_index]
	
	var speaker: String = line.get("speaker", "none")
	var ui_tween := create_tween().set_parallel(true)
	
	if speaker == "left":
		ui_tween.tween_property(left_portrait, "modulate", COLOR_SPEAKING, 0.15)
		ui_tween.tween_property(right_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(left_style, "border_color", BORDER_ACTIVE, 0.15)
		ui_tween.tween_property(right_style, "border_color", BORDER_INACTIVE, 0.15)
	elif speaker == "right":
		ui_tween.tween_property(left_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(right_portrait, "modulate", COLOR_SPEAKING, 0.15)
		ui_tween.tween_property(left_style, "border_color", BORDER_INACTIVE, 0.15)
		ui_tween.tween_property(right_style, "border_color", BORDER_ACTIVE, 0.15)
	else:
		ui_tween.tween_property(left_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(right_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(left_style, "border_color", BORDER_INACTIVE, 0.15)
		ui_tween.tween_property(right_style, "border_color", BORDER_INACTIVE, 0.15)
	
	if line.has("thought_title"):
		thought_title.text = line["thought_title"]
	
	if line.has("thought_tex") and line["thought_tex"] != "":
		var tex = load(line["thought_tex"])
		if tex != null:
			thought_image.texture = tex
	
	# Jalankan efek getar jika ada properti "shake" di baris JSON ("left", "right", "thought", atau "all")
	if line.has("shake"):
		_trigger_shake(str(line["shake"]))
	
	var full_text: String = line.get("text", "")
	dialogue_text.text = full_text
	dialogue_text.visible_ratio = 0.0
	
	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
		
	var duration: float = max(full_text.length() * typing_speed, 0.05)
	typing_tween = create_tween()
	typing_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)


func _trigger_shake(target_name: String, intensity: float = 8.0) -> void:
	var target: Control = null
	match target_name:
		"left":
			target = left_frame
		"right":
			target = right_frame
		"thought":
			target = thought_frame
		"all":
			target = main_vbox
			
	if target == null:
		return
	
	# Tunggu 1 frame agar HBoxContainer/VBoxContainer selesai mengatur posisi awal
	await get_tree().process_frame
	
	if shake_tweens.has(target_name) and shake_tweens[target_name].is_running():
		shake_tweens[target_name].kill()
		target.position = orig_positions[target_name]
	else:
		orig_positions[target_name] = target.position
		
	var base_pos: Vector2 = orig_positions[target_name]
	var shake_tween := create_tween()
	shake_tweens[target_name] = shake_tween
	
	for i in range(6):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		shake_tween.tween_property(target, "position", base_pos + offset, 0.04)
	shake_tween.tween_property(target, "position", base_pos, 0.04)


func _input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if pause_button.get_global_rect().has_point(event.position):
			return
	
	if is_paused:
		return
		
	var is_next_pressed: bool = event.is_action_pressed("ui_accept") or (
		event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	)
	
	if is_next_pressed:
		_handle_next_action()


func _handle_next_action() -> void:
	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
		dialogue_text.visible_ratio = 1.0
	else:
		_advance_dialogue()


func _advance_dialogue() -> void:
	current_index += 1
	if current_index < dialogue_lines.size():
		_show_current_line()
	else:
		is_active = false
		var close_tween := create_tween()
		close_tween.tween_property(root_ui, "modulate:a", 0.0, 0.25)
		await close_tween.finished
		hide()
		dialogue_finished.emit()


func _on_pause_pressed() -> void:
	is_paused = !is_paused
	if is_paused:
		pause_button.text = "▶"
		if typing_tween and typing_tween.is_running():
			typing_tween.pause()
	else:
		pause_button.text = "||"
		if typing_tween:
			typing_tween.play()
