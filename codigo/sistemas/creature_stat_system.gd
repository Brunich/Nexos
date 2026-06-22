## CreatureStatSystem — Cálculo central de stats, EXP y balance competitivo.
## Mantiene un BST máximo de 600 para formas finales y deriva preevoluciones
## a partir de la forma final preservando la especialización del Nexo.
extends RefCounted
class_name CreatureStatSystem

const ExperienceSystem = preload("res://codigo/batalla/experience_system.gd")
const PokedexData = preload("res://codigo/datos/pokedex_data.gd")

const FINAL_FORM_BST_CAP := 600
const STAT_KEYS := ["hp", "atk", "def", "spatk", "spdef", "spd"]
const RUNTIME_TO_BASE := {
	"hp_max": "hp",
	"atk": "atk",
	"def": "def",
	"sp_atk": "spatk",
	"sp_def": "spdef",
	"speed": "spd",
}
const BASE_TO_RUNTIME := {
	"hp": "hp_max",
	"atk": "atk",
	"def": "def",
	"spatk": "sp_atk",
	"spdef": "sp_def",
	"spd": "speed",
}
const MORPH_WEIGHTS := {
	"robust": {"hp": 1.35, "atk": 1.25, "def": 1.20, "spatk": 0.75, "spdef": 0.90, "spd": 0.55},
	"agile":  {"hp": 0.82, "atk": 0.78, "def": 0.82, "spatk": 1.18, "spdef": 1.05, "spd": 1.35},
	"hybrid": {"hp": 1.02, "atk": 1.00, "def": 1.00, "spatk": 1.00, "spdef": 0.98, "spd": 1.00},
}
const STAGE_SCALES := {
	1: [1.0],
	2: [0.68, 1.0],
	3: [0.46, 0.72, 1.0],
}

static func resolve_creature_id(creature_ref: Variant) -> int:
	if creature_ref is int:
		return int(creature_ref)
	if creature_ref is String:
		var as_text: String = String(creature_ref)
		if as_text.is_valid_int():
			return int(as_text)
		var wanted: String = as_text.to_lower().strip_edges()
		for entry in PokedexData.get_catalogue():
			if String(entry.get("name", "")).to_lower() == wanted:
				return int(entry.get("id", 0))
	return 0

static func base_stat_total(base_stats: Dictionary) -> int:
	var total := 0
	for key in STAT_KEYS:
		total += int(base_stats.get(key, 0))
	return total

static func get_base_stats(creature_id: int) -> Dictionary:
	var entry: Dictionary = PokedexData.get_entry(creature_id)
	if entry.is_empty():
		return _default_base_stats()

	var chain: Array = entry.get("evolution", [])
	if chain.is_empty():
		chain = [creature_id]

	var stage_index: int = chain.find(creature_id)
	if stage_index < 0:
		stage_index = chain.size() - 1

	var final_id: int = int(chain[chain.size() - 1])
	var final_entry: Dictionary = PokedexData.get_entry(final_id)
	var source_final_base: Dictionary = final_entry.get("base", entry.get("base", _default_base_stats()))
	var target_total: int = min(base_stat_total(source_final_base), FINAL_FORM_BST_CAP)
	var final_base: Dictionary = _profile_final_base(final_entry, source_final_base, target_total)

	if stage_index >= chain.size() - 1:
		return final_base

	var scale: float = _stage_scale(chain.size(), stage_index)
	return _scale_base_stats(final_base, scale)

static func infer_morphology(creature_id: int) -> String:
	var entry: Dictionary = PokedexData.get_entry(creature_id)
	if entry.is_empty():
		return "hybrid"

	var declared: String = String(entry.get("morphology", "")).to_lower()
	if declared in ["robust", "agile", "hybrid"]:
		return declared

	var base: Dictionary = entry.get("base", _default_base_stats())
	var weight := float(entry.get("weight", 0.0))
	var height := float(entry.get("height", 0.0))
	var physical := int(base.get("hp", 0)) + int(base.get("atk", 0)) + int(base.get("def", 0))
	var special := int(base.get("spatk", 0)) + int(base.get("spdef", 0)) + int(base.get("spd", 0))

	if weight >= 35.0 or height >= 1.4 or physical >= special + 25:
		return "robust"
	if (weight <= 14.0 and height <= 0.9) or special >= physical + 25 or int(base.get("spd", 0)) >= 95:
		return "agile"
	return "hybrid"

static func get_experience_progress(experience: int, level: int, creature_id: int) -> Dictionary:
	var growth_rate: ExperienceSystem.GrowthRate = ExperienceSystem.get_growth_rate(creature_id)
	var current_level_exp: int = ExperienceSystem.exp_for_level(level, growth_rate)
	var next_level_exp: int = ExperienceSystem.exp_for_level(min(level + 1, 100), growth_rate)
	var gained: int = clamp(experience - current_level_exp, 0, max(next_level_exp - current_level_exp, 0))
	var needed: int = max(1, next_level_exp - current_level_exp)
	return {
		"current_level_exp": current_level_exp,
		"next_level_exp": next_level_exp,
		"earned": gained,
		"needed": needed,
		"ratio": float(gained) / float(needed),
	}

static func recalculate_creature(creature: Object, preserve_hp_ratio: bool = false) -> Dictionary:
	var previous_stats: Dictionary = get_runtime_stat_dict(creature)
	var current_hp := int(creature.hp_cur)
	var previous_hp_max := int(max(1, previous_stats.get("hp_max", 1)))
	var base_stats: Dictionary = get_base_stats(int(creature.creature_id))
	var entry: Dictionary = PokedexData.get_entry(int(creature.creature_id))

	creature.type1 = entry.get("type1", creature.type1)
	creature.type2 = entry.get("type2", creature.type2)
	creature.hp_max = _calc_stat(int(base_stats.get("hp", 1)), int(creature.iv_hp), int(creature.level), true)
	creature.atk = _calc_stat(int(base_stats.get("atk", 1)), int(creature.iv_atk), int(creature.level), false)
	creature.def = _calc_stat(int(base_stats.get("def", 1)), int(creature.iv_def), int(creature.level), false)
	creature.sp_atk = _calc_stat(int(base_stats.get("spatk", 1)), int(creature.iv_sp_atk), int(creature.level), false)
	creature.sp_def = _calc_stat(int(base_stats.get("spdef", 1)), int(creature.iv_sp_def), int(creature.level), false)
	creature.speed = _calc_stat(int(base_stats.get("spd", 1)), int(creature.iv_speed), int(creature.level), false)

	if preserve_hp_ratio:
		var ratio: float = float(current_hp) / float(previous_hp_max)
		creature.hp_cur = clamp(int(round(ratio * float(creature.hp_max))), 0, int(creature.hp_max))
	else:
		creature.hp_cur = clamp(current_hp, 0, int(creature.hp_max))

	return diff_runtime_stats(previous_stats, get_runtime_stat_dict(creature))

static func apply_experience(creature: Object, amount: int) -> Dictionary:
	var safe_amount: int = max(0, amount)
	var growth_rate: ExperienceSystem.GrowthRate = ExperienceSystem.get_growth_rate(int(creature.creature_id))
	var before_level := int(creature.level)
	var level_steps: Array = []
	var final_deltas := {
		"hp_max": 0,
		"atk": 0,
		"def": 0,
		"sp_atk": 0,
		"sp_def": 0,
		"speed": 0,
	}

	creature.experience += safe_amount

	while int(creature.level) < 100:
		var next_level: int = int(creature.level) + 1
		var needed_total: int = ExperienceSystem.exp_for_level(next_level, growth_rate)
		if int(creature.experience) < needed_total:
			break

		var before_stats: Dictionary = get_runtime_stat_dict(creature)
		var before_hp_cur := int(creature.hp_cur)
		creature.level = next_level
		recalculate_creature(creature, false)
		var after_stats: Dictionary = get_runtime_stat_dict(creature)
		var deltas: Dictionary = diff_runtime_stats(before_stats, after_stats)
		var hp_gain: int = int(deltas.get("hp_max", 0))
		if hp_gain > 0 and before_hp_cur > 0:
			creature.hp_cur = min(int(creature.hp_cur) + hp_gain, int(creature.hp_max))

		for key in final_deltas.keys():
			final_deltas[key] = int(final_deltas[key]) + int(deltas.get(key, 0))

		level_steps.append({
			"from_level": next_level - 1,
			"to_level": next_level,
			"deltas": deltas.duplicate(),
		})

	return {
		"levels_gained": int(creature.level) - before_level,
		"from_level": before_level,
		"to_level": int(creature.level),
		"steps": level_steps,
		"final_deltas": final_deltas,
		"exp_progress": get_experience_progress(int(creature.experience), int(creature.level), int(creature.creature_id)),
	}

static func get_runtime_stat_dict(creature: Object) -> Dictionary:
	return {
		"hp_max": int(creature.hp_max),
		"atk": int(creature.atk),
		"def": int(creature.def),
		"sp_atk": int(creature.sp_atk),
		"sp_def": int(creature.sp_def),
		"speed": int(creature.speed),
	}

static func diff_runtime_stats(before_stats: Dictionary, after_stats: Dictionary) -> Dictionary:
	var deltas := {}
	for key in ["hp_max", "atk", "def", "sp_atk", "sp_def", "speed"]:
		deltas[key] = int(after_stats.get(key, 0)) - int(before_stats.get(key, 0))
	return deltas

static func _default_base_stats() -> Dictionary:
	return {"hp": 50, "atk": 50, "def": 50, "spatk": 50, "spdef": 50, "spd": 50}

static func _stage_scale(chain_size: int, stage_index: int) -> float:
	if STAGE_SCALES.has(chain_size):
		var row: Array = STAGE_SCALES[chain_size]
		return float(row[clamp(stage_index, 0, row.size() - 1)])
	if stage_index <= 0:
		return 0.48
	if stage_index == chain_size - 1:
		return 1.0
	return 0.72

static func _profile_final_base(entry: Dictionary, source_final_base: Dictionary, target_total: int) -> Dictionary:
	var morphology: String = infer_morphology(int(entry.get("id", 0)))
	var weights: Dictionary = MORPH_WEIGHTS.get(morphology, MORPH_WEIGHTS["hybrid"])
	var weight_sum: float = 0.0
	for key in STAT_KEYS:
		weight_sum += float(weights.get(key, 1.0))

	var raw_scores: Dictionary = {}
	for key in STAT_KEYS:
		var current_value := float(source_final_base.get(key, 50))
		var preferred_value := (float(target_total) * float(weights.get(key, 1.0))) / weight_sum
		raw_scores[key] = current_value * 0.70 + preferred_value * 0.30

	return _normalize_to_total(raw_scores, target_total)

static func _scale_base_stats(final_base: Dictionary, scale: float) -> Dictionary:
	var raw_scores: Dictionary = {}
	var target_total: int = max(120, int(round(float(base_stat_total(final_base)) * scale)))
	for key in STAT_KEYS:
		raw_scores[key] = float(final_base.get(key, 50)) * scale
	return _normalize_to_total(raw_scores, target_total)

static func _normalize_to_total(raw_scores: Dictionary, target_total: int) -> Dictionary:
	var values: Dictionary = {}
	var fractions: Array = []
	var used_total: int = 0

	for key in STAT_KEYS:
		var raw_value: float = max(1.0, float(raw_scores.get(key, 1.0)))
		var whole: int = int(floor(raw_value))
		values[key] = whole
		used_total += whole
		fractions.append({"key": key, "frac": raw_value - float(whole)})

	var diff: int = target_total - used_total
	if diff > 0:
		fractions.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["frac"]) > float(b["frac"]))
		var i: int = 0
		while diff > 0:
			var idx: int = i % max(1, fractions.size())
			var add_key := String(fractions[idx]["key"])
			values[add_key] = int(values.get(add_key, 0)) + 1
			diff -= 1
			i += 1
	elif diff < 0:
		fractions.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["frac"]) < float(b["frac"]))
		var j: int = 0
		while diff < 0 and j < 500:
			var idx2: int = j % max(1, fractions.size())
			var sub_key := String(fractions[idx2]["key"])
			if int(values.get(sub_key, 1)) > 1:
				values[sub_key] = int(values.get(sub_key, 1)) - 1
				diff += 1
			j += 1

	return values

static func _calc_stat(base_value: int, iv: int, level: int, is_hp: bool) -> int:
	if is_hp:
		return int(floor((2.0 * float(base_value) + float(iv)) * float(level) / 100.0)) + level + 10
	return int(floor((2.0 * float(base_value) + float(iv)) * float(level) / 100.0)) + 5
