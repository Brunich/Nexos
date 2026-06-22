## SettingsScreen — Pantalla de configuración del juego
## Construye su UI en _ready() vía código. Lee/guarda mediante GameOptions autoload.
extends Control

var _widgets: Dictionary = {}

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

func refresh() -> void:
	_sync_from_options()

func _build_ui() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	_section(vbox, "— Experiencia de Juego —")
	_option_select(vbox, "Velocidad de texto", "text_speed", ["Lenta", "Normal", "Rápida", "Instantánea"])
	_option_toggle(vbox, "Animaciones de batalla", "battle_animations")
	_option_toggle(vbox, "Mostrar números de daño", "show_damage_nums")
	_option_toggle(vbox, "Mostrar Esencia efectiva (ayuda para novatos)", "show_type_hint")
	_option_toggle(vbox, "Mostrar PP de Artes en batalla", "show_move_pp")
	_option_toggle(vbox, "Mostrar estado de Latido en batalla", "show_bond_in_battle")

	_section(vbox, "— Audio —")
	_option_slider(vbox, "Volumen Música (BGM)", "bgm_volume")
	_option_slider(vbox, "Volumen Efectos (SFX)", "sfx_volume")
	_option_toggle(vbox, "Reducir música al hablar", "duck_bgm_dialogue")

	_section(vbox, "— Modos Especiales —")
	_option_toggle(vbox, "Modo Huella del Alma (sin guías de tipo)", "nuzlocke_mode")
	_option_toggle(vbox, "Modo Latido Frágil (nexos pueden desobedecer)", "hardcore_mode")
	_option_toggle(vbox, "Modo Códice Completo (ver todos los nexos)", "show_full_dex")

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var btn_save = Button.new()
	btn_save.text = "Guardar configuración"
	btn_save.pressed.connect(_on_save_pressed)
	vbox.add_child(btn_save)

	_sync_from_options()

# ── Helpers para construir filas de opciones ──────────────────────────────────

func _section(parent: VBoxContainer, title: String) -> void:
	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lbl.add_theme_font_size_override("font_size", 11)
	parent.add_child(lbl)

func _option_select(parent: VBoxContainer, lbl_text: String, key: String, options: Array) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = lbl_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(lbl)
	var opt = OptionButton.new()
	opt.add_theme_font_size_override("font_size", 10)
	for o in options:
		opt.add_item(o)
	opt.item_selected.connect(func(idx): _set_option(key, idx))
	row.add_child(opt)
	_widgets[key] = opt

func _option_toggle(parent: VBoxContainer, lbl_text: String, key: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = lbl_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(lbl)
	var chk = CheckButton.new()
	chk.toggled.connect(func(pressed): _set_option(key, pressed))
	row.add_child(chk)
	_widgets[key] = chk

func _option_slider(parent: VBoxContainer, lbl_text: String, key: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = lbl_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(lbl)
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(80, 0)
	slider.value_changed.connect(func(val): _set_option(key, val))
	row.add_child(slider)
	_widgets[key] = slider

# ── Sincronización con GameOptions ────────────────────────────────────────────

func _sync_from_options() -> void:
	if not _widgets.has("text_speed"):
		return
	(_widgets["text_speed"] as OptionButton).selected        = GameOptions.text_speed
	(_widgets["battle_animations"] as CheckButton).button_pressed = GameOptions.battle_animations
	(_widgets["show_damage_nums"] as CheckButton).button_pressed  = GameOptions.show_damage_nums
	(_widgets["show_type_hint"] as CheckButton).button_pressed    = GameOptions.show_type_hint
	(_widgets["show_move_pp"] as CheckButton).button_pressed      = GameOptions.show_move_pp
	(_widgets["bgm_volume"] as HSlider).value  = GameOptions.bgm_volume
	(_widgets["sfx_volume"] as HSlider).value  = GameOptions.sfx_volume
	(_widgets["nuzlocke_mode"] as CheckButton).button_pressed = GameOptions.nuzlocke_mode
	(_widgets["hardcore_mode"] as CheckButton).button_pressed = GameOptions.hardcore_mode

func _set_option(key: String, value) -> void:
	match key:
		"text_speed":        GameOptions.text_speed        = value
		"battle_animations": GameOptions.battle_animations = value
		"show_damage_nums":  GameOptions.show_damage_nums  = value
		"show_type_hint":    GameOptions.show_type_hint    = value
		"show_move_pp":      GameOptions.show_move_pp      = value
		"bgm_volume":        GameOptions.bgm_volume        = value
		"sfx_volume":        GameOptions.sfx_volume        = value
		"nuzlocke_mode":     GameOptions.nuzlocke_mode     = value
		"hardcore_mode":     GameOptions.hardcore_mode     = value

func _on_save_pressed() -> void:
	GameOptions.save_options()
