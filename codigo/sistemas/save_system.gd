## SaveSystem — Sistema de guardado con 3 ranuras manuales + autosave
## Ranuras: user://saves/manual_1/2/3.json
## Autosave: user://saves/autosave.json
## Mantiene compatibilidad con el guardado legacy (user://emberveil_save.json)
extends Node

const SAVES_DIR    = "user://saves/"
const AUTOSAVE_PATH = "user://saves/autosave.json"
const LEGACY_PATH  = "user://emberveil_save.json"

# ── Ranuras manuales ──────────────────────────────────────────────────────────

static func slot_path(slot: int) -> String:
	return "user://saves/manual_%d.json" % slot

static func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

static func save_slot(game_manager: Node, slot: int) -> bool:
	_ensure_saves_dir()
	var data = _build_save_dict(game_manager)
	data["timestamp"] = Time.get_datetime_string_from_system()
	return _write_json(slot_path(slot), data)

static func load_slot(slot: int) -> Dictionary:
	return _read_json(slot_path(slot))

static func get_slot_info(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var data = _read_json(slot_path(slot))
	if data.is_empty():
		return {}
	return {
		"player_name": data.get("player_name", "???"),
		"playtime":    _seconds_to_hhmm(data.get("playtime_seconds", 0.0)),
		"timestamp":   data.get("timestamp", ""),
		"region":      data.get("region_name", "")
	}

# ── Autosave ──────────────────────────────────────────────────────────────────

static func save_auto(game_manager: Node) -> bool:
	_ensure_saves_dir()
	var data = _build_save_dict(game_manager)
	data["timestamp"] = Time.get_datetime_string_from_system()
	return _write_json(AUTOSAVE_PATH, data)

static func auto_exists() -> bool:
	return FileAccess.file_exists(AUTOSAVE_PATH)

static func load_auto() -> Dictionary:
	return _read_json(AUTOSAVE_PATH)

static func get_auto_info() -> Dictionary:
	if not auto_exists():
		return {}
	var data = _read_json(AUTOSAVE_PATH)
	if data.is_empty():
		return {}
	return {
		"player_name": data.get("player_name", "???"),
		"playtime":    _seconds_to_hhmm(data.get("playtime_seconds", 0.0)),
		"timestamp":   data.get("timestamp", "")
	}

# ── Compatibilidad con código legacy ─────────────────────────────────────────

static func save_exists() -> bool:
	return slot_exists(1) or slot_exists(2) or slot_exists(3) or FileAccess.file_exists(LEGACY_PATH)

static func save_game(game_manager: Node) -> bool:
	return save_slot(game_manager, 1)

static func load_game() -> Dictionary:
	# Intentar slot 1 primero, luego slots 2/3, luego legacy
	for slot in [1, 2, 3]:
		if slot_exists(slot):
			return load_slot(slot)
	if FileAccess.file_exists(LEGACY_PATH):
		return _read_json(LEGACY_PATH)
	return {}

static func delete_save() -> bool:
	var ok = true
	for slot in [1, 2, 3]:
		if slot_exists(slot):
			var err = DirAccess.remove_absolute(slot_path(slot))
			if err != OK:
				ok = false
	return ok

# ── Internals ─────────────────────────────────────────────────────────────────

static func _ensure_saves_dir() -> void:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)

static func _build_save_dict(gm: Node) -> Dictionary:
	var d = {
		"version": "2.1",
		"player_name": gm.player_name,
		"region_name": gm.current_region,
		"playtime_seconds": gm.playtime_seconds,
		"save_scene": gm.save_scene,
		"save_position": { "x": gm.save_position.x, "y": gm.save_position.y },
		"pending_spawn_id": gm.pending_spawn_id,
		"checkpoint_scene": gm.checkpoint_scene,
		"checkpoint_spawn_id": gm.checkpoint_spawn_id,
		"checkpoint_position": { "x": gm.checkpoint_position.x, "y": gm.checkpoint_position.y },
		"party": _serialize_party(gm.party),
		"storage_box": _serialize_party(gm.storage_box),
		"badges": gm.badges,
		"money": gm.money,
		"inventory": InventorySystem.get_snapshot(),
		"flags": gm.flags,
		"caught_ids": gm.caught_ids,
		"seen_ids": gm.seen_ids,
	}
	# Latido (vínculo por Tonal)
	if gm.latido != null:
		d["latido"] = gm.latido.to_dict()
	# Huella (identidad del jugador)
	if gm.huella != null:
		d["huella"] = gm.huella.to_dict()
	return d

static func _write_json(path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("SaveSystem: Error escribiendo en ", path)
		return false
	file.store_string(JSON.stringify(data))
	print("SaveSystem: guardado → ", path)
	return true

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("SaveSystem: error parseando ", path)
		return {}
	return json.data

static func _seconds_to_hhmm(seconds: float) -> String:
	var s = int(seconds)
	return "%02d:%02d" % [s / 3600, (s % 3600) / 60]

static func _serialize_party(party: Array) -> Array:
	var out = []
	for c in party:
		out.append({
			"id":        c.creature_id,
			"nickname":  c.nickname,
			"skin":      c.active_skin,
			"nature":    c.nature,
			"ability":   c.ability,
			"held_item": c.held_item,
			"catch_rate": c.catch_rate,
			"iv_hp":     c.iv_hp,
			"iv_atk":    c.iv_atk,
			"iv_def":    c.iv_def,
			"iv_sp_atk": c.iv_sp_atk,
			"iv_sp_def": c.iv_sp_def,
			"iv_speed":  c.iv_speed,
			"level":     c.level,
			"bond":      c.bond,
			"hp_cur":    c.hp_cur,
			"hp_max":    c.hp_max,
			"exp":       c.experience,
			"status":    c.status,
			"type1":     c.type1,
			"type2":     c.type2,
			"moves":     _serialize_moves(c.moves, c.moves_pp)
		})
	return out

static func _serialize_moves(moves: Array, moves_pp: Array) -> Array:
	var out = []
	for i in moves.size():
		var move: MoveData = moves[i]
		out.append({
			"name":   move.move_name,
			"pp":     moves_pp[i] if i < moves_pp.size() else move.pp_max,
			"pp_max": move.pp_max
		})
	return out
