extends Node

const SCENE_PATH := "res://escenas/overworld/villa_nexo.tscn"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameManager.setup_new_adventure("Probe")

	var scene: Node = load(SCENE_PATH).instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var quick_menu = get_tree().get_first_node_in_group("quick_menu")
	if quick_menu == null:
		push_error("QUICK_MENU_DIRECT_TOGGLE_PROBE: no existe quick_menu")
		get_tree().quit(1)
		return

	quick_menu.call("toggle_menu")
	await get_tree().process_frame

	if not bool(quick_menu.visible):
		push_error("QUICK_MENU_DIRECT_TOGGLE_PROBE: toggle_menu() no abrió quick_menu")
		get_tree().quit(1)
		return

	quick_menu.call("toggle_menu")
	await get_tree().process_frame

	if bool(quick_menu.visible):
		push_error("QUICK_MENU_DIRECT_TOGGLE_PROBE: toggle_menu() no cerró quick_menu")
		get_tree().quit(1)
		return

	print("QUICK_MENU_DIRECT_TOGGLE_PROBE ok")
	get_tree().quit()
