extends Node

const BATTLE_SCENE := preload("res://escenas/batalla/battle_scene.tscn")
const CreatureInstance := preload("res://codigo/recursos/creature_instance.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameManager.setup_new_adventure("Probe")
	var player = CreatureInstance.create(1020, 5)
	var enemy = CreatureInstance.create(1023, 4)
	GameManager.party = [player]

	var battle = BATTLE_SCENE.instantiate()
	add_child(battle)
	battle.setup_wild_encounter(player, enemy)

	var ready_ok := await _wait_until(func():
		return battle.get_node("ui/move_menu").visible
	, 4.0)
	if not ready_ok:
		push_error("battle_turn_probe: la batalla no llego al turno del jugador")
		battle.queue_free()
		await get_tree().process_frame
		get_tree().quit(1)
		return

	print("BATTLE_TURN_PROBE ok text=%s" % battle.get_node("ui/text_box").text)
	battle.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()

func _wait_until(predicate: Callable, timeout_seconds: float) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < int(timeout_seconds * 1000.0):
		if predicate.call():
			return true
		await get_tree().process_frame
	return false
