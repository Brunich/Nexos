@tool
## Ruta1Map — Controlador de la Ruta 1 (Villa Nexo → Ciudad Nora)
## Primera ruta del juego. Encuentros salvajes en hierba alta.
## Ruta lineal norte-sur con patches de hierba, árboles y un NPC guía.
extends Node2D

const _SHEET_NORA := "res://world_building_tiles/buildings objects, floor etc/Objetos Nora.png"

# ── Botón de editor: genera decoraciones de ruta ─────────────────────────────
@export_tool_button("Generar decoraciones") var _btn_gen: Callable = _generate_decorations


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Runtime: reproducir música de ruta
	AudioManager.on_zone_enter("ruta_1")


# ── Generador de decoraciones (solo desde editor) ─────────────────────────────
func _generate_decorations() -> void:
	if not Engine.is_editor_hint():
		return
	_clear_auto_props()

	# ── Cactus dispersos por la ruta ──────────────────────────────────────────
	# Izquierda superior
	_place_prop(Vector2(25,  50),  _SHEET_NORA, Rect2(900,  1100, 80, 130), 0.28)
	_place_prop(Vector2(20,  300), _SHEET_NORA, Rect2(1000, 1100, 80, 130), 0.3)
	_place_prop(Vector2(30,  480), _SHEET_NORA, Rect2(900,  1100, 80, 130), 0.25)
	_place_prop(Vector2(15,  700), _SHEET_NORA, Rect2(1000, 1100, 80, 130), 0.28)
	# Derecha superior
	_place_prop(Vector2(295, 120), _SHEET_NORA, Rect2(1000, 1100, 80, 130), 0.3)
	_place_prop(Vector2(290, 380), _SHEET_NORA, Rect2(900,  1100, 80, 130), 0.25)
	_place_prop(Vector2(295, 600), _SHEET_NORA, Rect2(1000, 1100, 80, 130), 0.28)
	_place_prop(Vector2(285, 750), _SHEET_NORA, Rect2(900,  1100, 80, 130), 0.25)

	# ── Rocas ─────────────────────────────────────────────────────────────────
	_place_prop(Vector2(30,  650), _SHEET_NORA, Rect2(600, 800, 100, 60), 0.3)
	_place_prop(Vector2(275, 250), _SHEET_NORA, Rect2(700, 800, 100, 60), 0.28)
	_place_prop(Vector2(22,  760), _SHEET_NORA, Rect2(600, 800, 100, 60), 0.25)

	# ── Árbol/palmera norte ────────────────────────────────────────────────────
	_place_prop(Vector2(32,  170), _SHEET_NORA, Rect2(1400, 1100, 120, 180), 0.22)
	_place_prop(Vector2(290, 430), _SHEET_NORA, Rect2(1500, 1100, 120, 180), 0.22)

	print("Ruta1Map: decoraciones auto-generadas (%d props)" % _count_auto_props())


# ── Helpers ───────────────────────────────────────────────────────────────────
func _count_auto_props() -> int:
	var c := 0
	for child in get_children():
		if child.name.begins_with("AutoProp_"):
			c += 1
	return c


func _clear_auto_props() -> void:
	for child in get_children():
		if child.name.begins_with("AutoProp_"):
			child.queue_free()


func _place_prop(pos: Vector2, sheet_path: String, region: Rect2, scale_factor: float) -> void:
	var n := get_child_count() + 1
	var prop := Node2D.new()
	prop.name = "AutoProp_%03d" % n
	prop.position = pos
	prop.y_sort_enabled = true

	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	spr.texture = load(sheet_path) as Texture2D
	spr.region_enabled = true
	spr.region_rect = region
	spr.centered = true
	spr.scale = Vector2(scale_factor, scale_factor)
	spr.offset = Vector2(0.0, -region.size.y * 0.5)

	prop.add_child(spr)
	add_child(prop)

	if Engine.is_editor_hint():
		var root: Node = get_tree().edited_scene_root
		if root:
			prop.owner = root
			spr.owner = root
