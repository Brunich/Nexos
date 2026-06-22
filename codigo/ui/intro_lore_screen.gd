## IntroLoreScreen — Pantalla de lore introductorio del mundo NEXOS / Anahuac
## Muestra 4 páginas de contexto con efecto typewriter. Cualquier tecla avanza.
## Desde la última página transiciona a la casa de Nana.
extends CanvasLayer

const NANA_HOUSE_SCENE = "res://escenas/overworld/villa_nexo.tscn"
const CHARS_PER_SECOND: float = 32.0

const PAGES = [
	"En el archipiélago del [b]Piélago[/b], existen seres llamados [b]nexos[/b]. No son animales — son algo más. Los [b]Guías[/b] que viajan con ellos aprenden esto pronto.\n\nEl vínculo entre un nexo y su Guía se llama [b]El Latido[/b]. Crece. Cambia. A veces se rompe.",
	"El Piélago tiene regiones distintas, cada una con su forma de entender el vínculo. En [b]Levante[/b] no se encierra a los nexos de noche — duermen junto a sus Guías. En [b]Zenera[/b] los usan para alimentar generadores. En [b]Nora[/b] tener un nexo que sobrevive el desierto dice algo de ti.\n\nNadie tiene razón del todo.",
	"Hace cincuenta años ocurrió algo que el mundo prefirió no recordar. Se llamó [b]el Evento Echonis[/b].\n\nUna investigadora llamada [b]Nora Vega[/b] descubrió que ciertos nexos — los [b]Primordiales[/b] — poseían inteligencia equivalente a la humana. El Campeón [b]Aldric[/b] enterró esa verdad para mantener la paz.\n\nAl final, nadie le creyó a Vega. Era más fácil seguir cómodos.",
	"Hoy cumples 17 años. Tu abuela [b]Nana Cais[/b] te ha esperado toda la semana. Dice que tiene algo importante que darte.\n\nEn el Piélago Central, a esta edad, se forma el primer vínculo.\n\n[b]Ya es hora.[/b]"
]

@onready var text_label: RichTextLabel = $center/vbox/text_label
@onready var page_indicator: Label = $center/vbox/page_indicator
@onready var hint_label: Label = $hint_label

var _current_page: int = 0
var _is_typing: bool = false
var _full_text: String = ""
var _typing_tween: Tween = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_show_page(0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		_advance()
	elif event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		_advance()

func _advance() -> void:
	if _is_typing:
		_skip_typing()
		return
	_current_page += 1
	if _current_page < PAGES.size():
		_show_page(_current_page)
	else:
		# Asegurarse de que el spawn sea en la posición correcta de nana_house
		GameManager.pending_spawn_id = "default"
		get_tree().change_scene_to_file(NANA_HOUSE_SCENE)

func _show_page(index: int) -> void:
	_full_text = PAGES[index]
	text_label.text = ""
	_is_typing = true
	# Indicador con puntos decorativos
	var dots_parts: Array[String] = []
	for _filled in range(index + 1):
		dots_parts.append("◆")
	for _empty in range(PAGES.size() - index - 1):
		dots_parts.append("◇")
	var dots := " ".join(dots_parts)
	page_indicator.text = dots.strip_edges()
	hint_label.text = "[ Presiona cualquier tecla para continuar... ]"

	if _typing_tween:
		_typing_tween.kill()

	# Contar solo caracteres visibles (sin BBCode) para la duración
	var visible_len = _strip_bbcode(_full_text).length()
	var duration = float(visible_len) / CHARS_PER_SECOND
	_typing_tween = create_tween()
	_typing_tween.tween_method(_set_chars, 0, _full_text.length(), duration)
	_typing_tween.tween_callback(_on_typing_done)

func _strip_bbcode(text: String) -> String:
	# Quitar tags BBCode para calcular duración correcta
	var result = text
	var in_tag = false
	var stripped = ""
	for c in result:
		if c == "[": in_tag = true
		elif c == "]": in_tag = false; continue
		elif not in_tag: stripped += c
	return stripped

func _set_chars(n: int) -> void:
	# Truncar texto respetando BBCode (no cortar en medio de un tag)
	text_label.text = _safe_truncate(_full_text, n)

func _safe_truncate(text: String, n: int) -> String:
	# Truncar mostrando texto visible hasta n, pero sin romper BBCode abierto
	if n >= text.length():
		return text
	var out = text.substr(0, n)
	# Si terminamos dentro de un tag, cerrar
	var last_open = out.rfind("[")
	var last_close = out.rfind("]")
	if last_open > last_close:
		out = out.substr(0, last_open)
	return out

func _on_typing_done() -> void:
	text_label.text = _full_text
	_is_typing = false
	if _current_page == PAGES.size() - 1:
		hint_label.text = "[ Presiona cualquier tecla para continuar... ]"

func _skip_typing() -> void:
	if _typing_tween:
		_typing_tween.kill()
		_typing_tween = null
	text_label.text = _full_text
	_is_typing = false
	if _current_page == PAGES.size() - 1:
		hint_label.text = "[ Presiona cualquier tecla para continuar... ]"
