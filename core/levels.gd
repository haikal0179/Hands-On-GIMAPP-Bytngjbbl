extends Node
## AUTOLOAD "Levels": tabel level/musuh. Satu musuh per level.
## time = detik per soal (soal bisa override pakai field "time" di JSON).
## Jumlah level = jumlah entri ALL; file soal-nya data/questions/level_N.json.

const ALL: Array = [
	{"title": "Test 1", "subtest": "TO", "enemy": "TyO", "hp": 160, "dmg": 30, "time": 15.0},
	{"title": "Test 2", "subtest": "PU-PPUBM", "enemy": "Anum", "hp": 160, "dmg": 35, "time": 15.0},
	{"title": "Test 3", "subtest": "LBI-LBE", "enemy": "Lita", "hp": 200, "dmg": 40, "time": 15.0},
	{"title": "UTBK", "subtest": "PK-PM", "enemy": "Tika", "hp": 300, "dmg": 60, "time": 12.0},
]


func count() -> int:
	return ALL.size()
