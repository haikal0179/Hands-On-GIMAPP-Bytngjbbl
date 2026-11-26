extends Control
## Layar akhir. Menang UTBK = tamat. Kalah di Level 4 = Deja Vu: pilih 1 upgrade untuk run berikutnya.

const UIKit := preload("res://core/ui_kit.gd")
const WIN_SCREEN := preload("res://assets/art/Win Screen.png")


func _ready() -> void:
	Audio.play_music("prologue" if GameState.result == "victory" else "flashback") #BGM

	if GameState.result == "victory":
		_show_win_screen()
		return

	var box := UIKit.centered_column(self, 8)

	box.add_child(UIKit.make_label("FAILED THE UTBK...", 26, Color(1.0, 0.4, 0.35)))
	box.add_child(UIKit.make_label("Deja vu. Time is looping back again.", 12, Color.WHITE, 420.0))
	if GameState.owned.is_empty():
		var retry := UIKit.make_button("Restart from the Beginning", 14)
		retry.pressed.connect(GameState.start_run)
		box.add_child(retry)
	else:
		box.add_child(UIKit.make_label("Choose 1 upgrade to carry into the next run:", 12, Color(1.0, 0.8, 0.3), 420.0))
		for id in GameState.owned:
			var u = GameState.get_upgrade(id)
			var b := UIKit.make_button("%s\n%s" % [u.display_name, u.desc], 11)
			b.custom_minimum_size = Vector2(440, 48)
			b.pressed.connect(_keep.bind(id))
			box.add_child(b)

	var menu := UIKit.make_button("Main Menu", 11)
	menu.pressed.connect(func() -> void: GameState.goto(Config.SCENE_TITLE))
	box.add_child(menu)


func _show_win_screen() -> void:
	var background := TextureRect.new()
	background.texture = WIN_SCREEN
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_add_win_screen_button(Vector2(0.70, 0.69), Vector2(0.99, 0.82), GameState.new_game)
	_add_win_screen_button(
		Vector2(0.70, 0.84),
		Vector2(0.99, 0.97),
		func() -> void: GameState.goto(Config.SCENE_TITLE)
	)


func _add_win_screen_button(anchor_start: Vector2, anchor_end: Vector2, action: Callable) -> void:
	var button := Button.new()
	button.anchor_left = anchor_start.x
	button.anchor_top = anchor_start.y
	button.anchor_right = anchor_end.x
	button.anchor_bottom = anchor_end.y
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(func() -> void: Audio.play_sfx("click"))
	button.pressed.connect(action)
	add_child(button)


func _keep(id: String) -> void:
	GameState.kept = id
	GameState.start_run()
