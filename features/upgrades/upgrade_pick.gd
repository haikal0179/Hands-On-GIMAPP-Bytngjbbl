extends Control
## Muncul setelah menang Level 1-3: pilih 1 upgrade dari tier level itu.
## Tampilan: background per stage + 1 kartu per upgrade (ikon pixel-art 32x32 dibesarkan 3x).

const UIKit := preload("res://core/ui_kit.gd")

const ICON_SCALE := 3                        # 32px x 3 = 96px. Kelipatan bulat supaya pixel tetap tajam.
const OWNED_ICON_SIZE := 24                  # ikon di baris "Your upgrades"
const CARD_SIZE := Vector2(188, 160)         # pas di area kosong bawah judul

## Sama dengan warna frame di ikon: Tier I hijau, II oranye, III biru.
const TIER_COLORS := {
	1: Color("4c7f24"),
	2: Color("e1a41c"),
	3: Color("4d58eb"),
}

const STAGE_BG_FILES := {
	1: "Upgradescreen_TO.png",
	2: "Upgradescreen_PU.png",
	3: "Upgradescreen_LBI.png",
}

const SEARCH_DIRS := [
	"res://assets/art/ui/upgrades/",
	"res://assets/art/ui/",
]

var picked := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Audio.play_music("flashback") # BGM

	var tier: int = clampi(GameState.level + 1, 1, 3)
	var tier_color: Color = TIER_COLORS.get(tier, Color.WHITE)

	# 1. Pasang gambar background sesuai stage (TO / PU / LBI)
	var bg_tex := _find_stage_bg_texture(tier)
	if bg_tex != null:
		var bg := TextureRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.texture = bg_tex
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		var fallback := ColorRect.new()
		fallback.color = UIKit.BG_COLOR
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(fallback)

	# 2. Susun kartu langsung memakai CenterContainer + VBoxContainer (tanpa ColorRect dari UIKit)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 124)
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top_spacer)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 14)
	box.add_child(cards)
	for id in GameState.upgrades_of_tier(tier):
		cards.add_child(_make_card(id, tier_color))

	box.add_child(_make_owned_row())


func _find_stage_bg_texture(tier: int) -> Texture2D:
	var target_name: String = STAGE_BG_FILES.get(tier, "Upgradescreen_TO.png")
	var target_lower := target_name.to_lower()

	for dir_path in SEARCH_DIRS:
		var exact_path: String = dir_path + target_name
		if ResourceLoader.exists(exact_path):
			return load(exact_path) as Texture2D

		var dir := DirAccess.open(dir_path)
		if dir != null:
			for file_name in dir.get_files():
				if file_name.to_lower() == target_lower:
					return load(dir_path + file_name) as Texture2D

	push_warning("Background upgrade screen tidak ditemukan: " + target_name)
	return null


# ---------- kartu upgrade ----------

func _make_card(id: String, accent: Color) -> Button:
	var u = GameState.get_upgrade(id)

	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style_normal := _card_style(Color(0.09, 0.11, 0.16, 0.94), accent.darkened(0.3))
	var style_hover := _card_style(Color(0.14, 0.17, 0.25, 0.98), accent.lightened(0.25))
	var style_pressed := _card_style(Color(0.06, 0.07, 0.11, 0.98), accent)
	card.add_theme_stylebox_override("normal", style_normal)
	card.add_theme_stylebox_override("hover", style_hover)
	card.add_theme_stylebox_override("pressed", style_pressed)
	card.add_theme_stylebox_override("hover_pressed", style_pressed)
	card.pressed.connect(_pick.bind(id))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	card.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	var icon := _make_icon(u, 32 * ICON_SCALE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(icon)

	var text_w := CARD_SIZE.x - 16.0
	col.add_child(UIKit.make_label(u.display_name, 11, Color.WHITE, text_w))
	col.add_child(UIKit.make_label(u.desc, 8, Color(0.75, 0.80, 0.88), text_w))
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
	var dim := Color(0.85, 0.92, 0.90)
	row.add_child(UIKit.make_label("Your upgrades:", 10, dim))

	var owned: Array = GameState.owned_upgrades()
	if owned.is_empty():
		row.add_child(UIKit.make_label("-", 10, dim))
	for u in owned:
		if _load_icon(u) == null:
			row.add_child(UIKit.make_label(u.display_name, 10, dim))
			continue
		var icon := _make_icon(u, OWNED_ICON_SIZE)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.tooltip_text = "%s\n%s" % [u.display_name, u.desc]
		row.add_child(icon)
	return row


# ---------- ikon ----------

func _make_icon(u, px: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = _load_icon(u)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
		return
	picked = true
	Audio.play_sfx("click")
	GameState.owned.append(id)
	GameState.level += 1
	GameState.goto(Config.SCENE_BATTLE)
