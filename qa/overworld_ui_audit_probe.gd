extends Node

const SCENES := [
	"res://escenas/overworld/villa_nexo.tscn",
	"res://escenas/overworld/ruta_1.tscn",
	"res://escenas/overworld/ciudad_nora.tscn",
]

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	for scene_path in SCENES:
		var packed: PackedScene = load(scene_path)
		if packed == null:
			push_error("OVERWORLD_UI_AUDIT: no se pudo cargar %s" % scene_path)
			ok = false
			continue

		var scene := packed.instantiate()
		add_child(scene)
		await get_tree().process_frame
		await get_tree().process_frame

		var has_game_menu := get_tree().get_first_node_in_group("game_menu") != null
		var has_quick_menu := get_tree().get_first_node_in_group("quick_menu") != null

		if not has_game_menu:
			push_error("OVERWORLD_UI_AUDIT: falta game_menu en %s" % scene_path)
			ok = false
		if not has_quick_menu:
			push_error("OVERWORLD_UI_AUDIT: falta quick_menu en %s" % scene_path)
			ok = false

		scene.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame

	if ok:
		print("OVERWORLD_UI_AUDIT ok")
	get_tree().quit(0 if ok else 1)
