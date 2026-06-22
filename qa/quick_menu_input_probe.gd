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

	var quick_menu := get_tree().get_first_node_in_group("quick_menu") as CanvasLayer
	if quick_menu == null:
		push_error("QUICK_MENU_INPUT_PROBE: no existe quick_menu")
		get_tree().quit(1)
		return

	var open_event := InputEventAction.new()
	open_event.action = "quick_menu"
	open_event.pressed = true
	Input.parse_input_event(open_event)
	for _step in range(3):
		await get_tree().process_frame
		await get_tree().physics_frame

	var open_release := InputEventAction.new()
	open_release.action = "quick_menu"
	open_release.pressed = false
	Input.parse_input_event(open_release)
	await get_tree().physics_frame

	if not quick_menu.visible:
		push_error("QUICK_MENU_INPUT_PROBE: quick_menu no se abrio con T")
		get_tree().quit(1)
		return

	var close_event := InputEventAction.new()
	close_event.action = "quick_menu"
	close_event.pressed = true
	Input.parse_input_event(close_event)
	for _step in range(3):
		await get_tree().process_frame
		await get_tree().physics_frame

	if quick_menu.visible:
		push_error("QUICK_MENU_INPUT_PROBE: quick_menu no se cerro con T")
		get_tree().quit(1)
		return

	print("QUICK_MENU_INPUT_PROBE ok")
	get_tree().quit()
