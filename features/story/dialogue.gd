extends CanvasLayer

signal dialogue_finished

@onready var root_ui: Control = $RootUI
@onready var background: ColorRect = $RootUI/Background
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

@export var typing_speed: float = 0.03
@export var default_json_path: String = "res://features/story/skrip_dialog.json"

const COLOR_SPEAKING := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_SILENT := Color(0.35, 0.35, 0.35, 1.0)
const BORDER_ACTIVE := Color(0.3, 1.0, 0.55, 1.0)
const BORDER_INACTIVE := Color(0.25, 0.25, 0.25, 1.0)

var left_style: StyleBoxFlat
var right_style: StyleBoxFlat
var left_name_label: Label
var right_name_label: Label

var dialogue_lines: Array = []
var current_index: int = 0
var typing_tween: Tween
var shake_tweens: Dictionary = {}
var orig_positions: Dictionary = {}
var is_active: bool = false


func _ready() -> void:
	layer = 20
	hide()
	_fit_to_viewport()
	
	background.color = Color(0.04, 0.045, 0.07, 1.0)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	left_style = left_frame.get_theme_stylebox("panel").duplicate()
	right_style = right_frame.get_theme_stylebox("panel").duplicate()
	left_frame.add_theme_stylebox_override("panel", left_style)
	right_frame.add_theme_stylebox_override("panel", right_style)
	
	left_name_label = _attach_name_label(left_frame, "JOHN UTBK")
	right_name_label = _attach_name_label(right_frame, "MUSUH")
	
	var top_section := $RootUI/MainMargin/MainVBox/TopSection
	top_section.alignment = BoxContainer.ALIGNMENT_CENTER
	left_frame.get_parent().size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_frame.get_parent().size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thought_title.get_parent().size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	left_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	right_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


func _fit_to_viewport() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var scale_factor := minf(vp_size.x / 1152.0, vp_size.y / 648.0)
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root_ui.position = Vector2.ZERO
	root_ui.size = vp_size / scale_factor
	root_ui.scale = Vector2(scale_factor, scale_factor)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _attach_name_label(frame: Control, default_text: String) -> Label:
	var parent := frame.get_parent()
	var idx := frame.get_index()
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	parent.add_child(col)
	parent.move_child(col, idx)
	
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 34)
	col.add_child(top_spacer)
	
	frame.reparent(col, false)
	
	var lbl := Label.new()
	lbl.text = default_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	col.add_child(lbl)
	return lbl


func play_story(dialogue_id: String, json_path: String = default_json_path) -> void:
	start_dialogue_from_json(json_path, dialogue_id)
	if is_active:
		await dialogue_finished


func start_dialogue_from_json(json_path: String, dialogue_id: String) -> void:
	if not FileAccess.file_exists(json_path):
		push_warning("File JSON dialog tidak ditemukan: " + json_path)
		return
	
	var file := FileAccess.open(json_path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Format JSON salah di baris %d: %s" % [json.get_error_line(), json.get_error_message()])
		return
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY or not data.has(dialogue_id):
		push_warning("ID dialog tidak ditemukan di JSON: " + dialogue_id)
		return
	
	var scene_data: Dictionary = data[dialogue_id]
	if scene_data.has("left_name"):
		left_name_label.text = str(scene_data["left_name"])
	if scene_data.has("right_name"):
		right_name_label.text = str(scene_data["right_name"])
		
	var left_tex: Texture2D = load(scene_data["left_portrait"]) if scene_data.get("left_portrait", "") != "" else null
	var right_tex: Texture2D = load(scene_data["right_portrait"]) if scene_data.get("right_portrait", "") != "" else null
	
	start_dialogue(scene_data.get("lines", []), left_tex, right_tex)


func start_dialogue(lines: Array, left_tex: Texture2D = null, right_tex: Texture2D = null) -> void:
	if lines.is_empty():
		return
	
	if left_tex != null:
		left_portrait.texture = _make_bust_portrait(left_tex, true)
	if right_tex != null:
		right_portrait.texture = _make_bust_portrait(right_tex, false)
		
	dialogue_lines = lines
	current_index = 0
	is_active = true
	
	root_ui.modulate.a = 0.0
	show()
	var open_tween := create_tween()
	open_tween.tween_property(root_ui, "modulate:a", 1.0, 0.25)
	
	_show_current_line()


func _show_current_line() -> void:
	var line: Dictionary = dialogue_lines[current_index]
	
	if line.has("left_name"):
		left_name_label.text = str(line["left_name"])
	if line.has("right_name"):
		right_name_label.text = str(line["right_name"])
		
	var speaker: String = line.get("speaker", "none")
	var ui_tween := create_tween().set_parallel(true)
	
	if speaker == "left":
		ui_tween.tween_property(left_portrait, "modulate", COLOR_SPEAKING, 0.15)
		ui_tween.tween_property(right_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(left_name_label, "modulate", COLOR_SPEAKING, 0.15)
		ui_tween.tween_property(right_name_label, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(left_style, "border_color", BORDER_ACTIVE, 0.15)
		ui_tween.tween_property(right_style, "border_color", BORDER_INACTIVE, 0.15)
	elif speaker == "right":
		ui_tween.tween_property(left_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(right_portrait, "modulate", COLOR_SPEAKING, 0.15)
		ui_tween.tween_property(left_name_label, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(right_name_label, "modulate", COLOR_SPEAKING, 0.15)
		ui_tween.tween_property(left_style, "border_color", BORDER_INACTIVE, 0.15)
		ui_tween.tween_property(right_style, "border_color", BORDER_ACTIVE, 0.15)
	else:
		ui_tween.tween_property(left_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(right_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(left_name_label, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(right_name_label, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(left_style, "border_color", BORDER_INACTIVE, 0.15)
		ui_tween.tween_property(right_style, "border_color", BORDER_INACTIVE, 0.15)
	
	if line.has("thought_title"):
		thought_title.text = line["thought_title"]
	
	if line.has("thought_tex") and line["thought_tex"] != "":
		var tex = load(line["thought_tex"])
		if tex != null:
			thought_image.texture = tex
	
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
		"left": target = left_frame
		"right": target = right_frame
		"thought": target = thought_frame
		"all": target = main_vbox
			
	if target == null:
		return
	
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


func _unhandled_input(event: InputEvent) -> void:
	if not is_active or get_tree().paused:
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


func _make_bust_portrait(tex: Texture2D, is_player: bool) -> Texture2D:
	if tex == null:
		return null
	var w := tex.get_width()
	var h := tex.get_height()
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	var offset_x := w * 0.04 if is_player else w * 0.14
	atlas.region = Rect2(offset_x, h * 0.03, w * 0.72, h * 0.62)
	return atlas
