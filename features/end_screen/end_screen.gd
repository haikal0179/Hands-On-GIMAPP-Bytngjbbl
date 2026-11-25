extends Control
## Layar akhir. Menang UTBK = tamat. Kalah di Level 4 = Deja Vu: pilih 1 upgrade untuk run berikutnya.

const UIKit := preload("res://core/ui_kit.gd")


func _ready() -> void:
	var box := UIKit.centered_column(self, 8)

	if GameState.result == "victory":
		box.add_child(UIKit.make_label("KAMU LULUS UTBK!", 26, Color(0.5, 1.0, 0.6)))
		box.add_child(UIKit.make_label("Loop berakhir. John akhirnya diterima.", 12, Color.WHITE, 420.0))
		var again := UIKit.make_button("Main lagi", 14)
		again.pressed.connect(GameState.new_game)
		box.add_child(again)
	else:
		box.add_child(UIKit.make_label("GAGAL DI UTBK...", 26, Color(1.0, 0.4, 0.35)))
		box.add_child(UIKit.make_label("Deja Vu. Waktu berputar kembali.", 12, Color.WHITE, 420.0))
		if GameState.owned.is_empty():
			var retry := UIKit.make_button("Ulangi dari awal", 14)
			retry.pressed.connect(GameState.start_run)
			box.add_child(retry)
		else:
			box.add_child(UIKit.make_label("Pilih 1 upgrade untuk dibawa ke run berikutnya:", 12, Color(1.0, 0.8, 0.3), 420.0))
			for id in GameState.owned:
				var u = GameState.get_upgrade(id)
				var b := UIKit.make_button("%s\n%s" % [u.display_name, u.desc], 11)
				b.custom_minimum_size = Vector2(440, 48)
				b.pressed.connect(_keep.bind(id))
				box.add_child(b)

	var menu := UIKit.make_button("Menu utama", 11)
	menu.pressed.connect(func() -> void: GameState.goto(Config.SCENE_TITLE))
	box.add_child(menu)


func _keep(id: String) -> void:
	GameState.kept = id
	GameState.start_run()
