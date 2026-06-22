extends CanvasLayer
class_name LevelUpPopup

const ICON_PATHS := {
	"hp_max": "res://world_building_tiles/Iconos/Icono hp.png",
	"sp_atk": "res://world_building_tiles/Iconos/Icono Ataque ambiental.png",
	"sp_def": "res://world_building_tiles/Iconos/Icono defensa ambiental.png",
	"atk": "res://world_building_tiles/Iconos/Icono Ataque fisico.png",
	"def": "res://world_building_tiles/Iconos/icono defensa fisica.png",
	"speed": "res://world_building_tiles/Iconos/Icono Velocidad.png",
}
const LABELS := {
	"hp_max": "HP",
	"sp_atk": "Ataque Ambiental",
	"sp_def": "Defensa Ambiental",
	"atk": "Ataque Fisico",
	"def": "Defensa Fisica",
	"speed": "Velocidad",
}
const ORDER := ["hp_max", "sp_atk", "sp_def", "atk", "def", "speed"]

@onready var title_label: Label = $panel/layout/title
@onready var subtitle_label: Label = $panel/layout/subtitle
@onready var stats_box: VBoxContainer = $panel/layout/stats

func _ready() -> void:
	visible = false

func show_level_up(creature_name: String, from_level: int, to_level: int, deltas: Dictionary) -> void:
	title_label.text = "¡%s subio de nivel!" % creature_name
	subtitle_label.text = "Nivel %d -> %d" % [from_level, to_level]
	_rebuild_stats(deltas)
	visible = true

func hide_popup() -> void:
	visible = false

func _rebuild_stats(deltas: Dictionary) -> void:
	for child in stats_box.get_children():
		child.queue_free()

	for key in ORDER:
		var delta_value := int(deltas.get(key, 0))
		if delta_value <= 0:
			continue
		stats_box.add_child(_make_stat_row(key, delta_value))

func _make_stat_row(stat_key: String, delta_value: int) -> Control:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 24)
	row.add_theme_constant_override("separation", 6)

	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(18, 18)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.texture = _load_icon(String(ICON_PATHS.get(stat_key, "")))
	row.add_child(icon_rect)

	var stat_label = Label.new()
	stat_label.text = String(LABELS.get(stat_key, stat_key))
	stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_label.add_theme_font_size_override("font_size", 10)
	stat_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.96))
	row.add_child(stat_label)

	var delta_label = Label.new()
	delta_label.text = "+%d" % delta_value
	delta_label.add_theme_font_size_override("font_size", 10)
	delta_label.add_theme_color_override("font_color", Color(0.40, 0.95, 0.55))
	row.add_child(delta_label)

	return row

func _load_icon(icon_path: String) -> Texture2D:
	if icon_path == "":
		return null
	if ResourceLoader.exists(icon_path):
		return load(icon_path)

	var image := Image.new()
	var absolute_path := ProjectSettings.globalize_path(icon_path)
	var err := image.load(absolute_path)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)
