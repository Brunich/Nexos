## ItemsScreen — Pantalla de bolsa / inventario con Ofrendas y objetos
## Construye su UI en código. Muestra categorías, descripción y botón Usar.
extends Control

# ── Categorías ────────────────────────────────────────────────────────────────
const CAT_ALL      = -1
const CAT_HEALING  = 0   # InventorySystem.ItemCategory.HEALING
const CAT_BATTLE   = 1   # InventorySystem.ItemCategory.BATTLE
const CAT_KEY      = 2   # InventorySystem.ItemCategory.KEY

const CAT_NAMES = {
	CAT_ALL:     "Todo",
	CAT_HEALING: "Sanación",
	CAT_BATTLE:  "Cápsulas",
	CAT_KEY:     "Especiales",
}

# ── Nodos creados en código ───────────────────────────────────────────────────
var _cat_buttons:    Array  = []
var _item_panels:    Array  = []
var _scroll:         ScrollContainer = null
var _list_container: VBoxContainer   = null
var _detail_panel:   PanelContainer  = null
var _detail_name:    Label  = null
var _detail_desc:    Label  = null
var _detail_qty:     Label  = null
var _use_btn:        Button = null
var _money_lbl:      Label  = null

var _current_cat:   int    = CAT_ALL
var _selected_item: String = ""

# ── Para el selector de Tonal ─────────────────────────────────────────────────
var _party_popup:   PanelContainer  = null
var _party_vbox:    VBoxContainer   = null

const PokedexData = preload("res://codigo/datos/pokedex_data.gd")

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Root margin
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   4)
	margin.add_theme_constant_override("margin_right",  4)
	margin.add_theme_constant_override("margin_top",    4)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(root_vbox)

	# ── Top bar: título + dinero ─────────────────────────────────────────────
	var top_row = HBoxContainer.new()
	root_vbox.add_child(top_row)

	var title_lbl = Label.new()
	title_lbl.text = "BOLSA"
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title_lbl)

	_money_lbl = Label.new()
	_money_lbl.add_theme_font_size_override("font_size", 10)
	_money_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	top_row.add_child(_money_lbl)

	# ── Filtro de categorías ─────────────────────────────────────────────────
	var cat_row = HBoxContainer.new()
	cat_row.add_theme_constant_override("separation", 3)
	cat_row.custom_minimum_size = Vector2(0, 24)
	root_vbox.add_child(cat_row)

	for cat_id in [CAT_ALL, CAT_HEALING, CAT_BATTLE, CAT_KEY]:
		var btn = Button.new()
		btn.text = CAT_NAMES[cat_id]
		btn.toggle_mode = true
		btn.button_pressed = (cat_id == _current_cat)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 9)
		var cid = cat_id
		btn.pressed.connect(func(): _filter_category(cid))
		cat_row.add_child(btn)
		_cat_buttons.append(btn)

	# ── Split: lista (izq) + detalles (der) ─────────────────────────────────
	var split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 90
	root_vbox.add_child(split)

	# Lista scroll
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	split.add_child(_scroll)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.add_theme_constant_override("separation", 3)
	_scroll.add_child(_list_container)

	# Panel de detalles
	_detail_panel = PanelContainer.new()
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_panel.custom_minimum_size = Vector2(96, 0)

	var dp_style = StyleBoxFlat.new()
	dp_style.bg_color    = Color(0.08, 0.08, 0.14)
	dp_style.border_color = Color(0.25, 0.25, 0.45)
	dp_style.border_width_left   = 2
	dp_style.border_width_top    = 2
	dp_style.border_width_right  = 2
	dp_style.border_width_bottom = 2
	dp_style.corner_radius_top_left     = 6
	dp_style.corner_radius_top_right    = 6
	dp_style.corner_radius_bottom_left  = 6
	dp_style.corner_radius_bottom_right = 6
	_detail_panel.add_theme_stylebox_override("panel", dp_style)
	split.add_child(_detail_panel)

	var dp_margin = MarginContainer.new()
	dp_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	dp_margin.add_theme_constant_override("margin_left",   6)
	dp_margin.add_theme_constant_override("margin_right",  6)
	dp_margin.add_theme_constant_override("margin_top",    6)
	dp_margin.add_theme_constant_override("margin_bottom", 6)
	_detail_panel.add_child(dp_margin)

	var dp_vbox = VBoxContainer.new()
	dp_vbox.add_theme_constant_override("separation", 5)
	dp_margin.add_child(dp_vbox)

	_detail_name = Label.new()
	_detail_name.text = "Selecciona\nun objeto"
	_detail_name.add_theme_font_size_override("font_size", 10)
	_detail_name.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dp_vbox.add_child(_detail_name)

	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.add_theme_font_size_override("font_size", 9)
	_detail_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dp_vbox.add_child(_detail_desc)

	_detail_qty = Label.new()
	_detail_qty.add_theme_font_size_override("font_size", 9)
	_detail_qty.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	dp_vbox.add_child(_detail_qty)

	_use_btn = Button.new()
	_use_btn.text = "Usar"
	_use_btn.disabled = true
	_use_btn.add_theme_font_size_override("font_size", 10)
	_use_btn.pressed.connect(_on_use_pressed)
	dp_vbox.add_child(_use_btn)

func refresh() -> void:
	_money_lbl.text = "₱ %d" % GameManager.money
	_filter_category(_current_cat)
	_selected_item = ""
	_detail_name.text = "Selecciona\nun objeto"
	_detail_desc.text = ""
	_detail_qty.text  = ""
	_use_btn.disabled = true

# ── Filtrar lista ─────────────────────────────────────────────────────────────
func _filter_category(cat: int) -> void:
	_current_cat = cat

	for i in _cat_buttons.size():
		var cats = [CAT_ALL, CAT_HEALING, CAT_BATTLE, CAT_KEY]
		_cat_buttons[i].button_pressed = (cats[i] == cat)

	for p in _item_panels:
		if is_instance_valid(p): p.queue_free()
	_item_panels.clear()

	var inv = InventorySystem.inventory
	if inv.is_empty():
		var lbl = Label.new()
		lbl.text = "Bolsa vacía."
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_list_container.add_child(lbl)
		_item_panels.append(lbl)
		return

	var shown = false
	for item_id in inv.keys():
		var data: Dictionary = InventorySystem.ITEMS.get(item_id, {})
		if data.is_empty(): continue
		if cat != CAT_ALL and data.get("category", -1) != cat: continue
		shown = true
		_add_item_row(item_id, inv[item_id], data)

	if not shown:
		var lbl = Label.new()
		lbl.text = "Nada en esta categoría."
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_list_container.add_child(lbl)
		_item_panels.append(lbl)

func _add_item_row(item_id: String, qty: int, data: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 28)

	var is_sel = (item_id == _selected_item)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25) if is_sel else Color(0.10, 0.10, 0.18)
	style.border_width_left  = 2 if is_sel else 0
	style.border_color = Color(1.0, 0.85, 0.25)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var name_lbl = Label.new()
	name_lbl.text = data.get("name", item_id)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 10)
	hbox.add_child(name_lbl)

	var qty_lbl = Label.new()
	qty_lbl.text = "×%d" % qty
	qty_lbl.add_theme_font_size_override("font_size", 10)
	qty_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	qty_lbl.custom_minimum_size = Vector2(28, 0)
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(qty_lbl)

	var click = Button.new()
	click.flat = true
	click.anchor_right  = 1.0
	click.anchor_bottom = 1.0
	panel.add_child(click)
	var iid = item_id
	click.pressed.connect(func(): _select_item(iid))

	_list_container.add_child(panel)
	_item_panels.append(panel)

func _select_item(item_id: String) -> void:
	_selected_item = item_id
	var data: Dictionary = InventorySystem.ITEMS.get(item_id, {})
	_detail_name.text = data.get("name", item_id)
	_detail_desc.text = data.get("desc", "")
	var qty = InventorySystem.get_quantity(item_id)
	_detail_qty.text  = "Cantidad: %d" % qty

	# Solo habilitar Usar para objetos de sanación (no de captura en overworld)
	var cat = data.get("category", -1)
	_use_btn.disabled = (cat != InventorySystem.ItemCategory.HEALING) or qty <= 0
	if cat == InventorySystem.ItemCategory.BATTLE:
		_use_btn.text = "Solo en batalla"
	elif cat == InventorySystem.ItemCategory.KEY:
		_use_btn.text = "Objeto clave"
	else:
		_use_btn.text = "Usar"

	# Rebuild list to highlight selection
	_filter_category(_current_cat)

# ── Usar objeto → selección de Tonal ─────────────────────────────────────────
func _on_use_pressed() -> void:
	if _selected_item == "" or GameManager.party.is_empty():
		return
	_show_party_popup()

func _show_party_popup() -> void:
	if _party_popup:
		_party_popup.queue_free()

	_party_popup = PanelContainer.new()
	_party_popup.set_anchors_preset(Control.PRESET_CENTER)
	_party_popup.custom_minimum_size = Vector2(180, 0)

	var style = StyleBoxFlat.new()
	style.bg_color    = Color(0.06, 0.06, 0.12, 0.97)
	style.border_color = Color(0.5, 0.4, 0.0)
	style.border_width_left = 2; style.border_width_top = 2
	style.border_width_right = 2; style.border_width_bottom = 2
	style.corner_radius_top_left     = 6; style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6; style.corner_radius_bottom_right = 6
	_party_popup.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(vbox)
	_party_popup.add_child(margin)

	var title = Label.new()
	title.text = "¿Con quién usar\n" + InventorySystem.ITEMS[_selected_item].get("name","") + "?"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	for i in GameManager.party.size():
		var c: CreatureInstance = GameManager.party[i]
		var entry = PokedexData.get_entry(c.creature_id)
		var name_str = c.nickname if c.nickname != "" else entry.get("name", "Nexo#%04d" % c.creature_id)
		var can_use = InventorySystem.can_use_item_on(_selected_item, c)
		var btn = Button.new()
		btn.text = "%s  %d/%d HP" % [name_str, c.hp_cur, c.hp_max]
		btn.disabled = not can_use
		btn.add_theme_font_size_override("font_size", 10)
		var idx = i
		btn.pressed.connect(func(): _use_on_party(idx))
		vbox.add_child(btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.add_theme_font_size_override("font_size", 10)
	cancel_btn.pressed.connect(func(): _party_popup.queue_free(); _party_popup = null)
	vbox.add_child(cancel_btn)

	add_child(_party_popup)

func _use_on_party(index: int) -> void:
	if index >= GameManager.party.size(): return
	var creature = GameManager.party[index]
	var msg = InventorySystem.use_item(_selected_item, creature)
	print("ItemsScreen: %s" % msg)
	if _party_popup:
		_party_popup.queue_free()
		_party_popup = null
	# Refrescar
	_money_lbl.text = "₱ %d" % GameManager.money
	var qty = InventorySystem.get_quantity(_selected_item)
	_detail_qty.text = "Cantidad: %d" % qty
	_use_btn.disabled = qty <= 0
	_filter_category(_current_cat)
