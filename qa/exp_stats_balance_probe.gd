extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var stat_system = load("res://codigo/sistemas/creature_stat_system.gd")
	if stat_system == null:
		push_error("exp_stats_balance_probe: falta creature_stat_system.gd")
		get_tree().quit(1)
		return

	var creature_script = load("res://codigo/recursos/creature_instance.gd")
	if creature_script == null:
		push_error("exp_stats_balance_probe: falta creature_instance.gd")
		get_tree().quit(1)
		return

	var final_base: Dictionary = stat_system.get_base_stats(1002)
	var first_base: Dictionary = stat_system.get_base_stats(1001)
	var final_total: int = stat_system.base_stat_total(final_base)
	var first_total: int = stat_system.base_stat_total(first_base)

	if final_total > 600:
		push_error("exp_stats_balance_probe: BST final excede 600 (%d)" % final_total)
		get_tree().quit(1)
		return

	if first_total >= final_total:
		push_error("exp_stats_balance_probe: la preevolucion no escala por debajo de la forma final")
		get_tree().quit(1)
		return

	var creature = creature_script.create(1002, 30)
	if creature == null:
		push_error("exp_stats_balance_probe: CreatureInstance.create no devolvio criatura")
		get_tree().quit(1)
		return

	if creature.hp_max <= 1 or creature.atk <= 0 or creature.sp_atk <= 0 or creature.speed <= 0:
		push_error("exp_stats_balance_probe: stats calculados invalidos")
		get_tree().quit(1)
		return

	var exp_progress: Dictionary = stat_system.get_experience_progress(creature.experience, creature.level, creature.creature_id)
	if float(exp_progress.get("ratio", -1.0)) < 0.0:
		push_error("exp_stats_balance_probe: ratio de experiencia invalido")
		get_tree().quit(1)
		return

	var level_result: Dictionary = stat_system.apply_experience(creature, 5000)
	if int(level_result.get("levels_gained", 0)) <= 0:
		push_error("exp_stats_balance_probe: apply_experience no subio niveles")
		get_tree().quit(1)
		return

	if not level_result.has("final_deltas"):
		push_error("exp_stats_balance_probe: apply_experience no reporta deltas")
		get_tree().quit(1)
		return

	print("EXP_STATS_BALANCE_PROBE ok final_total=%d first_total=%d level=%d" % [
		final_total, first_total, creature.level
	])
	get_tree().quit()
