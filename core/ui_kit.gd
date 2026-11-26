extends RefCounted
## Helper UI untuk layar yang dibangun lewat kode. Pemakaian di file lain:
##     const UIKit := preload("res://core/ui_kit.gd")
##     var box := UIKit.centered_column(self)
##     box.add_child(UIKit.make_label("Halo", 14))

const BG_COLOR := Color(0.08, 0.07, 0.12)


static func make_label(text: String, size: int = 14, color: Color = Color.WHITE, wrap_width: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap_width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(wrap_width, 0)
	return l


static func make_button(
	text: String,
	size: int = 14,
	anchor: Vector2 = Vector2.ZERO,
	offset: Vector2 = Vector2.ZERO,
	button_size: Vector2 = Vector2(160, 30)
) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = button_size
	b.pressed.connect(func() -> void: Audio.play_sfx("click"))
	set_control_layout(b, anchor, offset, button_size)
	return b


static func make_texture_button(
	texture: Texture2D,
	button_size: Vector2 = Vector2(48, 48),
	anchor: Vector2 = Vector2.ZERO,
	offset: Vector2 = Vector2.ZERO
) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = texture
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = button_size
	b.pressed.connect(func() -> void: Audio.play_sfx("click"))
	set_control_layout(b, anchor, offset, button_size)
	return b


static func set_control_layout(control: Control, anchor: Vector2, offset: Vector2, size: Vector2) -> void:
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + size.x
	control.offset_bottom = offset.y + size.y


## Latar polos + kolom di tengah layar. Mengembalikan VBoxContainer untuk diisi.
static func centered_column(host: Control, separation: int = 8) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	host.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	host.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	center.add_child(box)
	return box
