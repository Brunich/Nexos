## Test de movimiento del jugador — headless
## Carga el overworld, espera que el jugador spawne,
## le fuerza velocidad y verifica que move_and_slide lo mueve.
extends Node

const PLAYER_SCENE = preload("res://escenas/player/player.tscn")
const OVERWORLD_SCENE = preload("res://escenas/overworld/overworld.tscn")

var _player = null
var _pos_initial: Vector2 = Vector2.ZERO
var _frames: int = 0
var _test_done: bool = false

func _ready() -> void:
	# Configurar GameManager mínimo
	GameManager.setup_new_adventure("TestPlayer")
	GameManager.pending_spawn_id = "default"

	# Instanciar overworld
	var overworld = OVERWORLD_SCENE.instantiate()
	add_child(overworld)
	print("[MOVEMENT TEST] Overworld instanciado")

func _process(delta: float) -> void:
	if _test_done:
		return

	_frames += 1

	# Esperar 5 frames para que OverworldController._spawn_player (deferred) corra
	if _frames == 5:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			push_error("[MOVEMENT TEST] FALLO: Jugador no encontrado en la escena")
			_finish(false)
			return
		_pos_initial = _player.global_position
		print("[MOVEMENT TEST] Jugador encontrado en posición: %s" % _pos_initial)

	# Frames 5-25: forzar velocidad al jugador directamente
	if _frames >= 5 and _frames <= 25 and _player != null:
		_player.velocity = Vector2(80, 0)  # Mover hacia la derecha
		# move_and_slide es llamado dentro de _physics_process del player
		# pero en headless necesitamos llamarlo explícitamente
		_player.move_and_slide()

	# Frame 30: verificar que se movió
	if _frames == 30:
		if _player == null:
			push_error("[MOVEMENT TEST] FALLO: Jugador perdido")
			_finish(false)
			return

		var pos_final = _player.global_position
		var moved = pos_final.distance_to(_pos_initial)

		print("[MOVEMENT TEST] Posición inicial: %s" % _pos_initial)
		print("[MOVEMENT TEST] Posición final:   %s" % pos_final)
		print("[MOVEMENT TEST] Distancia movida: %.2f px" % moved)

		if moved > 1.0:
			print("[MOVEMENT TEST] ✅ PASS — El jugador SE MUEVE correctamente")
			_finish(true)
		else:
			push_error("[MOVEMENT TEST] ❌ FALLO — El jugador NO se movió (distancia: %.2f)" % moved)
			_finish(false)

func _finish(success: bool) -> void:
	_test_done = true
	if success:
		print("[MOVEMENT TEST] === RESULTADO: PASS ===")
	else:
		print("[MOVEMENT TEST] === RESULTADO: FALLO ===")
	get_tree().quit(0 if success else 1)
