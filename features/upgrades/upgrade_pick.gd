extends Control
## Muncul setelah menang Level 1-3: pilih 1 upgrade dari tier level itu.
## Tampilan: 1 kartu per upgrade (ikon pixel-art 32x32 dibesarkan 3x), warna border = warna tier.

const UIKit := preload("res://core/ui_kit.gd")

const ICON_SCALE := 3                        # 32px x 3 = 96px. Pakai kelipatan bulat supaya pixel tetap tajam.
const OWNED_ICON_SIZE := 32                  # ikon di baris "Upgrade kamu" (1x)
const CARD_SIZE := Vector2(190, 190)         # teks kepotong? naikkan angka tinggi (190)

## Sama dengan warna frame di ikon: Tier I hijau, II oranye, III biru.
const TIER_COLORS := {
	1: Color("4c7f24"),
	2: Color("e1a41c"),
	3: Color("4d58eb"),
}

var picked := false


func _ready() -> void:
	Audio.play_music("flashback") #BGM
	var box := UIKit.centered_column(self, 10)

	var tier := GameState.level + 1
	var tier_name: String = ["I", "II", "III"][tier - 1]
	var tier_color: Color = TIER_COLORS.get(tier, Color.WHITE)
	var title: String = GameState.current_level()["title"]
	box.add_child(UIKit.make_label("%s COMPLETE!" % title.to_upper(), 20, Color(0.5, 1.0, 0.6)))
	box.add_child(UIKit.make_label("Choose 1 Tier %s upgrade" % tier_name, 14, tier_color.lightened(0.35)))

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 16)
	box.add_child(cards)
	for id in GameState.upgrades_of_tier(tier):
		cards.add_child(_make_card(id, tier_color))

	box.add_child(_make_owned_row())


# ---------- kartu upgrade ----------

func _make_card(id: String, accent: Color) -> Button:
	var u = GameState.get_upgrade(id)

	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style_normal := _card_style(Color(0.09, 0.11, 0.16), accent.darkened(0.3))
	var style_hover := _card_style(Color(0.14, 0.17, 0.25), accent.lightened(0.25))
	var style_pressed := _card_style(Color(0.06, 0.07, 0.11), accent)
	card.add_theme_stylebox_override("normal", style_normal)
	card.add_theme_stylebox_override("hover", style_hover)
	card.add_theme_stylebox_override("pressed", style_pressed)
	card.add_theme_stylebox_override("hover_pressed", style_pressed)
	card.pressed.connect(_pick.bind(id))

	# Button bukan container, jadi isinya ditaruh di MarginContainer yang memenuhi kartu.
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	card.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	var icon := _make_icon(u, 32 * ICON_SCALE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(icon)

	var text_w := CARD_SIZE.x - 20.0
	col.add_child(UIKit.make_label(u.display_name, 12, Color.WHITE, text_w))
	col.add_child(UIKit.make_label(u.desc, 9, Color(0.72, 0.76, 0.85), text_w))
	return card


func _card_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	return s


# ---------- baris "Upgrade kamu" ----------

func _make_owned_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var dim := Color(0.7, 0.7, 0.8)
	row.add_child(UIKit.make_label("Your upgrades:", 10, dim))

	var owned: Array = GameState.owned_upgrades()
	if owned.is_empty():
		row.add_child(UIKit.make_label("-", 10, dim))
	for u in owned:
		if _load_icon(u) == null:
			row.add_child(UIKit.make_label(u.display_name, 10, dim))   # ikon belum ada -> tampil nama
			continue
		var icon := _make_icon(u, OWNED_ICON_SIZE)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP                  # supaya tooltip muncul
		icon.tooltip_text = "%s\n%s" % [u.display_name, u.desc]
		row.add_child(icon)
	return row


# ---------- ikon ----------

func _make_icon(u, px: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = _load_icon(u)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel-art: jangan di-blur
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(px, px)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _load_icon(u) -> Texture2D:
	var path: String = u.get_icon_path()
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Ikon upgrade tidak ditemukan: " + path)
	return null


# ---------- pilih ----------

func _pick(id: String) -> void:
	if picked:
		return   # cegah klik ganda (level bisa loncat 2x)
	picked = true
	Audio.play_sfx("click")
	GameState.owned.append(id)
	GameState.level += 1
	GameState.goto(Config.SCENE_BATTLE)
