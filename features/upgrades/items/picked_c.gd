extends "res://features/upgrades/upgrade.gd"
## TIER III - Haven't Picked C In A While: tombol tebak (QTE).
## Hijau = 3x serang, oranye = 1x serang +20%, merah = stun (soal berikutnya waktunya separuh).

var _qte_used_in_fight := false


func _init() -> void:
	id = "picked_c"
	display_name = "Haven't Picked C In A While"
	tier = 3
	desc = "Gamble (QTE): success = 3 attacks, failure = stun."


func on_battle_start(_battle) -> void:
	_qte_used_in_fight = false


func modify_quiz_options(opts: Dictionary) -> void:
	if _qte_used_in_fight:
		return
	add_action(opts, "Haven't Picked C: Gamble (QTE)", "qte")


func on_quiz_result(result: String, battle) -> bool:
	match result:
		"gamble_green":
			_qte_used_in_fight = true
			await battle.attack_enemy(3, 1.0, "FULL SUCCESS! Three hits in a row!")
			return true
		"gamble_orange":
			_qte_used_in_fight = true
			await battle.attack_enemy(1, 1.2, "Minor success! +20% attack.")
			return true
		"gamble_red":
			_qte_used_in_fight = true
			battle.stunned = true
			await battle.hurt_player("gamble_red", false, "STUN! Half the time for the next question.")
			return true
	return false
