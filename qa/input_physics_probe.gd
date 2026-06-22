## Prueba definitiva: simula input real y verifica que _physics_process mueve al jugador
extends Node

const OVERWORLD_SCENE = preload("res://escenas/overworld/overworld.tscn")

var _player = null
var _frames: int = 0
var _pos_before_input: Vector2 = Vector2.ZERO
var _phase: String = "wait_spawn"
var _physics_frames: int = 0

func _ready() -> void:
	GameManager.setup_new_adventure("TestPlayer")
	GameManager.pending_spawn_id = "default"
	var ow = OVERWORLD_SCENE.instantiate()
	add_child(ow)
	print("[INPUT-PHYSICS PROBE] Iniciando...")

func _process(_delta: float) -> void:
	_frames += 1

	match _phase:
		"wait_spawn":
			if _frames >= 8:
				_player = get_tree().get_first_node_in_group("player")
				if _player == null:
					push_error("FALLO: jugador no encontrado")
					_end(false); return
				print("[INPUT-PHYSICS PROBE] Jugador en: %s" % _player.global_position)
				print("[INPUT-PHYSICS PROBE] dialogue_active: %s" % GameManager.dialogue_active)
				print("[INPUT-PHYSICS PROBE] motion_mode: %s" % _player.motion_mode)
				_phase = "simulate_input"
				_frames = 0

		"simulate_input":
			# Simular input RIGHT programáticamente en cada frame de proceso
			Input.action_press("ui_right")
			_frames += 0  # ya incrementado arriba

			if _frames == 1:
				_pos_before_input = _player.global_position
				print("[INPUT-PHYSICS PROBE] Posición antes de input: %s" % _pos_before_input)

			if _frames >= 30:
				Input.action_release("ui_right")
				var pos_after = _player.global_position
				var dist = pos_after.distance_to(_pos_before_input)
				print("[INPUT-PHYSICS PROBE] Posición después de input: %s" % pos_after)
				print("[INPUT-PHYSICS PROBE] Distancia recorrida: %.2f px" % dist)
				print("[INPUT-PHYSICS PROBE] velocity en ese momento: %s" % _player.velocity)
				if dist > 1.0:
					print("[INPUT-PHYSICS PROBE] ✅ PASS — Input simulado SÍ mueve al jugador")
					_end(true)
				else:
					print("[INPUT-PHYSICS PROBE] ❌ FALLO — Input simulado NO mueve al jugador")
					print("[INPUT-PHYSICS PROBE] → Causa posible: dialogue_active=%s" % GameManager.dialogue_active)
					_end(false)

func _end(ok: bool) -> void:
	_phase = "done"
	if ok:
		print("[INPUT-PHYSICS PROBE] === RESULTADO: ✅ PIPELINE INPUT→MOVIMIENTO FUNCIONA ===")
	else:
		print("[INPUT-PHYSICS PROBE] === RESULTADO: ❌ PIPELINE ROTO ===")
	get_tree().quit(0 if ok else 1)
