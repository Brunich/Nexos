## EncounterTable — Tablas de encuentros salvajes por zona
## Uso: EncounterTable.get_encounter_id(zone_name, player_level) -> int (creature_id)
## Devuelve -1 si la zona no tiene encuentros definidos.

# ── Tablas por zona ───────────────────────────────────────────────────────────
# Cada entrada: { "id": creature_id, "min_lv": N, "max_lv": N, "weight": N }
# "weight" es peso relativo (higher = más frecuente)

const TABLES : Dictionary = {
	"pielago_central": [
		{ "id": 1027, "min_lv": 3, "max_lv": 6, "weight": 35 },   # Miauth
		{ "id": 1039, "min_lv": 3, "max_lv": 6, "weight": 25 },   # Jollow
		{ "id": 1020, "min_lv": 4, "max_lv": 7, "weight": 20 },   # Aurora
		{ "id": 1030, "min_lv": 4, "max_lv": 7, "weight": 20 },   # Velimal
	],
	"route1": [
		{ "id": 1022, "min_lv": 3, "max_lv": 7, "weight": 30 },   # Derritol
		{ "id": 1029, "min_lv": 3, "max_lv": 7, "weight": 25 },   # Pectrix
		{ "id": 1024, "min_lv": 4, "max_lv": 8, "weight": 25 },   # Gorripo
		{ "id": 1032, "min_lv": 3, "max_lv": 6, "weight": 20 },   # Semillillo
	],
	"route2": [
		{ "id": 1021, "min_lv": 5, "max_lv": 10, "weight": 30 },  # Axolurk
		{ "id": 1023, "min_lv": 5, "max_lv": 10, "weight": 25 },  # Florista
		{ "id": 1028, "min_lv": 6, "max_lv": 11, "weight": 25 },  # Mordecur
		{ "id": 1031, "min_lv": 7, "max_lv": 12, "weight": 20 },  # Cascabex
	],
	"canopyhold": [
		{ "id": 1023, "min_lv": 8,  "max_lv": 14, "weight": 30 }, # Florista
		{ "id": 1032, "min_lv": 5,  "max_lv": 10, "weight": 25 }, # Semillillo
		{ "id": 1039, "min_lv": 7,  "max_lv": 13, "weight": 25 }, # Jollow
		{ "id": 1036, "min_lv": 10, "max_lv": 15, "weight": 20 }, # Palohex
	],
	"tidelock": [
		{ "id": 1021, "min_lv": 8,  "max_lv": 14, "weight": 35 }, # Axolurk
		{ "id": 1027, "min_lv": 5,  "max_lv": 10, "weight": 25 }, # Miauth
		{ "id": 1034, "min_lv": 10, "max_lv": 16, "weight": 25 }, # Alacrix
		{ "id": 1037, "min_lv": 12, "max_lv": 18, "weight": 15 }, # Serphueso
	],
	"ashenveil": [
		{ "id": 1022, "min_lv": 6,  "max_lv": 12, "weight": 30 }, # Derritol
		{ "id": 1031, "min_lv": 8,  "max_lv": 14, "weight": 25 }, # Cascabex
		{ "id": 1029, "min_lv": 7,  "max_lv": 13, "weight": 25 }, # Pectrix
		{ "id": 1038, "min_lv": 12, "max_lv": 18, "weight": 20 }, # Totemix
	],
	"duskwall": [
		{ "id": 1039, "min_lv": 10, "max_lv": 16, "weight": 30 }, # Jollow
		{ "id": 1035, "min_lv": 10, "max_lv": 16, "weight": 30 }, # Calavela
		{ "id": 1025, "min_lv": 14, "max_lv": 20, "weight": 25 }, # Hollfrost
		{ "id": 1033, "min_lv": 18, "max_lv": 25, "weight": 15 }, # Copalux
	],
	"nora": [
		{ "id": 1028, "min_lv": 8,  "max_lv": 15, "weight": 30 }, # Mordecur
		{ "id": 1037, "min_lv": 10, "max_lv": 16, "weight": 25 }, # Serphueso
		{ "id": 1038, "min_lv": 12, "max_lv": 18, "weight": 25 }, # Totemix
		{ "id": 1031, "min_lv": 10, "max_lv": 16, "weight": 20 }, # Cascabex
	],
	"zenera": [
		{ "id": 1022, "min_lv": 10, "max_lv": 18, "weight": 30 }, # Derritol
		{ "id": 1034, "min_lv": 12, "max_lv": 20, "weight": 25 }, # Alacrix
		{ "id": 1029, "min_lv": 10, "max_lv": 17, "weight": 25 }, # Pectrix
		{ "id": 1026, "min_lv": 16, "max_lv": 24, "weight": 20 }, # Lienx
	],
	"levante": [
		{ "id": 1035, "min_lv": 10, "max_lv": 18, "weight": 30 }, # Calavela
		{ "id": 1033, "min_lv": 15, "max_lv": 22, "weight": 25 }, # Copalux
		{ "id": 1039, "min_lv": 8,  "max_lv": 14, "weight": 25 }, # Jollow
		{ "id": 1026, "min_lv": 18, "max_lv": 26, "weight": 20 }, # Lienx
	],
}

const ZONE_ALIASES : Dictionary = {
	"villa_nexo": "pielago_central",
	"ruta_1": "route1",
	"ruta1": "route1",
	"ciudad_nora": "nora",
	"ruta_2": "route2",
	"ruta2": "route2",
}

# ─────────────────────────────────────────────────────────────────────────────

## Devuelve un creature_id aleatorio para la zona dada.
## Usa los pesos de la tabla. Devuelve -1 si la zona no está definida.
static func get_encounter_id(zone_name: String, _player_level: int = 5) -> int:
	var resolved_zone := resolve_zone_name(zone_name)
	var table : Array = TABLES.get(resolved_zone, [])
	if table.is_empty():
		return -1
	var total_weight : int = 0
	for row in table:
		total_weight += row["weight"]
	var roll : int = randi() % total_weight
	var acc  : int = 0
	for row in table:
		acc += row["weight"]
		if roll < acc:
			return row["id"]
	return table[-1]["id"]

## Devuelve nivel aleatorio para el encuentro en la zona.
static func get_encounter_level(zone_name: String, _player_level: int = 5) -> int:
	var resolved_zone := resolve_zone_name(zone_name)
	var table : Array = TABLES.get(resolved_zone, [])
	if table.is_empty():
		return 3
	# Promedio de todos los rangos de la zona
	var total_id  := get_encounter_id(resolved_zone, _player_level)
	for row in table:
		if row["id"] == total_id:
			return randi_range(row["min_lv"], row["max_lv"])
	return 3

## Lista de IDs que pueden aparecer en una zona (para preview en UI)
static func get_zone_ids(zone_name: String) -> Array:
	var resolved_zone := resolve_zone_name(zone_name)
	var table : Array = TABLES.get(resolved_zone, [])
	return table.map(func(r): return r["id"])

static func resolve_zone_name(zone_name: String) -> String:
	return ZONE_ALIASES.get(zone_name, zone_name)
