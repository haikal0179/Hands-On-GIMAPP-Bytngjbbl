extends Control
## Layar judul. Tombol Mulai = run baru dari nol (upgrade bawaan dihapus).

const UIKit := preload("res://core/ui_kit.gd")


func _ready() -> void:
	var box := UIKit.centered_column(self, 14)
	box.add_child(UIKit.make_label("The Ultimate UTBK", 30, Color(1.0, 0.65, 0.1)))
	box.add_child(UIKit.make_label("WILL YOU PASS UTBK?????", 14))
	var start := UIKit.make_button("MULAI", 16)
	start.pressed.connect(GameState.new_game)
	box.add_child(start)
	box.add_child(UIKit.make_label("Jawab soal sebelum waktu habis. Tombol 1-4 = pilih jawaban.", 10, Color(0.7, 0.7, 0.8)))
