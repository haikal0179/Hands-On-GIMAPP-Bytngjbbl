extends Control
## Layar akhir. Menang UTBK = tamat. Kalah di Level 4 = Deja Vu: pilih 1 upgrade untuk run berikutnya.

const UIKit := preload("res://core/ui_kit.gd")


func _ready() -> void:
	Audio.play_music("prologue" if GameState.result == "victory" else "flashback") #BGM
	var box := UIKit.centered_column(self, 8)

	if GameState.result == "victory":
		box.add_child(UIKit.make_label("YOU PASSED THE UTBK!", 26, Color(0.5, 1.0, 0.6)))
		box.add_child(UIKit.make_label("The loop is over. TheO finally got accepted.", 12, Color.WHITE, 420.0))
		var again := UIKit.make_button("Play Again", 14)
		again.pressed.connect(GameState.new_game)
		box.add_child(again)
	else:
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


func _keep(id: String) -> void:
	GameState.kept = id
	GameState.start_run()
