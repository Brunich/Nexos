extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var hp_bar_scene: PackedScene = load("res://escenas/batalla/hp_bar.tscn")
	if hp_bar_scene == null:
		push_error("level_up_ui_probe: no cargo hp_bar.tscn")
		get_tree().quit(1)
		return

	var hp_bar = hp_bar_scene.instantiate()
	add_child(hp_bar)

	if hp_bar.get_node_or_null("exp_bar") == null:
		push_error("level_up_ui_probe: falta exp_bar debajo de HP")
		get_tree().quit(1)
		return

	if hp_bar.has_method("set_exp_progress"):
		hp_bar.set_exp_progress(24, 100)
		var exp_bar: ProgressBar = hp_bar.get_node("exp_bar")
		if int(exp_bar.value) != 24 or int(exp_bar.max_value) != 100:
			push_error("level_up_ui_probe: set_exp_progress no actualizo la barra")
			get_tree().quit(1)
			return
	else:
		push_error("level_up_ui_probe: hp_bar.gd no expone set_exp_progress")
		get_tree().quit(1)
		return

	var popup_scene: PackedScene = load("res://escenas/ui/level_up_popup.tscn")
	if popup_scene == null:
		push_error("level_up_ui_probe: falta level_up_popup.tscn")
		get_tree().quit(1)
		return

	var popup = popup_scene.instantiate()
	add_child(popup)
	if not popup.has_method("show_level_up"):
		push_error("level_up_ui_probe: popup sin metodo show_level_up")
		get_tree().quit(1)
		return

	var deltas := {
		"hp_max": 4,
		"atk": 2,
		"sp_atk": 3,
		"def": 1,
		"sp_def": 2,
		"speed": 5,
	}
	popup.show_level_up("Embral", 5, 6, deltas)
	await get_tree().process_frame

	var stats_list = popup.get_node_or_null("panel/layout/stats")
	if stats_list == null or stats_list.get_child_count() < 6:
		push_error("level_up_ui_probe: el popup no renderizo las 6 filas de stats")
		get_tree().quit(1)
		return

	for row in stats_list.get_children():
		var icon_rect = row.get_child(0)
		if icon_rect is TextureRect and icon_rect.texture == null:
			push_error("level_up_ui_probe: una fila del popup no cargo su icono")
			get_tree().quit(1)
			return

	print("LEVEL_UP_UI_PROBE ok rows=%d" % stats_list.get_child_count())
	get_tree().quit()
