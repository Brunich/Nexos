## NPCController — Comportamiento de NPCs en el overworld
## Adjunto a CharacterBody2D de los NPCs.
## Maneja: deambular, interacción, diálogo.
extends CharacterBody2D

@export var npc_id: String = ""
@export var wander_range: float = 0.0    ## 0 = NPC estático
@export var wander_speed: float = 20.0
@export var dialogue_key: String = ""    ## Clave de diálogo en dialogue_data

@onready var sprite: AnimatedSprite2D = $sprite
@onready var interact_area: Area2D = $interact_area

var exclaim_label: Label = null

var _spawn_position: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _wander_wait: float = 0.0
var _is_waiting: bool = true
var _has_sprite_frames: bool = false
var _facing: String = "down"
var _player_in_range: bool = false
var _was_dialogue_active: bool = false
var _post_dialogue_cooldown: float = 0.0

const WANDER_MIN_WAIT = 1.5
const WANDER_MAX_WAIT = 4.0
const ARRIVAL_THRESHOLD = 4.0
const POST_DIALOGUE_COOLDOWN = 2.0

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_spawn_position = global_position
	_target_position = global_position
	_is_waiting = true
	_wander_wait = randf_range(WANDER_MIN_WAIT, WANDER_MAX_WAIT)
	exclaim_label = _ensure_exclaim_label()

	_has_sprite_frames = (sprite.sprite_frames != null and sprite.sprite_frames != null)
	if _has_sprite_frames and sprite.sprite_frames.has_animation("idle_down"):
		sprite.play("idle_down")

	if exclaim_label:
		exclaim_label.visible = false

	# NPCs no bloquean físicamente al jugador — la interacción usa Area2D
	collision_layer = 0
	collision_mask  = 0

	if interact_area:
		interact_area.body_entered.connect(_on_player_enter_range)
		interact_area.body_exited.connect(_on_player_exit_range)

# ── Loop ──────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Detectar fin de diálogo → cooldown para evitar que el NPC vague inmediatamente
	if _was_dialogue_active and not GameManager.dialogue_active:
		_post_dialogue_cooldown = POST_DIALOGUE_COOLDOWN
		_is_waiting = true
		_wander_timer = 0.0
	_was_dialogue_active = GameManager.dialogue_active

	if GameManager.dialogue_active or _post_dialogue_cooldown > 0.0:
		_post_dialogue_cooldown = maxf(0.0, _post_dialogue_cooldown - delta)
		velocity = Vector2.ZERO
		return

	if wander_range <= 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_wander_timer += delta

	if _is_waiting:
		if _wander_timer >= _wander_wait:
			_pick_new_target()
	else:
		var to_target = _target_position - global_position
		if to_target.length() < ARRIVAL_THRESHOLD:
			_arrive()
		else:
			velocity = to_target.normalized() * wander_speed
			_update_facing(velocity)
			move_and_slide()
			return

	velocity = Vector2.ZERO
	move_and_slide()

func _pick_new_target() -> void:
	var angle = randf() * TAU
	var dist  = randf_range(8.0, wander_range)
	_target_position = _spawn_position + Vector2(cos(angle), sin(angle)) * dist
	_is_waiting = false
	_wander_timer = 0.0
	_play_walk_anim()

func _arrive() -> void:
	_is_waiting = true
	_wander_timer = 0.0
	_wander_wait  = randf_range(WANDER_MIN_WAIT, WANDER_MAX_WAIT)
	velocity = Vector2.ZERO
	_play_idle_anim()

# ── Dirección y animación ─────────────────────────────────────────────────────
func _update_facing(vel: Vector2) -> void:
	if vel.length() < 0.1:
		return
	var new_facing: String
	if abs(vel.x) >= abs(vel.y):
		new_facing = "right" if vel.x > 0 else "left"
	else:
		new_facing = "down" if vel.y > 0 else "up"
	if new_facing != _facing:
		_facing = new_facing
		_play_walk_anim()

func _play_walk_anim() -> void:
	_try_play("walk_" + _facing)

func _play_idle_anim() -> void:
	_try_play("idle_" + _facing)

func _try_play(anim_name: String) -> void:
	if not _has_sprite_frames:
		return
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)

# ── Interacción con jugador ───────────────────────────────────────────────────
func _on_player_enter_range(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if exclaim_label:
			exclaim_label.visible = true

func _on_player_exit_range(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if exclaim_label:
			exclaim_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if GameManager.dialogue_active:
		return
	if event.is_action_pressed("interact"):
		_start_dialogue()

func _start_dialogue() -> void:
	var text = _get_dialogue_text()
	if text == "":
		return

	# Buscar el dialogue_box en la escena actual
	var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box == null:
		push_warning("NPCController: no se encontró dialogue_box en la escena")
		return

	# Girar NPC hacia el jugador
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_face_toward(player.global_position)

	# Registrar en Huella — interacción con NPC
	GameManager.registrar_huella("dialogo_curioso")

	dialogue_box.show_message(text, npc_id)
	if exclaim_label:
		exclaim_label.visible = false

func _face_toward(target_pos: Vector2) -> void:
	var diff = target_pos - global_position
	if abs(diff.x) >= abs(diff.y):
		_facing = "right" if diff.x > 0 else "left"
	else:
		_facing = "down" if diff.y > 0 else "up"
	_play_idle_anim()

func _get_dialogue_text() -> String:
	var fallback_map = {
		"dona_elva":         "Bienvenido al Piélago. Cuida bien a tus nexos — un Guía que descuida a sus compañeros no llega lejos.",
		"elder_brix":        "El Latido no es poder... es vínculo. Un nexo que se siente respetado da más de lo que imaginas.",
		"villager_tomas":    "Hoy es buen día para explorar. ¿Ya elegiste tu nexo inicial?",
		"mercader_juan":     "Tengo cápsulas y objetos de calidad. Lo que necesites para el camino.",
		"nina_laura":        "Vi un nexo extraño ayer por la ruta norte. Se quedó mirándome fijo. No era agresivo — solo... observaba.",
		"guardiana_ignar":   "¿Quieres el Sello del Guardián? Tu valentía es clara. Pero el Latido es lo que realmente cuenta aquí.",
		"cael_brynn":        "También empiezo hoy. Abuelo dice que el primer vínculo lo cambia todo. Supongo que ya lo veremos.",
		"sabio_cuauh":       "El Piélago guarda secretos que ningún Códice ha registrado. Hay tiempo, pero no demasiado.",
		"posadero_mario":    "La clínica tiene los mejores cuidados de la región. Un buen descanso mejora el Latido de tus nexos.",
		"pescador_cayo":     "Los nexos del mar no se vinculan fácil. Primero hay que ganarse su respeto.",
		"abuela_paz":        "Cuando era joven, el primer vínculo era motivo de celebración. El Latido sigue siendo sagrado.",
	}
	if dialogue_key != "":
		return dialogue_key
	return fallback_map.get(npc_id, "Buen camino, Guía.")

func _ensure_exclaim_label() -> Label:
	var existing := get_node_or_null("exclaim_label") as Label
	if existing:
		return existing

	var label := Label.new()
	label.name = "exclaim_label"
	label.text = "!"
	label.position = Vector2(-4, -26)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	return label
