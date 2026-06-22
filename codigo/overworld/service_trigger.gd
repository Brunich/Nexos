## ServiceTrigger — Zona de acceso a servicios de ciudad (clínica, etc.)
## Adjunto a Area2D en clínicas y PCs.
## Cuando el jugador interactúa, abre CityServiceMenu.
extends Area2D

@export var service_type: String = "clinic"  # clinic / pc / shop

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
	if event.is_action_pressed("interact"):
		_open_service()

func _open_service() -> void:
	var menu = get_tree().get_first_node_in_group("city_service_menu")
	if menu == null:
		push_warning("ServiceTrigger: no se encontró CityServiceMenu en la escena")
		return
	menu.open(service_type)
