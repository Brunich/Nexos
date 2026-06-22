## SaveScreen — Pantalla de guardado con 3 ranuras manuales + autosave
## Construye su UI en _ready() vía código. No requiere nodos hijos en .tscn.
extends Control

var _slot_info_labels: Array = []
var _status_label: Label = null
var _auto_info_label: Label = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

func refresh() -> void:
	_refresh_data()

func _build_ui() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# Título
	var hdr = Label.new()
	hdr.text = "Guardar Partida"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	vbox.add_child(HSeparator.new())

	# Info del jugador actual
	var current_info = Label.new()
	current_info.add_theme_font_size_override("font_size", 9)
	current_info.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	var tonales_str = "%d Nexo%s" % [GameManager.party.size(), "s" if GameManager.party.size() != 1 else ""]
	var huella_str = ""
	if GameManager.huella:
		huella_str = "  ·  Huella: " + GameManager.huella.nombre(GameManager.huella.tipo_dominante())
	current_info.text = "Guía: %s  ·  %s  ·  %s%s  ·  ₱%d" % [
		GameManager.player_name,
		GameManager.get_playtime_string(),
		tonales_str,
		huella_str,
		GameManager.money
	]
	vbox.add_child(current_info)

	vbox.add_child(HSeparator.new())

	# 3 ranuras manuales
	for i in 3:
		_build_slot_row(vbox, i + 1)

	vbox.add_child(HSeparator.new())

	# Sección autosave
	var auto_hdr = Label.new()
	auto_hdr.text = "Autoguardado"
	auto_hdr.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	auto_hdr.add_theme_font_size_override("font_size", 10)
	vbox.add_child(auto_hdr)

	_auto_info_label = Label.new()
	_auto_info_label.text = "Sin autoguardado"
	_auto_info_label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(_auto_info_label)

	# Feedback de estado
	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.text = ""
	vbox.add_child(_status_label)

	_refresh_data()

func _build_slot_row(parent: VBoxContainer, slot: int) -> void:
	var panel = PanelContainer.new()
	parent.add_child(panel)

	var inner = HBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	panel.add_child(inner)

	var text_col = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(text_col)

	var slot_lbl = Label.new()
	slot_lbl.text = "Ranura %d" % slot
	slot_lbl.add_theme_font_size_override("font_size", 10)
	slot_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	text_col.add_child(slot_lbl)

	var info = Label.new()
	info.text = "— Vacía —"
	info.add_theme_font_size_override("font_size", 9)
	text_col.add_child(info)
	_slot_info_labels.append(info)

	var save_btn = Button.new()
	save_btn.text = "Guardar"
	var s = slot
	save_btn.pressed.connect(func(): _on_save(s))
	inner.add_child(save_btn)

func _refresh_data() -> void:
	if _slot_info_labels.size() < 3:
		return

	# Actualizar info del jugador si el label existe
	var scroll = get_node_or_null("ScrollContainer")
	if scroll:
		var vbox = scroll.get_node_or_null("VBoxContainer")
		if vbox and vbox.get_child_count() > 2:
			var current_info = vbox.get_child(2)
			if current_info is Label:
				current_info.text = "Jugador: %s  |  Tiempo: %s  |  $%d" % [
					GameManager.player_name,
					GameManager.get_playtime_string(),
					GameManager.money
				]

	for i in 3:
		var slot = i + 1
		if SaveSystem.slot_exists(slot):
			var si = SaveSystem.get_slot_info(slot)
			_slot_info_labels[i].text = "%s  %s\n%s" % [
				si.get("player_name", "???"),
				si.get("playtime", "00:00"),
				si.get("timestamp", "").substr(0, 10)
			]
		else:
			_slot_info_labels[i].text = "— Vacía —"

	if _auto_info_label:
		if SaveSystem.auto_exists():
			var ai = SaveSystem.get_auto_info()
			_auto_info_label.text = "%s  %s  |  %s" % [
				ai.get("player_name", "???"),
				ai.get("playtime", "00:00"),
				ai.get("timestamp", "").substr(0, 10)
			]
		else:
			_auto_info_label.text = "Sin autoguardado"

func _on_save(slot: int) -> void:
	if GameManager.party.is_empty():
		_status_label.text = "¡Empieza tu aventura antes de guardar!"
		return
	var ok = SaveSystem.save_slot(GameManager, slot)
	_status_label.text = ("¡Guardado en Ranura %d!" % slot) if ok else "Error al guardar."
	_refresh_data()
	# Desvanecer el mensaje después de 2s
	var tween = create_tween()
	tween.tween_property(_status_label, "modulate:a", 0.0, 1.0).set_delay(1.5)
	tween.tween_callback(func():
		_status_label.modulate.a = 1.0
		_status_label.text = ""
	)
