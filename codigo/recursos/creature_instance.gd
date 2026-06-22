## CreatureInstance — Instancia de una criatura en el equipo del jugador
## Contiene stats calculados, movimientos, estado de batalla y vínculo.
## Usado por InventorySystem, SaveSystem, BattleManager (futuro).
class_name CreatureInstance
extends RefCounted

const CreatureStatSystem = preload("res://codigo/sistemas/creature_stat_system.gd")
const ExperienceSystem = preload("res://codigo/batalla/experience_system.gd")
const PokedexData = preload("res://codigo/datos/pokedex_data.gd")

# ── Enum de estado ─────────────────────────────────────────────────────────────
enum Status { NONE, POISONED, BADLY_POISONED, BURNED, PARALYZED, FROZEN, ASLEEP }

# ── Identidad ─────────────────────────────────────────────────────────────────
var creature_id: int = 0
var nickname: String = ""
var active_skin: String = "default"

# ── Tipos ──────────────────────────────────────────────────────────────────────
var type1: String = "Normal"
var type2: String = ""

# ── Stats base y personalización ──────────────────────────────────────────────
var nature: String = "Hardy"
var ability: String = ""
var held_item: String = ""
var catch_rate: int = 45
var level: int = 5
var experience: int = 0

# ── IVs (0-31) ────────────────────────────────────────────────────────────────
var iv_hp: int = 0
var iv_atk: int = 0
var iv_def: int = 0
var iv_sp_atk: int = 0
var iv_sp_def: int = 0
var iv_speed: int = 0

# ── HP ─────────────────────────────────────────────────────────────────────────
var hp_cur: int = 1
var hp_max: int = 1
var atk: int = 1
var def: int = 1
var sp_atk: int = 1
var sp_def: int = 1
var speed: int = 1

# ── Estado ────────────────────────────────────────────────────────────────────
var status: Status = Status.NONE

# ── Vínculo (Latido) ──────────────────────────────────────────────────────────
var bond: int = 50  # 0-100

# ── Movimientos ────────────────────────────────────────────────────────────────
var moves: Array = []      # Array[MoveData]
var moves_pp: Array = []   # Array[int] — PP actual, paralelo a moves

# ─────────────────────────────────────────────────────────────────────────────

func display_name() -> String:
	if nickname != "":
		return nickname
	var entry := PokedexData.get_entry(creature_id)
	if not entry.is_empty():
		return String(entry.get("name", "Tonal#%04d" % creature_id))
	return "Tonal#%04d" % creature_id

func is_fainted() -> bool:
	return hp_cur <= 0

func restore_hp(amount: int) -> int:
	var old = hp_cur
	hp_cur = min(hp_cur + amount, hp_max)
	return hp_cur - old

func take_damage(amount: int) -> void:
	hp_cur = max(0, hp_cur - amount)

func get_stat_snapshot() -> Dictionary:
	return CreatureStatSystem.get_runtime_stat_dict(self)

func recalculate_stats(preserve_hp_ratio: bool = false) -> Dictionary:
	return CreatureStatSystem.recalculate_creature(self, preserve_hp_ratio)

func gain_experience(amount: int) -> Dictionary:
	return CreatureStatSystem.apply_experience(self, amount)

func get_exp_progress() -> Dictionary:
	return CreatureStatSystem.get_experience_progress(experience, level, creature_id)

static func create(creature_ref: Variant, at_level: int = 5) -> CreatureInstance:
	var creature_id_resolved := CreatureStatSystem.resolve_creature_id(creature_ref)
	var entry := PokedexData.get_entry(creature_id_resolved)
	var creature := CreatureInstance.new()

	creature.creature_id = creature_id_resolved
	creature.level = max(1, at_level)
	creature.experience = ExperienceSystem.exp_for_level(
		creature.level,
		ExperienceSystem.get_growth_rate(creature_id_resolved)
	)
	creature.type1 = entry.get("type1", "Normal")
	creature.type2 = entry.get("type2", "")
	creature.ability = entry.get("ability", "")
	creature.catch_rate = int(entry.get("catch_rate", 45))
	creature.iv_hp = randi() % 32
	creature.iv_atk = randi() % 32
	creature.iv_def = randi() % 32
	creature.iv_sp_atk = randi() % 32
	creature.iv_sp_def = randi() % 32
	creature.iv_speed = randi() % 32
	creature.recalculate_stats(false)
	creature.hp_cur = creature.hp_max
	return creature

## Inicializar PP de todos los movimientos (llamar tras cargar movimientos)
func init_pp() -> void:
	moves_pp.resize(moves.size())
	for i in moves.size():
		var move: MoveData = moves[i]
		moves_pp[i] = move.pp_max

## Intercambiar posición de dos movimientos. Devuelve true si tuvo éxito.
func swap_moves(index_a: int, index_b: int) -> bool:
	if index_a < 0 or index_a >= moves.size():
		return false
	if index_b < 0 or index_b >= moves.size():
		return false
	var tmp_move = moves[index_a]
	moves[index_a] = moves[index_b]
	moves[index_b] = tmp_move
	if moves_pp.size() == moves.size():
		var tmp_pp = moves_pp[index_a]
		moves_pp[index_a] = moves_pp[index_b]
		moves_pp[index_b] = tmp_pp
	return true
