## StarterSelect — Pantalla de selección de nexo inicial
## Layout: 4 tarjetas arriba, panel de detalle abajo.
## ←/→ o click para navegar. Enter/Z/Espacio para confirmar.
extends CanvasLayer

signal starter_selected(creature: CreatureInstance)

const ExperienceSystem = preload("res://codigo/batalla/experience_system.gd")
const RuntimeTextureLoader = preload("res://codigo/util/runtime_texture_loader.gd")

# Starters según world_bible.html — uno por región del Piélago
const STARTERS = [
	{
		"id": 1001, "name": "Embral",
		"type1": "Fuego", "type2": "Espectro",
		"region": "Levante",
		"desc": "Un cachorro cuya llama es visible a través de sus costillas. En Levante dicen que guía a los muertos en las noches de celebración. Leal hasta la obsesión.",
		"latido": "Estable",
		"base_hp": 45, "nature": "Valiente", "ability": "Llamarada",
		"color": Color(0.85, 0.28, 0.08),
	},
	{
		"id": 1003, "name": "Folimp",
		"type1": "Planta", "type2": "",
		"region": "Coralia",
		"desc": "Un hada de las hojas que abre sus pétalos solo ante quienes confía. Tranquila y observadora. Tarda en confiar — cuando lo hace, no lo olvida.",
		"latido": "Estable",
		"base_hp": 45, "nature": "Sereno", "ability": "Follaje",
		"color": Color(0.22, 0.68, 0.22),
	},
	{
		"id": 1008, "name": "Aquellux",
		"type1": "Agua", "type2": "Eléctrico",
		"region": "Piélago",
		"desc": "Una anguila eléctrica de los mares del Piélago. Su bio-electricidad guía a los navegantes. Inquieta, siempre en movimiento, chispea cuando se emociona.",
		"latido": "Tenso",
		"base_hp": 40, "nature": "Impulsivo", "ability": "Torrente",
		"color": Color(0.15, 0.55, 0.85),
	},
	{
		"id": 1017, "name": "Drakpup",
		"type1": "Dragón", "type2": "",
		"region": "Zenera",
		"desc": "Una cría de dragón volcánico. Joven e inexperta, con un poder latente enorme. En Zenera los criaban para alimentar generadores — este escapó antes de ser registrado.",
		"latido": "Estable",
		"base_hp": 45, "nature": "Adamante", "ability": "Piel Tosca",
		"color": Color(0.70, 0.18, 0.50),
	},
]

# ── Colores por Esencia ──────────────────────────────────────────────────────
const TYPE_COLORS = {
	"Fuego":    Color(0.90, 0.40, 0.10),
	"Espectro": Color(0.50, 0.25, 0.75),
	"Planta":   Color(0.20, 0.70, 0.20),
	"Agua":     Color(0.15, 0.50, 0.90),
	"Eléctrico":Color(0.95, 0.85, 0.10),
	"Dragón":   Color(0.45, 0.10, 0.80),
	"Normal":   Color(0.60, 0.60, 0.60),
}

# ── Estado ───────────────────────────────────────────────────────────────────
var _selected: int = 0
var _card_panels: Array = []   # PanelContainer por cada tarjeta
var _detail_name:   Label = null
var _detail_region: Label = null
var _detail_types:  HBoxContainer = null
var _detail_desc:   Label = null
var _detail_stats:  Label = null
var _detail_sprite: TextureRect = null
var _confirm_btn:   Button = null
var _dot_labels:    Array = []

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	GameManager.dialogue_active = true
	layer = 10
	_build_ui()
	_select(0)

# ── Construcción de UI ────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Fondo completo
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.10, 1.0)
	add_child(bg)

	# Márgenes mínimos para aprovechar el espacio en 320×192
	var root = MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left",  3)
	root.add_theme_constant_override("margin_right", 3)
	root.add_theme_constant_override("margin_top",   3)
	root.add_theme_constant_override("margin_bottom",3)
	add_child(root)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	root.add_child(vbox)

	# ── Título compacto ────────────────────────────────────────────────────────
	var title = Label.new()
	title.text = "Elige tu primer nexo"
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# ── Fila de tarjetas ───────────────────────────────────────────────────────
	var cards_row = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 3)
	vbox.add_child(cards_row)

	for i in STARTERS.size():
		var s = STARTERS[i]
		var panel = _make_card(s, i)
		cards_row.add_child(panel)
		_card_panels.append(panel)

	# ── Separador ──────────────────────────────────────────────────────────────
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 1)
	sep.modulate = Color(0.3, 0.3, 0.5, 0.8)
	vbox.add_child(sep)

	# ── Panel de detalle (HBox: sprite izq + info der) ─────────────────────────
	var detail = HBoxContainer.new()
	detail.add_theme_constant_override("separation", 5)
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(detail)

	# Sprite (cuadrado pequeño a la izquierda)
	_detail_sprite = TextureRect.new()
	_detail_sprite.custom_minimum_size   = Vector2(44, 44)
	_detail_sprite.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_sprite.expand_mode           = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_detail_sprite.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_detail_sprite.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	detail.add_child(_detail_sprite)

	# Info a la derecha
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_child(info_vbox)

	# Nombre + región en la misma fila
	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 4)
	info_vbox.add_child(name_row)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 10)
	_detail_name.add_theme_color_override("font_color", Color(1, 1, 1))
	name_row.add_child(_detail_name)

	_detail_region = Label.new()
	_detail_region.add_theme_font_size_override("font_size", 7)
	_detail_region.add_theme_color_override("font_color", Color(0.5, 0.5, 0.65))
	_detail_region.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_region.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	_detail_region.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	name_row.add_child(_detail_region)

	# Esencias (tipos)
	_detail_types = HBoxContainer.new()
	_detail_types.add_theme_constant_override("separation", 4)
	info_vbox.add_child(_detail_types)

	# Descripción (autowrap, máx 3 líneas visibles)
	_detail_desc = Label.new()
	_detail_desc.autowrap_mode      = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.add_theme_font_size_override("font_size", 7)
	_detail_desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88))
	_detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_desc.max_lines_visible   = 4
	info_vbox.add_child(_detail_desc)

	# Naturaleza / Habilidad / Latido en una sola línea compacta
	_detail_stats = Label.new()
	_detail_stats.add_theme_font_size_override("font_size", 7)
	_detail_stats.add_theme_color_override("font_color", Color(0.65, 0.75, 0.65))
	_detail_stats.clip_text = false
	info_vbox.add_child(_detail_stats)

	# ── Fila inferior: confirmación ────────────────────────────────────────────
	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 6)
	vbox.add_child(bottom_row)

	var nav_hint = Label.new()
	nav_hint.text = "← → navegar"
	nav_hint.add_theme_font_size_override("font_size", 7)
	nav_hint.add_theme_color_override("font_color", Color(0.35, 0.35, 0.50))
	nav_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(nav_hint)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Formar Vínculo [Z]"
	_confirm_btn.add_theme_font_size_override("font_size", 8)
	_confirm_btn.pressed.connect(_on_confirm)
	bottom_row.add_child(_confirm_btn)

	# _dot_labels array vacío (removemos los puntos para ahorrar espacio)
	_dot_labels.clear()

# ── Construir una tarjeta compacta ────────────────────────────────────────────
func _make_card(s: Dictionary, idx: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size   = Vector2(0, 28)

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.08, 0.08, 0.14)
	style_normal.border_width_top    = 2
	style_normal.border_width_bottom = 2
	style_normal.border_width_left   = 2
	style_normal.border_width_right  = 2
	style_normal.border_color = Color(0.25, 0.25, 0.40)
	style_normal.corner_radius_top_left     = 4
	style_normal.corner_radius_top_right    = 4
	style_normal.corner_radius_bottom_left  = 4
	style_normal.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style_normal)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	panel.add_child(vb)

	var name_lbl = Label.new()
	name_lbl.text = s["name"]
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	vb.add_child(name_lbl)

	# Barra de color de tipo
	var type_bar = ColorRect.new()
	type_bar.color = TYPE_COLORS.get(s["type1"], Color(0.5, 0.5, 0.5))
	type_bar.custom_minimum_size = Vector2(0, 3)
	vb.add_child(type_bar)

	var type_lbl = Label.new()
	var type_str = s["type1"] + ("/" + s["type2"] if s["type2"] != "" else "")
	type_lbl.text = type_str
	type_lbl.add_theme_font_size_override("font_size", 7)
	type_lbl.add_theme_color_override("font_color", TYPE_COLORS.get(s["type1"], Color(0.7, 0.7, 0.7)))
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(type_lbl)

	# Click para seleccionar
	var btn = Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(btn)
	var capture_idx = idx
	btn.pressed.connect(func(): _select(capture_idx))

	return panel

# ── Seleccionar un starter ────────────────────────────────────────────────────
func _select(index: int) -> void:
	_selected = index
	var s = STARTERS[index]

	# Resaltar tarjeta seleccionada
	for i in _card_panels.size():
		var panel: PanelContainer = _card_panels[i]
		var style = StyleBoxFlat.new()
		if i == index:
			style.bg_color     = s["color"].darkened(0.5)
			style.border_color = s["color"]
			style.border_width_top    = 2
			style.border_width_bottom = 2
			style.border_width_left   = 2
			style.border_width_right  = 2
		else:
			style.bg_color     = Color(0.08, 0.08, 0.14)
			style.border_color = Color(0.25, 0.25, 0.40)
			style.border_width_top    = 2
			style.border_width_bottom = 2
			style.border_width_left   = 2
			style.border_width_right  = 2
		style.corner_radius_top_left     = 4
		style.corner_radius_top_right    = 4
		style.corner_radius_bottom_left  = 4
		style.corner_radius_bottom_right = 4
		panel.add_theme_stylebox_override("panel", style)

	# Indicadores de posición
	for i in _dot_labels.size():
		var dot: Label = _dot_labels[i]
		if i == index:
			dot.add_theme_color_override("font_color", s["color"])
		else:
			dot.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))

	# Actualizar detalle
	_detail_name.text   = s["name"]
	_detail_name.add_theme_color_override("font_color", s["color"].lightened(0.3))
	_detail_region.text = s["region"]
	_detail_desc.text   = s["desc"]
	_detail_stats.text  = "Naturaleza: %s   Habilidad: %s   ◐ Latido: %s" % [
		s["nature"], s["ability"], s["latido"]
	]

	# Esencias
	for child in _detail_types.get_children():
		child.queue_free()
	await get_tree().process_frame
	for type_str in [s["type1"], s.get("type2", "")]:
		if type_str == "":
			continue
		var badge = Label.new()
		badge.text = type_str.to_upper()
		badge.add_theme_font_size_override("font_size", 8)
		badge.add_theme_color_override("font_color", TYPE_COLORS.get(type_str, Color(0.7, 0.7, 0.7)))
		_detail_types.add_child(badge)

	# Sprite del nexo — resolver desde el loader central
	var tex: Texture2D = RuntimeTextureLoader.load_nexo_sprite_by_id(int(s["id"]))
	if tex == null:
		# Fallback: rectángulo de color con borde
		var img = Image.create(44, 44, false, Image.FORMAT_RGBA8)
		img.fill(s["color"].darkened(0.35))
		for px in range(44):
			img.set_pixel(px, 0,   s["color"])
			img.set_pixel(px, 43,  s["color"])
			img.set_pixel(0,  px,  s["color"])
			img.set_pixel(43, px,  s["color"])
		tex = ImageTexture.create_from_image(img)
	_detail_sprite.texture = tex
	_detail_sprite.modulate = Color(1, 1, 1)

	# Actualizar botón de confirmación con el color del nexo
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color     = s["color"].darkened(0.4)
	btn_style.border_color = s["color"]
	btn_style.border_width_top    = 1
	btn_style.border_width_bottom = 1
	btn_style.border_width_left   = 1
	btn_style.border_width_right  = 1
	btn_style.corner_radius_top_left     = 4
	btn_style.corner_radius_top_right    = 4
	btn_style.corner_radius_bottom_left  = 4
	btn_style.corner_radius_bottom_right = 4
	_confirm_btn.add_theme_stylebox_override("normal", btn_style)
	_confirm_btn.add_theme_stylebox_override("hover",  btn_style)
	_confirm_btn.add_theme_color_override("font_color", Color(1, 1, 1))

# ── Input ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_select((_selected - 1 + STARTERS.size()) % STARTERS.size())
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_select((_selected + 1) % STARTERS.size())
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_on_confirm()

# ── Confirmar selección ───────────────────────────────────────────────────────
func _on_confirm() -> void:
	var creature = _make_creature(STARTERS[_selected])
	GameManager.party.append(creature)
	GameManager.dialogue_active = false
	starter_selected.emit(creature)
	queue_free()

# ── Crear instancia del nexo ──────────────────────────────────────────────────
func _make_creature(s: Dictionary) -> CreatureInstance:
	var c = CreatureInstance.create(int(s["id"]), 5)
	c.nickname    = ""
	c.type1       = s["type1"]
	c.type2       = s.get("type2", "")
	c.nature      = s["nature"]
	c.ability     = s["ability"]
	c.bond        = 50
	c.experience  = ExperienceSystem.exp_for_level(5, ExperienceSystem.get_growth_rate(c.creature_id))
	c.recalculate_stats(false)
	c.hp_cur    = c.hp_max
	c.moves     = []
	c.moves_pp  = []
	print("StarterSelect: nexo creado — %s (aguante=%d, vínculo=%d)" % [s["name"], c.hp_max, c.bond])
	return c
