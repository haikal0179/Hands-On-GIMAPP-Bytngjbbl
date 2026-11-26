extends Node
## AUTOLOAD "Config": semua angka & path global di SATU tempat. Tidak ada logika di sini.
## Mau ubah balance / path? Edit file ini saja.

# ---- scene ----
const SCENE_TITLE := "res://features/title/title.tscn"
const SCENE_SETTINGS := "res://features/settings/settings.tscn"
const SCENE_BATTLE := "res://features/battle/battle.tscn"
const SCENE_UPGRADE := "res://features/upgrades/upgrade_pick.tscn"
const SCENE_END := "res://features/end_screen/end_screen.tscn"

# ---- folder data ---- (folder upgrade ada di features/upgrades/registry.gd)
const QUESTIONS_DIR := "res://data/questions"          # level_1.json ... level_4.json

# ---- player ----
const PLAYER_NAME := "UTBK, John"
const PLAYER_MAX_HP := 180
const BASE_DAMAGE := 40

## UNTUK TES: isi id upgrade supaya langsung dimiliki tiap run, mis. ["picked_c", "typo_spotted"].
## Kosongkan lagi sebelum export!
const DEBUG_START_UPGRADES: Array = []
