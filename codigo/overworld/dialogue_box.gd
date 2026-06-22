## DialogueBox — Caja de diálogo del overworld
## Adjunto al nodo Control interno de un CanvasLayer en las escenas de overworld.
## Maneja: mostrar texto paginado, avanzar, cerrar.
extends Control

var panel: PanelContainer = null
var label: RichTextLabel = null
var arrow: Label = null

var _pages: Array[String] = []
var _current_page: int = 0
var _is_visible: bool = false
var _typing_tween: Tween = null
var _full_text: String = ""
var _is_typing: bool = false

const CHARS_PER_SECOND: float = 40.0
const MAX_CHARS_PER_PAGE: int = 160

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui_if_missing()
	add_to_group("dialogue_box")
	panel.visible = false
	arrow.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _is_visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _is_typing:
			_skip_typing()
		else:
			advance()

# ── API pública ───────────────────────────────────────────────────────────────

## Mostrar un mensaje (puede ser largo; se pagina automáticamente)
func show_message(text: String, _speaker: String = "") -> void:
	_pages = _paginate(text)
	_current_page = 0
	_is_visible = true
	GameManager.dialogue_active = true
	panel.visible = true
	arrow.visible = false
	_show_page(_current_page)

## Avanzar a la siguiente página o cerrar si ya no hay más
func advance() -> void:
	_current_page += 1
	if _current_page < _pages.size():
		_show_page(_current_page)
	else:
		close()

## Cerrar la caja de diálogo
func close() -> void:
	if _typing_tween:
		_typing_tween.kill()
		_typing_tween = null
	panel.visible = false
	arrow.visible = false
	_is_visible = false
	_is_typing = false
	GameManager.dialogue_active = false

func is_active() -> bool:
	return _is_visible

# ── Paginación ────────────────────────────────────────────────────────────────
func _paginate(text: String) -> Array[String]:
	var pages: Array[String] = []
	var words = text.split(" ")
	var current = ""

	for word in words:
		var candidate = (current + " " + word).strip_edges()
		if candidate.length() <= MAX_CHARS_PER_PAGE:
			current = candidate
		else:
			if current != "":
				pages.append(current)
			current = word

	if current != "":
		pages.append(current)

	return pages if pages.size() > 0 else [""]

# ── Mostrar página con efecto de máquina de escribir ─────────────────────────
func _show_page(index: int) -> void:
	_full_text = _pages[index]
	label.text = ""
	arrow.visible = false
	_is_typing = true

	if _typing_tween:
		_typing_tween.kill()

	var total_chars = _full_text.length()
	var duration = total_chars / CHARS_PER_SECOND

	_typing_tween = create_tween()
	_typing_tween.tween_method(_set_visible_chars, 0, total_chars, duration)
	_typing_tween.tween_callback(_on_typing_done)

func _set_visible_chars(n: int) -> void:
	label.text = _full_text.substr(0, n)

func _on_typing_done() -> void:
	label.text = _full_text
	_is_typing = false
	arrow.visible = (_current_page < _pages.size() - 1) or true  # siempre mostrar "v" para continuar

func _skip_typing() -> void:
	if _typing_tween:
		_typing_tween.kill()
		_typing_tween = null
	label.text = _full_text
	_is_typing = false
	arrow.visible = true

func _build_ui_if_missing() -> void:
	panel = get_node_or_null("panel") as PanelContainer
	if panel == null:
		set_anchors_preset(Control.PRESET_FULL_RECT)

		panel = PanelContainer.new()
		panel.name = "panel"
		panel.anchor_left = 0.08
		panel.anchor_top = 0.72
		panel.anchor_right = 0.92
		panel.anchor_bottom = 0.96
		add_child(panel)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.05, 0.10, 0.92)
		style.border_color = Color(0.85, 0.75, 0.45)
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		panel.add_theme_stylebox_override("panel", style)

		var margin := MarginContainer.new()
		margin.name = "margin"
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		panel.add_child(margin)

		label = RichTextLabel.new()
		label.name = "label"
		label.bbcode_enabled = false
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("normal_font_size", 10)
		margin.add_child(label)

		arrow = Label.new()
		arrow.name = "arrow"
		arrow.text = "v"
		arrow.anchor_left = 1.0
		arrow.anchor_top = 1.0
		arrow.anchor_right = 1.0
		arrow.anchor_bottom = 1.0
		arrow.offset_left = -18.0
		arrow.offset_top = -18.0
		arrow.offset_right = -6.0
		arrow.offset_bottom = -4.0
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow.add_theme_font_size_override("font_size", 10)
		arrow.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
		panel.add_child(arrow)
	else:
		label = get_node_or_null("panel/margin/label") as RichTextLabel
		arrow = get_node_or_null("panel/arrow") as Label

	if label == null:
		var margin := panel.get_node_or_null("margin") as MarginContainer
		if margin == null:
			margin = MarginContainer.new()
			margin.name = "margin"
			panel.add_child(margin)
		label = RichTextLabel.new()
		label.name = "label"
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		margin.add_child(label)

	if arrow == null:
		arrow = Label.new()
		arrow.name = "arrow"
		arrow.text = "v"
		panel.add_child(arrow)
