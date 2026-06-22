extends Node

const PokedexData = preload("res://codigo/datos/pokedex_data.gd")
const RuntimeTextureLoader = preload("res://codigo/util/runtime_texture_loader.gd")

func _ready() -> void:
	var ok := true
	for id in PokedexData.get_all_ids():
		var entry: Dictionary = PokedexData.get_entry(id)
		var tex: Texture2D = null
		var sprite_name: String = str(entry.get("sprite", ""))
		if sprite_name != "":
			tex = RuntimeTextureLoader.load_nexo_sprite_by_name(sprite_name)
		else:
			tex = RuntimeTextureLoader.load_nexo_sprite_by_id(id)
		if tex == null:
			push_error("SPRITE_RESOLUTION_PROBE: no se resolvio sprite para id=%d name=%s" % [id, str(entry.get("name", "?"))])
			ok = false
	

	if ok:
		print("SPRITE_RESOLUTION_PROBE ok")
	get_tree().quit(0 if ok else 1)
