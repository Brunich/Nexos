## ItemPickup — Objeto recolectable en el suelo del overworld
## Adjunto a Area2D. Al interactuar (o al entrar), da el objeto al inventario.
extends Area2D

@export var item_id: String = ""
@export var quantity: int = 1
@export var auto_pickup: bool = false  ## true = recoger al pasar encima

var _collected: bool = false

func _ready() -> void:
	if auto_pickup:
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not _collected:
		_collect()

func _unhandled_input(event: InputEvent) -> void:
	if _collected or auto_pickup:
		return
	# Verificar si el jugador está cerca e interactúa
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if global_position.distance_to(player.global_position) > 24.0:
		return
	if event.is_action_pressed("interact"):
		_collect()

func _collect() -> void:
	if item_id == "":
		return
	_collected = true
	InventorySystem.add_item(item_id, quantity)

	var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		var name_str = InventorySystem.ITEMS.get(item_id, {}).get("name", item_id)
		dialogue_box.show_message("Recogiste: %s ×%d" % [name_str, quantity])

	# Ocultar el sprite del objeto
	for child in get_children():
		if child is Node2D:
			child.visible = false
