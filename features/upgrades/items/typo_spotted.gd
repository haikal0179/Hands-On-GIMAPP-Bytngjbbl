extends "res://features/upgrades/upgrade.gd"
## TIER II - Typo Spotted: lewati 1 soal dan langsung serang, 1x per musuh.

var used := false


func _init() -> void:
	id = "typo_spotted"
	display_name = "Typo Spotted"
	tier = 2
	desc = "Skip 1 question and attack immediately (once per enemy)."


func on_battle_start(_battle) -> void:
	used = false


func modify_quiz_options(opts: Dictionary) -> void:
	if not used:
		add_action(opts, "Typo Spotted: skip & attack", "skip")


func on_quiz_result(result: String, battle) -> bool:
	if result != "skip":
		return false
	used = true
	await battle.attack_enemy(1, 1.0, "Typo Spotted! Skipping the question and attacking now.")
	return true
