extends Node

const SCENE_PATH := "res://escenas/overworld/ruta_1.tscn"
const CreatureInstance = preload("res://codigo/recursos/creature_instance.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameManager.setup_new_adventure("Probe")
	GameManager.party = [CreatureInstance.create(1020, 5)]

	var scene: Node = load(SCENE_PATH).instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var grass_nodes := _collect_tall_grass(scene)
	if grass_nodes.is_empty():
		push_error("ROUTE_ENCOUNTER_PROBE: no hay grass patches en ruta_1")
		get_tree().quit(1)
		return

	var grass: Area2D = grass_nodes[0]
	var encounter_id: int = grass.EncounterTable.get_encounter_id("ruta_1", 5)
	if encounter_id == -1:
		push_error("ROUTE_ENCOUNTER_PROBE: ruta_1 no resolvio encuentros")
		get_tree().quit(1)
		return

	print("ROUTE_ENCOUNTER_PROBE ok encounter_id=%d" % encounter_id)
	get_tree().quit()

func _collect_tall_grass(root: Node) -> Array:
	var nodes: Array = []
	for child in root.get_children():
		var script: Variant = child.get_script()
		if script != null and String(script.resource_path).ends_with("tall_grass.gd"):
			nodes.append(child)
		nodes.append_array(_collect_tall_grass(child))
	return nodes
