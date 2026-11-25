extends Control
## Layar judul. Tombol Mulai = run baru dari nol.

const UIKit := preload("res://core/ui_kit.gd")

var credit_overlay: ColorRect


func _ready() -> void:
	Audio.play_music("prologue") # BGM 
	var box := UIKit.centered_column(self, 14)
	box.add_child(UIKit.make_label("The Ultimate UTBK", 30, Color(1.0, 0.6, 0.0)))
	box.add_child(UIKit.make_label("WILL YOU PASS UTBK?????", 14))

	# 1. Tombol MULAI (tetap pakai GameState.new_game bawaan tim)
	var start := UIKit.make_button("MULAI", 16)
	start.pressed.connect(GameState.new_game)
	box.add_child(start)

	# 2. Tombol KREDIT
	var credit := UIKit.make_button("KREDIT", 16)
	credit.pressed.connect(_on_credit_pressed)
	box.add_child(credit)

	# 3. Tombol KELUAR (sembunyikan otomatis jika dijalankan di Web)
	if not OS.has_feature("web"):
		var exit_btn := UIKit.make_button("KELUAR", 16)
		exit_btn.pressed.connect(_on_exit_pressed)
		box.add_child(exit_btn)

	box.add_child(UIKit.make_label("Jawab soal sebelum waktu habis. Tombol 1-4 = pilih jawaban.", 12))

	_build_credit_overlay()


func _build_credit_overlay() -> void:
	credit_overlay = ColorRect.new()
	credit_overlay.color = Color(0.0, 0.0, 0.0, 0.85)
	credit_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	credit_overlay.hide()
	add_child(credit_overlay)

	var credit_box := UIKit.centered_column(credit_overlay, 12)
	credit_box.add_child(UIKit.make_label("KREDIT TIM", 24, Color(1.0, 0.6, 0.0)))
	credit_box.add_child(UIKit.make_label("The Ultimate UTBK\n\n- Nama Anggota 1 (Role)\n- Nama Anggota 2 (Role)\n- Nama Anggota 3 (Role)", 14))

	var close_btn := UIKit.make_button("TUTUP", 16)
	close_btn.pressed.connect(credit_overlay.hide)
	credit_box.add_child(close_btn)


func _on_credit_pressed() -> void:
	credit_overlay.show()

func _on_exit_pressed() -> void:
	get_tree().quit()
