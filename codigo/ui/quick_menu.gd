## QuickMenu — Menú rápido activado con la tecla T
## Muestra 5 opciones en un panel compacto centrado.
## T/Esc para abrir/cerrar. ↑↓ para navegar, Enter/Z para confirmar.
## Opciones: Cambios · Bolsa · NEXODEX · Guardar · Ajustes
extends CanvasLayer

const BoxScreen = preload("res://codigo/ui/box_screen.gd")

# ── Opciones ──────────────────────────────────────────────────────────────────
const OPTIONS = [
	{ "label": "Cambios",        "icon": "⚔" },
	{ "label": "Bolsa",          "icon": "◉" },
	{ "label": "NEXODEX",        "icon": "◈" },
	{ "label": "Guardar",        "icon": "◉" },
	{ "label": "Ajustes",        "icon": "≡" },
]

const COLOR_BG       = Color(0.05, 0.05, 0.12, 0.96)
const COLOR_SELECTED = Color(0.20, 0.18, 0.05)
const COLOR_BORDER_SEL = Color(1.0, 0.85, 0.2)
const COLOR_BORDER_NRM = Color(0.28, 0.28, 0.45)
const COLOR_TITLE    = Color(1.0, 0.85, 0.3)
const COLOR_HINT     = Color(0.35, 0.35, 0.55)

# ── Estado ────────────────────────────────────────────────────────────────────
var _is_open:      bool    = false
var _selected:     int     = 0
var _in_sub:       bool    = false   # Estamos en una sub-pantalla (Lugares)
var _sub_screen:   Control = null

# ── Nodos de la lista ─────────────────────────────────────────────────────────
var _root_panel:   PanelContainer = null
var _option_rows:  Array          = []   # Array de PanelContainer (una por opción)
var _option_lbls:  Array          = []   # Labels de texto
var _status_lbl:   Label          = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	set_process_unhandled_input(true)
	visible = false
	add_to_group("quick_menu")
	_build_ui()

# ── Construcción de UI (lista de opciones) ────────────────────────────────────
func _build_ui() -> void:
	# Fondo semi-transparente que cubre la pantalla
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.45)
	bg.name  = "bg"
	add_child(bg)

	# Panel central compacto — 150 × 120 px centrado en 320×192
	_root_panel = PanelContainer.new()
	_root_panel.anchor_left   = 0.5
	_root_panel.anchor_top    = 0.5
	_root_panel.anchor_right  = 0.5
	_root_panel.anchor_bottom = 0.5
	_root_panel.offset_left   = -75.0
	_root_panel.offset_top    = -62.0
	_root_panel.offset_right  =  75.0
	_root_panel.offset_bottom =  62.0

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color     = COLOR_BG
	bg_style.border_color = Color(0.4, 0.35, 0.65)
	bg_style.border_width_top    = 2
	bg_style.border_width_bottom = 2
	bg_style.border_width_left   = 2
	bg_style.border_width_right  = 2
	bg_style.corner_radius_top_left     = 6
	bg_style.corner_radius_top_right    = 6
	bg_style.corner_radius_bottom_left  = 6
	bg_style.corner_radius_bottom_right = 6
	_root_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(_root_panel)

	var outer = MarginContainer.new()
	outer.add_theme_constant_override("margin_left",  6)
	outer.add_theme_constant_override("margin_right", 6)
	outer.add_theme_constant_override("margin_top",   5)
	outer.add_theme_constant_override("margin_bottom",5)
	_root_panel.add_child(outer)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	outer.add_child(vbox)

	# ── Título ────────────────────────────────────────────────────────────────
	var title = Label.new()
	title.text = "NEXOS"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 1)
	sep.modulate = Color(0.35, 0.30, 0.60)
	vbox.add_child(sep)

	# ── Filas de opciones ─────────────────────────────────────────────────────
	_option_rows.clear()
	_option_lbls.clear()
	for i in OPTIONS.size():
		var opt = OPTIONS[i]
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 18)

		var row_style = _make_row_style(false)
		row.add_theme_stylebox_override("panel", row_style)

		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 4)
		row.add_child(hb)

		var icon_lbl = Label.new()
		icon_lbl.text = opt["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 9)
		icon_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.85))
		icon_lbl.custom_minimum_size = Vector2(12, 0)
		hb.add_child(icon_lbl)

		var text_lbl = Label.new()
		text_lbl.text = opt["label"]
		text_lbl.add_theme_font_size_override("font_size", 9)
		text_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(text_lbl)

		# Click
		var btn = Button.new()
		btn.flat = true
		btn.anchor_right  = 1.0
		btn.anchor_bottom = 1.0
		row.add_child(btn)
		var ci = i
		btn.pressed.connect(func(): _select_and_confirm(ci))

		vbox.add_child(row)
		_option_rows.append(row)
		_option_lbls.append(text_lbl)

	# ── Separador + pista ─────────────────────────────────────────────────────
	var sep2 = HSeparator.new()
	sep2.add_theme_constant_override("separation", 1)
	sep2.modulate = Color(0.35, 0.30, 0.60)
	vbox.add_child(sep2)

	_status_lbl = Label.new()
	_status_lbl.text = "↑↓ navegar  Enter confirmar  T/Esc cerrar"
	_status_lbl.add_theme_font_size_override("font_size", 7)
	_status_lbl.add_theme_color_override("font_color", COLOR_HINT)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_lbl)

func _make_row_style(selected: bool) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color     = COLOR_SELECTED if selected else Color(0, 0, 0, 0)
	s.border_color = COLOR_BORDER_SEL if selected else Color(0, 0, 0, 0)
	s.border_width_left   = 2 if selected else 0
	s.border_width_right  = 0
	s.border_width_top    = 0
	s.border_width_bottom = 0
	s.corner_radius_top_left     = 3
	s.corner_radius_top_right    = 3
	s.corner_radius_bottom_left  = 3
	s.corner_radius_bottom_right = 3
	return s

# ── Abrir / Cerrar ────────────────────────────────────────────────────────────
func _open() -> void:
	_is_open = true
	_in_sub  = false
	visible  = true
	GameManager.dialogue_active = true
	_select(_selected)

func _close() -> void:
	_is_open = false
	visible  = false
	if not _in_sub:
		GameManager.dialogue_active = false
	_in_sub = false

func toggle_menu() -> void:
	if _in_sub:
		_close_sub()
		return
	if _is_open:
		_close()
	elif not GameManager.dialogue_active:
		_open()

func is_open() -> bool:
	return _is_open

func _close_sub() -> void:
	if _sub_screen:
		_sub_screen.queue_free()
		_sub_screen = null
	_root_panel.visible = true
	_in_sub = false
	_select(_selected)

# ── Navegación ────────────────────────────────────────────────────────────────
func _select(index: int) -> void:
	_selected = index
	for i in _option_rows.size():
		_option_rows[i].add_theme_stylebox_override("panel", _make_row_style(i == index))
		var lbl = _option_lbls[i]
		lbl.add_theme_color_override("font_color",
			COLOR_TITLE if i == index else Color(0.9, 0.9, 0.9))

func _select_and_confirm(index: int) -> void:
	_select(index)
	_confirm()

func _confirm() -> void:
	match _selected:
		0:  # Cambios / Almacén
			_open_box_screen()
		1:  # Bolsa
			_open_game_menu(1)
		2:  # Nexodex
			_open_game_menu(2)
		3:  # Guardar
			_open_game_menu(3)
		4:  # Ajustes
			_open_game_menu(4)

# ── Acciones específicas ──────────────────────────────────────────────────────
func _open_game_menu(tab: int) -> void:
	_close()
	await get_tree().process_frame
	var gm = get_tree().get_first_node_in_group("game_menu")
	if gm and gm.has_method("open_on_tab"):
		gm.open_on_tab(tab)
	else:
		push_warning("QuickMenu: no se encontró game_menu en el árbol")

func _open_box_screen() -> void:
	_root_panel.visible = false
	_in_sub = true

	_sub_screen = BoxScreen.new()
	_sub_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_sub_screen)
	_sub_screen.closed.connect(_close_sub)

func _do_quick_save() -> void:
	if GameManager.party.is_empty():
		_show_status("Empieza tu aventura primero.")
		return
	var ok = SaveSystem.save_slot(GameManager, 1)
	if ok:
		_show_status("¡Guardado en Ranura 1!")
		await get_tree().create_timer(1.2).timeout
		_close()
	else:
		_show_status("Error al guardar.")

func _show_status(text: String) -> void:
	if _status_lbl:
		_status_lbl.text = text
		_status_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	await get_tree().create_timer(1.5).timeout
	if _status_lbl and is_inside_tree():
		_status_lbl.text = "↑↓ navegar  Enter confirmar  T/Esc cerrar"
		_status_lbl.add_theme_color_override("font_color", COLOR_HINT)

func _is_raw_shortcut(event: InputEvent, physical_key: Key, unicode_char: String) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	if key_event.physical_keycode == physical_key:
		return true
	return unicode_char != "" and key_event.unicode == unicode_char.unicode_at(0)

func _handle_input(event: InputEvent) -> bool:
	if not _is_open or _in_sub:
		return false

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
		return true
	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_select((_selected - 1 + OPTIONS.size()) % OPTIONS.size())
		return true
	if event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_select((_selected + 1) % OPTIONS.size())
		return true
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_confirm()
		return true

	return false

# ── Input ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	_handle_input(event)

func _shortcut_input(event: InputEvent) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	pass
