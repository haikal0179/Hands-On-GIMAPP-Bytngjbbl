extends Control
## Muncul setelah menang Level 1-3: pilih 1 upgrade dari tier level itu.

const UIKit := preload("res://core/ui_kit.gd")


func _ready() -> void:
	var box := UIKit.centered_column(self, 8)

	var tier := GameState.level + 1
	var tier_name: String = ["I", "II", "III"][tier - 1]
	var title: String = GameState.current_level()["title"]
	box.add_child(UIKit.make_label("%s SELESAI!" % title.to_upper(), 20, Color(0.5, 1.0, 0.6)))
	box.add_child(UIKit.make_label("Pilih 1 upgrade Tier %s" % tier_name, 14))

	for id in GameState.upgrades_of_tier(tier):
		var u = GameState.get_upgrade(id)
		var b := UIKit.make_button("%s\n%s" % [u.display_name, u.desc], 11)
		b.custom_minimum_size = Vector2(440, 48)
		b.pressed.connect(_pick.bind(id))
		box.add_child(b)

	var names: Array = []
	for id in GameState.owned:
		names.append(GameState.get_upgrade(id).display_name)
	var have := "-" if names.is_empty() else ", ".join(names)
	box.add_child(UIKit.make_label("Upgrade kamu: " + have, 10, Color(0.7, 0.7, 0.8), 440.0))


func _pick(id: String) -> void:
	GameState.owned.append(id)
	GameState.level += 1
	GameState.goto(Config.SCENE_BATTLE)
