## TallGrass — Zona de hierba alta con encuentros aleatorios
## Adjunto a Area2D en mapas de overworld/rutas.
## Cuenta pasos del jugador y lanza encuentros según probabilidad.
extends Area2D

const EncounterTable = preload("res://codigo/datos/encounter_table.gd")
const PokedexData = preload("res://codigo/datos/pokedex_data.gd")
## CreatureInstance disponible globalmente via class_name — no requiere preload.

@export var encounter_chance: float = 0.10   ## Probabilidad base por paso (10%)
@export var min_steps_between: int = 3        ## Pasos mínimos entre encuentros
@export var zone_name: String = ""            ## Nombre de zona para tabla de encuentros

var _player_inside: bool = false
var _steps_since_last: int = 0
var _last_player_pos: Vector2 = Vector2.ZERO
const STEP_DISTANCE: float = 14.0  ## Pixeles por "paso" a 16px/tile

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_last_player_pos = body.global_position

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _process(_delta: float) -> void:
	if not _player_inside:
		return
	if GameManager.dialogue_active:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dist = player.global_position.distance_to(_last_player_pos)
	if dist >= STEP_DISTANCE:
		_last_player_pos = player.global_position
		_on_player_step()

func _on_player_step() -> void:
	_steps_since_last += 1
	if _steps_since_last < min_steps_between:
		return

	# Probabilidad base — DifficultySystem es RefCounted, se instancia por BattleManager cuando esté listo
	var roll = randf()
	if roll < encounter_chance:
		_steps_since_last = 0
		_trigger_encounter()

func _trigger_encounter() -> void:
	var zname : String = zone_name
	if zname == "":
		var oc = get_tree().get_first_node_in_group("overworld_controller")
		if oc and "zone_name" in oc:
			zname = oc.zone_name
	if zname == "":
		zname = "pielago_central"

	var player_lv : int = 5
	if GameManager.party.size() > 0:
		var first = GameManager.party[0]
		player_lv = first.level if first is Object else first.get("level", 5)

	var creature_id : int = EncounterTable.get_encounter_id(zname, player_lv)
	if creature_id == -1:
		print("TallGrass: zona '%s' sin tabla — sin encuentro" % zname)
		return

	var lv    : int        = EncounterTable.get_encounter_level(zname, player_lv)
	var entry : Dictionary = PokedexData.get_entry(creature_id)
	if entry.is_empty():
		return

	GameManager.mark_seen(creature_id)
	print("TallGrass: encuentro → %s Nv.%d en '%s'" % [entry.get("name","?"), lv, zname])

	if GameManager.party.is_empty():
		push_warning("TallGrass: no hay Nexos en el equipo, no se puede iniciar batalla")
		return

	# Guardar escena actual para volver al terminar la batalla
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.scene_file_path != "":
		GameManager.update_save_position(current_scene.scene_file_path, Vector2.ZERO)

	var enemy_creature = CreatureInstance.create(creature_id, lv)
	GameManager.dialogue_active = true
	# Transición a escena de batalla
	GameManager.pending_spawn_id = ""
	var battle_scene_node = load("res://escenas/batalla/battle_scene.tscn").instantiate()
	get_tree().root.add_child(battle_scene_node)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = battle_scene_node
	battle_scene_node.setup_wild_encounter(GameManager.party[0], enemy_creature)
