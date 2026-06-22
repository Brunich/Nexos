## BattleManager — Lógica central de batalla por turnos.
## Adjunto al nodo battle_manager en battle_scene.tscn.
## Emite señales para que BattleScene actualice la UI.
extends Node
class_name BattleManager

const VinculoSystem    = preload("res://codigo/sistemas/vinculo_system.gd")
const CreatureStatSystem = preload("res://codigo/sistemas/creature_stat_system.gd")
const ExperienceSystem = preload("res://codigo/batalla/experience_system.gd")

# ── Estado de batalla ─────────────────────────────────────────────────────────
enum Phase {
	INTRO,
	PLAYER_MENU,
	RESOLVING,   # procesando turno (no acepta input)
	CATCH_ANIM,
	LEVEL_UP,
	BATTLE_END,
}

enum BattleResult { FLED, WIN, LOSS, CAUGHT }

# ── Señales ───────────────────────────────────────────────────────────────────
signal phase_changed(phase: Phase)
signal text_queued(text: String)
signal player_hp_changed(hp_cur: int, hp_max: int)
signal enemy_hp_changed(hp_cur: int, hp_max: int)
signal player_exp_changed(earned: int, needed: int)
signal battle_ended(result: BattleResult)
signal level_up(creature_name: String, from_lv: int, to_lv: int, deltas: Dictionary)
signal catch_wobble(n_wobbles: int)
signal vinculo_result(success: bool, creature)   # creature = enemy si éxito

# ── Datos de batalla ──────────────────────────────────────────────────────────
var player_creature  = null   # CreatureInstance
var enemy_creature   = null   # CreatureInstance
var is_wild          : bool = true
var turn_number      : int  = 0
var current_phase    : Phase = Phase.INTRO

# ── Tabla de efectividad de tipos (multiplicadores) ───────────────────────────
# Formato: "ATACANTE_DEFENSOR" → multiplicador float
# Solo se registran las entradas != 1.0. Las ausentes valen 1.0.
# Tipos: Normal Fire Water Grass Electric Ice Fighting Poison Ground
#        Flying Psychic Bug Rock Ghost Dragon Dark Steel Fairy Veil
const TYPE_CHART : Dictionary = {
	# Fire
	"Fire_Grass": 2.0,    "Fire_Ice": 2.0,    "Fire_Bug": 2.0,    "Fire_Steel": 2.0,
	"Fire_Fire": 0.5,     "Fire_Water": 0.5,  "Fire_Rock": 0.5,   "Fire_Dragon": 0.5,
	# Water
	"Water_Fire": 2.0,    "Water_Ground": 2.0, "Water_Rock": 2.0,
	"Water_Water": 0.5,   "Water_Grass": 0.5,  "Water_Dragon": 0.5,
	# Grass
	"Grass_Water": 2.0,   "Grass_Ground": 2.0, "Grass_Rock": 2.0,
	"Grass_Fire": 0.5,    "Grass_Grass": 0.5,  "Grass_Poison": 0.5,
	"Grass_Flying": 0.5,  "Grass_Bug": 0.5,    "Grass_Dragon": 0.5, "Grass_Steel": 0.5,
	# Electric
	"Electric_Water": 2.0,"Electric_Flying": 2.0,
	"Electric_Grass": 0.5,"Electric_Electric": 0.5, "Electric_Dragon": 0.5,
	"Electric_Ground": 0.0,
	# Ice
	"Ice_Grass": 2.0,     "Ice_Ground": 2.0,   "Ice_Flying": 2.0,  "Ice_Dragon": 2.0,
	"Ice_Fire": 0.5,      "Ice_Water": 0.5,    "Ice_Ice": 0.5,     "Ice_Steel": 0.5,
	# Fighting
	"Fighting_Normal": 2.0, "Fighting_Ice": 2.0, "Fighting_Rock": 2.0,
	"Fighting_Dark": 2.0,   "Fighting_Steel": 2.0,
	"Fighting_Poison": 0.5, "Fighting_Flying": 0.5, "Fighting_Psychic": 0.5,
	"Fighting_Bug": 0.5,    "Fighting_Fairy": 0.5,
	"Fighting_Ghost": 0.0,
	# Poison
	"Poison_Grass": 2.0,  "Poison_Fairy": 2.0,
	"Poison_Poison": 0.5, "Poison_Ground": 0.5, "Poison_Rock": 0.5, "Poison_Ghost": 0.5,
	"Poison_Steel": 0.0,
	# Ground
	"Ground_Fire": 2.0,   "Ground_Electric": 2.0, "Ground_Poison": 2.0,
	"Ground_Rock": 2.0,   "Ground_Steel": 2.0,
	"Ground_Grass": 0.5,  "Ground_Bug": 0.5,
	"Ground_Flying": 0.0,
	# Flying
	"Flying_Grass": 2.0,  "Flying_Fighting": 2.0, "Flying_Bug": 2.0,
	"Flying_Electric": 0.5, "Flying_Rock": 0.5,   "Flying_Steel": 0.5,
	# Psychic
	"Psychic_Fighting": 2.0, "Psychic_Poison": 2.0,
	"Psychic_Psychic": 0.5,  "Psychic_Steel": 0.5,
	"Psychic_Dark": 0.0,
	# Bug
	"Bug_Grass": 2.0,     "Bug_Psychic": 2.0,  "Bug_Dark": 2.0,
	"Bug_Fire": 0.5,      "Bug_Fighting": 0.5, "Bug_Flying": 0.5,
	"Bug_Ghost": 0.5,     "Bug_Steel": 0.5,    "Bug_Fairy": 0.5,
	# Rock
	"Rock_Fire": 2.0,     "Rock_Ice": 2.0,     "Rock_Flying": 2.0, "Rock_Bug": 2.0,
	"Rock_Fighting": 0.5, "Rock_Ground": 0.5,  "Rock_Steel": 0.5,
	# Ghost
	"Ghost_Psychic": 2.0, "Ghost_Ghost": 2.0,
	"Ghost_Dark": 0.5,
	"Ghost_Normal": 0.0,
	# Dragon
	"Dragon_Dragon": 2.0,
	"Dragon_Steel": 0.5,
	"Dragon_Fairy": 0.0,
	# Dark
	"Dark_Psychic": 2.0,  "Dark_Ghost": 2.0,
	"Dark_Fighting": 0.5, "Dark_Dark": 0.5,    "Dark_Fairy": 0.5,
	# Steel
	"Steel_Ice": 2.0,     "Steel_Rock": 2.0,   "Steel_Fairy": 2.0,
	"Steel_Fire": 0.5,    "Steel_Water": 0.5,  "Steel_Electric": 0.5, "Steel_Steel": 0.5,
	# Fairy
	"Fairy_Fighting": 2.0, "Fairy_Dragon": 2.0, "Fairy_Dark": 2.0,
	"Fairy_Fire": 0.5,     "Fairy_Poison": 0.5, "Fairy_Steel": 0.5,
	# Veil
	"Veil_Ghost": 2.0,    "Veil_Psychic": 2.0, "Veil_Dragon": 2.0,
	"Veil_Dark": 0.5,     "Veil_Fire": 0.5,
	"Veil_Normal": 0.0,
	# Normal
	"Normal_Ghost": 0.0,
	"Normal_Rock": 0.5,   "Normal_Steel": 0.5,
}

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("battle_manager")

# ── Inicio de batalla ─────────────────────────────────────────────────────────
func setup_wild(player_c, enemy_c) -> void:
	player_creature = player_c
	enemy_creature  = enemy_c
	is_wild         = true
	turn_number     = 0
	_set_phase(Phase.INTRO)

# ── Cambio de fase ─────────────────────────────────────────────────────────────
func _set_phase(phase: Phase) -> void:
	current_phase = phase
	phase_changed.emit(phase)

# ── Acción del jugador ─────────────────────────────────────────────────────────
## Llamado por BattleScene cuando el jugador elige un movimiento.
func player_use_move(move_index: int) -> void:
	if current_phase != Phase.PLAYER_MENU:
		return
	if move_index < 0 or move_index >= player_creature.moves.size():
		return
	_set_phase(Phase.RESOLVING)
	_execute_turn_move(move_index)

## Llamado cuando el jugador quiere huir.
func player_run() -> void:
	if current_phase != Phase.PLAYER_MENU:
		return
	_set_phase(Phase.RESOLVING)
	text_queued.emit("¡%s escapó!" % GameManager.player_name)
	await get_tree().create_timer(1.2).timeout
	_end_battle(BattleResult.FLED)

## Llamado cuando el jugador usa una Ofrenda desde la bolsa.
func player_use_ofrenda(ofrenda_id: String) -> void:
	if current_phase != Phase.PLAYER_MENU:
		return
	if not is_wild:
		text_queued.emit("¡No puedes vincular Tonales ya guiados!")
		return
	_set_phase(Phase.RESOLVING)
	turn_number += 1
	var prob : float = VinculoSystem.calc_prob(enemy_creature, ofrenda_id, false, false, turn_number)
	var pulsos : int = VinculoSystem.pulsos_animacion(prob)
	text_queued.emit("¡Lanzaste una Ofrenda!")
	_set_phase(Phase.CATCH_ANIM)
	catch_wobble.emit(pulsos)
	await get_tree().create_timer(0.15 * pulsos + 0.5).timeout
	var success : bool = VinculoSystem.intentar_vinculo(enemy_creature, ofrenda_id, false, false, turn_number)
	if success:
		text_queued.emit("¡%s formó un vínculo contigo!" % enemy_creature.display_name())
		vinculo_result.emit(true, enemy_creature)
		await get_tree().create_timer(1.5).timeout
		GameManager.party.append(enemy_creature)
		_end_battle(BattleResult.CAUGHT)
	else:
		text_queued.emit("¡%s resistió el vínculo!" % enemy_creature.display_name())
		vinculo_result.emit(false, null)
		await get_tree().create_timer(1.0).timeout
		await _run_enemy_move()

# ── Turno del movimiento ──────────────────────────────────────────────────────
func _execute_turn_move(move_index: int) -> void:
	turn_number += 1
	var player_move = player_creature.moves[move_index]
	var player_first := _goes_first(player_creature, player_move.priority,
								   enemy_creature,  0)

	if player_first:
		await _apply_move(player_creature, enemy_creature, move_index)
		if enemy_creature.is_fainted():
			await _handle_victory()
			return
		await _run_enemy_move()
		if player_creature.is_fainted():
			return   # _handle_loss ya llamado dentro de _run_enemy_move
	else:
		await _run_enemy_move()
		if player_creature.is_fainted():
			return
		await _apply_move(player_creature, enemy_creature, move_index)
		if enemy_creature.is_fainted():
			await _handle_victory()
			return

	_set_phase(Phase.PLAYER_MENU)

func _run_enemy_move() -> void:
	await _apply_enemy_move()
	if player_creature.is_fainted():
		await _handle_loss()

# ── Aplicar movimiento ────────────────────────────────────────────────────────
func _apply_move(attacker, defender, move_index: int) -> void:
	var move = attacker.moves[move_index]
	# Gasta PP
	if move_index < attacker.moves_pp.size():
		attacker.moves_pp[move_index] = max(0, attacker.moves_pp[move_index] - 1)

	text_queued.emit("¡%s usó %s!" % [attacker.display_name(), move.move_name])
	await get_tree().create_timer(0.5).timeout

	if move.power <= 0:
		# Movimiento de estado — placeholder
		text_queued.emit("(movimiento de estado — sin efecto aún)")
		await get_tree().create_timer(0.5).timeout
		return

	# Verificar precisión
	if move.accuracy < 100:
		var hit_roll := randi() % 100
		if hit_roll >= move.accuracy:
			text_queued.emit("¡El movimiento falló!")
			await get_tree().create_timer(0.5).timeout
			return

	var dmg : int = _calc_damage(attacker, defender, move)
	var effectiveness := _type_effectiveness(move.type_name(), defender.type1, defender.type2)
	if effectiveness >= 2.0:
		text_queued.emit("¡Es muy efectivo!")
	elif effectiveness <= 0.0:
		text_queued.emit("No afecta a %s..." % defender.display_name())
		return
	elif effectiveness <= 0.5:
		text_queued.emit("No es muy efectivo...")

	defender.take_damage(dmg)

	if defender == enemy_creature:
		enemy_hp_changed.emit(enemy_creature.hp_cur, enemy_creature.hp_max)
	else:
		player_hp_changed.emit(player_creature.hp_cur, player_creature.hp_max)

	await get_tree().create_timer(0.3).timeout

func _apply_enemy_move() -> void:
	if enemy_creature.moves.is_empty():
		# Sin movimientos → ataque básico generado
		_apply_scratch_attack()
		return
	var idx: int = randi() % enemy_creature.moves.size()
	await _apply_move(enemy_creature, player_creature, idx)

func _apply_scratch_attack() -> void:
	text_queued.emit("¡%s atacó!" % enemy_creature.display_name())
	await get_tree().create_timer(0.4).timeout
	var atk  := int(enemy_creature.atk)
	var def  := int(player_creature.def)
	var dmg: int = max(1, int(atk * 0.5) - int(def * 0.25))
	player_creature.take_damage(dmg)
	player_hp_changed.emit(player_creature.hp_cur, player_creature.hp_max)
	await get_tree().create_timer(0.3).timeout

# ── Victoria / derrota ────────────────────────────────────────────────────────
func _handle_victory() -> void:
	text_queued.emit("¡%s fue derrotado!" % enemy_creature.display_name())
	await get_tree().create_timer(1.0).timeout
	var base_exp : int = int(PokedexData.get_entry(enemy_creature.creature_id).get("base_exp", 64))
	var gained   : int = ExperienceSystem.exp_gained(base_exp, enemy_creature.level, is_wild)
	text_queued.emit("%s ganó %d puntos de EXP." % [player_creature.display_name(), gained])
	await get_tree().create_timer(0.5).timeout
	var result   : Dictionary = player_creature.gain_experience(gained)
	var progress : Dictionary = player_creature.get_exp_progress()
	player_exp_changed.emit(progress.get("earned", 0), progress.get("needed", 1))
	await get_tree().create_timer(0.4).timeout

	if result.get("levels_gained", 0) > 0:
		_set_phase(Phase.LEVEL_UP)
		var steps : Array = result.get("steps", [])
		for step in steps:
			var from_lv : int = step.get("from_level", player_creature.level - 1)
			var to_lv   : int = step.get("to_level",   player_creature.level)
			var deltas  : Dictionary = step.get("deltas", {})
			level_up.emit(player_creature.display_name(), from_lv, to_lv, deltas)
			text_queued.emit("¡%s avanzó al nivel %d!" % [player_creature.display_name(), to_lv])
			player_hp_changed.emit(player_creature.hp_cur, player_creature.hp_max)
			await get_tree().create_timer(0.3).timeout
		# BattleScene esperará señal; aquí esperamos respuesta antes de continuar
		await get_tree().create_timer(2.5).timeout

	# Latido: victoria
	var idx: int = GameManager.party.find(player_creature)
	if idx >= 0:
		GameManager.latido_victoria(idx)

	_end_battle(BattleResult.WIN)

func _handle_loss() -> void:
	text_queued.emit("¡%s no puede continuar!" % player_creature.display_name())
	await get_tree().create_timer(1.0).timeout
	var idx: int = GameManager.party.find(player_creature)
	if idx >= 0:
		GameManager.latido_derrota(idx)
	_end_battle(BattleResult.LOSS)

func _end_battle(result: BattleResult) -> void:
	_set_phase(Phase.BATTLE_END)
	battle_ended.emit(result)

# ── Cálculo de daño ───────────────────────────────────────────────────────────
func _calc_damage(attacker, defender, move) -> int:
	var category  : int = int(move.category)
	var atk_stat  : int
	var def_stat  : int
	if category == 0:   # Physical
		atk_stat = int(attacker.atk)
		def_stat = int(defender.def)
	else:               # Special
		atk_stat = int(attacker.sp_atk)
		def_stat = int(defender.sp_def)

	var level := int(attacker.level)
	var power: int = max(1, int(move.power))
	var base  := float(2 * level + 10) / 250.0 * (float(atk_stat) / float(max(1, def_stat))) * float(power) + 2.0

	# STAB
	var stab : float = 1.0
	if move.type_name() == attacker.type1 or (attacker.type2 != "" and move.type_name() == attacker.type2):
		stab = 1.5

	# Tipo efectividad
	var eff := _type_effectiveness(move.type_name(), defender.type1, defender.type2)

	# Variación aleatoria 0.85-1.0
	var rng : float = 0.85 + randf() * 0.15

	return max(1, int(base * stab * eff * rng))

func _type_effectiveness(atk_type: String, def_type1: String, def_type2: String) -> float:
	var eff  := TYPE_CHART.get("%s_%s" % [atk_type, def_type1], 1.0) as float
	if def_type2 != "":
		eff *= TYPE_CHART.get("%s_%s" % [atk_type, def_type2], 1.0) as float
	return eff

# ── Prioridad y velocidad ─────────────────────────────────────────────────────
func _goes_first(a, a_priority: int, b, b_priority: int) -> bool:
	if a_priority != b_priority:
		return a_priority > b_priority
	return int(a.speed) >= int(b.speed)

# ─────────────────────────────────────────────────────────────────────────────
const PokedexData = preload("res://codigo/datos/pokedex_data.gd")
