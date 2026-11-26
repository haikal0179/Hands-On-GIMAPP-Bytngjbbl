extends Control
## TAMPILAN normal stage saja (tidak ada aturan game di sini).
## Mau ganti kotak warna jadi pixel art? Buka scenes/battle_ui.tscn, ganti node
## PlayerSprite / EnemySprite / *Portrait jadi TextureRect (nama node jangan diubah).

signal pause_pressed

@export var shrink_scale := 0.6     # ukuran kartu HP saat quiz terbuka
@export var shrink_time := 0.25

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var damage_label: Label = %DamageLabel
@onready var player_card: Control = %PlayerCard
@onready var enemy_card: Control = %EnemyCard
@onready var player_sprite: Control = %PlayerSprite
@onready var enemy_sprite: Control = %EnemySprite
@onready var player_name: Label = %PlayerNameLabel
@onready var enemy_name: Label = %EnemyNameLabel
@onready var player_bar: ProgressBar = %PlayerHpBar
@onready var enemy_bar: ProgressBar = %EnemyHpBar
@onready var player_hp_label: Label = %PlayerHpLabel
@onready var enemy_hp_label: Label = %EnemyHpLabel


func _ready() -> void:
	%PauseButton.pressed.connect(func() -> void: pause_pressed.emit())
	damage_label.visible = false


func setup(title: String, p_name: String, p_hp: int, p_max: int, e_name: String, e_hp: int, e_max: int) -> void:
	title_label.text = title
	player_name.text = p_name
	enemy_name.text = e_name
	_set_bar(player_bar, player_hp_label, p_hp, p_max, false)
	_set_bar(enemy_bar, enemy_hp_label, e_hp, e_max, false)


func set_player_hp(cur: int, max_hp: int) -> void:
	_set_bar(player_bar, player_hp_label, cur, max_hp, true)


func set_enemy_hp(cur: int, max_hp: int) -> void:
	_set_bar(enemy_bar, enemy_hp_label, cur, max_hp, true)


func show_message(text: String) -> void:
	message_label.text = text


## target: "player" atau "enemy". Kedip + goyang + angka melayang "-40".
func hit(target: String, amount: int) -> void:
	flash(target)
	float_text(target, "-%d" % amount, Color(1.0, 0.35, 0.3))


func flash(target: String) -> void:
	var spr: Control = enemy_sprite if target == "enemy" else player_sprite
	spr.modulate = Color(3, 3, 3, 1)
	create_tween().tween_property(spr, "modulate", Color.WHITE, 0.3)
	var base := spr.position
	var tw := create_tween()
	for i in 3:
		var dx := 6.0 if i % 2 == 0 else -6.0
		tw.tween_property(spr, "position", base + Vector2(dx, 0), 0.04)
	tw.tween_property(spr, "position", base, 0.04)


func float_text(target: String, text: String, color: Color = Color.WHITE) -> void:
	var anchor: Control = enemy_sprite if target == "enemy" else player_sprite
	damage_label.text = text
	damage_label.add_theme_color_override("font_color", color)
	damage_label.position = anchor.position + Vector2(0, -30)
	damage_label.modulate.a = 1.0
	damage_label.visible = true
	var tw := create_tween()
	tw.tween_property(damage_label, "position:y", damage_label.position.y - 24.0, 0.7)
	tw.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.7)
	tw.tween_callback(func() -> void: damage_label.visible = false)


## on = true: quiz terbuka (kartu mengecil, karakter disembunyikan). false: layar normal.
func set_quiz_mode(on: bool) -> void:
	var s := Vector2.ONE * (shrink_scale if on else 1.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(player_card, "scale", s, shrink_time)
	tw.tween_property(enemy_card, "scale", s, shrink_time)
	for n in [player_sprite, enemy_sprite, title_label, message_label]:
		n.visible = not on


func _set_bar(bar: ProgressBar, label: Label, cur: int, max_hp: int, animate: bool) -> void:
	bar.max_value = max_hp
	label.text = "HP: %d/%d" % [cur, max_hp]
	if animate:
		create_tween().tween_property(bar, "value", float(cur), 0.35)
	else:
		bar.value = cur
