extends RefCounted
## KELAS DASAR semua upgrade. Satu upgrade = satu file yang "extends" file ini.
## Cukup override hook yang dibutuhkan; sisanya biarkan (default = tidak melakukan apa-apa).
## JANGAN memanggil GameState dari file upgrade (bisa bikin error dependensi melingkar).
## Upgrade baru = salin items/sharpened_pencil.gd. Tidak ada daftar yang perlu diedit:
## registry.gd memindai folder items/ otomatis. Panduan lengkap: docs/UPGRADES.md
## Contoh paling sederhana: sharpened_pencil.gd dan pattern_recognition.gd.
const ICON_DIR := "res://assets/art/ui/upgrades/"
var id := ""             # unik, huruf kecil + underscore
var display_name := ""   # nama yang tampil di layar pilih upgrade
var tier := 1            # 1 = hadiah Level 1, 2 = Level 2, 3 = Level 3
var desc := ""           # deskripsi singkat
var icon_path := ""      


## Dipanggil di awal tiap battle (reset status per musuh di sini).
func on_battle_start(_battle) -> void:
	pass


## Damage serangan player. Terima damage sekarang, kembalikan damage baru.
func modify_damage(dmg: float) -> float:
	return dmg


## Dipanggil saat player akan kena serangan karena salah/telat. true = serangan dihindari.
func should_dodge() -> bool:
	return false


## Waktu per soal (detik). Terima waktu sekarang, kembalikan waktu baru.
func modify_time(t: float) -> float:
	return t


## Atur opsi yang dikirim ke layar quiz. Kunci yang dikenal:
##   opts["remove_wrong"] = true   -> hapus 1 opsi salah (soal pilihan ganda)
##   opts["actions"]               -> tombol tambahan, isi lewat add_action() di bawah
##   opts["stunned"]               -> (hanya dibaca) true kalau soal ini kena stun
func modify_quiz_options(_opts: Dictionary) -> void:
	pass


## Tambah tombol di layar quiz. `result` = hasil yang dikirim ke on_quiz_result saat tombol
## ditekan, kecuali "qte" yang membuka mini-game QTE (hasilnya gamble_green/orange/red).
func add_action(opts: Dictionary, label: String, result: String) -> void:
	var list: Array = opts.get("actions", [])
	list.append({"label": label, "result": result})
	opts["actions"] = list


## Dipanggil saat quiz selesai, sebelum aturan bawaan battle. result: "correct", "wrong",
## "timeout", "skip", "gamble_green", "gamble_orange", "gamble_red".
## Kembalikan true kalau upgrade ini sudah menangani hasilnya (boleh pakai await,
## mis. await battle.attack_enemy(...) atau await battle.hurt_player(...)).
func on_quiz_result(_result: String, _battle) -> bool:
	return false

## Path ikon 32x32 untuk layar pilih upgrade. Biasanya tidak perlu diubah: cukup taruh PNG
## bernama sama dengan display_name di ICON_DIR (contoh: "Sharpened Pencil.png").
func get_icon_path() -> String:
	if icon_path != "":
		return icon_path
	return ICON_DIR + display_name.replace("'", "_") + ".png"
