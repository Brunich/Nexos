extends Node

const TITLE_SCENE := "res://escenas/ui/title_screen.tscn"
const INTRO_SCENE := "res://escenas/ui/intro_lore_screen.tscn"
const OVERWORLD_SCENE := "res://escenas/overworld/villa_nexo.tscn"

func _ready() -> void:
	reparent(get_tree().root)
	call_deferred("_run")

func _run() -> void:
	print("FLOW_PROBE step=setup")
	GameManager.setup_new_adventure("Probe")
	GameManager.dialogue_active = false

	print("FLOW_PROBE step=title_change")
	get_tree().change_scene_to_file(TITLE_SCENE)
	await _wait_for_scene(TITLE_SCENE)
	print("FLOW_PROBE step=title_ready")

	var title := get_tree().current_scene
	if title == null or not title.has_method("_start_new_game"):
		push_error("TITLE_TO_QUICK_MENU_FLOW_PROBE: no se cargo title_screen")
		get_tree().quit(1)
		return
	title._start_new_game("Probe")

	await _wait_for_scene(INTRO_SCENE)
	print("FLOW_PROBE step=intro_ready")
	var intro := get_tree().current_scene
	if intro == null or not intro.has_method("_advance"):
		push_error("TITLE_TO_QUICK_MENU_FLOW_PROBE: no se cargo intro_lore_screen")
		get_tree().quit(1)
		return

	for _i in 12:
		if get_tree().current_scene == null or get_tree().current_scene.scene_file_path != INTRO_SCENE:
			break
		print("FLOW_PROBE step=intro_advance idx=", _i)
		intro._advance()
		await get_tree().process_frame

	await _wait_for_scene(OVERWORLD_SCENE)
	print("FLOW_PROBE step=overworld_ready")
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame

	var quick_menu := get_tree().get_first_node_in_group("quick_menu") as CanvasLayer
	if quick_menu == null:
		push_error("TITLE_TO_QUICK_MENU_FLOW_PROBE: quick_menu no existe en overworld")
		get_tree().quit(1)
		return

	var t_event := InputEventKey.new()
	t_event.physical_keycode = KEY_T
	t_event.keycode = KEY_T
	t_event.unicode = 116
	t_event.pressed = true
	Input.parse_input_event(t_event)
	await get_tree().process_frame

	if not quick_menu.visible:
		push_error("TITLE_TO_QUICK_MENU_FLOW_PROBE: T no abrio quick_menu tras flujo real")
		get_tree().quit(1)
		return

	var close_event := InputEventKey.new()
	close_event.physical_keycode = KEY_T
	close_event.keycode = KEY_T
	close_event.unicode = 116
	close_event.pressed = true
	Input.parse_input_event(close_event)
	await get_tree().process_frame

	if quick_menu.visible:
		push_error("TITLE_TO_QUICK_MENU_FLOW_PROBE: T no cerro quick_menu tras flujo real")
		get_tree().quit(1)
		return

	print("TITLE_TO_QUICK_MENU_FLOW_PROBE ok")
	get_tree().quit()

func _wait_for_scene(path: String, timeout_frames: int = 90) -> void:
	var frames := 0
	while frames < timeout_frames:
		var current := get_tree().current_scene
		if current != null and current.scene_file_path == path:
			return
		frames += 1
		await get_tree().process_frame
	push_error("TITLE_TO_QUICK_MENU_FLOW_PROBE: timeout esperando escena %s (actual=%s)" % [path, get_tree().current_scene.scene_file_path if get_tree().current_scene else "null"])
	get_tree().quit(1)
