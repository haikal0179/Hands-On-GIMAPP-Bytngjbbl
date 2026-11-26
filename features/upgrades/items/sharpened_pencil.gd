extends "res://features/upgrades/upgrade.gd"
## TIER I - Sharpened Pencil: +25% damage tiap serangan yang masuk.


func _init() -> void:
	id = "sharpened_pencil"
	display_name = "Sharpened Pencil"
	tier = 1
	desc = "+25% damage tiap serangan."


func modify_damage(dmg: float) -> float:
	return dmg * 1.25
