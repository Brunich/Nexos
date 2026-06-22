@tool
extends Node2D
class_name LevelArchitect

## Herramienta de nivel: coloca props con pivote en la base, Y-sort y colisión solo en el zócalo inferior.
## La brocha del viewport 2D la reenvía el addon `addons/level_architect` (EditorPlugin._forward_canvas_gui_input).

const DEFAULT_EXTERNAL_SCAN := "C:/Users/bruni/OneDrive/Desktop/Programming Brunich/IA TEAM/PROYECTOS/05_NEXOS/world_building_tiles"

const _IMAGE_EXTS: PackedStringArray = ["png", "webp", "jpg", "jpeg", "bmp"]

@export_group("Origen de tiles")
@export var use_external_folder: bool = false:
	set(value):
		use_external_folder = value
		_rebuild_catalog()
@export_dir var external_tile_folder: String = DEFAULT_EXTERNAL_SCAN:
	set(value):
		external_tile_folder = value
		_rebuild_catalog()
@export var res_tile_folder: String = "res://world_building_tiles":
	set(value):
		res_tile_folder = value
		_rebuild_catalog()
@export var scan_subfolders: bool = true:
	set(value):
		scan_subfolders = value
		_rebuild_catalog()

@export_group("Brocha")
@export var brush_enabled: bool = true
@export var require_shift_for_brush: bool = true
@export var snap_to_grid: bool = true
@export_range(1, 256, 1) var snap_grid_px: int = 16

@export_group("Escala normalizada")
## 0 = sin normalizar (tamaño real de la textura).
## >0 = la dimensión más pequeña de la imagen se escala a este valor en píxeles de mundo.
## Recomendado: 32 para props medianos, 16 para tiles pequeños, 64 para edificios.
@export_range(0, 256, 8, "suffix:px") var normalize_to_px: int = 32

@export_group("Colisión (base)")
@export_range(0.05, 1.0, 0.01) var collision_bottom_ratio: float = 0.2

@export_group("Catálogo")
@export var selected_asset: int = 0

var _catalog_paths: Array[String] = []
var _catalog_labels: Array[String] = []


func _enter_tree() -> void:
	y_sort_enabled = true
	if Engine.is_editor_hint():
		_rebuild_catalog()


func _validate_property(property: Dictionary) -> void:
	if property.name == "selected_asset":
		_ensure_catalog()
		property.hint = PROPERTY_HINT_ENUM
		if _catalog_labels.is_empty():
			property.hint_string = "No hay imágenes (revisa carpeta / Rescan)"
		else:
			property.hint_string = ",".join(_catalog_labels)


func _rebuild_catalog() -> void:
	if not Engine.is_editor_hint():
		return
	_catalog_paths.clear()
	_catalog_labels.clear()
	var root := _scan_root_path()
	if not root.is_empty():
		_scan_images_recursive(root, scan_subfolders, _catalog_paths, _catalog_labels)
		_sort_catalog_by_label()
	if selected_asset >= _catalog_paths.size():
		selected_asset = maxi(_catalog_paths.size() - 1, 0)
	notify_property_list_changed()


func _ensure_catalog() -> void:
	if _catalog_paths.is_empty() and Engine.is_editor_hint():
		_rebuild_catalog()


func _scan_root_path() -> String:
	var path := res_tile_folder.strip_edges()
	if use_external_folder:
		path = external_tile_folder.strip_edges().replace("\\", "/")
	if path.is_empty():
		return ""
	if use_external_folder:
		return path
	if not path.ends_with("/"):
		path += "/"
	return path


func _scan_images_recursive(dir_path: String, recursive: bool, paths: Array[String], labels: Array[String]) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		push_warning("LevelArchitect: no se pudo abrir carpeta: %s" % dir_path)
		return
	da.list_dir_begin()
	var entry := da.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = da.get_next()
			continue
		var full: String = dir_path.path_join(entry)
		if da.current_is_dir():
			if recursive:
				_scan_images_recursive(full, true, paths, labels)
		else:
			var ext := entry.get_extension().to_lower()
			if ext in _IMAGE_EXTS:
				paths.append(full)
				labels.append(entry.get_basename())
		entry = da.get_next()


func _sort_catalog_by_label() -> void:
	var n := _catalog_paths.size()
	if n <= 1:
		return
	var order: Array[int] = []
	order.resize(n)
	for i in n:
		order[i] = i
	order.sort_custom(func(a: int, b: int) -> bool:
		return _catalog_labels[a].nocasecmp_to(_catalog_labels[b]) < 0
	)
	var paths2: Array[String] = []
	var labels2: Array[String] = []
	paths2.resize(n)
	labels2.resize(n)
	for i in n:
		var j: int = order[i]
		paths2[i] = _catalog_paths[j]
		labels2[i] = _catalog_labels[j]
	_catalog_paths = paths2
	_catalog_labels = labels2


func _get_selected_path() -> String:
	_ensure_catalog()
	if _catalog_paths.is_empty():
		return ""
	var idx := clampi(selected_asset, 0, _catalog_paths.size() - 1)
	return _catalog_paths[idx]


func _load_texture(path: String) -> Texture2D:
	if path.begins_with("res://"):
		var res := load(path)
		return res as Texture2D
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_warning("LevelArchitect: Image.load falló (%s): %s" % [error_string(err), path])
		return null
	var tex := ImageTexture.create_from_image(img)
	return tex


func _next_prop_name() -> String:
	var n := get_child_count() + 1
	return "PlacedProp_%03d" % n


func _apply_snap(p: Vector2) -> Vector2:
	if not snap_to_grid or snap_grid_px <= 0:
		return p
	var g := float(snap_grid_px)
	return Vector2(roundf(p.x / g) * g, roundf(p.y / g) * g)


func place_prop_at_local(local_pos: Vector2) -> Node2D:
	var path := _get_selected_path()
	if path.is_empty():
		push_warning("LevelArchitect: catálogo vacío o índice inválido.")
		return null
	var tex := _load_texture(path)
	if tex == null:
		return null

	var pos := _apply_snap(local_pos)
	var tw := float(tex.get_width())
	var th := float(tex.get_height())

	# Calcular escala de normalización
	# normalize_to_px == 0 → sin normalizar (escala 1.0)
	# normalize_to_px > 0 → la dimensión mínima queda a ese número de píxeles en mundo
	var disp_scale := 1.0
	if normalize_to_px > 0:
		var smallest := minf(tw, th)
		if smallest > 0.0:
			disp_scale = float(normalize_to_px) / smallest

	var prop := Node2D.new()
	prop.name = _next_prop_name()
	prop.position = pos
	prop.y_sort_enabled = true

	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	spr.texture = tex
	spr.centered = true
	spr.scale = Vector2(disp_scale, disp_scale)
	# offset en espacio local de textura (antes de escala) → sube el sprite hasta que su base quede en pos
	spr.offset = Vector2(0.0, -th * 0.5)

	var body := StaticBody2D.new()
	body.name = "StaticBody2D"

	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	# La colisión usa tamaño en píxeles de mundo (tw/th × escala)
	var world_w := tw * disp_scale
	var world_h := th * disp_scale
	var col_h: float = world_h * clampf(collision_bottom_ratio, 0.05, 1.0)
	rect.size = Vector2(world_w, col_h)
	cs.shape = rect
	cs.position = Vector2(0.0, -col_h * 0.5)

	prop.add_child(spr)
	prop.add_child(body)
	body.add_child(cs)
	add_child(prop)

	if Engine.is_editor_hint():
		var scene_root: Node = get_tree().edited_scene_root
		if scene_root:
			_set_owner_recursive(prop, scene_root)

	return prop


func _set_owner_recursive(node: Node, scene_root: Node) -> void:
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		n.owner = scene_root
		for c in n.get_children():
			stack.append(c)


func _brush_modifiers_ok(event: InputEventMouseButton) -> bool:
	if not require_shift_for_brush:
		return true
	return event.shift_pressed


## Llamada desde el addon del editor.
## El plugin hace la conversión viewport-píxeles → local y llama place_prop_at_local() directamente.
## Esta función existe como stub por si se llama desde otro contexto futuro.
func _forward_canvas_gui_input(_event: InputEvent) -> bool:
	return false
