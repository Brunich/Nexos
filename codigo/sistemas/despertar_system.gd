## DespertarSystem — Sistema de Despertar (reemplaza Evolution)
## Los Tonales no "evolucionan" — Despiertan a su forma más plena.
## Tipos de Despertar: Madurez (nivel), Profundidad de Vínculo (bond), Piedra de Despertar (objeto)
##
## Uso:  DespertarSystem.puede_despertar(creature) → bool
##        DespertarSystem.despertar(creature) → CreatureInstance (nueva forma)
extends RefCounted
class_name DespertarSystem

const CreatureInstanceClass = preload("res://codigo/recursos/creature_instance.gd")
const CreatureStatSystem = preload("res://codigo/sistemas/creature_stat_system.gd")

## Tabla de Despertar: creature_id → condición
## trigger_type: "madurez" | "vinculo" | "piedra" | "hora"
## target_id: nuevo creature_id tras el Despertar
const DESPERTAR_DATA: Dictionary = {
	# Embral → Embralcinder (Madurez nivel 28, Latido Estable mínimo)
	1001: {
		"target_id":    1002,
		"trigger_type": "madurez",
		"level":        28,
		"bond_minimo":  50,
		"nombre":       "Embralcinder",
		"mensaje":      "Embral está Despertando. La llama dentro de él arde diferente ahora...",
	},
	# Folimp → Folivian (Madurez nivel 22, Latido Estable)
	1003: {
		"target_id":    1004,
		"trigger_type": "madurez",
		"level":        22,
		"bond_minimo":  45,
		"nombre":       "Folivian",
		"mensaje":      "Folimp está Despertando. Sus pétalos se abren lentamente...",
	},
	# Drakpup → Scarfang (Madurez nivel 30, Latido Resonante)
	1017: {
		"target_id":    1012,
		"trigger_type": "madurez",
		"level":        30,
		"bond_minimo":  80,
		"nombre":       "Scarfang",
		"mensaje":      "Drakpup está Despertando. El fuego volcánico lo recorre entero...",
	},
}

## ¿Puede este Tonal Despertar ahora?
static func puede_despertar(creature) -> bool:  # creature: CreatureInstance
	var data: Dictionary = DESPERTAR_DATA.get(creature.creature_id, {})
	if data.is_empty():
		return false

	match data["trigger_type"]:
		"madurez":
			var ok_lvl  = creature.level >= data.get("level", 100)
			var ok_bond = creature.bond  >= data.get("bond_minimo", 0)
			return ok_lvl and ok_bond
		"vinculo":
			return creature.bond >= data.get("bond_minimo", 100)
		"piedra":
			return false  # Se activa externamente con un objeto
		"hora":
			return false  # Se activa por DayNightSystem
	return false

## Ejecuta el Despertar. Crea y devuelve la nueva instancia del Tonal.
## La criatura antigua debe ser reemplazada en el partido por la nueva.
static func despertar(creature, pokedex_data = null) -> Object:  # → CreatureInstance
	var data: Dictionary = DESPERTAR_DATA.get(creature.creature_id, {})
	if data.is_empty():
		return creature

	var nueva = CreatureInstanceClass.new()
	nueva.creature_id  = data["target_id"]
	nueva.nickname     = creature.nickname
	nueva.active_skin  = creature.active_skin
	nueva.level        = creature.level
	nueva.experience   = creature.experience
	nueva.bond         = creature.bond
	# IVs se heredan
	nueva.iv_hp     = creature.iv_hp
	nueva.iv_atk    = creature.iv_atk
	nueva.iv_def    = creature.iv_def
	nueva.iv_sp_atk = creature.iv_sp_atk
	nueva.iv_sp_def = creature.iv_sp_def
	nueva.iv_speed  = creature.iv_speed
	# Naturaleza y habilidad
	nueva.nature    = creature.nature
	nueva.ability   = creature.ability
	nueva.status    = creature.status
	nueva.moves     = creature.moves.duplicate()
	nueva.moves_pp  = creature.moves_pp.duplicate()

	# Obtener stats de la nueva forma desde PokedexData
	if pokedex_data != null:
		var entry = pokedex_data.get_entry(nueva.creature_id)
		if not entry.is_empty():
			nueva.type1  = entry.get("type1", creature.type1)
			nueva.type2  = entry.get("type2", creature.type2)
		else:
			nueva.type1  = creature.type1
			nueva.type2  = creature.type2
	else:
		nueva.type1  = creature.type1
		nueva.type2  = creature.type2

	var hp_ratio := float(max(creature.hp_cur, 0)) / float(max(creature.hp_max, 1))
	CreatureStatSystem.recalculate_creature(nueva, false)
	nueva.hp_cur = clamp(int(round(hp_ratio * float(nueva.hp_max))), 0, nueva.hp_max)

	# Marcar como vinculado en el GameManager
	GameManager.mark_caught(nueva.creature_id)

	print("DespertarSystem: %s → %s ¡DESPERTÓ! (bond=%d)" % [
		data.get("nombre","?"), creature.display_name(), nueva.bond
	])
	return nueva

## Mensaje de Despertar para este Tonal
static func mensaje_despertar(creature_id: int) -> String:
	return DESPERTAR_DATA.get(creature_id, {}).get("mensaje",
		"¡El Tonal está Despertando!")

## Nombre del Tonal destino del Despertar
static func nombre_destino(creature_id: int) -> String:
	return DESPERTAR_DATA.get(creature_id, {}).get("nombre", "???")

## ¿Tiene este Tonal una ruta de Despertar definida?
static func tiene_despertar(creature_id: int) -> bool:
	return DESPERTAR_DATA.has(creature_id)
