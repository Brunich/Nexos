## CityServiceMenu — Menú de servicios de ciudad (Clínica, Terminal, Tienda)
##   "clinic"  — cura los nexos del equipo
##   "pc"      — guarda y retira nexos del depósito
##   "shop"    — compra cápsulas y objetos
## Adjunto a CanvasLayer en city_service_menu.tscn.
## Se abre desde ServiceTrigger con el tipo de servicio.
extends CanvasLayer

@onready var dimmer = $dimmer

const PokedexData = preload("res://codigo/datos/pokedex_data.gd")

var _current_service: String = ""
var _dialogue_box = null

const CLINIC_GREETINGS = [
	"Médica: Bienvenido/a. Tus nexos quedan en buenas manos.",
	"Médica: Déjalos aquí, los cuidamos bien.",
	"Médica: ¿Vienen a descansar tus compañeros? Enseguida los atendemos.",
	"Médica: Los tendremos listos en un momento.",
]

const CLINIC_DONE = [
	"Médica: Listos. Tus nexos están completamente recuperados.",
	"Médica: El Latido se siente estable en todos ellos. Buen camino.",
	"Médica: Cuídalos bien en el camino.",
]

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("city_service_menu")
	dimmer.visible = false
	dimmer.color = Color(0, 0, 0, 0.5)

func open(service_type: String) -> void:
	_current_service = service_type
	_dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	GameManager.dialogue_active = true
	dimmer.visible = true

	match service_type:
		"clinic", "temazcal":
			_run_clinic()
		"pc", "altar":
			_show_message("Terminal de Nexos: Función en desarrollo.")
		"shop", "mercado":
			_show_message("Tienda: Función en desarrollo.")
		_:
			_show_message("Este servicio no está disponible por ahora.")

func _run_clinic() -> void:
	var greeting = CLINIC_GREETINGS[randi() % CLINIC_GREETINGS.size()]
	await _show_message_and_wait(greeting)

	var any_hurt = false
	for i in GameManager.party.size():
		var creature: CreatureInstance = GameManager.party[i]
		if creature.hp_cur < creature.hp_max or creature.status != 0:
			any_hurt = true
		creature.hp_cur = creature.hp_max
		creature.status = 0
		creature.bond = clamp(creature.bond + 5, 0, 100)
		GameManager.latido_curar(i)

	GameManager.registrar_huella("curar_tonal")

	var done_msg = CLINIC_DONE[randi() % CLINIC_DONE.size()]
	if not any_hurt:
		done_msg = "Médica: Tus nexos ya estaban en perfectas condiciones."
	await _show_message_and_wait(done_msg)

	_close()

func _show_message_and_wait(text: String) -> void:
	if _dialogue_box:
		_dialogue_box.show_message(text)
		await get_tree().create_timer(0.1).timeout
		while _dialogue_box.is_active():
			await get_tree().process_frame
	else:
		await get_tree().create_timer(1.5).timeout

func _show_message(text: String) -> void:
	await _show_message_and_wait(text)
	_close()

func _close() -> void:
	GameManager.dialogue_active = false
	dimmer.visible = false
