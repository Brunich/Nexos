## PartyScreen — Pantalla del equipo de Tonales
## Muestra los Tonales del jugador con nombre real, Esencia, Latido y HP.
## Adjunto a Control en game_menu.tscn/party_screen.
extends Control

const PokedexData       = preload("res://codigo/datos/pokedex_data.gd")
const DespertarSystem   = preload("res://codigo/sistemas/despertar_system.gd")
const STATS_SCENE_PATH  = "res://escenas/ui/stats_screen.tscn"

@onready var slot_container = $scroll/slot_container
@onready var summary_sprite = $summary_panel/sprite
@onready var summary_name   = $summary_panel/name_label
@onready var summary_nick   = $summary_panel/nickname_lbl
@onready var summary_level  = $summary_panel/level_label
@onready var summary_hp_bar = $summary_panel/hp_bar
@onready var summary_hp_txt = $summary_panel/hp_txt
@onready var summary_status = $summary_panel/status_label
@onready var btn_stats      = $summary_panel/btn_stats
@onready var btn_swap       = $summary_panel/btn_swap
@onready var btn_heal       = $summary_panel/btn_heal

var _selected_index: int  = 0
var _slot_buttons: Array  = []
var _swap_from: int       = -1   # índice origen para intercambio

# Labels extra que creamos en código
var _type_label:      Label  = null
var _latido_label:    Label  = null
var _bond_bar:        ProgressBar = null
var _despertar_btn:   Button = null

const STATUS_LABELS = {
	0: "", 1: "VEN", 2: "VEN+", 3: "QMD", 4: "PAR", 5: "HLO", 6: "DOR",
}

const STATUS_COLORS = {
	0: Color(0.9, 0.9, 0.9),
	1: Color(0.4, 0.9, 0.2),
	2: Color(0.2, 0.8, 0.1),
	3: Color(0.95, 0.45, 0.1),
	4: Color(0.9, 0.8, 0.1),
	5: Color(0.4, 0.7, 0.95),
	6: Color(0.45, 0.45, 0.85),
}

# Colores de estado de Latido (0=RESONANTE, 1=ESTABLE, 2=TENSO, 3=ROTO)
const LATIDO_COLORS = [
	Color(1.0, 0.85, 0.2),   # RESONANTE — dorado
	Color(0.3,  0.85, 0.4),  # ESTABLE   — verde
	Color(0.95, 0.58, 0.1),  # TENSO     — naranja
	Color(0.90, 0.20, 0.2),  # ROTO      — rojo
]
const LATIDO_NAMES = ["◈ Resonante", "● Estable", "◐ Tenso", "○ Roto"]

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# ── Añadir labels extra al summary_panel ────────────────────────────────
	var panel = $summary_panel

	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 9)
	_type_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	panel.add_child(_type_label)
	panel.move_child(_type_label, 3)  # Después de level_label

	_latido_label = Label.new()
	_latido_label.add_theme_font_size_override("font_size", 9)
	panel.add_child(_latido_label)

	_bond_bar = ProgressBar.new()
	_bond_bar.min_value    = 0
	_bond_bar.max_value    = 100
	_bond_bar.show_percentage = false
	_bond_bar.custom_minimum_size = Vector2(0, 6)
	panel.add_child(_bond_bar)

	# Botón de Despertar (aparece solo cuando aplica)
	_despertar_btn = Button.new()
	_despertar_btn.text = "✦ ¡DESPERTAR!"
	_despertar_btn.add_theme_font_size_override("font_size", 10)
	_despertar_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_despertar_btn.visible = false
	_despertar_btn.pressed.connect(_on_btn_despertar)
	panel.add_child(_despertar_btn)

	# ── Conectar botones ────────────────────────────────────────────────────
	btn_stats.pressed.connect(_on_btn_stats)
	btn_swap.text = "Mover lugar"
	btn_swap.pressed.connect(_on_btn_swap)
	btn_heal.text = "Curar (Suero)"
	btn_heal.pressed.connect(_on_btn_heal)

	_clear_summary()

# ── API pública ───────────────────────────────────────────────────────────────
func refresh() -> void:
	_swap_from = -1
	_build_slots()
	if GameManager.party.size() > 0:
		_select_slot(0)
	else:
		_clear_summary()

# ── Construcción de slots ─────────────────────────────────────────────────────
func _build_slots() -> void:
	for btn in _slot_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_slot_buttons.clear()

	for i in GameManager.party.size():
		var c: CreatureInstance = GameManager.party[i]
		var entry = PokedexData.get_entry(c.creature_id)
		var creature_name = entry.get("name", "Nexo#%04d" % c.creature_id)
		var display = c.nickname if c.nickname != "" else creature_name
		var hp_pct  = float(c.hp_cur) / float(max(c.hp_max, 1))

		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 36)

		var style = StyleBoxFlat.new()
		var bg_col = Color(0.10, 0.10, 0.18)
		if c.hp_cur <= 0:
			bg_col = Color(0.15, 0.08, 0.08)
		style.bg_color = bg_col
		style.border_width_left   = 3
		style.border_width_top    = 1
		style.border_width_right  = 1
		style.border_width_bottom = 1
		style.border_color = _hp_color(hp_pct) if c.hp_cur > 0 else Color(0.5, 0.15, 0.15)
		style.corner_radius_top_left     = 4
		style.corner_radius_top_right    = 4
		style.corner_radius_bottom_left  = 4
		style.corner_radius_bottom_right = 4
		panel.add_theme_stylebox_override("panel", style)

		var vbox = VBoxContainer.new()
		panel.add_child(vbox)

		var top_row = HBoxContainer.new()
		vbox.add_child(top_row)

		var name_lbl = Label.new()
		name_lbl.text = display
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 11)
		var name_col = Color(1, 1, 1) if c.hp_cur > 0 else Color(0.5, 0.3, 0.3)
		name_lbl.add_theme_color_override("font_color", name_col)
		top_row.add_child(name_lbl)

		var lv_lbl = Label.new()
		lv_lbl.text = "Nv.%d" % c.level
		lv_lbl.add_theme_font_size_override("font_size", 9)
		lv_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
		top_row.add_child(lv_lbl)

		if c.hp_cur > 0:
			var hp_bar = ProgressBar.new()
			hp_bar.min_value = 0; hp_bar.max_value = c.hp_max; hp_bar.value = c.hp_cur
			hp_bar.show_percentage = false
			hp_bar.custom_minimum_size = Vector2(0, 5)
			vbox.add_child(hp_bar)
		else:
			var ko_lbl = Label.new()
			ko_lbl.text = "AGOTADO"
			ko_lbl.add_theme_font_size_override("font_size", 8)
			ko_lbl.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
			vbox.add_child(ko_lbl)

		var click_btn = Button.new()
		click_btn.flat = true
		click_btn.anchor_right  = 1.0
		click_btn.anchor_bottom = 1.0
		panel.add_child(click_btn)
		var idx = i
		click_btn.pressed.connect(func(): _select_slot(idx))

		slot_container.add_child(panel)
		_slot_buttons.append(panel)

func _select_slot(index: int) -> void:
	_selected_index = index

	# Highlight selected slot
	for i in _slot_buttons.size():
		var p = _slot_buttons[i] as PanelContainer
		if not is_instance_valid(p): continue
		var c_inst: CreatureInstance = GameManager.party[i]
		var hp_pct = float(c_inst.hp_cur) / float(max(c_inst.hp_max, 1))
		var style = p.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			if i == index:
				style.border_color = Color(1.0, 0.85, 0.25)
				style.border_width_left = 4
			else:
				style.border_color = _hp_color(hp_pct) if c_inst.hp_cur > 0 else Color(0.5, 0.15, 0.15)
				style.border_width_left = 3

	if index >= GameManager.party.size():
		_clear_summary()
		return

	_populate_summary(GameManager.party[index])

func _populate_summary(c: CreatureInstance) -> void:
	var entry = PokedexData.get_entry(c.creature_id)
	var creature_name = entry.get("name", "Nexo#%04d" % c.creature_id)

	summary_name.text  = creature_name
	summary_nick.text  = '"%s"' % c.nickname if c.nickname != "" else ""
	summary_level.text = "Nv. %d" % c.level

	# Esencia (tipo) en español
	var type1 = entry.get("type1", "Normal")
	var type2 = entry.get("type2", "")
	var es1 = PokedexData.esencia_es(type1)
	var es2 = PokedexData.esencia_es(type2) if type2 != "" else ""
	var type_str = es1 + (" / " + es2 if es2 != "" else "")
	_type_label.text = "Esencia: " + type_str

	# HP bar con color
	summary_hp_bar.min_value = 0
	summary_hp_bar.max_value = c.hp_max
	summary_hp_bar.value     = c.hp_cur
	var hp_pct = float(c.hp_cur) / float(max(c.hp_max, 1))
	summary_hp_txt.text = "%d / %d Aguante" % [c.hp_cur, c.hp_max]

	# Estado
	var st_txt = STATUS_LABELS.get(c.status, "")
	summary_status.text  = st_txt
	summary_status.add_theme_color_override("font_color", STATUS_COLORS.get(c.status, Color(1,1,1)))

	# Latido (vínculo emocional)
	var latido_val = c.bond  # 0-100
	var latido_idx = _bond_to_latido_idx(latido_val)
	_latido_label.text = "Latido: " + LATIDO_NAMES[latido_idx]
	_latido_label.add_theme_color_override("font_color", LATIDO_COLORS[latido_idx])
	_bond_bar.value = latido_val

	# Botones
	btn_stats.disabled = false
	btn_swap.text = "Mover lugar" if _swap_from < 0 else "Colocar aquí"
	btn_heal.disabled = c.hp_cur >= c.hp_max or c.hp_cur <= 0
	btn_heal.text = "Curar (Suero)" if InventorySystem.has_item("potion") else "Sin sueros"

	# Despertar
	var puede_desp = DespertarSystem.puede_despertar(c)
	if _despertar_btn:
		_despertar_btn.visible = puede_desp
		if puede_desp:
			var nom_dest = DespertarSystem.nombre_destino(c.creature_id)
			_despertar_btn.text = "✦ ¡Despertar → %s!" % nom_dest

	summary_sprite.texture = null  # Se asignará cuando existan sprites

func _clear_summary() -> void:
	summary_name.text  = "Equipo vacío"
	summary_nick.text  = ""
	summary_level.text = ""
	summary_hp_bar.value = 0
	summary_hp_txt.text  = ""
	summary_status.text  = ""
	if _type_label:      _type_label.text    = ""
	if _latido_label:    _latido_label.text  = ""
	if _bond_bar:        _bond_bar.value     = 0
	if _despertar_btn:   _despertar_btn.visible = false
	summary_sprite.texture = null
	btn_stats.disabled = true
	btn_heal.disabled  = true

# ── Botones ───────────────────────────────────────────────────────────────────
func _on_btn_stats() -> void:
	if _selected_index >= GameManager.party.size():
		return
	if not ResourceLoader.exists(STATS_SCENE_PATH):
		return
	var stats_packed = load(STATS_SCENE_PATH)
	var stats_node = stats_packed.instantiate()
	# Añadir como CanvasLayer sobre todo
	get_tree().root.add_child(stats_node)
	if stats_node.has_method("show_creature"):
		stats_node.show_creature(GameManager.party[_selected_index])

func _on_btn_swap() -> void:
	if GameManager.party.size() < 2:
		return
	if _swap_from < 0:
		# Iniciar intercambio
		_swap_from = _selected_index
		btn_swap.text = "Cancelar"
	elif _swap_from == _selected_index:
		# Cancelar
		_swap_from = -1
		btn_swap.text = "Mover lugar"
	else:
		# Ejecutar intercambio
		var tmp = GameManager.party[_swap_from]
		GameManager.party[_swap_from] = GameManager.party[_selected_index]
		GameManager.party[_selected_index] = tmp
		_swap_from = -1
		_build_slots()
		_select_slot(_selected_index)

func _on_btn_heal() -> void:
	if _selected_index >= GameManager.party.size():
		return
	var creature = GameManager.party[_selected_index]
	var old_hp = creature.hp_cur
	var msg = InventorySystem.use_item("potion", creature)
	if creature.hp_cur > old_hp:
		# Curación exitosa — mejorar Latido y registrar Huella
		GameManager.latido_curar(_selected_index)
		creature.bond = clamp(creature.bond + 3, 0, 100)
	summary_hp_bar.value = creature.hp_cur
	summary_hp_txt.text  = "%d / %d Aguante" % [creature.hp_cur, creature.hp_max]
	btn_heal.text = "Curar (Suero)" if InventorySystem.has_item("potion") else "Sin sueros"
	btn_heal.disabled = creature.hp_cur >= creature.hp_max or creature.hp_cur <= 0
	# Actualizar slot bar
	_build_slots()
	_select_slot(_selected_index)
	print("PartyScreen: %s" % msg)

func _on_btn_despertar() -> void:
	if _selected_index >= GameManager.party.size():
		return
	var c: CreatureInstance = GameManager.party[_selected_index]
	if not DespertarSystem.puede_despertar(c):
		return

	var msg = DespertarSystem.mensaje_despertar(c.creature_id)
	print("PartyScreen: %s" % msg)

	var nueva = DespertarSystem.despertar(c, PokedexData)
	GameManager.party[_selected_index] = nueva

	# Efecto visual simple: título temporal
	var popup = Label.new()
	popup.text = msg
	popup.add_theme_font_size_override("font_size", 11)
	popup.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	get_tree().root.add_child(popup)

	var tween = get_tree().root.create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(popup.queue_free)

	_build_slots()
	_select_slot(_selected_index)

# ── Utilidades ────────────────────────────────────────────────────────────────
func _hp_color(pct: float) -> Color:
	if pct > 0.5: return Color(0.2, 0.85, 0.3)
	if pct > 0.2: return Color(0.95, 0.80, 0.1)
	return Color(0.9, 0.2, 0.2)

func _bond_to_latido_idx(bond: int) -> int:
	if bond >= 80: return 0  # RESONANTE
	if bond >= 50: return 1  # ESTABLE
	if bond >= 20: return 2  # TENSO
	return 3                 # ROTO
