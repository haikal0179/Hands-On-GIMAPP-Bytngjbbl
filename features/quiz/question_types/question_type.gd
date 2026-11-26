extends RefCounted
## KELAS DASAR jenis soal. Satu jenis soal = satu file di question_types/ yang "extends" file ini,
## lalu didaftarkan 1 baris di registry.gd. quiz_panel.gd tidak perlu diedit.
##
## Alur: panel memanggil build() -> pemain menjawab -> emit resolved("correct" / "wrong").

## Jawaban final. outcome: "correct" atau "wrong".
signal resolved(outcome: String)
## Timer soal harus berhenti (mis. puzzle selesai, sedang menampilkan animasi benar).
signal timer_stopped


## Cek format soal dari JSON. Kembalikan "" kalau valid, atau pesan kesalahan.
func validate(_q: Dictionary) -> String:
	return ""


## Bangun tampilan soal ke dalam `content` (Control kosong seukuran layar 640x360 milik panel;
## taruh node dengan posisi absolut, atau buat container sendiri di dalamnya).
## opts = opsi dari upgrade (mis. opts["remove_wrong"], opts["stunned"]).
func build(_content: Control, _q: Dictionary, _opts: Dictionary) -> void:
	pass


## Tombol keyboard yang ditekan saat soal aktif (keycode = KEY_1, KEY_SPACE, dst).
func on_key(_keycode: int) -> void:
	pass
