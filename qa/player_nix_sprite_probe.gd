extends Node

const PLAYER_SCENE := "res://escenas/player/player.tscn"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameManager.setup_new_adventure("Probe")

	var player_scene: PackedScene = load(PLAYER_SCENE)
	if player_scene == null:
		push_error("PLAYER_NIX_SPRITE_PROBE: no se pudo cargar player.tscn")
		get_tree().quit(1)
		return

	var player := player_scene.instantiate()
	add_child(player)
	await get_tree().process_frame
	await get_tree().process_frame

	var sprite := player.get_node_or_null("sprite") as AnimatedSprite2D
	if sprite == null:
		push_error("PLAYER_NIX_SPRITE_PROBE: falta AnimatedSprite2D")
		get_tree().quit(1)
		return

	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("walk_down"):
		push_error("PLAYER_NIX_SPRITE_PROBE: no se cargaron animaciones")
		get_tree().quit(1)
		return

	var tex := sprite.sprite_frames.get_frame_texture("walk_down", 0)
	if tex == null:
		push_error("PLAYER_NIX_SPRITE_PROBE: frame walk_down_0 ausente")
		get_tree().quit(1)
		return

	var tex_path := tex.resource_path
	if not tex_path.contains("Sprites_Nexos/personaje/overworld/walk_down_0.png"):
		push_error("PLAYER_NIX_SPRITE_PROBE: frame inesperado %s" % tex_path)
		get_tree().quit(1)
		return

	print("PLAYER_NIX_SPRITE_PROBE ok path=%s size=%s" % [tex_path, tex.get_size()])
	get_tree().quit()
