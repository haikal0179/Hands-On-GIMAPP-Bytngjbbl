extends "res://features/upgrades/upgrade.gd"
## TIER III - Caffeine Overdose: timer separuh, tapi damage 2x.


func _init() -> void:
	id = "caffeine_overdose"
	display_name = "Caffeine Overdose"
	tier = 3
	desc = "The timer is halved, but damage is doubled."


func modify_time(t: float) -> float:
	return t * 0.5


func modify_damage(dmg: float) -> float:
	return dmg * 2.0
