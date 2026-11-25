extends "res://features/upgrades/upgrade.gd"
## TIER III - Haven't Picked C In A While: tombol tebak (QTE).
## Hijau = 3x serang, oranye = 1x serang +20%, merah = stun (soal berikutnya waktunya separuh).


func _init() -> void:
	id = "picked_c"
	display_name = "Haven't Picked C In A While"
	tier = 3
	desc = "Tombol judi (QTE): sukses = 3x serang, gagal = stun."


func modify_quiz_options(opts: Dictionary) -> void:
	add_action(opts, "Haven't Picked C: tebak (QTE)", "qte")


func on_quiz_result(result: String, battle) -> bool:
	match result:
		"gamble_green":
			await battle.attack_enemy(3, 1.0, "FULL SUCCESS! Tiga serangan beruntun!")
			return true
		"gamble_orange":
			await battle.attack_enemy(1, 1.2, "Minor success! Serangan +20%.")
			return true
		"gamble_red":
			battle.stunned = true
			await battle.hurt_player("gamble_red", false, "STUN! Soal berikutnya waktunya separuh.")
			return true
	return false
