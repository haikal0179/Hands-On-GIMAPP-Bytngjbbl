extends RefCounted
## DAFTAR UPGRADE (otomatis). Semua file *.gd di items/ dipindai sendiri,
## jadi upgrade baru = taruh 1 file di items/. TIDAK ada daftar yang perlu diedit
## (artinya tidak ada konflik git di file ini saat 3 orang menambah upgrade).
##
## Syarat file upgrade: "extends" upgrade.gd dan mengisi `id` di _init().

const ITEMS_DIR := "res://features/upgrades/items"

static var _cache: Dictionary = {}
static var _built := false


static func _build() -> void:
	if _built:
		return
	_built = true
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_error("Registry: folder tidak ditemukan: " + ITEMS_DIR)
		return
	var files: Array = []
	for f in dir.get_files():
		var fname: String = f
		# Saat export, script terdaftar sebagai "nama.gd.remap".
		if fname.ends_with(".remap"):
			fname = fname.trim_suffix(".remap")
		if fname.ends_with(".gd") and not files.has(fname):
			files.append(fname)
	files.sort()
	for fname in files:
		var script = load("%s/%s" % [ITEMS_DIR, fname])
		if script == null:
			push_warning("Registry: gagal memuat " + fname)
			continue
		var u = script.new()
		if str(u.id) == "":
			push_warning("Registry: %s tidak punya id, dilewati" % fname)
			continue
		if _cache.has(u.id):
			push_warning("Registry: id '%s' kembar (%s), dilewati" % [u.id, fname])
			continue
		_cache[u.id] = u


static func get_upgrade(id: String):
	_build()
	return _cache.get(id)


## id semua upgrade pada tier tertentu (urut nama file).
static func ids_of_tier(tier: int) -> Array:
	_build()
	var out: Array = []
	for id in _cache:
		if int(_cache[id].tier) == tier:
			out.append(id)
	return out
