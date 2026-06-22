extends Node

const PLAYER_SCENE := preload("res://escenas/player/player.tscn")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameManager.setup_new_adventure("Probe")
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var sprite := player.get_node("sprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		push_error("PLAYER_NIX_FRAMES_PROBE: sprite frames no cargados")
		get_tree().quit(1)
		return

	var down := sprite.sprite_frames.get_frame_texture("walk_down", 0)
	var left := sprite.sprite_frames.get_frame_texture("walk_left", 1)
	var up := sprite.sprite_frames.get_frame_texture("walk_up", 0)
	if down == null or left == null or up == null:
		push_error("PLAYER_NIX_FRAMES_PROBE: faltan texturas base")
		get_tree().quit(1)
		return

	if down.get_width() < 80 or down.get_height() < 96:
		push_error("PLAYER_NIX_FRAMES_PROBE: Nix sigue usando frames chicos/legacy (%sx%s)" % [down.get_width(), down.get_height()])
		get_tree().quit(1)
		return

	print("PLAYER_NIX_FRAMES_PROBE ok walk_down=%sx%s walk_left=%sx%s walk_up=%sx%s" % [
		down.get_width(), down.get_height(),
		left.get_width(), left.get_height(),
		up.get_width(), up.get_height()
	])
	get_tree().quit()
