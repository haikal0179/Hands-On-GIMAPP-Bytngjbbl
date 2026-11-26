extends "res://features/upgrades/upgrade.gd"
## TIER II - Seems About Right: 1 opsi salah dihapus dari tiap soal pilihan ganda.


func _init() -> void:
	id = "seems_about_right"
	display_name = "Seems About Right"
	tier = 2
	desc = "Removes 1 incorrect option from each multiple-choice question."

John
func modify_quiz_options(opts: Dictionary) -> void:
	opts["remove_wrong"] = true
