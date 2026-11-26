extends Control
## Layar judul dengan aset Main Menu (1).png tanpa tombol Settings.

const UIKit := preload("res://core/ui_kit.gd")
const MENU_TEXTURE_PATH := "res://assets/art/ui/Main Menu (1).png"

var credit_overlay: ColorRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Audio.play_music("prologue")

	# 1. Tampilkan gambar aset Main Menu (256x144) secara penuh dengan filter Nearest
	var bg_art := TextureRect.new()
	bg_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_SCALE
	bg_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(MENU_TEXTURE_PATH):
		bg_art.texture = load(MENU_TEXTURE_PATH) as Texture2D
	add_child(bg_art)

	# 2. Area klik transparan tepat di atas tombol START, CREDITS, dan EXIT
	var start_btn := _make_hotspot_button(Rect2(0.370, 0.492, 0.268, 0.140))
	start_btn.pressed.connect(GameState.new_game)
	bg_art.add_child(start_btn)

	var credits_btn := _make_hotspot_button(Rect2(0.370, 0.658, 0.268, 0.140))
	credits_btn.pressed.connect(_on_credit_pressed)
	bg_art.add_child(credits_btn)

	if not OS.has_feature("web"):
		var exit_btn := _make_hotspot_button(Rect2(0.370, 0.822, 0.268, 0.140))
		exit_btn.pressed.connect(_on_exit_pressed)
		bg_art.add_child(exit_btn)

	# 3. Overlay Credits bawaan UIKit
	_build_credit_overlay()


func _make_hotspot_button(rel_rect: Rect2) -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	btn.anchor_left = rel_rect.position.x
	btn.anchor_top = rel_rect.position.y
	btn.anchor_right = rel_rect.position.x + rel_rect.size.x
	btn.anchor_bottom = rel_rect.position.y + rel_rect.size.y
	btn.offset_left = 0.0
	btn.offset_top = 0.0
	btn.offset_right = 0.0
	btn.offset_bottom = 0.0

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	normal.set_corner_radius_all(12)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1.0, 1.0, 1.0, 0.16)
	hover.border_color = Color(1.0, 1.0, 1.0, 0.45)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(12)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.0, 0.0, 0.0, 0.22)
	pressed.set_corner_radius_all(12)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.pressed.connect(func() -> void: Audio.play_sfx("click"))
	return btn


func _build_credit_overlay() -> void:
	credit_overlay = ColorRect.new()
	credit_overlay.color = Color(0.0, 0.0, 0.0, 0.85)
	credit_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	credit_overlay.hide()
	add_child(credit_overlay)

	var credit_box := UIKit.centered_column(credit_overlay, 12)
	credit_box.add_child(UIKit.make_label("TEAM CREDITS", 24, Color(1.0, 0.6, 0.0)))
	credit_box.add_child(UIKit.make_label("The Test of Time\n\n- Team Member 1 (Role)\n- Team Member 2 (Role)\n- Team Member 3 (Role)", 14))

	var close_btn := UIKit.make_button("CLOSE", 16)
	close_btn.pressed.connect(credit_overlay.hide)
	credit_box.add_child(close_btn)


func _on_credit_pressed() -> void:
	credit_overlay.show()


func _on_exit_pressed() -> void:
	get_tree().quit()
