## BoxScreen — Cambios: gestión de equipo y caja de almacenamiento
## Construye su UI en código. Muestra equipo (hasta 6) + caja (ilimitada).
## Click en un nexo lo selecciona, click en otro slot lo intercambia.
extends Control

const RuntimeTextureLoader = preload("res://codigo/util/runtime_texture_loader.gd")
const PokedexData = preload("res://codigo/datos/pokedex_data.gd")

var _selected_source: String = ""   # "party" o "box"
var _selected_index:  int    = -1   # índice en el array

var _party_slots:  Array = []   # Array de PanelContainer (party)
var _box_slots:    Array = []   # Array de PanelContainer (box)

signal closed

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

func refresh() -> void:
	_clear_selection()
	_rebuild_slots()

# ── Construcción de UI ────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.12, 1.0)
	add_child(bg)

	var root = MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left",  4)
	root.add_theme_constant_override("margin_right", 4)
	root.add_theme_constant_override("margin_top",   4)
	root.add_theme_constant_override("margin_bottom",4)
	add_child(root)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	root.add_child(vbox)

	# ── Encabezado ────────────────────────────────────────────────────────────
	var hdr_row = HBoxContainer.new()
	vbox.add_child(hdr_row)

	var title = Label.new()
	title.text = "Cambios y Almacen"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_row.add_child(title)

	var hint = Label.new()
	hint.text = "[selecciona dos para intercambiar]"
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.6))
	hdr_row.add_child(hint)

	vbox.add_child(HSeparator.new())

	# ── Equipo ────────────────────────────────────────────────────────────────
	var party_lbl = Label.new()
	party_lbl.text = "Equipo"
	party_lbl.add_theme_font_size_override("font_size", 8)
	party_lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	vbox.add_child(party_lbl)

	var party_grid = GridContainer.new()
	party_grid.columns = 6
	party_grid.add_theme_constant_override("h_separation", 2)
	party_grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(party_grid)

	# Construir los 6 slots de equipo
	_party_slots.clear()
	for i in 6:
		var slot = _make_slot()
		party_grid.add_child(slot)
		_party_slots.append(slot)
		var ci = i
		var btn = slot.get_node("btn")
		btn.pressed.connect(func(): _on_slot_clicked("party", ci))

	vbox.add_child(HSeparator.new())

	# ── Caja de almacenamiento ─────────────────────────────────────────────────
	var box_lbl = Label.new()
	box_lbl.text = "Caja"
	box_lbl.add_theme_font_size_override("font_size", 8)
	box_lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	vbox.add_child(box_lbl)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var box_grid = GridContainer.new()
	box_grid.columns = 6
	box_grid.add_theme_constant_override("h_separation", 2)
	box_grid.add_theme_constant_override("v_separation", 2)
	box_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box_grid)

	# Construir slots de caja (máx 30)
	_box_slots.clear()
	var box_size : int = max(GameManager.storage_box.size(), 6)
	box_size = min(box_size, 30)
	for i in box_size:
		var slot = _make_slot()
		box_grid.add_child(slot)
		_box_slots.append(slot)
		var ci = i
		var btn = slot.get_node("btn")
		btn.pressed.connect(func(): _on_slot_clicked("box", ci))

	# ── Pie: botón cerrar ──────────────────────────────────────────────────────
	vbox.add_child(HSeparator.new())
	var close_btn = Button.new()
	close_btn.text = "Cerrar  [ Esc ]"
	close_btn.add_theme_font_size_override("font_size", 8)
	close_btn.pressed.connect(func(): closed.emit())
	vbox.add_child(close_btn)

	_rebuild_slots()

# ── Crear un slot vacío ────────────────────────────────────────────────────────
func _make_slot() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(46, 46)

	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.08, 0.08, 0.15)
	style.border_color = Color(0.25, 0.25, 0.40)
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	panel.add_theme_stylebox_override("panel", style)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	panel.add_child(vb)

	var sprite = TextureRect.new()
	sprite.name = "sprite"
	sprite.custom_minimum_size = Vector2(32, 32)
	sprite.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.expand_mode         = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(sprite)

	var name_lbl = Label.new()
	name_lbl.name = "name_lbl"
	name_lbl.text = "---"
	name_lbl.add_theme_font_size_override("font_size", 6)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	name_lbl.clip_text = true
	vb.add_child(name_lbl)

	# Botón invisible sobre todo el panel para capturar clicks
	var btn = Button.new()
	btn.name = "btn"
	btn.flat = true
	btn.anchor_right  = 1.0
	btn.anchor_bottom = 1.0
	panel.add_child(btn)

	return panel

# ── Rellenar slots con datos reales ───────────────────────────────────────────
func _rebuild_slots() -> void:
	for i in _party_slots.size():
		_fill_slot(_party_slots[i], GameManager.party, i)
	for i in _box_slots.size():
		_fill_slot(_box_slots[i], GameManager.storage_box, i)

func _fill_slot(panel: PanelContainer, arr: Array, index: int) -> void:
	var sprite   = panel.get_node("VBoxContainer/sprite")   as TextureRect
	var name_lbl = panel.get_node("VBoxContainer/name_lbl") as Label
	var style    = StyleBoxFlat.new()
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2

	if index < arr.size():
		var c = arr[index]
		var cid   : int    = c.creature_id if c is Object else c.get("creature_id", 0)
		var clv   : int    = c.level       if c is Object else c.get("level", 1)
		var cname : String = _creature_name(cid)
		name_lbl.text = "%s\nNv.%d" % [cname, clv]
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

		# Sprite
		var entry  = PokedexData.get_entry(cid)
		var sname  = entry.get("sprite", "")
		var tex : Texture2D = null
		if sname != "":
			tex = RuntimeTextureLoader.load_nexo_sprite_by_name(sname)
		if tex == null:
			tex = RuntimeTextureLoader.load_nexo_sprite_by_id(cid)
		sprite.texture  = tex
		sprite.modulate = Color(1, 1, 1)

		style.bg_color     = Color(0.08, 0.10, 0.20)
		style.border_color = Color(0.35, 0.35, 0.60)
	else:
		name_lbl.text = "---"
		name_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
		sprite.texture  = null
		sprite.modulate = Color(1, 1, 1, 0)
		style.bg_color     = Color(0.06, 0.06, 0.12)
		style.border_color = Color(0.20, 0.20, 0.30)

	panel.add_theme_stylebox_override("panel", style)

func _creature_name(cid: int) -> String:
	var entry = PokedexData.get_entry(cid)
	return entry.get("name", "Nexo#%04d" % cid)

# ── Selección e intercambio ───────────────────────────────────────────────────
func _on_slot_clicked(source: String, index: int) -> void:
	var arr : Array = GameManager.party if source == "party" else GameManager.storage_box

	if _selected_source == "" or _selected_index == -1:
		# Primera selección
		if index >= arr.size():
			return   # slot vacío como primera selección → ignorar
		_selected_source = source
		_selected_index  = index
		_highlight_selected(source, index)
	else:
		# Segunda selección → intercambiar
		_swap_creatures(_selected_source, _selected_index, source, index)
		_clear_selection()
		_rebuild_slots()

func _swap_creatures(s1: String, i1: int, s2: String, i2: int) -> void:
	var arr1 : Array = GameManager.party if s1 == "party" else GameManager.storage_box
	var arr2 : Array = GameManager.party if s2 == "party" else GameManager.storage_box

	# Validar
	if i1 >= arr1.size():
		return

	if i2 < arr2.size():
		# Swap con otro nexo existente
		var tmp = arr1[i1]
		arr1[i1] = arr2[i2]
		arr2[i2] = tmp
	else:
		# Mover a slot vacío
		if arr1 == arr2:
			return   # mismo array, slot vacío al final — mover
		arr2.append(arr1[i1])
		arr1.remove_at(i1)

	print("BoxScreen: intercambio %s[%d] ↔ %s[%d]" % [s1, i1, s2, i2])

func _highlight_selected(source: String, index: int) -> void:
	var slots = _party_slots if source == "party" else _box_slots
	if index < slots.size():
		var panel = slots[index]
		var style = StyleBoxFlat.new()
		style.bg_color     = Color(0.20, 0.18, 0.05)
		style.border_color = Color(1.0, 0.85, 0.2)
		style.border_width_top    = 2
		style.border_width_bottom = 2
		style.border_width_left   = 2
		style.border_width_right  = 2
		style.corner_radius_top_left = 2
		style.corner_radius_top_right = 2
		style.corner_radius_bottom_left = 2
		style.corner_radius_bottom_right = 2
		panel.add_theme_stylebox_override("panel", style)

func _clear_selection() -> void:
	_selected_source = ""
	_selected_index  = -1

# ── Input ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _selected_source != "":
			_clear_selection()
			_rebuild_slots()
		else:
			closed.emit()
