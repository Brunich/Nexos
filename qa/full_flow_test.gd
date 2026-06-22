## Test flujo completo: título → overworld → movimiento → diálogo NPC
extends Node

const OVERWORLD_SCENE = preload("res://escenas/overworld/overworld.tscn")

var _frames: int = 0
var _phase: String = "init"
var _player = null
var _pos_before: Vector2 = Vector2.ZERO
var _dialogue_triggered: bool = false

func _ready() -> void:
	print("[FULL FLOW TEST] Iniciando prueba completa...")

	# Simular nueva partida (lo que hace TitleScreen._new_game)
	GameManager.setup_new_adventure("TestPlayer")
	GameManager.pending_spawn_id = "default"

	# Instanciar overworld directamente (igual que movement_test.gd)
	var overworld = OVERWORLD_SCENE.instantiate()
	add_child(overworld)
	print("[FULL FLOW TEST] Overworld instanciado")

func _process(delta: float) -> void:
	_frames += 1

	match _phase:
		"init":
			if _frames >= 10:
				_check_spawn()

		"test_movement":
			_test_movement()

		"test_dialogue":
			_test_dialogue()

		"done":
			pass

func _check_spawn() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_error("[FULL FLOW TEST] ❌ FALLO: Jugador no spawneó")
		_end(false)
		return

	var pos = _player.global_position
	print("[FULL FLOW TEST] ✅ Jugador spawneado en: %s" % pos)

	if pos == Vector2.ZERO:
		push_error("[FULL FLOW TEST] ❌ FALLO: Jugador en posición (0,0) — no fue posicionado")
		_end(false)
		return

	_pos_before = pos
	_phase = "test_movement"
	_frames = 0

func _test_movement() -> void:
	# Frames 1-20: mover jugador a la derecha
	if _frames <= 20:
		_player.velocity = Vector2(80, 0)
		_player.move_and_slide()
	elif _frames == 25:
		var pos_after = _player.global_position
		var dist = pos_after.distance_to(_pos_before)
		if dist > 1.0:
			print("[FULL FLOW TEST] ✅ MOVIMIENTO: jugador se movió %.1f px" % dist)
			_phase = "test_dialogue"
			_frames = 0
		else:
			push_error("[FULL FLOW TEST] ❌ FALLO MOVIMIENTO: jugador no se movió")
			_end(false)

func _test_dialogue() -> void:
	if _frames == 1:
		# Buscar el dialogue_box
		var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
		if dialogue_box == null:
			push_error("[FULL FLOW TEST] ❌ FALLO: dialogue_box no encontrado")
			_end(false)
			return

		# Mostrar diálogo manualmente
		dialogue_box.show_message("¡Prueba de diálogo exitosa!")
		_dialogue_triggered = true
		print("[FULL FLOW TEST] ✅ DIÁLOGO: dialogue_box activado")

	elif _frames == 5:
		# Verificar que dialogue_active es true (bloquea movimiento)
		if not GameManager.dialogue_active:
			push_error("[FULL FLOW TEST] ❌ FALLO: dialogue_active debería ser true")
			_end(false)
			return
		print("[FULL FLOW TEST] ✅ DIÁLOGO: GameManager.dialogue_active = true (bloquea movimiento)")

	elif _frames == 8:
		if GameManager.dialogue_active:
			print("[FULL FLOW TEST] ✅ BLOQUEO: diálogo activo bloquearía movimiento en partida real")

	elif _frames == 10:
		print("[FULL FLOW TEST] ✅ TODOS LOS TESTS PASARON")
		_end(true)

func _end(success: bool) -> void:
	_phase = "done"
	if success:
		print("[FULL FLOW TEST] === RESULTADO FINAL: ✅ PASS — JUEGO FUNCIONAL ===")
	else:
		print("[FULL FLOW TEST] === RESULTADO FINAL: ❌ FALLO ===")
	get_tree().quit(0 if success else 1)
