extends Control

signal closed

const UIKit := preload("res://core/ui_kit.gd")
const CLOSE_ICON := preload("res://assets/art/button/Close button.png")
const SETTINGS_FRAME := preload("res://assets/art/ui/Settings_frame.png")
const VOLUME_FILL := preload("res://assets/art/ui/Settings_bar filling.png")
const VOLUME_GRABBER := preload("res://assets/art/ui/Settings_bar slider.png")

@export var close_to_main_menu := true

var volume_slider: HSlider
var volume_fill_bar: TextureProgressBar


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_settings_frame()
	_add_volume_slider()
	_add_close_button()


func _add_settings_frame() -> void:
	var frame := TextureRect.new()
	frame.texture = SETTINGS_FRAME
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)


func _add_volume_slider() -> void:
	var art_scale := get_viewport_rect().size / SETTINGS_FRAME.get_size()
	var fill_image := _get_art_image(VOLUME_FILL)
	var grabber_image := _get_art_image(VOLUME_GRABBER)
	if fill_image == null or grabber_image == null:
		return

	var fill_bounds := fill_image.get_used_rect()
	var grabber_bounds := grabber_image.get_used_rect()
	if not _has_visible_pixels(fill_bounds):
		push_error("Settings: volume fill artwork contains no visible pixels.")
		return
	if not _has_visible_pixels(grabber_bounds):
		push_error("Settings: volume slider artwork contains no visible pixels.")
		return

	var track_position := Vector2(fill_bounds.position) * art_scale
	var track_size := Vector2(fill_bounds.size) * art_scale
	var grabber_size := Vector2(grabber_bounds.size) * art_scale
	var fill_texture := _crop_and_scale_art(fill_image, fill_bounds, art_scale)
	var grabber_texture := _crop_and_scale_art(grabber_image, grabber_bounds, art_scale)
	if fill_texture == null or grabber_texture == null:
		return

	volume_fill_bar = TextureProgressBar.new()
	volume_fill_bar.position = track_position
	volume_fill_bar.size = track_size
	volume_fill_bar.min_value = 0.0
	volume_fill_bar.max_value = 1.0
	volume_fill_bar.step = 0.01
	volume_fill_bar.value = Audio.get_master_volume()
	volume_fill_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	volume_fill_bar.texture_progress = fill_texture
	volume_fill_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	volume_fill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(volume_fill_bar)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.position = Vector2(
		track_position.x,
		track_position.y + (track_size.y - grabber_size.y) * 0.5
	)
	volume_slider.size = Vector2(track_size.x, grabber_size.y)
	volume_slider.custom_minimum_size = volume_slider.size
	volume_slider.add_theme_icon_override("grabber", grabber_texture)
	volume_slider.add_theme_icon_override("grabber_highlight", grabber_texture)
	volume_slider.add_theme_icon_override("grabber_disabled", grabber_texture)
	volume_slider.add_theme_stylebox_override("slider", StyleBoxEmpty.new())
	volume_slider.add_theme_stylebox_override("grabber_area", StyleBoxEmpty.new())
	volume_slider.add_theme_stylebox_override("grabber_area_highlight", StyleBoxEmpty.new())
	volume_slider.value = Audio.get_master_volume()
	volume_slider.value_changed.connect(_on_volume_changed)
	add_child(volume_slider)


func _add_close_button() -> void:
	var close_button := UIKit.make_texture_button(
		CLOSE_ICON,
		Vector2(48.0, 48.0),
		Vector2(1.0, 0.0),
		Vector2(-64.0, 16.0)
	)
	close_button.tooltip_text = "Back to Menu"
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func _get_art_image(source: Texture2D) -> Image:
	var image := source.get_image()
	if image == null or image.is_empty():
		push_error("Settings: unable to read volume artwork.")
		return null
	if image.is_compressed():
		var error := image.decompress()
		if error != OK:
			push_error("Settings: unable to decompress volume artwork (error %d)." % error)
			return null
	return image


func _has_visible_pixels(bounds: Rect2i) -> bool:
	return bounds.size.x > 0 and bounds.size.y > 0


func _crop_and_scale_art(image: Image, bounds: Rect2i, art_scale: Vector2) -> Texture2D:
	var target_size := Vector2i(
		roundi(bounds.size.x * art_scale.x),
		roundi(bounds.size.y * art_scale.y)
	)
	if not _has_visible_pixels(Rect2i(Vector2i.ZERO, target_size)):
		push_error("Settings: scaled volume artwork has an invalid size.")
		return null

	var cropped := image.get_region(bounds)
	cropped.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(cropped)


func _on_close_pressed() -> void:
	if close_to_main_menu:
		GameState.goto(Config.SCENE_TITLE)
	else:
		closed.emit()


func _on_volume_changed(value: float) -> void:
	Audio.set_master_volume(value)
	volume_fill_bar.value = value
