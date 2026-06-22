## Verifica que las acciones de movimiento existen y tienen WASD + flechas mapeados
extends Node

func _ready() -> void:
	var actions = ["ui_left", "ui_right", "ui_up", "ui_down"]
	var wasd = [65, 68, 87, 83]  # A, D, W, S (physical keycodes)
	var arrow = [4194319, 4194321, 4194320, 4194322]  # Left, Right, Up, Down

	var all_ok := true

	for i in actions.size():
		var action = actions[i]
		if not InputMap.has_action(action):
			push_error("[INPUT PROBE] ❌ Acción '%s' NO existe en InputMap" % action)
			all_ok = false
			continue

		var events = InputMap.action_get_events(action)
		var has_wasd := false
		var has_arrow := false

		for ev in events:
			if ev is InputEventKey:
				if ev.physical_keycode == wasd[i]:
					has_wasd = true
				if ev.physical_keycode == arrow[i]:
					has_arrow = true

		if has_arrow and has_wasd:
			print("[INPUT PROBE] ✅ %s → flecha + WASD (%d eventos)" % [action, events.size()])
		elif has_arrow:
			push_error("[INPUT PROBE] ❌ %s → solo flecha, falta WASD (keycode %d)" % [action, wasd[i]])
			all_ok = false
		elif has_wasd:
			push_error("[INPUT PROBE] ❌ %s → solo WASD, falta flecha" % action)
			all_ok = false
		else:
			push_error("[INPUT PROBE] ❌ %s → sin flechas ni WASD" % action)
			all_ok = false

	if all_ok:
		print("[INPUT PROBE] ✅ PASS — WASD y flechas correctamente mapeados")
	else:
		print("[INPUT PROBE] ❌ FALLO — revisar project.godot [input]")
	get_tree().quit(0 if all_ok else 1)
