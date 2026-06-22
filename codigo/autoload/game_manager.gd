## GameManager — Autoload global de estado del juego NEXOS
## Maneja: jugador, party, flags, posición guardada, transiciones de escena,
##         sistema de Huella (identidad) y Latido (vínculo por Tonal).
extends Node

const LatidoSystem = preload("res://codigo/sistemas/latido_system.gd")
const HuellaSystem = preload("res://codigo/sistemas/huella_system.gd")

# ── Datos del jugador ─────────────────────────────────────────────────────────
var player_name: String = "Nix"
var current_region: String = "sierra_norte"
var playtime_seconds: float = 0.0

# ── Posición de guardado y checkpoint ─────────────────────────────────────────
var save_scene: String = "res://escenas/overworld/villa_nexo.tscn"
var save_position: Vector2 = Vector2(240, 300)
var pending_spawn_id: String = ""

var checkpoint_scene: String = "res://escenas/overworld/villa_nexo.tscn"
var checkpoint_spawn_id: String = ""
var checkpoint_position: Vector2 = Vector2(240, 300)

# ── Party y almacenamiento ────────────────────────────────────────────────────
var party: Array = []
var storage_box: Array = []

# ── Progresión ────────────────────────────────────────────────────────────────
var badges: Array = []
var money: int = 500
var flags: Dictionary = {}
var caught_ids: Array = []
var seen_ids: Array = []

# ── Estado de UI/juego (no se guarda) ─────────────────────────────────────────
var dialogue_active: bool = false
var transition_in_progress: bool = false

# ── Sistemas de identidad y vínculo ───────────────────────────────────────────
var latido: LatidoSystem = null
var huella: HuellaSystem = null

# ── Autosave ──────────────────────────────────────────────────────────────────
var _autosave_timer: Timer = null
const AUTOSAVE_INTERVAL = 180.0  # 3 minutos

# ── Señales ───────────────────────────────────────────────────────────────────
signal scene_transition_requested(scene_path: String, spawn_id: String)
signal flag_changed(flag_name: String, value: bool)
signal money_changed(new_amount: int)

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.autostart = false
	_autosave_timer.timeout.connect(_on_autosave_timer)
	add_child(_autosave_timer)
	# Inicializar sistemas de identidad y vínculo
	latido = LatidoSystem.new()
	huella = HuellaSystem.new()
	print("GameManager: iniciado (NEXOS)")

func _on_autosave_timer() -> void:
	if party.size() > 0 and flag_check("nana_intro_done"):
		SaveSystem.save_auto(self)

func start_autosave() -> void:
	if _autosave_timer and not _autosave_timer.is_stopped():
		return
	_autosave_timer.start()

func _process(delta: float) -> void:
	if not dialogue_active:
		playtime_seconds += delta

# ── Nueva partida ─────────────────────────────────────────────────────────────
func setup_new_adventure(name: String = "Nix") -> void:
	player_name = name
	current_region = "sierra_norte"
	playtime_seconds = 0.0
	save_scene = "res://escenas/overworld/villa_nexo.tscn"
	save_position = Vector2(240, 300)
	pending_spawn_id = "default"
	checkpoint_scene = save_scene
	checkpoint_spawn_id = "default"
	checkpoint_position = save_position
	party = []
	storage_box = []
	badges = []
	money = 500
	flags = {}
	caught_ids = []
	seen_ids = []
	dialogue_active = false
	# ── Objetos de inicio ─────────────────────────────────────────────────────
	InventorySystem.inventory.clear()
	InventorySystem.add_item("potion",          3)   # 3× Suero rojo
	InventorySystem.add_item("ofrenda_copal",   3)   # 3× Ofrenda de Copal
	InventorySystem.add_item("ofrenda_jade",    1)   # 1× Ofrenda de Jade (regalo Nana)
	start_autosave()
	print("GameManager: nueva aventura para '%s'" % player_name)

# ── Cargar datos desde SaveSystem ─────────────────────────────────────────────
func apply_load(data: Dictionary) -> void:
	if data.is_empty():
		return
	player_name         = data.get("player_name", "Nix")
	current_region      = data.get("region_name", "sierra_norte")
	playtime_seconds    = data.get("playtime_seconds", 0.0)
	save_scene          = data.get("save_scene", "res://escenas/overworld/villa_nexo.tscn")
	var sp              = data.get("save_position", {"x": 240, "y": 300})
	save_position       = Vector2(sp.get("x", 240), sp.get("y", 300))
	pending_spawn_id    = data.get("pending_spawn_id", "")
	checkpoint_scene    = data.get("checkpoint_scene", save_scene)
	checkpoint_spawn_id = data.get("checkpoint_spawn_id", "")
	var cp              = data.get("checkpoint_position", {"x": 240, "y": 300})
	checkpoint_position = Vector2(cp.get("x", 240), cp.get("y", 300))
	badges              = data.get("badges", [])
	money               = data.get("money", 500)
	flags               = data.get("flags", {})
	caught_ids          = data.get("caught_ids", [])
	seen_ids            = data.get("seen_ids", [])
	# Restaurar Latido
	if latido == null: latido = LatidoSystem.new()
	if data.has("latido"):
		latido.from_dict(data["latido"])
	# Restaurar Huella
	if huella == null: huella = HuellaSystem.new()
	if data.has("huella"):
		huella.from_dict(data["huella"])
	start_autosave()
	print("GameManager: datos cargados para '%s'" % player_name)

# ── Transición de escena ───────────────────────────────────────────────────────
## Llamado por WarpZone cuando el jugador pisa la zona de warp
func request_scene_change(scene_path: String, spawn_id: String = "") -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	pending_spawn_id = spawn_id
	scene_transition_requested.emit(scene_path, spawn_id)
	# Pequeño delay para que la animación de transición pueda ocurrir
	await get_tree().create_timer(0.05).timeout
	get_tree().change_scene_to_file(scene_path)
	# transition_in_progress se resetea en el próximo _ready del OverworldController

func clear_transition() -> void:
	transition_in_progress = false

# ── Guardar posición del jugador ──────────────────────────────────────────────
func update_save_position(scene_path: String, position: Vector2, spawn_id: String = "") -> void:
	save_scene = scene_path
	save_position = position
	if spawn_id != "":
		pending_spawn_id = spawn_id

func set_checkpoint(scene_path: String, position: Vector2, spawn_id: String = "") -> void:
	checkpoint_scene    = scene_path
	checkpoint_position = position
	checkpoint_spawn_id = spawn_id

# ── Flags ─────────────────────────────────────────────────────────────────────
func flag_set(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)

func flag_check(flag_name: String) -> bool:
	return flags.get(flag_name, false)

# ── Dinero ────────────────────────────────────────────────────────────────────
func add_money(amount: int) -> void:
	money = max(0, money + amount)
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true

# ── Criaturas vistas/capturadas ───────────────────────────────────────────────
func mark_seen(creature_id: int) -> void:
	if creature_id not in seen_ids:
		seen_ids.append(creature_id)

func mark_caught(creature_id: int) -> void:
	mark_seen(creature_id)
	if creature_id not in caught_ids:
		caught_ids.append(creature_id)

# ── Registro de Huella (identidad del jugador) ────────────────────────────────
func registrar_huella(accion_id: String) -> void:
	if huella:
		huella.registrar(accion_id)

# ── Registro de Latido (vínculo por Tonal) ───────────────────────────────────
## Devuelve la clave de vínculo para un Tonal en el equipo (posición-based)
func latido_id(creature_index: int) -> String:
	return "party_%d" % creature_index

## Mejora el Latido al curar un Tonal
func latido_curar(creature_index: int) -> void:
	if latido:
		latido.evento_cuidado(latido_id(creature_index))
	registrar_huella("curar_tonal")

## Deteriora el Latido cuando un Tonal cae en batalla
func latido_derrota(creature_index: int) -> void:
	if latido:
		latido.evento_derrota(latido_id(creature_index))

## Mejora el Latido con victoria en batalla
func latido_victoria(creature_index: int) -> void:
	if latido:
		latido.evento_victoria(latido_id(creature_index))

## Obtiene el valor de bond del sistema LatidoSystem para un Tonal del equipo
func get_latido_valor(creature_index: int) -> int:
	if latido == null: return 50
	var lid = latido_id(creature_index)
	return latido.vinculos.get(lid, 60)

# ── Utilidades ────────────────────────────────────────────────────────────────
func get_playtime_string() -> String:
	var hours   = int(playtime_seconds) / 3600
	var minutes = (int(playtime_seconds) % 3600) / 60
	return "%02d:%02d" % [hours, minutes]
