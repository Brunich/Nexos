## VinculoSystem — Sistema de Vínculo (reemplaza catch_system.gd)
## Implementa la fórmula de vínculo de la Biblia de NEXOS:
##   P(vínculo) = (HP_max*3 - HP_actual*2) / (HP_max*3) * tasa_tonal * mult_ofrenda * mult_estado
##
## Los Tonales no se capturan — se vinculan mediante Ofrendas ceremoniales.
## Animación: pulsos de luz (1=falla, 2=casi, 3=muy cerca, 4+destello=ÉXITO)
extends RefCounted
class_name VinculoSystem

# ── Multiplicadores por tipo de Cápsula ──────────────────────────────────────
const OFRENDA_MULT: Dictionary = {
	"ofrenda_copal":            1.0,
	"ofrenda_cempasuchil":      1.5,   # +bonus Espectro/Sombra
	"ofrenda_jade":             1.5,
	"ofrenda_obsidiana":        2.0,
	"ofrenda_miel":             1.0,   # +cura HP al vincularse
	"ofrenda_xocolatl":         4.0,   # solo primer turno
	"ofrenda_turquesa":         3.0,   # +bonus Agua/Hielo
	"ofrenda_fuego_ceremonial": 3.5,   # +bonus noche/cuevas
	"ofrenda_sagrada":          999.0, # garantizado
}

# Tipos con bonus de Cápsula Sombra
const CEMPASUCHIL_TYPES: Array = ["Ghost", "Dark"]

# Tipos con bonus de Cápsula Marina
const TURQUESA_TYPES: Array = ["Water", "Ice"]

# ── Multiplicadores por estado de alteración del Tonal ───────────────────────
const STATUS_MULT: Dictionary = {
	0: 1.0,   # NONE
	1: 1.5,   # POISONED
	2: 1.5,   # BADLY_POISONED
	3: 1.5,   # BURNED
	4: 2.0,   # PARALYZED
	5: 2.5,   # FROZEN
	6: 2.0,   # ASLEEP
}

# ─────────────────────────────────────────────────────────────────────────────

## Calcula la probabilidad de vínculo (0.0–1.0).
## target:    CreatureInstance del Tonal salvaje
## ofrenda_id: String con el ID del objeto ("ofrenda_copal" etc.)
## is_night:  bool — true si es de noche en el mundo
## is_cave:   bool — true si la escena es una cueva/interior oscuro
## turn_number: int — número de turno del combate (empieza en 1)
static func calc_prob(
	target,             # CreatureInstance
	ofrenda_id: String,
	is_night:   bool = false,
	is_cave:    bool = false,
	turn_number: int = 1
) -> float:
	# Datos del ITEMS dict
	var item_data: Dictionary = InventorySystem.ITEMS.get(ofrenda_id, {})
	if item_data.is_empty():
		return 0.0

	# Garantizado (Ofrenda Sagrada)
	if item_data.get("guaranteed_capture", false):
		return 1.0

	# Multiplicador base de la Ofrenda
	var mult_ofrenda: float = OFRENDA_MULT.get(ofrenda_id, 1.0)

	# Bonus por Esencia (tipo)
	var type1: String = target.type1
	var type2: String = target.type2
	var type_bonus: Array = item_data.get("type_bonus", [])
	if not type_bonus.is_empty():
		if type1 in type_bonus or (type2 != "" and type2 in type_bonus):
			mult_ofrenda *= 1.5

	# Bonus por primera vuelta (Xocolatl)
	if item_data.get("first_turn_only", false) and turn_number > 1:
		mult_ofrenda = 1.0  # Sin bonus fuera del primer turno

	# Bonus nocturno (Fuego Ceremonial)
	if item_data.get("night_bonus", false) and (is_night or is_cave):
		mult_ofrenda *= 1.0  # Ya tiene mult alto de base; aquí podría subir más
	elif item_data.get("night_bonus", false):
		mult_ofrenda = max(1.0, mult_ofrenda * 0.8)  # Reducción de día

	# Tasa del Tonal (catch_rate 0-255 → 0.0-1.0 base)
	var catch_rate: int = target.catch_rate if target.has_method("display_name") else 45
	var tasa_tonal: float = float(catch_rate) / 255.0

	# Multiplicador por estado
	var mult_estado: float = STATUS_MULT.get(int(target.status), 1.0)

	# HP actual y máximo
	var hp_max: float  = float(max(target.hp_max, 1))
	var hp_cur: float  = float(max(target.hp_cur, 0))

	# Fórmula central de la Biblia:
	# P = (HP_max*3 - HP_actual*2) / (HP_max*3) * tasa_tonal * mult_ofrenda * mult_estado
	var p_base: float = (hp_max * 3.0 - hp_cur * 2.0) / (hp_max * 3.0)
	var p_final: float = clampf(p_base * tasa_tonal * mult_ofrenda * mult_estado, 0.0, 1.0)

	return p_final

## Intenta el vínculo. Devuelve true si se forma, false si falla.
## Llama a mark_caught en GameManager si tiene éxito.
static func intentar_vinculo(
	target,
	ofrenda_id:  String,
	is_night:    bool = false,
	is_cave:     bool = false,
	turn_number: int  = 1
) -> bool:
	var prob = calc_prob(target, ofrenda_id, is_night, is_cave, turn_number)
	var roll = randf()
	var exito = roll <= prob

	if exito:
		GameManager.mark_caught(target.creature_id)
		# Aplicar bono de miel
		var item_data = InventorySystem.ITEMS.get(ofrenda_id, {})
		if item_data.get("on_catch_heal", false):
			target.hp_cur = target.hp_max
		# Ajustar bond según la Ofrenda
		var bond_seed: int = item_data.get("bond_seed", 50)
		target.bond = clamp(bond_seed + randi() % 10 - 5, 0, 100)

	print("VinculoSystem: prob=%.2f roll=%.2f → %s" % [prob, roll, "ÉXITO" if exito else "FALLO"])
	return exito

## Cuenta cuántos pulsos de luz mostrar (1-4) para la animación.
## Más pulsos = más cerca del éxito. 4 = éxito total.
static func pulsos_animacion(prob: float) -> int:
	if prob >= 1.0:  return 4
	if prob >= 0.65: return 3
	if prob >= 0.35: return 2
	return 1
