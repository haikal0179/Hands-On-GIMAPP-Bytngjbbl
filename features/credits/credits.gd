extends Control

const BG_PATHS := [
	"res://assets/art/ui/Credits menu.png",
	"res://assets/art/ui/credits/Credits menu.png",
]

const COLOR_ROLE := Color("a7f0d2")      # Hijau mint untuk judul role (bold)
const COLOR_NAME := Color("f5f4e6")      # Putih krem untuk nama anggota
const COLOR_SHADOW := Color("1d222d")

const LEFT_COLUMN_CREDITS := [
	{
		"role": "TEAM LEADER",
		"names": ["Bertrand Reynardo Liem"]
	},
	{
		"role": "GAME PRODUCERS",
		"names": [
			"Bertrand Reynardo Liem",
			"Retashuman Safiy"
		]
	},
	{
		"role": "GAME DESIGNER",
		"names": ["Darryl Gunawan"]
	},
	{
		"role": "AUDIO ARTIST",
		"names": ["Retashuman Safiy"]
	},
]

const RIGHT_COLUMN_CREDITS := [
	{
		"role": "PROGRAMMERS",
		"names": [
			"Fernando Almer Renjiro",
			"Muhammad Haikal Putra Rizae",
			"Nathan Ghanesvara Astawa"
		]
	},
	{
		"role": "WRITERS",
		"names": [
			"Bertrand Reynardo Liem",
			"Skolastika Filia Tandean"
		]
	},
	{
		"role": "VISUAL ARTISTS",
		"names": [
			"Darryl Gunawan",
			"Neshandra Aqilazahra Brillianto",
			"Skolastika Filia Tandean"
		]
	},
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Sembunyikan node placeholder lama jika ada
	for child in get_children():
		if child is CanvasItem:
			child.visible = false

	# 1. Pasang background Credits menu.png
	var bg_tex := _load_credits_bg()
	if bg_tex != null:
		var bg := TextureRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.texture = bg_tex
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)

	# 2. Area konten di dalam kotak biru bawah banner "CREDITS" (y: 38% - 83%)
	var columns := HBoxContainer.new()
	columns.anchor_left = 0.06
	columns.anchor_right = 0.94
	columns.anchor_top = 0.38
	columns.anchor_bottom = 0.83
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_theme_constant_override("separation", 36)
	add_child(columns)

	columns.add_child(_build_column(LEFT_COLUMN_CREDITS))
	columns.add_child(_build_column(RIGHT_COLUMN_CREDITS))

	# 3. Tombol BACK di bagian bawah
	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.anchor_left = 0.5
	back_btn.anchor_right = 0.5
	back_btn.anchor_top = 0.86
	back_btn.anchor_bottom = 0.86
	back_btn.offset_left = -65
	back_btn.offset_right = 65
	back_btn.offset_top = -14
	back_btn.offset_bottom = 14
	back_btn.add_theme_font_size_override("font_size", 12)
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)


func _build_column(groups: Array) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)

	for group in groups:
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 1)

		var role_lbl := RichTextLabel.new()
		role_lbl.bbcode_enabled = true
		role_lbl.fit_content = true
		role_lbl.scroll_active = false
		role_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		role_lbl.text = "[center][b]%s[/b][/center]" % group["role"]
		role_lbl.add_theme_font_size_override("bold_font_size", 11)
		role_lbl.add_theme_color_override("default_color", COLOR_ROLE)
		role_lbl.add_theme_color_override("font_shadow_color", COLOR_SHADOW)
		role_lbl.add_theme_constant_override("shadow_offset_x", 1)
		role_lbl.add_theme_constant_override("shadow_offset_y", 1)
		block.add_child(role_lbl)

		for person_name in group["names"]:
			var name_lbl := Label.new()
			name_lbl.text = person_name
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.add_theme_font_size_override("font_size", 10)
			name_lbl.add_theme_color_override("font_color", COLOR_NAME)
			name_lbl.add_theme_color_override("font_shadow_color", COLOR_SHADOW)
			name_lbl.add_theme_constant_override("shadow_offset_x", 1)
			name_lbl.add_theme_constant_override("shadow_offset_y", 1)
			block.add_child(name_lbl)

		col.add_child(block)

	return col


func _on_back_pressed() -> void:
	Audio.play_sfx("click")
	if get_parent() != get_tree().root:
		queue_free()
	else:
		GameState.goto("res://features/title/title.tscn")


func _load_credits_bg() -> Texture2D:
	for path in BG_PATHS:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	push_warning("Credits menu.png tidak ditemukan di res://assets/art/ui/")
	return null
