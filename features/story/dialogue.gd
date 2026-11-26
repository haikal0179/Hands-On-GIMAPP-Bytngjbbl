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

const DIALOGUE_BG_PATH := "res://assets/art/ui/Inner thoughts screen.png"

# Koordinat presisi elemen pada kanvas 1152x648
const THOUGHT_TITLE_RECT := Rect2(266, 48, 630, 60)
const LEFT_SLOT_RECT := Rect2(279, 117, 207, 225)
const RIGHT_SLOT_RECT := Rect2(676, 117, 207, 225)
const LEFT_NAME_RECT := Rect2(270, 352, 225, 24)
const RIGHT_NAME_RECT := Rect2(667, 352, 225, 24)
const DIALOGUE_TEXT_RECT := Rect2(104, 404, 980, 110)

const COLOR_SPEAKING := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_SILENT := Color(0.42, 0.42, 0.46, 1.0)
const COLOR_NAME_SILENT := Color(0.68, 0.72, 0.78, 1.0)
const BORDER_ACTIVE := Color(0.53, 0.83, 0.71, 1.0)
const BORDER_INACTIVE := Color(0.22, 0.24, 0.30, 1.0)
const COLOR_THOUGHT_TITLE := Color(0.65, 0.94, 0.78, 1.0)
const COLOR_DIALOGUE_TEXT := Color(0.16, 0.18, 0.23, 1.0)

var screen_bg: TextureRect
var custom_layer: Control
var click_catcher: Control
var left_slot: PanelContainer
var right_slot: PanelContainer
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

	background.color = Color(0.216, 0.239, 0.298, 1.0)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_setup_codec_asset_layout()


func _setup_codec_asset_layout() -> void:
	main_margin.visible = false

	custom_layer = Control.new()
	custom_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(custom_layer)

	# Penangkap klik kiri di seluruh layar dialog
	click_catcher = Control.new()
	click_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	click_catcher.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_catcher.gui_input.connect(_on_screen_gui_input)
	custom_layer.add_child(click_catcher)

	# Gambar latar Inner thoughts screen.png (tulisan bawaan di atas dibersihkan otomatis)
	screen_bg = TextureRect.new()
	screen_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen_bg.stretch_mode = TextureRect.STRETCH_SCALE
	screen_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(DIALOGUE_BG_PATH):
		var raw_bg := load(DIALOGUE_BG_PATH) as Texture2D
		screen_bg.texture = _erase_baked_header(raw_bg)
	custom_layer.add_child(screen_bg)

	# Judul dinamis dari JSON (thought_title) menggantikan posisi tulisan atas
	thought_title.reparent(custom_layer, false)
	thought_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	thought_title.position = THOUGHT_TITLE_RECT.position
	thought_title.size = THOUGHT_TITLE_RECT.size
	thought_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thought_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	thought_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thought_title.add_theme_font_size_override("font_size", 34)
	thought_title.add_theme_color_override("font_color", COLOR_THOUGHT_TITLE)
	thought_title.add_theme_color_override("font_outline_color", Color(0.14, 0.17, 0.23, 1.0))
	thought_title.add_theme_constant_override("outline_size", 4)

	# Slot potret kiri & kanan
	left_style = _make_slot_style(BORDER_INACTIVE)
	right_style = _make_slot_style(BORDER_INACTIVE)

	left_slot = _create_portrait_slot(LEFT_SLOT_RECT, left_style)
	right_slot = _create_portrait_slot(RIGHT_SLOT_RECT, right_style)

	left_portrait.reparent(left_slot, false)
	left_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	left_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	left_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	right_portrait.reparent(right_slot, false)
	right_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	right_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	right_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	right_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Label nama pembicara
	left_name_label = _create_name_label(LEFT_NAME_RECT, "TheO")
	right_name_label = _create_name_label(RIGHT_NAME_RECT, "ENEMY")

	# Isi teks dialog utama di dalam gelembung krem bawah
	dialogue_text.reparent(custom_layer, false)
	dialogue_text.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	dialogue_text.position = DIALOGUE_TEXT_RECT.position
	dialogue_text.size = DIALOGUE_TEXT_RECT.size
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text.add_theme_color_override("default_color", COLOR_DIALOGUE_TEXT)
	dialogue_text.add_theme_font_size_override("normal_font_size", 22)


func _erase_baked_header(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null or img.is_empty():
		return tex
	if img.is_compressed():
		img.decompress()

	var w := img.get_width()
	var h := img.get_height()
	var bg_col := img.get_pixel(clampi(int(w * 0.24), 0, w - 1), clampi(int(h * 0.13), 0, h - 1))

	var x_start := clampi(int(w * 0.26), 0, w - 1)
	var x_end := clampi(int(w * 0.76), 0, w)
	var y_start := clampi(int(h * 0.078), 0, h - 1)
	var y_end := clampi(int(h * 0.168), 0, h)

	for y in range(y_start, y_end):
		for x in range(x_start, x_end):
			var c := img.get_pixel(x, y)
			if c.g > 0.72 and c.b > 0.60 and c.r < 0.78:
				img.set_pixel(x, y, bg_col)

	return ImageTexture.create_from_image(img)


func _create_portrait_slot(rect: Rect2, style: StyleBoxFlat) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.position = rect.position
	slot.size = rect.size
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_stylebox_override("panel", style)
	custom_layer.add_child(slot)
	return slot


func _make_slot_style(border_col: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.28, 0.38, 0.45, 0.45)
	st.border_color = border_col
	st.set_border_width_all(3)
	return st


func _create_name_label(rect: Rect2, default_text: String) -> Label:
	var lbl := Label.new()
	lbl.position = rect.position
	lbl.size = rect.size
	lbl.text = default_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.85, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.14, 0.16, 0.21, 1.0))
	lbl.add_theme_constant_override("outline_size", 3)
	custom_layer.add_child(lbl)
	return lbl


func _fit_to_viewport() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var scale_factor := minf(vp_size.x / 1152.0, vp_size.y / 648.0)
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root_ui.position = Vector2.ZERO
	root_ui.size = vp_size / scale_factor
	root_ui.scale = Vector2(scale_factor, scale_factor)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


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
		ui_tween.tween_property(right_name_label, "modulate", COLOR_NAME_SILENT, 0.15)
		ui_tween.tween_property(left_style, "border_color", BORDER_ACTIVE, 0.15)
		ui_tween.tween_property(right_style, "border_color", BORDER_INACTIVE, 0.15)
	elif speaker == "right":
		ui_tween.tween_property(left_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(right_portrait, "modulate", COLOR_SPEAKING, 0.15)
		ui_tween.tween_property(left_name_label, "modulate", COLOR_NAME_SILENT, 0.15)
		ui_tween.tween_property(right_name_label, "modulate", COLOR_SPEAKING, 0.15)
		ui_tween.tween_property(left_style, "border_color", BORDER_INACTIVE, 0.15)
		ui_tween.tween_property(right_style, "border_color", BORDER_ACTIVE, 0.15)
	else:
		ui_tween.tween_property(left_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(right_portrait, "modulate", COLOR_SILENT, 0.15)
		ui_tween.tween_property(left_name_label, "modulate", COLOR_NAME_SILENT, 0.15)
		ui_tween.tween_property(right_name_label, "modulate", COLOR_NAME_SILENT, 0.15)
		ui_tween.tween_property(left_style, "border_color", BORDER_INACTIVE, 0.15)
		ui_tween.tween_property(right_style, "border_color", BORDER_INACTIVE, 0.15)

	var title_str := str(line.get("thought_title", "INNER THOUGHTS"))
	thought_title.text = title_str.to_upper()
	thought_title.visible = title_str != ""

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
		"left": target = left_slot
		"right": target = right_slot
		"thought": target = thought_title
		"all": target = custom_layer

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


func _on_screen_gui_input(event: InputEvent) -> void:
	if not is_active or get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_handle_next_action()


func _input(event: InputEvent) -> void:
	if not is_active or get_tree().paused:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
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
