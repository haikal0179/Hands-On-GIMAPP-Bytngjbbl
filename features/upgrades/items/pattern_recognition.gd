extends "res://features/upgrades/upgrade.gd"
## TIER I - Pattern Recognition: 50% menghindar serangan musuh saat jawaban salah/telat.

const DODGE_CHANCE := 0.5


func _init() -> void:
	id = "pattern_recognition"
	display_name = "Pattern Recognition"
	tier = 1
	desc = "50% menghindar kalau jawaban salah."


func should_dodge() -> bool:
	return randf() < DODGE_CHANCE
