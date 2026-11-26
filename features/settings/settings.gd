extends Control

signal closed

const UIKit := preload("res://core/ui_kit.gd")
const CLOSE_ICON := preload("res://assets/art/button/Close button.png")

@export var close_to_main_menu := true

var volume_slider: HSlider
var volume_value_label: Label


func _ready() -> void:
	var box := UIKit.centered_column(self, 14)
	box.add_child(UIKit.make_label("SETTINGS", 26, Color(1.0, 0.6, 0.0)))
	box.add_child(UIKit.make_label("Master Volume", 16))

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	box.add_child(volume_row)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.custom_minimum_size = Vector2(240, 32)
	volume_slider.value = Audio.get_master_volume()
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_row.add_child(volume_slider)

	volume_value_label = UIKit.make_label("", 14)
	volume_value_label.custom_minimum_size = Vector2(48, 0)
	volume_row.add_child(volume_value_label)
	_update_volume_label(volume_slider.value)

	var close_button := UIKit.make_texture_button(
		CLOSE_ICON,
		Vector2(48.0, 48.0),
		Vector2(1.0, 0.0),
		Vector2(-64.0, 16.0)
	)
	close_button.tooltip_text = "Back to Menu"
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func _on_close_pressed() -> void:
	if close_to_main_menu:
		GameState.goto(Config.SCENE_TITLE)
	else:
		closed.emit()


func _on_volume_changed(value: float) -> void:
	Audio.set_master_volume(value)
	_update_volume_label(value)


func _update_volume_label(value: float) -> void:
	volume_value_label.text = "%d%%" % roundi(value * 100.0)
