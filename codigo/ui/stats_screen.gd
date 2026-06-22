## StatsScreen — full creature detail view.
## Shows: sprite, name/level/type, all 6 base stats with animated bars,
## current moves with PP, EXP progress to next level, status condition.
class_name StatsScreen extends Control

const ExperienceSystem = preload("res://codigo/batalla/experience_system.gd")
const RuntimeTextureLoader = preload("res://codigo/util/runtime_texture_loader.gd")
const PokedexData = preload("res://codigo/datos/pokedex_data.gd")
const CreatureStatSystem = preload("res://codigo/sistemas/creature_stat_system.gd")

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var sprite_rect   : TextureRect  = $layout/left/sprite_rect
@onready var name_label    : Label        = $layout/left/name_label
@onready var nickname_lbl  : Label        = $layout/left/nickname_lbl
@onready var level_label   : Label        = $layout/left/level_label
@onready var type1_badge   : Label        = $layout/left/type_row/type1
@onready var type2_badge   : Label        = $layout/left/type_row/type2
@onready var status_badge  : Label        = $layout/left/status_badge
@onready var exp_bar       : ProgressBar  = $layout/left/exp_bar
@onready var exp_label     : Label        = $layout/left/exp_label
@onready var height_lbl    : Label        = $layout/left/flavor/height
@onready var weight_lbl    : Label        = $layout/left/flavor/weight
@onready var desc_label    : Label        = $layout/left/desc_label

@onready var stat_bars     : VBoxContainer = $layout/right/stats_panel/stat_bars
@onready var move_list     : VBoxContainer = $layout/right/moves_panel/move_list

@onready var btn_back      : Button = $layout/right/btn_back
@onready var btn_next_skin : Button = $layout/right/btn_next_skin
@onready var btn_move_up   : Button = $layout/right/btn_move_up
@onready var btn_move_down : Button = $layout/right/btn_move_down
@onready var move_hint_lbl : Label  = $layout/right/move_hint

# Labels añadidos en código
var _latido_lbl: Label = null
var _bond_bar:   ProgressBar = null

const MAX_BAR_STAT = 320.0   ## Barra suficiente para stats finales ya calculados

var _current_creature : CreatureInstance = null
var _selected_move_index : int = -1

# Stat display order and labels
const STAT_ORDER = [
	["HP",       "hp_max"],
	["Ataque",   "atk"],
	["Defensa",  "def"],
	["Atq. Esp", "sp_atk"],
	["Def. Esp", "sp_def"],
	["Velocidad","speed"],
]

# Stat bar colors
const STAT_COLORS = {
	"hp_max":  Color(0.25, 0.85, 0.25),
	"atk":     Color(0.95, 0.45, 0.15),
	"def":     Color(0.90, 0.80, 0.10),
	"sp_atk":  Color(0.40, 0.60, 1.00),
	"sp_def":  Color(0.40, 0.85, 0.85),
	"speed":   Color(0.95, 0.35, 0.70),
}

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	btn_back.pressed.connect(func(): hide())
	btn_next_skin.pressed.connect(_on_next_skin)
	btn_move_up.pressed.connect(_on_move_up_pressed)
	btn_move_down.pressed.connect(_on_move_down_pressed)

	# Agregar Latido display al panel izquierdo
	var left_panel = $layout/left
	_latido_lbl = Label.new()
	_latido_lbl.add_theme_font_size_override("font_size", 10)
	left_panel.add_child(_latido_lbl)

	_bond_bar = ProgressBar.new()
	_bond_bar.min_value = 0
	_bond_bar.max_value = 100
	_bond_bar.show_percentage = false
	_bond_bar.custom_minimum_size = Vector2(0, 6)
	left_panel.add_child(_bond_bar)

func show_creature(creature: CreatureInstance) -> void:
	_current_creature = creature
	_selected_move_index = -1
	_populate(creature)
	show()

func _populate(c: CreatureInstance) -> void:
	# ── Sprite ────────────────────────────────────────────────────────────
	var skin := c.active_skin
	var tex: Texture2D = null
	if skin != "" and skin != "default":
		var alt_path := "res://Sprites_Nexos/%s_%s.png" % [str(c.creature_id), skin]
		tex = RuntimeTextureLoader.load_texture(alt_path)
	if tex == null:
		tex = RuntimeTextureLoader.load_nexo_sprite_by_id(int(c.creature_id))
	sprite_rect.texture = tex

	# ── Name / level / type ───────────────────────────────────────────────
	var entry = PokedexData.get_entry(c.creature_id)
	name_label.text   = entry.get("name", "Nexo#%04d" % c.creature_id)
	nickname_lbl.text = '"%s"' % c.nickname if c.nickname != "" else ""
	level_label.text  = "Lv. %d" % c.level

	var type1 = entry.get("type1", "Normal")
	var type2 = entry.get("type2", "")
	_set_type_badge(type1_badge, type1)
	if type2 != "":
		_set_type_badge(type2_badge, type2)
		type2_badge.show()
	else:
		type2_badge.hide()

	# ── Status ────────────────────────────────────────────────────────────
	var status_map := {
		CreatureInstance.Status.NONE: "",
		CreatureInstance.Status.BURNED: "QMD",
		CreatureInstance.Status.PARALYZED: "PAR",
		CreatureInstance.Status.POISONED: "ENV",
		CreatureInstance.Status.BADLY_POISONED: "ENV+",
		CreatureInstance.Status.ASLEEP: "DOR",
		CreatureInstance.Status.FROZEN: "HLO",
	}
	var status_str: String = status_map.get(c.status, "")
	status_badge.text = status_str
	status_badge.visible = (status_str != "")

	# ── EXP bar ───────────────────────────────────────────────────────────
	var exp_progress := CreatureStatSystem.get_experience_progress(c.experience, c.level, c.creature_id)
	var exp_to_next := int(exp_progress.get("needed", 1))
	var exp_gained := int(exp_progress.get("earned", 0))
	exp_bar.max_value = exp_to_next
	exp_bar.value = clamp(exp_gained, 0, exp_to_next)
	exp_label.text = "EXP: %d / %d" % [exp_gained, exp_to_next]

	# ── Flavor text ───────────────────────────────────────────────────────
	if height_lbl: height_lbl.text = "Altura: %.1f m" % entry.get("height", 0.0)
	if weight_lbl: weight_lbl.text = "Peso: %.1f kg" % entry.get("weight", 0.0)
	if desc_label: desc_label.text = entry.get("description", "")

	# ── Latido (vínculo emocional) ────────────────────────────────────────────
	if _latido_lbl:
		var bond_val = c.bond
		var latido_names  = ["◈ Resonante", "● Estable", "◐ Tenso", "○ Roto"]
		var latido_colors = [Color(1.0,0.85,0.2), Color(0.3,0.85,0.4),
		                     Color(0.95,0.58,0.1), Color(0.9,0.2,0.2)]
		var li = 3
		if bond_val >= 80: li = 0
		elif bond_val >= 50: li = 1
		elif bond_val >= 20: li = 2
		_latido_lbl.text = "Latido: " + latido_names[li]
		_latido_lbl.add_theme_color_override("font_color", latido_colors[li])
		if _bond_bar: _bond_bar.value = bond_val

	# ── Stat bars ─────────────────────────────────────────────────────────
	for child in stat_bars.get_children():
		stat_bars.remove_child(child)
		child.queue_free()

	var total = 0
	var base_stats := CreatureStatSystem.get_base_stats(c.creature_id)
	for row in STAT_ORDER:
		var stat_name  = row[1]
		var stat_val   = c.get(stat_name) as int
		total         += stat_val
		var base_key: String = {
			"hp_max": "hp",
			"atk": "atk",
			"def": "def",
			"sp_atk": "spatk",
			"sp_def": "spdef",
			"speed": "spd",
		}.get(stat_name, "hp")
		var base_val := int(base_stats.get(base_key, stat_val))
		_add_stat_row(row[0], stat_val, base_val, STAT_COLORS.get(stat_name, Color(0.7,0.7,0.7)))

	_add_stat_row("Total", total, total, Color(0.85, 0.85, 0.85), true)

	# ── Move list ─────────────────────────────────────────────────────────
	for child in move_list.get_children():
		move_list.remove_child(child)
		child.queue_free()
	_selected_move_index = clamp(_selected_move_index, -1, c.moves.size() - 1)

	for i in c.moves.size():
		_add_move_row(i, c.moves[i], c.moves_pp[i])
	_refresh_move_controls()

func _add_stat_row(label: String, current: int, base_val: int,
                   color: Color, is_total: bool = false) -> void:
	var hbox = HBoxContainer.new()
	stat_bars.add_child(hbox)

	var lbl = Label.new()
	lbl.text                   = label
	lbl.custom_minimum_size    = Vector2(72, 0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hbox.add_child(lbl)

	var num_lbl = Label.new()
	num_lbl.text = str(current)
	num_lbl.custom_minimum_size = Vector2(36, 0)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num_lbl.add_theme_font_size_override("font_size", 11)
	num_lbl.add_theme_color_override("font_color", color)
	hbox.add_child(num_lbl)

	if not is_total:
		var bar = ProgressBar.new()
		bar.min_value     = 0
		bar.max_value     = MAX_BAR_STAT
		bar.value         = 0   # animated in
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(bar)

		# Animate fill
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(bar, "value", float(current), 0.5)

func _add_move_row(index: int, move: MoveData, pp: int) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 34)
	move_list.add_child(panel)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var type_badge = Label.new()
	type_badge.text = MoveData.Type.keys()[move.type]
	type_badge.custom_minimum_size = Vector2(68, 0)
	type_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_badge.add_theme_font_size_override("font_size", 10)
	var tc = PokedexData.type_color(MoveData.Type.keys()[move.type])
	type_badge.add_theme_color_override("font_color", tc)
	hbox.add_child(type_badge)

	var name_lbl = Label.new()
	name_lbl.text = move.move_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(name_lbl)

	var pwr_lbl = Label.new()
	pwr_lbl.text = "POT %d" % move.power if move.power > 0 else "Estado"
	pwr_lbl.add_theme_font_size_override("font_size", 10)
	pwr_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hbox.add_child(pwr_lbl)

	var pp_lbl = Label.new()
	pp_lbl.text = "PP %d/%d" % [pp, move.pp_max]
	pp_lbl.custom_minimum_size = Vector2(64, 0)
	pp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pp_lbl.add_theme_font_size_override("font_size", 10)
	var pp_color = Color(0.2, 0.8, 0.2) if pp > move.pp_max / 2 else \
	               Color(0.9, 0.7, 0.1) if pp > 0 else Color(0.9, 0.2, 0.2)
	pp_lbl.add_theme_color_override("font_color", pp_color)
	hbox.add_child(pp_lbl)

	var btn = Button.new()
	btn.flat = true
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	panel.add_child(btn)
	btn.pressed.connect(func(): _select_move(index))

	if index == _selected_move_index:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1.0, 0.82, 0.25, 0.18)
		style.border_color = Color(1.0, 0.82, 0.25)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", style)

# ── Skin cycling ──────────────────────────────────────────────────────────────
func _on_next_skin() -> void:
	if _current_creature == null: return
	var entry = PokedexData.get_entry(_current_creature.creature_id)
	# We don't store skins in CreatureInstance directly, just cycle "default"/"frost"/etc.
	_populate(_current_creature)

func _select_move(index: int) -> void:
	_selected_move_index = index
	_populate(_current_creature)

func _on_move_up_pressed() -> void:
	if _current_creature == null or _selected_move_index <= 0:
		return
	if _current_creature.swap_moves(_selected_move_index, _selected_move_index - 1):
		_selected_move_index -= 1
		move_hint_lbl.text = "Arte movido hacia arriba."
		_populate(_current_creature)

func _on_move_down_pressed() -> void:
	if _current_creature == null or _selected_move_index < 0 or _selected_move_index >= _current_creature.moves.size() - 1:
		return
	if _current_creature.swap_moves(_selected_move_index, _selected_move_index + 1):
		_selected_move_index += 1
		move_hint_lbl.text = "Arte movido hacia abajo."
		_populate(_current_creature)

func _refresh_move_controls() -> void:
	if _current_creature == null or _current_creature.moves.is_empty():
		move_hint_lbl.text = "Este nexo no tiene Artes aprendidos."
		btn_move_up.disabled = true
		btn_move_down.disabled = true
		return
	if _selected_move_index < 0 or _selected_move_index >= _current_creature.moves.size():
		move_hint_lbl.text = "Selecciona un Arte para moverlo."
		btn_move_up.disabled = true
		btn_move_down.disabled = true
		return
	var move_name: String = (_current_creature.moves[_selected_move_index] as MoveData).move_name
	move_hint_lbl.text = "Arte: %s" % move_name
	btn_move_up.disabled = _selected_move_index <= 0
	btn_move_down.disabled = _selected_move_index >= _current_creature.moves.size() - 1

func _input(event: InputEvent) -> void:
	if not visible or _current_creature == null:
		return
	if event.is_action_pressed("ui_cancel"):
		hide()
		accept_event()
		return
	if _current_creature.moves.is_empty():
		return
	if event.is_action_pressed("ui_down"):
		if _selected_move_index < 0:
			_selected_move_index = 0
		else:
			_selected_move_index = mini(_current_creature.moves.size() - 1, _selected_move_index + 1)
		_populate(_current_creature)
		accept_event()
	elif event.is_action_pressed("ui_up"):
		if _selected_move_index < 0:
			_selected_move_index = _current_creature.moves.size() - 1
		else:
			_selected_move_index = maxi(0, _selected_move_index - 1)
		_populate(_current_creature)
		accept_event()
	elif event.is_action_pressed("ui_left"):
		_on_move_up_pressed()
		accept_event()
	elif event.is_action_pressed("ui_right"):
		_on_move_down_pressed()
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		if _selected_move_index < 0:
			_selected_move_index = 0
			_populate(_current_creature)
		accept_event()

# ── EXP formula (simple cubic) ───────────────────────────────────────────────
func _exp_for_level(lvl: int) -> int:
	if _current_creature == null:
		return 0
	var growth_rate := ExperienceSystem.get_growth_rate(_current_creature.creature_id)
	return ExperienceSystem.exp_for_level(max(1, lvl), growth_rate)

func _set_type_badge(label: Label, type_name: String) -> void:
	label.text = PokedexData.esencia_es(type_name).to_upper()
	var col = PokedexData.type_color(type_name)
	label.add_theme_color_override("font_color", col)
