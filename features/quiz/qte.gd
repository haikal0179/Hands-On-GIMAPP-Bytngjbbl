extends RefCounted
## QTE "Nembak Soal" (dipakai upgrade Haven't Picked C lewat action "qte").
## Penanda bergerak bolak-balik; pemain menekan STOP / SPASI.
## Merah = gamble_red, oranye = gamble_orange, hijau = gamble_green.

const UIKit := preload("res://core/ui_kit.gd")

signal stopped(outcome: String)

const SPEED := 0.9      # kecepatan penanda (lebar bar per detik)
const WIDTH := 440.0
const GREEN := Vector2(0.42, 0.58)
const ORANGE := Vector2(0.30, 0.70)

var active := false
var _pos := 0.0
var _dir := 1.0
var _marker: ColorRect


func build(content: Container) -> void:
	active = true
	content.add_child(UIKit.make_label("MAKE YOUR GUESS!  (SPACE / click STOP)", 12, Color(1, 0.8, 0.3)))

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(WIDTH, 36)
	content.add_child(bar)
	var segs: Array = [
		[0.0, 0.30, Color(0.75, 0.22, 0.17)],
		[0.30, 0.42, Color(0.90, 0.49, 0.13)],
		[0.42, 0.58, Color(0.15, 0.68, 0.38)],
		[0.58, 0.70, Color(0.90, 0.49, 0.13)],
		[0.70, 1.0, Color(0.75, 0.22, 0.17)],
	]
	for s in segs:
		var r := ColorRect.new()
		r.color = s[2]
		r.position = Vector2(float(s[0]) * WIDTH, 7)
		r.size = Vector2((float(s[1]) - float(s[0])) * WIDTH, 22)
		bar.add_child(r)
	_marker = ColorRect.new()
	_marker.color = Color.WHITE
	_marker.size = Vector2(4, 36)
	bar.add_child(_marker)

	_pos = randf()
	_dir = 1.0 if randf() < 0.5 else -1.0

	var stop := UIKit.make_button("STOP!", 14)
	stop.pressed.connect(stop_now)
	content.add_child(stop)
	content.add_child(UIKit.make_label("Red = stun   Orange = +20% attack   Green = 3x attack", 10))


func tick(delta: float) -> void:
	if not active:
		return
	_pos += _dir * SPEED * delta
	if _pos >= 1.0:
		_pos = 1.0
		_dir = -1.0
	elif _pos <= 0.0:
		_pos = 0.0
		_dir = 1.0
	_marker.position.x = _pos * (WIDTH - 4.0)


func on_key(keycode: int) -> void:
	if keycode == KEY_SPACE:
		stop_now()


func stop_now() -> void:
	if not active:
		return
	active = false
	var outcome := "gamble_red"
	if _pos >= GREEN.x and _pos <= GREEN.y:
		outcome = "gamble_green"
	elif _pos >= ORANGE.x and _pos <= ORANGE.y:
		outcome = "gamble_orange"
	stopped.emit(outcome)
