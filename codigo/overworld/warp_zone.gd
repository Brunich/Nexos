## WarpZone — Zona de transición entre escenas
## Adjunto a Area2D en las escenas de overworld.
## Cuando el jugador entra, solicita el cambio de escena al GameManager.
extends Area2D

@export var target_scene: String = ""
@export var target_spawn: String = ""

var _triggered: bool = false

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return
	if target_scene == "":
		push_warning("WarpZone: target_scene está vacío en %s" % name)
		return
	if not ResourceLoader.exists(target_scene):
		push_warning("WarpZone: la escena '%s' no existe todavía" % target_scene)
		return

	_triggered = true
	print("WarpZone: '%s' → '%s' (spawn: '%s')" % [name, target_scene, target_spawn])
	GameManager.request_scene_change(target_scene, target_spawn)
