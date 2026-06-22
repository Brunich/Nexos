@tool
extends EditorPlugin

## LevelArchitectPlugin — Reenvía clics del viewport 2D al nodo LevelArchitect activo.
## Compatible con Godot 4.3+ / 4.6.2:
##   get_editor_interface() fue deprecado en 4.3 → usar EditorInterface como singleton estático.
##
## Conversión de coordenadas:
##   _forward_canvas_gui_input recibe event.position en PÍXELES del SubViewport del editor.
##   get_canvas_transform() mapea mundo → píxeles; invertido: píxeles → mundo.
##   to_local() convierte mundo → espacio local del LevelArchitect.
##
## Si el punto sigue desplazado con cámara/zoom inusuales:
##   Reemplaza vp.get_canvas_transform() por vp.get_final_transform() * vp.get_canvas_transform()

var _la: LevelArchitect = null


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	_refresh_target()

	if _la == null or not _la.brush_enabled:
		return false

	if not event is InputEventMouseButton:
		return false

	var mb := event as InputEventMouseButton

	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return false

	if _la.require_shift_for_brush and not mb.shift_pressed:
		return false

	# ── Conversión viewport-píxeles → mundo → local ───────────────────────────
	var vp: SubViewport = EditorInterface.get_editor_viewport_2d()
	var canvas_xf: Transform2D = vp.get_canvas_transform()
	var world_pos: Vector2 = canvas_xf.affine_inverse() * mb.position
	var local_pos: Vector2 = _la.to_local(world_pos)

	_la.place_prop_at_local(local_pos)
	return true


func _refresh_target() -> void:
	# Godot 4.3+: EditorInterface es un singleton estático, no se llama get_editor_interface()
	var sel := EditorInterface.get_selection().get_selected_nodes()
	_la = null
	if sel.is_empty():
		return
	var candidate: Node = sel[0]
	if candidate is LevelArchitect:
		_la = candidate as LevelArchitect
