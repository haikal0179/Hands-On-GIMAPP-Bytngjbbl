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


static func make_button(text: String, size: int = 14) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(160, 30)
	b.pressed.connect(func() -> void: Audio.play_sfx("click"))
	return b


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
