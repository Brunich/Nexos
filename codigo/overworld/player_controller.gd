## PlayerController — Controlador del jugador (Nix) en el overworld
## Adjunto a CharacterBody2D (player.tscn).
## Carga sprites dinámicamente desde Sprites_Nexos/personaje/overworld/.
## Soporta: caminar 4-dir, correr (Shift), animaciones, cámara, interacción.
extends CharacterBody2D

# ── Propiedades exportadas ────────────────────────────────────────────────────
@export var walk_speed: float = 80.0
@export var run_speed: float = 140.0
@export var player_name: String = "Nix"

# ── Nodos hijos ──────────────────────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $sprite
@onready var name_label: Label = $name_label

# ── Estado interno ───────────────────────────────────────────────────────────
var _facing: String = "down"
var _is_moving: bool = false
var _is_running: bool = false
var _frames_loaded: bool = false

# ── Constantes ───────────────────────────────────────────────────────────────
const SPRITE_BASE = "res://Sprites_Nexos/personaje/overworld/"
const DIRECTIONS = ["down", "right", "left", "up"]
const WALK_FPS = 6.0
const RUN_FPS = 9.0
const IDLE_FRAME = 0   # primer frame de cada dirección = pose idle

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_physics_process(true)
	GameManager.dialogue_active = false

	name_label.text = player_name
	if GameManager.player_name != "":
		player_name = GameManager.player_name
		name_label.text = player_name

	_load_sprite_frames()
	if _frames_loaded:
		sprite.play("idle_down")

	add_to_group("player")
	print("PlayerController: '%s' listo en %s" % [player_name, global_position])

# ── Cargar frames desde disco ────────────────────────────────────────────────
func _load_sprite_frames() -> void:
	var sf = SpriteFrames.new()
	# Limpiar la animación default que SpriteFrames crea automáticamente
	if sf.has_animation("default"):
		sf.remove_animation("default")

	for dir in DIRECTIONS:
		# ── Walk animation ──
		var walk_name = "walk_" + dir
		sf.add_animation(walk_name)
		sf.set_animation_speed(walk_name, WALK_FPS)
		sf.set_animation_loop(walk_name, true)
		for i in range(4):
			var path = SPRITE_BASE + "walk_%s_%d.png" % [dir, i]
			var tex = _load_texture(path)
			if tex:
				sf.add_frame(walk_name, tex)

		# ── Run animation ──
		var run_name = "run_" + dir
		sf.add_animation(run_name)
		sf.set_animation_speed(run_name, RUN_FPS)
		sf.set_animation_loop(run_name, true)
		for i in range(4):
			var path = SPRITE_BASE + "run_%s_%d.png" % [dir, i]
			var tex = _load_texture(path)
			if tex:
				sf.add_frame(run_name, tex)

		# ── Idle animation (single frame from walk_0) ──
		var idle_name = "idle_" + dir
		sf.add_animation(idle_name)
		sf.set_animation_speed(idle_name, 1.0)
		sf.set_animation_loop(idle_name, false)
		var idle_path = SPRITE_BASE + "walk_%s_0.png" % dir
		var idle_tex = _load_texture(idle_path)
		if idle_tex:
			sf.add_frame(idle_name, idle_tex)

	sprite.sprite_frames = sf
	_frames_loaded = true
	print("PlayerController: %d animaciones cargadas" % sf.get_animation_names().size())

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	# Fallback: intentar como archivo importado
	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img:
			var tex = ImageTexture.create_from_image(img)
			return tex
	push_warning("PlayerController: no se encontró textura '%s'" % path)
	return null

# ── Loop principal ───────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if GameManager.dialogue_active:
		velocity = Vector2.ZERO
		_set_moving(false)
		move_and_slide()
		return

	var input_vec: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	_is_running = Input.is_action_pressed("run") or Input.is_key_pressed(KEY_SHIFT)
	var speed: float = run_speed if _is_running else walk_speed
	velocity = input_vec * speed

	_update_facing_and_anim(input_vec)
	_set_moving(input_vec.length() > 0.1)

	move_and_slide()

# ── Dirección y animación ────────────────────────────────────────────────────
func _update_facing_and_anim(input_vec: Vector2) -> void:
	if not _frames_loaded:
		return

	if input_vec.length() < 0.1:
		# Parado → idle
		if _is_moving:
			_play_anim("idle_" + _facing)
		return

	var new_facing: String
	if abs(input_vec.x) >= abs(input_vec.y):
		new_facing = "right" if input_vec.x > 0 else "left"
	else:
		new_facing = "down" if input_vec.y > 0 else "up"

	var prefix = "run_" if _is_running else "walk_"
	if new_facing != _facing or not _is_moving:
		_facing = new_facing
		_play_anim(prefix + _facing)
	elif _is_running != _was_running():
		_play_anim(prefix + _facing)

func _was_running() -> bool:
	# Detectar si la animación actual es de correr
	return sprite.animation.begins_with("run_")

func _set_moving(moving: bool) -> void:
	_is_moving = moving

func _play_anim(anim_name: String) -> void:
	if not _frames_loaded:
		return
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)

# ── API pública ──────────────────────────────────────────────────────────────
func get_facing() -> String:
	return _facing

func teleport_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
