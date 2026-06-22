## TitleScreen — Pantalla de título del juego NEXUS
## Shift = iniciar / continuar. Enter en el nombre = nueva partida.
## El campo de nombre tiene "Nix" como default.
extends CanvasLayer

const OVERWORLD_SCENE   = "res://escenas/overworld/villa_nexo.tscn"
const INTRO_LORE_SCENE  = "res://escenas/ui/intro_lore_screen.tscn"

@onready var name_input:  LineEdit = $center/card/margin/vbox/name_row/name_input
@onready var prompt_label: Label   = $center/card/margin/vbox/prompt
@onready var save_label:  Label    = $center/card/margin/vbox/save_label

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	var has_save = SaveSystem.save_exists()
	name_input.text = "Nix"
	name_input.grab_focus()

	if has_save:
		prompt_label.text = "[ SHIFT = Continuar partida ]"
		save_label.text   = "Enter en el nombre = Nueva partida"
	else:
		prompt_label.text = "[ SHIFT o Enter = Comenzar ]"
		save_label.text   = ""

	# Enter dentro del campo de nombre → siempre nueva partida
	name_input.text_submitted.connect(_on_name_submitted)
	print("TitleScreen: cargado. Guardado: %s" % has_save)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Solo SHIFT inicia/continúa (para no comer las teclas del nombre)
		if event.physical_keycode == KEY_SHIFT:
			get_viewport().set_input_as_handled()
			_start_game()
	elif event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		_start_game()

func _on_name_submitted(text: String) -> void:
	# Enter dentro del LineEdit → siempre nueva partida (ignora save)
	_start_new_game(text)

func _start_game() -> void:
	if SaveSystem.save_exists():
		_load_game()
	else:
		_start_new_game(name_input.text)

func _start_new_game(raw_name: String) -> void:
	var final_name = raw_name.strip_edges()
	if final_name == "":
		final_name = "Nix"
	GameManager.setup_new_adventure(final_name)
	GameManager.pending_spawn_id = "default"
	print("TitleScreen: nueva partida → intro lore [%s]" % final_name)
	get_tree().change_scene_to_file(INTRO_LORE_SCENE)

func _load_game() -> void:
	var data = SaveSystem.load_game()
	if data.is_empty():
		_start_new_game(name_input.text)
		return
	GameManager.apply_load(data)
	var scene_to_load = GameManager.save_scene
	if scene_to_load == "" or not ResourceLoader.exists(scene_to_load):
		scene_to_load = OVERWORLD_SCENE
	print("TitleScreen: cargando partida → %s" % scene_to_load)
	get_tree().change_scene_to_file(scene_to_load)
