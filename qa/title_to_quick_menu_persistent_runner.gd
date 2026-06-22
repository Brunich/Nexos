extends Node

const TITLE_SCENE := "res://escenas/ui/title_screen.tscn"
const INTRO_SCENE := "res://escenas/ui/intro_lore_screen.tscn"
const OVERWORLD_SCENE := "res://escenas/overworld/villa_nexo.tscn"

func run() -> void:
	call_deferred("_run")

func _run() -> void:
	GameManager.setup_new_adventure("Probe")
	GameManager.dialogue_active = false

	get_tree().change_scene_to_file(TITLE_SCENE)
	await _wait_for_scene(TITLE_SCENE)

	var title := get_tree().current_scene
	if title == null or not title.has_method("_start_new_game"):
		push_error("TITLE_FLOW_PERSISTENT: title_screen no disponible")
		get_tree().quit(1)
		return
	title._start_new_game("Probe")

	await _wait_for_scene(INTRO_SCENE)
	var intro := get_tree().current_scene
	if intro == null or not intro.has_method("_advance"):
		push_error("TITLE_FLOW_PERSISTENT: intro_lore_screen no disponible")
		get_tree().quit(1)
		return

	for _i in range(12):
		if get_tree().current_scene == null or get_tree().current_scene.scene_file_path != INTRO_SCENE:
			break
		if intro.has_method("_skip_typing"):
			intro._skip_typing()
		intro._advance()
		await get_tree().process_frame

	await _wait_for_scene(OVERWORLD_SCENE)
	for _frame in range(4):
		await get_tree().process_frame
		await get_tree().physics_frame

	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		push_error("TITLE_FLOW_PERSISTENT: no existe player en overworld")
		get_tree().quit(1)
		return

	var start_pos := player.global_position
	var move_event := InputEventAction.new()
	move_event.action = "ui_right"
	move_event.pressed = true
	Input.parse_input_event(move_event)
	for _step in range(8):
		await get_tree().physics_frame
	var release_event := InputEventAction.new()
	release_event.action = "ui_right"
	release_event.pressed = false
	Input.parse_input_event(release_event)
	await get_tree().physics_frame

	if player.global_position.x <= start_pos.x:
		push_error("TITLE_FLOW_PERSISTENT: el jugador no se movio tras intro")
		get_tree().quit(1)
		return

	var quick_menu := get_tree().get_first_node_in_group("quick_menu") as CanvasLayer
	if quick_menu == null:
		push_error("TITLE_FLOW_PERSISTENT: quick_menu no existe en overworld")
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
		push_error("TITLE_FLOW_PERSISTENT: quick_menu no abrio tras flujo real")
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
		push_error("TITLE_FLOW_PERSISTENT: quick_menu no cerro tras flujo real")
		get_tree().quit(1)
		return

	print("TITLE_FLOW_PERSISTENT ok start=%s end=%s" % [start_pos, player.global_position])
	get_tree().quit()

func _wait_for_scene(path: String, timeout_frames: int = 240) -> void:
	var frames := 0
	while frames < timeout_frames:
		var current := get_tree().current_scene
		if current != null and current.scene_file_path == path:
			return
		frames += 1
		await get_tree().process_frame
	push_error("TITLE_FLOW_PERSISTENT: timeout esperando %s" % path)
	get_tree().quit(1)
