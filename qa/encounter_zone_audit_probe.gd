extends Node

const EncounterTable = preload("res://codigo/datos/encounter_table.gd")

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
			push_error("ENCOUNTER_ZONE_AUDIT: no se pudo cargar %s" % scene_path)
			ok = false
			continue

		var scene := packed.instantiate()
		add_child(scene)
		await get_tree().process_frame

		var oc := scene.get_node_or_null("OverworldController")
		if oc == null:
			push_error("ENCOUNTER_ZONE_AUDIT: %s no tiene OverworldController" % scene_path)
			ok = false
			scene.queue_free()
			await get_tree().process_frame
			continue

		var zone_name: String = String(oc.get("zone_name"))
		var grass_nodes := _collect_tall_grass(scene)
		if not grass_nodes.is_empty() and EncounterTable.get_encounter_id(zone_name, 5) == -1:
			push_error("ENCOUNTER_ZONE_AUDIT: la zona '%s' en %s no tiene tabla de encuentros valida" % [zone_name, scene_path])
			ok = false

		scene.queue_free()
		await get_tree().process_frame

	if ok:
		print("ENCOUNTER_ZONE_AUDIT ok")
	get_tree().quit(0 if ok else 1)

func _collect_tall_grass(root: Node) -> Array:
	var nodes: Array = []
	for child in root.get_children():
		var script: Variant = child.get_script()
		if script != null and String(script.resource_path).ends_with("tall_grass.gd"):
			nodes.append(child)
		nodes.append_array(_collect_tall_grass(child))
	return nodes
