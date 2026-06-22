## InteractionTrigger — Zona de interacción con objetos del mundo
## Adjunto a Area2D para objetos interactuables (señales, carteles, cofres).
extends Area2D

@export var trigger_id: String = ""
@export var message: String = "..."
@export var one_time: bool = false

var _used: bool = false
var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if GameManager.dialogue_active:
		return
	if one_time and _used:
		return
	if event.is_action_pressed("interact"):
		_used = true
		var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
		if dialogue_box and message != "":
			dialogue_box.show_message(message)
