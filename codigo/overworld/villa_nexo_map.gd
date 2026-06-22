@tool
## VillaNexoMap — Controlador del pueblo inicial Villa Nexo
## Adjunto al nodo raíz de villa_nexo.tscn.
## Pueblo pequeño y acogedor donde Nix recibe su primer Nexo de Nana Remi.
extends Node2D

const _SHEET_VILLA  := "res://world_building_tiles/buildings objects, floor etc/Objetos villa brasa.png"
const _SHEET_VILLA2 := "res://world_building_tiles/buildings objects, floor etc/Objetos villabrasa2.png"

# ── Botón de editor: genera props decorativos adicionales ─────────────────────
@export_tool_button("Generar decoraciones") var _btn_gen: Callable = _generate_decorations


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Runtime: reproducir música de la zona
	AudioManager.on_zone_enter("villa_nexo")


# ── Generador de decoraciones (solo desde editor) ─────────────────────────────
func _generate_decorations() -> void:
	if not Engine.is_editor_hint():
		return
	_clear_auto_props()

	# Arbusto / mata frente a casa de Nana Remi (izquierda)
	_place_prop(Vector2(56,  132), _SHEET_VILLA, Rect2(1400, 900, 140, 190), 0.15)
	# Arbusto frente a casa vecino (derecha)
	_place_prop(Vector2(400, 132), _SHEET_VILLA, Rect2(1550, 900, 140, 190), 0.15)
	# Árbol extra al centro-norte
	_place_prop(Vector2(240, 60),  _SHEET_VILLA, Rect2(1400, 900, 140, 190), 0.18)
	# Maceta frente a tienda (par)
	_place_prop(Vector2(348, 252), _SHEET_VILLA2, Rect2(800, 400, 60, 80),   0.22)
	_place_prop(Vector2(392, 252), _SHEET_VILLA2, Rect2(800, 400, 60, 80),   0.22)
	# Árbol esquina inferior izquierda
	_place_prop(Vector2(28,  310), _SHEET_VILLA, Rect2(1550, 900, 140, 190), 0.18)
	# Árbol esquina inferior derecha
	_place_prop(Vector2(452, 310), _SHEET_VILLA, Rect2(1400, 900, 140, 190), 0.18)

	print("VillaNexoMap: decoraciones auto-generadas (%d props)" % _count_auto_props())


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


## Coloca un prop derivado de una región del sheet dado.
## pos: posición local en el nodo raíz de la escena
## region: Rect2 dentro del sheet (x, y, w, h en píxeles del sheet)
## scale_factor: factor de escala visual (ajusta hasta que el tamaño en mundo sea correcto)
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
	# Pivote en la base: offset sube medio ancho de región (en espacio local antes de escala)
	spr.offset = Vector2(0.0, -region.size.y * 0.5)

	prop.add_child(spr)
	add_child(prop)

	if Engine.is_editor_hint():
		var root: Node = get_tree().edited_scene_root
		if root:
			prop.owner = root
			spr.owner = root
