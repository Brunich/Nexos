## WildBoss — Encuentro especial con jefe salvaje
## Adjunto a Area2D o CharacterBody2D en rutas.
## Dispara un encuentro de batalla cuando el jugador entra al área.
extends Area2D

@export var boss_creature_id: int = 1001
@export var boss_level: int = 15
@export var one_time: bool = true
@export var flag_id: String = ""  ## Flag que se activa al derrotarlo

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Si ya fue derrotado en esta partida, desactivar
	if flag_id != "" and GameManager.flag_check(flag_id):
		_triggered = true

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if _triggered:
		return

	_triggered = one_time
	print("WildBoss: encuentro con criatura %d nivel %d" % [boss_creature_id, boss_level])
	# TODO: conectar con BattleManager cuando esté listo
	# BattleManager.start_boss_encounter(boss_creature_id, boss_level, flag_id)
