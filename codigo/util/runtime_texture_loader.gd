## RuntimeTextureLoader — Carga texturas en runtime con caché y fallback
## Todas las funciones son estáticas. Se usa como: RuntimeTextureLoader.load_texture(path)
class_name RuntimeTextureLoader

const PokedexData = preload("res://codigo/datos/pokedex_data.gd")

static var _cache: Dictionary = {}
static var _sprite_index_ready: bool = false
static var _sprite_index: Dictionary = {}

## Cargar una textura desde path. Devuelve null si no existe (sin crash).
static func load_texture(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]

	if not ResourceLoader.exists(path):
		_cache[path] = null
		return null

	var tex = ResourceLoader.load(path, "Texture2D")
	_cache[path] = tex
	return tex

## Limpiar caché (llamar al cambiar de escena si hay memory pressure)
static func clear_cache() -> void:
	_cache.clear()
	_sprite_index.clear()
	_sprite_index_ready = false

## Carga sprite por nombre de campo "sprite" en PokedexData (res://Sprites_Nexos/).
static func load_nexo_sprite_by_name(sprite_name: String) -> Texture2D:
	if sprite_name == "":
		return null
	var direct_path := "res://Sprites_Nexos/" + sprite_name + ".png"
	var tex := load_texture(direct_path)
	if tex != null:
		return tex

	_ensure_sprite_index()
	var normalized := _normalize_key(sprite_name)
	if _sprite_index.has(normalized):
		return load_texture(String(_sprite_index[normalized]))
	return null

static func load_nexo_sprite_by_id(creature_id: int) -> Texture2D:
	var entry: Dictionary = PokedexData.get_entry(creature_id)
	if entry.is_empty():
		return _build_placeholder_texture({
			"name": "Nexo",
			"type1": "Normal",
		})

	var sprite_name: String = str(entry.get("sprite", ""))
	if sprite_name != "":
		var named := load_nexo_sprite_by_name(sprite_name)
		if named != null:
			return named

	_ensure_sprite_index()
	var candidate_names: Array[String] = _build_sprite_candidates(entry)
	for candidate in candidate_names:
		var normalized := _normalize_key(candidate)
		if _sprite_index.has(normalized):
			return load_texture(String(_sprite_index[normalized]))

	var entry_name := _normalize_key(str(entry.get("name", "")))
	for key in _sprite_index.keys():
		var norm_key := str(key)
		if norm_key.begins_with(entry_name) or entry_name.begins_with(norm_key):
			return load_texture(String(_sprite_index[key]))

	return _build_placeholder_texture(entry)

static func _ensure_sprite_index() -> void:
	if _sprite_index_ready:
		return
	_sprite_index_ready = true
	_sprite_index.clear()

	var root_path := ProjectSettings.globalize_path("res://Sprites_Nexos")
	if not DirAccess.dir_exists_absolute(root_path):
		return

	_scan_sprite_dir(root_path)

static func _scan_sprite_dir(abs_dir: String) -> void:
	var dir := DirAccess.open(abs_dir)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue

		var child_abs := abs_dir.path_join(name)
		if dir.current_is_dir():
			_scan_sprite_dir(child_abs)
			continue
		if not name.to_lower().ends_with(".png"):
			continue

		var rel_path := child_abs.replace(ProjectSettings.globalize_path("res://"), "res://").replace("\\", "/")
		var base_name := name.get_basename()
		var normalized := _normalize_key(base_name)
		if not _sprite_index.has(normalized):
			_sprite_index[normalized] = rel_path
	dir.list_dir_end()

static func _build_sprite_candidates(entry: Dictionary) -> Array[String]:
	var raw_name := str(entry.get("name", ""))
	var candidates: Array[String] = [
		raw_name,
		raw_name.to_lower(),
		raw_name.capitalize(),
		"%s_base" % raw_name,
		"%s_base_96" % raw_name,
		"%s_base_128" % raw_name,
		"%s_Fase1" % raw_name,
		"%s_fase1" % raw_name,
		"%s_fase 1" % raw_name,
	]
	return candidates

static func _normalize_key(value: String) -> String:
	var out := value.to_lower()
	out = out.replace(" ", "")
	out = out.replace("_", "")
	out = out.replace("-", "")
	out = out.replace(".", "")
	return out

static func _build_placeholder_texture(entry: Dictionary) -> Texture2D:
	var type_color: Color = PokedexData.type_color(str(entry.get("type1", "Normal")))
	var fill := type_color.darkened(0.55)
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(fill)

	for x in range(64):
		img.set_pixel(x, 0, type_color)
		img.set_pixel(x, 63, type_color)
	for y in range(64):
		img.set_pixel(0, y, type_color)
		img.set_pixel(63, y, type_color)

	var accent := type_color.lightened(0.25)
	for px in range(16, 48):
		img.set_pixel(px, 20, accent)
		img.set_pixel(px, 44, accent)
	for py in range(20, 45):
		img.set_pixel(16, py, accent)
		img.set_pixel(47, py, accent)

	return ImageTexture.create_from_image(img)
