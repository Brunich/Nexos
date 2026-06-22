## ExperienceSystem — Fórmulas de experiencia para NEXOS
## Todas las funciones son estáticas.
## Tasas de crecimiento: FAST, MEDIUM_FAST, MEDIUM_SLOW, SLOW, ERRATIC, FLUCTUATING
class_name ExperienceSystem

enum GrowthRate {
	FAST,
	MEDIUM_FAST,
	MEDIUM_SLOW,
	SLOW,
	ERRATIC,
	FLUCTUATING,
}

## EXP total necesaria para alcanzar 'level' según la tasa de crecimiento
static func exp_for_level(level: int, rate: GrowthRate) -> int:
	var n = max(1, level)
	match rate:
		GrowthRate.FAST:
			return int(0.8 * n * n * n)
		GrowthRate.MEDIUM_FAST:
			return n * n * n
		GrowthRate.MEDIUM_SLOW:
			return int(1.2 * n * n * n - 15.0 * n * n + 100.0 * n - 140)
		GrowthRate.SLOW:
			return int(1.25 * n * n * n)
		GrowthRate.ERRATIC:
			# Simplified piecewise
			if n <= 50:
				return int(n * n * n * (100 - n) / 50)
			elif n <= 68:
				return int(n * n * n * (150 - n) / 100)
			elif n <= 98:
				return int(n * n * n * int((1911 - 10 * n) / 3) / 500)
			else:
				return int(n * n * n * (160 - n) / 100)
		GrowthRate.FLUCTUATING:
			if n <= 15:
				return int(n * n * n * (int((n + 1) / 3) + 24) / 50)
			elif n <= 36:
				return int(n * n * n * (n + 14) / 50)
			else:
				return int(n * n * n * (int(n / 2) + 32) / 50)
	return n * n * n  # fallback MEDIUM_FAST

## EXP ganada al derrotar una criatura
static func exp_gained(base_exp: int, level: int, wild: bool = true) -> int:
	var a = 1.0 if wild else 1.5
	return int((a * base_exp * level) / 7.0)

## Obtener la tasa de crecimiento de una criatura por ID
## Mapeamos IDs NEXUS 1001-1019 a tasas según el diseño del CLAUDE.md
static func get_growth_rate(creature_id: int) -> GrowthRate:
	match creature_id:
		1001, 1002:          return GrowthRate.MEDIUM_SLOW  # Embral / Embralcinder
		1003, 1004:          return GrowthRate.MEDIUM_FAST  # Folimp / Folivian
		1005:                return GrowthRate.FAST          # Larvox
		1006:                return GrowthRate.MEDIUM_SLOW  # Solmund
		1007, 1011:          return GrowthRate.SLOW         # Crystabel / Glacinth
		1008, 1009:          return GrowthRate.MEDIUM_FAST  # Aquellux / Oshenite
		1010, 1013, 1019:    return GrowthRate.SLOW         # Necroveil / Bonehound / Spectryn
		1012, 1017:          return GrowthRate.SLOW         # Scarfang / Drakpup
		1014:                return GrowthRate.MEDIUM_SLOW  # Veildark
		1015, 1016:          return GrowthRate.FAST         # Spidrel / Deepfin
		1018:                return GrowthRate.MEDIUM_FAST  # Voltux
	return GrowthRate.MEDIUM_FAST  # Fallback
