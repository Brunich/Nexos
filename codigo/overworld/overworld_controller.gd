## OverworldController — Coordinador genérico de escena en el overworld
## Adjunto a un Node en cualquier mapa de overworld.
## Maneja: spawn del jugador, música de zona, checkpoints.
## Cada mapa define sus spawn points como Marker2D hijos con nombres "spawn_X".
extends Node

@export var zone_name: String = "villa_nexo"
@export var zone_music: String = ""   # Nombre de audio para AudioManager

const PLAYER_SCENE = preload("res://escenas/player/player.tscn")
const GAME_MENU_SCENE = preload("res://escenas/ui/game_menu.tscn")
const QUICK_MENU_SCENE = preload("res://escenas/ui/quick_menu.tscn")

var _player: CharacterBody2D = null
var _quick_menu_latched: bool = false

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	GameManager.clear_transition()
	GameManager.dialogue_active = false
	add_to_group("overworld_controller")
	if zone_music != "":
		AudioManager.on_zone_enter(zone_music)
	call_deferred("_ensure_overworld_ui")
	call_deferred("_spawn_player")
	print("OverworldController: zona '%s' lista" % zone_name)

func _ensure_overworld_ui() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return

	if get_tree().get_first_node_in_group("game_menu") == null:
		scene_root.add_child(GAME_MENU_SCENE.instantiate())

	if get_tree().get_first_node_in_group("quick_menu") == null:
		scene_root.add_child(QUICK_MENU_SCENE.instantiate())

# ── Instanciar jugador ───────────────────────────────────────────────────────
func _spawn_player() -> void:
	var existing = get_tree().get_first_node_in_group("player")
	if existing:
		_player = existing
		_position_player()
		return
	_player = PLAYER_SCENE.instantiate()
	get_parent().add_child(_player)
	_position_player()

func _position_player() -> void:
	var spawn_id: String = GameManager.pending_spawn_id
	var pos: Vector2 = Vector2.ZERO
	var found := false

	# Buscar Marker2D con nombre "spawn_{id}"
	if spawn_id != "":
		var marker_name = "spawn_" + spawn_id
		var marker = get_parent().find_child(marker_name, true, false)
		if marker and marker is Node2D:
			pos = marker.global_position
			found = true

	# Fallback: spawn_default
	if not found:
		var default_marker = get_parent().find_child("spawn_default", true, false)
		if default_marker and default_marker is Node2D:
			pos = default_marker.global_position
			found = true

	# Último fallback: centro del mapa
	if not found:
		pos = Vector2(160, 96)

	_player.global_position = pos
	GameManager.pending_spawn_id = ""
	print("OverworldController: jugador en %s (spawn='%s')" % [pos, spawn_id])

# ── Guardar posición periódicamente ──────────────────────────────────────────
func _process(_delta: float) -> void:
	_poll_quick_menu_shortcut()
	if _player == null or GameManager.transition_in_progress:
		return
	var scene = get_tree().current_scene
	if scene == null or scene.scene_file_path == "":
		return
	GameManager.update_save_position(scene.scene_file_path, _player.global_position)

func _poll_quick_menu_shortcut() -> void:
	var pressed := Input.is_action_pressed("quick_menu") or Input.is_key_pressed(KEY_T)
	if pressed and not _quick_menu_latched:
		_quick_menu_latched = true
		var quick_menu = get_tree().get_first_node_in_group("quick_menu")
		if quick_menu and quick_menu.has_method("toggle_menu"):
			quick_menu.toggle_menu()
	elif not pressed:
		_quick_menu_latched = false
