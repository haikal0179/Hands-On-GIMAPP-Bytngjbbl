extends Control

signal pause_pressed

const PLAYER_IDLE_PATH := "res://assets/art/char/TheO Idle.png"
const PLAYER_ATTACK_PATH := "res://assets/art/char/TheO Attack.png"

const PLAYER_NAMECARD := {
	"normal_frame": "res://assets/art/ui/namecards/Normal mode/Theo/NormalTheo_frame.png",
	"normal_fill": "res://assets/art/ui/namecards/Normal mode/Theo/NormalTheo_filling.png",
	"quiz_frame": "res://assets/art/ui/namecards/Quiz mode (smaller)/Theo/QuizTheo_frame.png",
	"quiz_fill": "res://assets/art/ui/namecards/Quiz mode (smaller)/Theo/QuizTheo_filling.png",
}

const ENEMY_SPRITES := {
	"tyo": {
		"idle": "res://assets/art/char/TyO (TO) Idle.png",
		"attack": "res://assets/art/char/TyO (TO) Attack.png",
	},
	"anum": {
		"idle": "res://assets/art/char/Anum (PU) Idle.png",
		"attack": "res://assets/art/char/Anum (PU) Attack.png",
	},
	"lita": {
		"idle": "res://assets/art/char/Lita (LBILBE) Idle.png",
		"attack": "res://assets/art/char/Lita (LBILBE) Attack.png",
	},
	"tika": {
		"idle": "res://assets/art/char/Tika (PKPM) Idle.png",
		"attack": "res://assets/art/char/Tika (PKPM) Attack.png",
	},
}

const ENEMY_NAMECARDS := {
	"tyo": {
		"normal_frame": "res://assets/art/ui/namecards/Normal mode/Tyo/NormalTyo_frame.png",
		"normal_fill": "res://assets/art/ui/namecards/Normal mode/Tyo/NormalTyo_filling.png",
		"quiz_frame": "res://assets/art/ui/namecards/Quiz mode (smaller)/Tyo/QuizTyo_frame.png",
		"quiz_fill": "res://assets/art/ui/namecards/Quiz mode (smaller)/Tyo/QuizTyo_filling.png",
	},
	"anum": {
		"normal_frame": "res://assets/art/ui/namecards/Normal mode/Anum/NormamAnum_frame.png",
		"normal_fill": "res://assets/art/ui/namecards/Normal mode/Anum/NormslAnum_filling.png",
		"quiz_frame": "res://assets/art/ui/namecards/Quiz mode (smaller)/Anum/AnumQuiz_frame.png",
		"quiz_fill": "res://assets/art/ui/namecards/Quiz mode (smaller)/Anum/AnumQuiz_filling.png",
	},
	"lita": {
		"normal_frame": "res://assets/art/ui/namecards/Normal mode/Lita/NormalLita_frame.png",
		"normal_fill": "res://assets/art/ui/namecards/Normal mode/Lita/NormalLita_filling.png",
		"quiz_frame": "res://assets/art/ui/namecards/Quiz mode (smaller)/Lita/QuizLita_frame.png",
		"quiz_fill": "res://assets/art/ui/namecards/Quiz mode (smaller)/Lita/QuizLita_filling.png",
	},
	"tika": {
		"normal_frame": "res://assets/art/ui/namecards/Normal mode/Tika/NormalTika_frame.png",
		"normal_fill": "res://assets/art/ui/namecards/Normal mode/Tika/NormalTika_filling.png",
		"quiz_frame": "res://assets/art/ui/namecards/Quiz mode (smaller)/Tika/QuizTika_frame.png",
		"quiz_fill": "res://assets/art/ui/namecards/Quiz mode (smaller)/Tika/QuizTika_filling.png",
	},
}

const LEVEL_FALLBACK_KEYS := ["tyo", "anum", "lita", "tika"]
const CARD_SHRINK_SCALE := 0.62

# --- Stage background & papan quiz (assets/art/stages/) ---
const STAGE_BACKGROUNDS := {
	"tyo": "res://assets/art/stages/Stage_TO.png",
	"anum": "res://assets/art/stages/Stage_PU.png",
	"lita": "res://assets/art/stages/Stage_LBI.png",
	"tika": "res://assets/art/stages/Stage_PKPM.png",
}
const QUIZ_BOARD_PATH := "res://assets/art/stages/Stage_background quiz.png"
const QUIZ_BOARD_REGION := Rect2(191, 92, 909, 529)   # bagian PNG yang terisi (kanvas 1280x720)
const QUIZ_BOARD_RECT := Rect2(96, 46, 454, 264)      # posisi & ukuran papan di layar 640x360
const QUIZ_BOARD_TINT := Color(0.55, 0.6, 0.85, 1.0)  # digelapkan sedikit biar teks putih kebaca

# --- Namecard ---
const CARD_ART_SCALE_NORMAL := 0.4   # aset digambar di kanvas 1280x720, layar game 640x360
const CARD_ART_SCALE_QUIZ := 0.32
const PLAYER_CARD_FALLBACK_POS := Vector2(40, 8)
const ENEMY_CARD_FALLBACK_POS := Vector2(420, 12)

# --- Warna plat judul & log (diambil dari palet aset) ---
const PLATE_BG := Color(0.93, 0.93, 0.84)
const PLATE_BORDER := Color(0.255, 0.255, 0.224)
const PLATE_TEXT := Color(0.255, 0.255, 0.224)

var player_idle_tex: Texture2D
var player_attack_tex: Texture2D
var enemy_idle_tex: Texture2D
var enemy_attack_tex: Texture2D

var stage_bg: TextureRect
var quiz_board: TextureRect
var battle_layer: Control
var title_label: Label
var log_label: Label

var player_shadow: Panel
var enemy_shadow: Panel
var player_sprite: TextureRect
var enemy_sprite: TextureRect

# Kartu HP Pemain (Mode Fallback Vector)
var player_card: Panel
var player_portrait: TextureRect
var player_name_label: Label
var player_bar: ProgressBar
var player_hp_label: Label

# Kartu HP Pemain (Mode Custom PNG Namecard TheO)
var player_custom_root: Control
var player_tex_bar: TextureProgressBar
var player_frame_overlay: TextureRect
var player_custom_hp_label: Label
var has_custom_player_card := false
var active_player_card_tex := {}

# Kartu HP Musuh (Mode Fallback Vector)
var enemy_card: Panel
var enemy_portrait: TextureRect
var enemy_name_label: Label
var enemy_bar: ProgressBar
var enemy_hp_label: Label

# Kartu HP Musuh (Mode Custom PNG Namecard)
var enemy_custom_root: Control
var enemy_tex_bar: TextureProgressBar
var enemy_frame_overlay: TextureRect
var enemy_custom_hp_label: Label
var has_custom_enemy_card := false
var active_enemy_card_tex := {}

var player_base_pos := Vector2(60, 196)
var enemy_base_pos := Vector2(452, 185)
var player_idle_tween: Tween
var enemy_idle_tween: Tween
var is_built := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not is_built:
		_build_ui()


func setup(stage_title: String, p_name: String, p_hp: int, p_max: int,
		e_name: String, e_hp: int, e_max: int) -> void:
	if not is_built:
		_build_ui()

	title_label.text = stage_title.to_upper()
	player_name_label.text = p_name
	enemy_name_label.text = e_name

	player_idle_tex = _safe_load_tex(PLAYER_IDLE_PATH)
	player_attack_tex = _safe_load_tex(PLAYER_ATTACK_PATH)

	var enemy_key := _resolve_enemy_key(e_name)
	stage_bg.texture = _safe_load_tex(STAGE_BACKGROUNDS.get(enemy_key, ""))
	var enemy_paths: Dictionary = ENEMY_SPRITES[enemy_key]
	enemy_idle_tex = _safe_load_tex(enemy_paths["idle"])
	enemy_attack_tex = _safe_load_tex(enemy_paths["attack"])

	player_sprite.texture = player_idle_tex
	enemy_sprite.texture = enemy_idle_tex

	player_portrait.texture = _make_bust_portrait(player_idle_tex, true)
	enemy_portrait.texture = _make_bust_portrait(enemy_idle_tex, false)

	_setup_player_namecard()
	_setup_enemy_namecard(enemy_key)

	set_player_hp(p_hp, p_max)
	set_enemy_hp(e_hp, e_max)

	_start_player_idle()
	_start_enemy_idle()


func _setup_player_namecard() -> void:
	var raw_nf := _safe_load_tex(PLAYER_NAMECARD["normal_frame"])
	var raw_nb := _safe_load_tex(PLAYER_NAMECARD["normal_fill"])
	var raw_qf := _safe_load_tex(PLAYER_NAMECARD["quiz_frame"])
	var raw_qb := _safe_load_tex(PLAYER_NAMECARD["quiz_fill"])

	if (raw_nf != null and raw_nb != null) or (raw_qf != null and raw_qb != null):
		var norm_crop := _crop_paired_textures(raw_nf, raw_nb)
		var quiz_crop := _crop_paired_textures(raw_qf, raw_qb)
		active_player_card_tex = {
			"normal_frame": norm_crop["a"],
			"normal_fill": norm_crop["b"],
			"normal_size": norm_crop["size"],
			"normal_fill_rel": norm_crop["fill_rel"],
			"quiz_frame": quiz_crop["a"],
			"quiz_fill": quiz_crop["b"],
			"quiz_size": quiz_crop["size"],
			"quiz_fill_rel": quiz_crop["fill_rel"],
		}
		has_custom_player_card = true
		player_card.visible = false
		player_custom_root.visible = true
		_apply_player_card_mode(false)
		return

	has_custom_player_card = false
	player_card.visible = true
	player_custom_root.visible = false


func _apply_player_card_mode(quiz_on: bool) -> void:
	if not has_custom_player_card:
		return

	var has_quiz: bool = active_player_card_tex["quiz_frame"] != null and active_player_card_tex["quiz_fill"] != null
	var has_norm: bool = active_player_card_tex["normal_frame"] != null and active_player_card_tex["normal_fill"] != null
	var use_quiz_tex := (quiz_on and has_quiz) or (not has_norm)

	var tex_size: Vector2 = active_player_card_tex["quiz_size"] if use_quiz_tex else active_player_card_tex["normal_size"]
	var fill_rel: Rect2 = active_player_card_tex["quiz_fill_rel"] if use_quiz_tex else active_player_card_tex["normal_fill_rel"]

	var art_scale := CARD_ART_SCALE_QUIZ if quiz_on else CARD_ART_SCALE_NORMAL
	var target_w := roundf(tex_size.x * art_scale)
	var target_h := roundf(tex_size.y * art_scale)

	player_tex_bar.texture_progress = active_player_card_tex["quiz_fill"] if use_quiz_tex else active_player_card_tex["normal_fill"]
	player_frame_overlay.texture = active_player_card_tex["quiz_frame"] if use_quiz_tex else active_player_card_tex["normal_frame"]

	player_custom_root.size = Vector2(target_w, target_h)
	player_custom_root.pivot_offset = player_custom_root.size * 0.5
	player_custom_root.position = Vector2(40.0, 12.0)

	var bar_pos := Vector2(roundf(fill_rel.position.x * target_w), roundf(fill_rel.position.y * target_h))
	var bar_size := Vector2(roundf(fill_rel.size.x * target_w), roundf(fill_rel.size.y * target_h))

	player_tex_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	player_tex_bar.position = bar_pos
	player_tex_bar.size = bar_size

	player_custom_hp_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	player_custom_hp_label.position = bar_pos
	player_custom_hp_label.size = bar_size
	player_custom_hp_label.add_theme_font_size_override("font_size", 6 if quiz_on else 7)

	player_custom_root.scale = Vector2(0.92, 0.92)
	create_tween().tween_property(player_custom_root, "scale", Vector2.ONE, 0.18)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _setup_enemy_namecard(enemy_key: String) -> void:
	if ENEMY_NAMECARDS.has(enemy_key):
		var paths: Dictionary = ENEMY_NAMECARDS[enemy_key]
		var raw_nf := _safe_load_tex(paths["normal_frame"])
		var raw_nb := _safe_load_tex(paths["normal_fill"])
		var raw_qf := _safe_load_tex(paths["quiz_frame"])
		var raw_qb := _safe_load_tex(paths["quiz_fill"])

		if (raw_nf != null and raw_nb != null) or (raw_qf != null and raw_qb != null):
			var norm_crop := _crop_paired_textures(raw_nf, raw_nb)
			var quiz_crop := _crop_paired_textures(raw_qf, raw_qb)
			active_enemy_card_tex = {
				"normal_frame": norm_crop["a"],
				"normal_fill": norm_crop["b"],
				"normal_size": norm_crop["size"],
				"normal_fill_rel": norm_crop["fill_rel"],
				"quiz_frame": quiz_crop["a"],
				"quiz_fill": quiz_crop["b"],
				"quiz_size": quiz_crop["size"],
				"quiz_fill_rel": quiz_crop["fill_rel"],
			}
			has_custom_enemy_card = true
			enemy_card.visible = false
			enemy_custom_root.visible = true
			_apply_enemy_card_mode(false)
			return

	has_custom_enemy_card = false
	enemy_card.visible = true
	enemy_custom_root.visible = false


func _apply_enemy_card_mode(quiz_on: bool) -> void:
	if not has_custom_enemy_card:
		return

	var has_quiz: bool = active_enemy_card_tex["quiz_frame"] != null and active_enemy_card_tex["quiz_fill"] != null
	var has_norm: bool = active_enemy_card_tex["normal_frame"] != null and active_enemy_card_tex["normal_fill"] != null
	var use_quiz_tex := (quiz_on and has_quiz) or (not has_norm)

	var tex_size: Vector2 = active_enemy_card_tex["quiz_size"] if use_quiz_tex else active_enemy_card_tex["normal_size"]
	var fill_rel: Rect2 = active_enemy_card_tex["quiz_fill_rel"] if use_quiz_tex else active_enemy_card_tex["normal_fill_rel"]

	# Aset digambar di kanvas 1280x720 -> kali 0.4 / 0.32 supaya pas dengan layar game 640x360
	var art_scale := CARD_ART_SCALE_QUIZ if quiz_on else CARD_ART_SCALE_NORMAL
	var target_w := roundf(tex_size.x * art_scale)
	var target_h := roundf(tex_size.y * art_scale)

	enemy_tex_bar.texture_progress = active_enemy_card_tex["quiz_fill"] if use_quiz_tex else active_enemy_card_tex["normal_fill"]
	enemy_frame_overlay.texture = active_enemy_card_tex["quiz_frame"] if use_quiz_tex else active_enemy_card_tex["normal_frame"]

	enemy_custom_root.size = Vector2(target_w, target_h)
	enemy_custom_root.pivot_offset = enemy_custom_root.size * 0.5
	# kanan-atas di semua mode (normal & quiz), sejajar dengan kartu TheO
	enemy_custom_root.position = Vector2(640.0 - target_w - 16.0, 12.0)

	# Slot bar & angka HP mengikuti posisi slot di aset
	var bar_pos := Vector2(roundf(fill_rel.position.x * target_w), roundf(fill_rel.position.y * target_h))
	var bar_size := Vector2(roundf(fill_rel.size.x * target_w), roundf(fill_rel.size.y * target_h))

	enemy_tex_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	enemy_tex_bar.position = bar_pos
	enemy_tex_bar.size = bar_size

	enemy_custom_hp_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	enemy_custom_hp_label.position = bar_pos
	enemy_custom_hp_label.size = bar_size
	enemy_custom_hp_label.add_theme_font_size_override("font_size", 6 if quiz_on else 7)

	# efek "pop" kecil setiap kartu ganti mode
	enemy_custom_root.scale = Vector2(0.92, 0.92)
	create_tween().tween_property(enemy_custom_root, "scale", Vector2.ONE, 0.18)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_quiz_mode(on: bool) -> void:
	battle_layer.visible = not on

	# Papan soal memudar masuk saat quiz, hilang saat kembali ke battle
	quiz_board.visible = on
	if on:
		quiz_board.modulate = Color(QUIZ_BOARD_TINT, 0.0)
		create_tween().tween_property(quiz_board, "modulate:a", 1.0, 0.2)

	var target := Vector2.ONE * (CARD_SHRINK_SCALE if on else 1.0)
	if has_custom_player_card:
		_apply_player_card_mode(on)
	else:
		var tp := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tp.tween_property(player_card, "scale", target, 0.25)

	if has_custom_enemy_card:
		_apply_enemy_card_mode(on)
	else:
		var te := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		te.tween_property(enemy_card, "scale", target, 0.25)


func show_message(text: String) -> void:
	log_label.text = text
	log_label.visible = text != ""


func set_player_hp(hp: int, max_hp: int) -> void:
	player_bar.max_value = max_hp
	player_tex_bar.max_value = max_hp

	var t := create_tween().set_parallel(true)
	t.tween_property(player_bar, "value", float(hp), 0.25)
	t.tween_property(player_tex_bar, "value", float(hp), 0.25)

	player_hp_label.text = "HP: %d/%d" % [hp, max_hp]
	player_custom_hp_label.text = "%d/%d" % [hp, max_hp]


func set_enemy_hp(hp: int, max_hp: int) -> void:
	enemy_bar.max_value = max_hp
	enemy_tex_bar.max_value = max_hp

	var t := create_tween().set_parallel(true)
	t.tween_property(enemy_bar, "value", float(hp), 0.25)
	t.tween_property(enemy_tex_bar, "value", float(hp), 0.25)

	enemy_hp_label.text = "HP: %d/%d" % [hp, max_hp]
	enemy_custom_hp_label.text = "%d/%d" % [hp, max_hp]


func hit(target: String, damage: int) -> void:
	if target == "enemy":
		_play_player_attack()
		_play_enemy_hurt(damage)
	elif target == "player":
		_play_enemy_attack()
		_play_player_hurt(damage)


func float_text(target: String, text: String, color: Color) -> void:
	var anchor_pos := enemy_base_pos + Vector2(36, -8) if target == "enemy" else player_base_pos + Vector2(36, -8)
	_spawn_popup(text, anchor_pos, color)


# =====================================================
#  ANIMASI IDLE, ATTACK, & HURT
# =====================================================

func _start_player_idle() -> void:
	if player_idle_tween and player_idle_tween.is_running():
		player_idle_tween.kill()
	player_sprite.texture = player_idle_tex
	player_sprite.position = player_base_pos
	player_sprite.scale = Vector2.ONE

	player_idle_tween = create_tween().set_loops()
	player_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	player_idle_tween.tween_property(player_sprite, "scale", Vector2(1.03, 0.96), 0.7)
	player_idle_tween.tween_property(player_sprite, "scale", Vector2(0.99, 1.02), 0.7)


func _start_enemy_idle() -> void:
	if enemy_idle_tween and enemy_idle_tween.is_running():
		enemy_idle_tween.kill()
	enemy_sprite.texture = enemy_idle_tex
	enemy_sprite.position = enemy_base_pos
	enemy_sprite.scale = Vector2.ONE

	enemy_idle_tween = create_tween().set_loops()
	enemy_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	enemy_idle_tween.tween_property(enemy_sprite, "scale", Vector2(0.97, 1.03), 0.65)
	enemy_idle_tween.tween_property(enemy_sprite, "scale", Vector2(1.03, 0.96), 0.65)


func _play_player_attack() -> void:
	if player_idle_tween and player_idle_tween.is_running():
		player_idle_tween.kill()

	if player_attack_tex != null:
		player_sprite.texture = player_attack_tex
	player_sprite.scale = Vector2(1.08, 1.08)

	var t := create_tween()
	t.tween_property(player_sprite, "position", player_base_pos + Vector2(46, -12), 0.11)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.30)
	t.tween_property(player_sprite, "position", player_base_pos, 0.16)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(_start_player_idle)


func _play_enemy_attack() -> void:
	if enemy_idle_tween and enemy_idle_tween.is_running():
		enemy_idle_tween.kill()

	if enemy_attack_tex != null:
		enemy_sprite.texture = enemy_attack_tex
	enemy_sprite.scale = Vector2(1.08, 1.08)

	var t := create_tween()
	t.tween_property(enemy_sprite, "position", enemy_base_pos + Vector2(-46, 12), 0.11)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.30)
	t.tween_property(enemy_sprite, "position", enemy_base_pos, 0.16)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(_start_enemy_idle)


func _play_enemy_hurt(damage: int) -> void:
	_spawn_popup("-%d" % damage, enemy_base_pos + Vector2(36, -10), Color("ffd166"))
	_flash_and_shake(enemy_sprite, enemy_base_pos, 12.0)
	if has_custom_enemy_card:
		_shake_card(enemy_custom_root, enemy_custom_root.position)
	else:
		_shake_card(enemy_card, ENEMY_CARD_FALLBACK_POS)


func _play_player_hurt(damage: int) -> void:
	_spawn_popup("-%d" % damage, player_base_pos + Vector2(36, -10), Color("ef476f"))
	_flash_and_shake(player_sprite, player_base_pos, -12.0)
	if has_custom_player_card:
		_shake_card(player_custom_root, player_custom_root.position)
	else:
		_shake_card(player_card, PLAYER_CARD_FALLBACK_POS)


func _flash_and_shake(node: Control, base_pos: Vector2, knockback_x: float) -> void:
	node.modulate = Color(3.2, 3.2, 3.2, 1.0)
	var t := create_tween()
	t.tween_property(node, "position", base_pos + Vector2(knockback_x, -4), 0.05)
	t.tween_property(node, "position", base_pos + Vector2(-knockback_x * 0.5, 2), 0.05)
	t.tween_property(node, "position", base_pos + Vector2(knockback_x * 0.3, 0), 0.05)
	t.tween_property(node, "position", base_pos, 0.06)

	var flash_t := create_tween()
	flash_t.tween_property(node, "modulate", Color.WHITE, 0.28)


func _shake_card(card: Control, base_pos: Vector2) -> void:
	var t := create_tween()
	t.tween_property(card, "position", base_pos + Vector2(4, 0), 0.04)
	t.tween_property(card, "position", base_pos + Vector2(-4, 0), 0.04)
	t.tween_property(card, "position", base_pos, 0.04)


func _spawn_popup(text: String, pos: Vector2, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_font_size_override("font_size", 22)
	battle_layer.add_child(l)

	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", pos.y - 28, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.75).set_delay(0.15)
	t.chain().tween_callback(l.queue_free)


# =====================================================
#  PEMBANGUNAN TAMPILAN UI
# =====================================================

func _build_ui() -> void:
	is_built = true
	var bg := ColorRect.new()
	bg.color = Color("1e2230")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Latar stage (gambarnya diisi di setup() sesuai musuh)
	stage_bg = TextureRect.new()
	stage_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_bg.stretch_mode = TextureRect.STRETCH_SCALE
	stage_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage_bg)

	# Papan soal semi-transparan (hanya tampil saat mode quiz)
	quiz_board = TextureRect.new()
	quiz_board.position = QUIZ_BOARD_RECT.position
	quiz_board.size = QUIZ_BOARD_RECT.size
	quiz_board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	quiz_board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	quiz_board.stretch_mode = TextureRect.STRETCH_SCALE
	quiz_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quiz_board.modulate = QUIZ_BOARD_TINT
	quiz_board.visible = false
	var board_src := _safe_load_tex(QUIZ_BOARD_PATH)
	if board_src != null:
		var board_atlas := AtlasTexture.new()
		board_atlas.atlas = board_src
		board_atlas.region = QUIZ_BOARD_REGION
		quiz_board.texture = board_atlas
	add_child(quiz_board)

	battle_layer = Control.new()
	battle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(battle_layer)

	# Plat judul stage (tengah-atas)
	title_label = Label.new()
	title_label.position = Vector2(252, 14)
	title_label.size = Vector2(160, 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", PLATE_TEXT)
	title_label.add_theme_stylebox_override("normal", _make_plate_style())
	battle_layer.add_child(title_label)

	# Plat pesan/log (tengah-bawah, di lantai antara dua karakter)
	log_label = Label.new()
	log_label.position = Vector2(214, 294)
	log_label.size = Vector2(220, 46)
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_font_size_override("font_size", 11)
	log_label.add_theme_color_override("font_color", PLATE_TEXT)
	log_label.add_theme_stylebox_override("normal", _make_plate_style())
	log_label.visible = false
	battle_layer.add_child(log_label)

	player_shadow = _make_shadow(Vector2(68, 303), Vector2(72, 14))
	battle_layer.add_child(player_shadow)
	enemy_shadow = _make_shadow(Vector2(481, 288), Vector2(68, 14))
	battle_layer.add_child(enemy_shadow)

	player_sprite = TextureRect.new()
	player_sprite.position = player_base_pos
	player_sprite.size = Vector2(128, 128)
	player_sprite.pivot_offset = Vector2(51, 118)
	player_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	battle_layer.add_child(player_sprite)

	enemy_sprite = TextureRect.new()
	enemy_sprite.position = enemy_base_pos
	enemy_sprite.size = Vector2(116, 116)
	enemy_sprite.pivot_offset = Vector2(64, 108)
	enemy_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	battle_layer.add_child(enemy_sprite)

	# --- Kartu HP pemain versi vektor (fallback) ---
	var pc := _build_status_card(PLAYER_CARD_FALLBACK_POS, Color("4cc9f0"), false)
	player_card = pc["panel"]
	player_portrait = pc["portrait"]
	player_name_label = pc["name"]
	player_bar = pc["bar"]
	player_hp_label = pc["hp"]

	# --- Kartu namecard PNG pemain (TheO) ---
	_build_custom_player_card()

	# --- Kartu HP musuh versi vektor (fallback) ---
	var ec := _build_status_card(ENEMY_CARD_FALLBACK_POS, Color("f72585"), true)
	enemy_card = ec["panel"]
	enemy_portrait = ec["portrait"]
	enemy_name_label = ec["name"]
	enemy_bar = ec["bar"]
	enemy_hp_label = ec["hp"]
	enemy_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN   # HP habis dari kiri

	# --- Kartu namecard PNG musuh (TyO / Anum / Lita / Tika) ---
	_build_custom_enemy_card()


func _build_custom_player_card() -> void:
	player_custom_root = Control.new()
	player_custom_root.position = Vector2(40, 12)
	player_custom_root.size = Vector2(193, 105)
	player_custom_root.visible = false
	player_custom_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_custom_root)

	player_frame_overlay = TextureRect.new()
	player_frame_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	player_frame_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_frame_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_frame_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	player_custom_root.add_child(player_frame_overlay)

	player_tex_bar = TextureProgressBar.new()
	player_tex_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_tex_bar.nine_patch_stretch = true
	player_tex_bar.step = 0.01
	player_tex_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	player_custom_root.add_child(player_tex_bar)

	player_custom_hp_label = Label.new()
	player_custom_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_custom_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_custom_hp_label.add_theme_font_size_override("font_size", 8)
	player_custom_hp_label.add_theme_color_override("font_color", Color.WHITE)
	player_custom_hp_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	player_custom_hp_label.add_theme_constant_override("outline_size", 3)
	player_custom_root.add_child(player_custom_hp_label)


func _build_custom_enemy_card() -> void:
	enemy_custom_root = Control.new()
	enemy_custom_root.position = Vector2(425, 12)
	enemy_custom_root.size = Vector2(193, 105)
	enemy_custom_root.visible = false
	enemy_custom_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(enemy_custom_root)

	# Layer 1 (Bawah): Frame Namecard
	enemy_frame_overlay = TextureRect.new()
	enemy_frame_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	enemy_frame_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	enemy_frame_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_frame_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	enemy_custom_root.add_child(enemy_frame_overlay)

	# Layer 2 (Atas Frame): Filling HP Bar
	# FILL_RIGHT_TO_LEFT = bar habis dari KIRI, sisa HP menempel di kanan
	enemy_tex_bar = TextureProgressBar.new()
	enemy_tex_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	enemy_tex_bar.nine_patch_stretch = true
	enemy_tex_bar.step = 0.01
	enemy_tex_bar.fill_mode = TextureProgressBar.FILL_RIGHT_TO_LEFT
	enemy_custom_root.add_child(enemy_tex_bar)

	# Layer 3 (Paling Atas): angka HP, ditaruh di tengah slot bar oleh _apply_enemy_card_mode()
	enemy_custom_hp_label = Label.new()
	enemy_custom_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_custom_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_custom_hp_label.add_theme_font_size_override("font_size", 8)
	enemy_custom_hp_label.add_theme_color_override("font_color", Color.WHITE)
	enemy_custom_hp_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	enemy_custom_hp_label.add_theme_constant_override("outline_size", 3)
	enemy_custom_root.add_child(enemy_custom_hp_label)


func _build_status_card(pos: Vector2, accent_color: Color, pivot_top_right: bool) -> Dictionary:
	var panel := Panel.new()
	panel.position = pos
	panel.size = Vector2(204, 52)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.pivot_offset = Vector2(panel.size.x, 0.0) if pivot_top_right else Vector2.ZERO

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.16, 0.92)
	style.border_color = accent_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var portrait_bg := Panel.new()
	portrait_bg.position = Vector2(5, 5)
	portrait_bg.size = Vector2(42, 42)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.16, 0.19, 0.27, 1.0)
	p_style.border_color = accent_color.darkened(0.25)
	p_style.set_border_width_all(1)
	portrait_bg.add_theme_stylebox_override("panel", p_style)
	panel.add_child(portrait_bg)

	var portrait := TextureRect.new()
	portrait.position = Vector2(2, 2)
	portrait.size = Vector2(38, 38)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_bg.add_child(portrait)

	var name_lbl := Label.new()
	name_lbl.position = Vector2(54, 3)
	name_lbl.size = Vector2(142, 18)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(name_lbl)

	var bar := ProgressBar.new()
	bar.position = Vector2(54, 22)
	bar.size = Vector2(142, 10)
	bar.show_percentage = false

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.18, 0.20, 0.26, 1.0)
	bar_bg.set_corner_radius_all(2)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = accent_color
	bar_fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bar_bg)
	bar.add_theme_stylebox_override("fill", bar_fill)
	panel.add_child(bar)

	var hp_lbl := Label.new()
	hp_lbl.position = Vector2(54, 33)
	hp_lbl.size = Vector2(142, 16)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_lbl.add_theme_font_size_override("font_size", 10)
	hp_lbl.add_theme_color_override("font_color", Color("cbd5e1"))
	panel.add_child(hp_lbl)

	return {
		"panel": panel,
		"portrait": portrait,
		"name": name_lbl,
		"bar": bar,
		"hp": hp_lbl,
	}


func _make_shadow(pos: Vector2, sz: Vector2) -> Panel:
	var s := Panel.new()
	s.position = pos
	s.size = sz
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.17, 0.19, 0.27, 0.35)
	st.set_corner_radius_all(int(sz.y * 0.5))
	s.add_theme_stylebox_override("panel", st)
	return s


func _make_plate_style() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = PLATE_BG
	st.border_color = PLATE_BORDER
	st.set_border_width_all(2)
	st.content_margin_left = 6
	st.content_margin_right = 6
	st.content_margin_top = 3
	st.content_margin_bottom = 3
	return st


func _crop_paired_textures(tex_a: Texture2D, tex_b: Texture2D) -> Dictionary:
	if tex_a == null or tex_b == null:
		return {"a": tex_a, "b": tex_b, "size": Vector2(220, 64), "fill_rel": Rect2(0, 0, 1, 1)}
	var img_a := tex_a.get_image()
	var img_b := tex_b.get_image()
	if img_a == null or img_b == null or img_a.is_empty() or img_b.is_empty():
		return {"a": tex_a, "b": tex_b, "size": tex_a.get_size(), "fill_rel": Rect2(0, 0, 1, 1)}
	if img_a.is_compressed():
		img_a.decompress()
	if img_b.is_compressed():
		img_b.decompress()

	var rect_a := img_a.get_used_rect()
	var rect_b := img_b.get_used_rect()
	var used := rect_a.merge(rect_b)
	if used.size.x <= 0 or used.size.y <= 0:
		return {"a": tex_a, "b": tex_b, "size": tex_a.get_size(), "fill_rel": Rect2(0, 0, 1, 1)}

	var out_a := ImageTexture.create_from_image(img_a.get_region(used))
	var out_b := ImageTexture.create_from_image(img_b.get_region(rect_b))

	var rel := Rect2(
		float(rect_b.position.x - used.position.x) / float(used.size.x),
		float(rect_b.position.y - used.position.y) / float(used.size.y),
		float(rect_b.size.x) / float(used.size.x),
		float(rect_b.size.y) / float(used.size.y)
	)
	return {"a": out_a, "b": out_b, "size": Vector2(used.size), "fill_rel": rel}


func _resolve_enemy_key(e_name: String) -> String:
	var lower := e_name.to_lower()
	if "tyo" in lower or "(to)" in lower:
		return "tyo"
	elif "anum" in lower or "(pu)" in lower:
		return "anum"
	elif "lita" in lower or "lbi" in lower or "lbe" in lower:
		return "lita"
	elif "tika" in lower or "pk" in lower or "pm" in lower:
		return "tika"

	var idx: int = clampi(GameState.level, 0, LEVEL_FALLBACK_KEYS.size() - 1)
	return LEVEL_FALLBACK_KEYS[idx]


func _safe_load_tex(path: String) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


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
