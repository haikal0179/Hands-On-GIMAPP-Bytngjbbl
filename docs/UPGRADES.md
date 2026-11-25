# Writing an upgrade

One upgrade = one file in `features/upgrades/items/`. The registry scans that folder on its
own, so adding an upgrade never edits a shared file (no merge conflicts between teammates).

## Steps
1. Copy `items/sharpened_pencil.gd` to `items/your_upgrade.gd`.
2. Change `id` (unique, lowercase_with_underscores), `display_name`, `tier` (1-3), `desc`.
3. Override the hooks you need. Delete the rest.
4. Run `python3 tools/check_project.py`, then play. It appears on the pick screen of its tier.

```gdscript
extends "res://features/upgrades/upgrade.gd"

func _init() -> void:
	id = "sharpened_pencil"
	display_name = "Sharpened Pencil"
	tier = 1
	desc = "+25% damage."

func modify_damage(dmg: float) -> float:
	return dmg * 1.25
```

## Hooks (all optional)
| Hook | Use |
|---|---|
| `modify_damage(dmg)` | change the player's attack damage |
| `should_dodge()` | return true to dodge an enemy hit |
| `modify_time(t)` | change seconds per question |
| `modify_quiz_options(opts)` | set `opts["remove_wrong"] = true`, or call `add_action(opts, label, result)` to add a button |
| `on_quiz_result(result, battle)` | handle the result yourself; return true if handled; may `await battle.attack_enemy(hits, mult, msg)` / `await battle.hurt_player(key, allow_dodge, extra)` |
| `on_battle_start(battle)` | reset per-enemy state |

`add_action(opts, "Button text", "my_result")` puts a button on the quiz panel. Pressing it
sends `"my_result"` to your `on_quiz_result`. The special result `"qte"` opens the timing
mini-game, which then reports `gamble_green`, `gamble_orange` or `gamble_red`.

## Rules
- Never reference `GameState` (or any autoload) from an upgrade file; it can cause circular
  dependency errors. Use the `battle` argument instead.
- Keep per-run state in the upgrade object and reset it in `on_battle_start`.
