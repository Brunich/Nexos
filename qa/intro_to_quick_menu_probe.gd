extends Node

const INTRO_SCENE := "res://escenas/ui/intro_lore_screen.tscn"
const OVERWORLD_SCENE := "res://escenas/overworld/villa_nexo.tscn"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameManager.setup_new_adventure("Probe")
	GameManager.dialogue_active = false

	get_tree().change_scene_to_file(INTRO_SCENE)
	await _wait_for_scene(INTRO_SCENE)

	var intro := get_tree().current_scene
	if intro == null or not intro.has_method("_advance"):
		push_error("INTRO_TO_QUICK_MENU_PROBE: intro_lore_screen no disponible")
		get_tree().quit(1)
		return

	for _i in 12:
		if get_tree().current_scene == null or get_tree().current_scene.scene_file_path != INTRO_SCENE:
			break
		intro._skip_typing()
		intro._advance()
		await get_tree().process_frame

	await _wait_for_scene(OVERWORLD_SCENE)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame

	var quick_menu := get_tree().get_first_node_in_group("quick_menu") as CanvasLayer
	if quick_menu == null:
		push_error("INTRO_TO_QUICK_MENU_PROBE: quick_menu no existe")
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
		push_error("INTRO_TO_QUICK_MENU_PROBE: T no abrió quick_menu tras intro")
		get_tree().quit(1)
		return

	Input.parse_input_event(t_event)
	await get_tree().process_frame

	if quick_menu.visible:
		push_error("INTRO_TO_QUICK_MENU_PROBE: T no cerró quick_menu tras intro")
		get_tree().quit(1)
		return

	print("INTRO_TO_QUICK_MENU_PROBE ok")
	get_tree().quit()

func _wait_for_scene(path: String, timeout_frames: int = 240) -> void:
	var frames := 0
	while frames < timeout_frames:
		var current := get_tree().current_scene
		if current != null and current.scene_file_path == path:
			return
		frames += 1
		await get_tree().process_frame
	push_error("INTRO_TO_QUICK_MENU_PROBE: timeout esperando %s" % path)
	get_tree().quit(1)
