## SantuarioData — Datos de los 8 Santuarios de Anahuac
## "Santuario" reemplaza "Gym". "Guardián/Guardiana" reemplaza "Gym Leader".
## "Sello" reemplaza "Badge".
## Uso: SantuarioData.get_santuario(id) → Dictionary

static var _santuarios: Array = [
	{
		"id":          "santuario_ascua",
		"numero":      1,
		"nombre":      "Santuario Ascua",
		"ciudad":      "Villa Ixtla",
		"guardián":    "Ignacio 'Nacho' Brasa",
		"npc_id":      "ignar",
		"esencia1":    "Fire",
		"esencia2":    "Normal",
		"sello":       "Sello Ascua",
		"nivel_min":   12,
		"nivel_max":   18,
		"descripcion": "Un volcán extinto reconvertido en lugar de prueba. El calor aquí no quema — purifica.",
		"estetica":    "Lava solidificada. Llamas perennes en antorchas de obsidiana. El suelo irradia calor.",
		"puzzle":      "Plataformas de lava que se hunden — cruzar en el orden correcto sin caer.",
		"team": [
			{"nombre": "Larvox", "id": 1005, "nivel": 14, "es1": "Bug", "es2": ""},
			{"nombre": "Embral", "id": 1001, "nivel": 18, "es1": "Fire", "es2": "Normal"},
		],
		"recompensa_dinero": 1800,
		"entrenadores": [
			{"nombre": "Calentador Peto",  "dialogo": "¡El fuego es vida! ¡Mis Tonales están listos!"},
			{"nombre": "Aprendiz Llama",   "dialogo": "Nacho me enseñó que el calor viene del corazón, no de las llamas."},
		],
	},
	{
		"id":          "santuario_marea",
		"numero":      2,
		"nombre":      "Santuario Marea",
		"ciudad":      "Puerto Xólotl",
		"guardián":    "Marina Xochitl",
		"npc_id":      "marina",
		"esencia1":    "Water",
		"esencia2":    "Ice",
		"sello":       "Sello Marea",
		"nivel_min":   20,
		"nivel_max":   28,
		"descripcion": "Un muelle cubierto donde el mar y el Santuario son lo mismo. La prueba es paciencia.",
		"estetica":    "Muelle de madera vieja. Agua visible por todos lados. Bruma matutina constante.",
		"puzzle":      "Corrientes de agua que llevan al jugador hacia atrás — hay que nadar contra la corriente correcta.",
		"team": [
			{"nombre": "Oshenite", "id": 1009, "nivel": 24, "es1": "Water", "es2": "Ice"},
			{"nombre": "Aquellux", "id": 1008, "nivel": 28, "es1": "Water", "es2": "Electric"},
		],
		"recompensa_dinero": 2800,
		"entrenadores": [
			{"nombre": "Marinero Tito",  "dialogo": "El mar no se pelea — se respeta. Y yo respeto cada ola."},
			{"nombre": "Buzos Berta",    "dialogo": "Ahí abajo hay Tonales que nunca nadie ha visto. Marina lo sabe."},
		],
	},
	{
		"id":          "santuario_quetzal",
		"numero":      3,
		"nombre":      "Santuario Quetzal",
		"ciudad":      "Selva Quetzal",
		"guardián":    "Silvia Quetzal",
		"npc_id":      "sylvari",
		"esencia1":    "Grass",
		"esencia2":    "Bug",
		"sello":       "Sello Quetzal",
		"nivel_min":   28,
		"nivel_max":   36,
		"descripcion": "El bosque ES el Santuario. No hay paredes — solo árboles y el sonido del viento.",
		"estetica":    "Bosque vivo. Telarañas brillantes. Luz solar que entra en rayos. Mariposas por todos lados.",
		"puzzle":      "Laberinto de raíces y ramas — algunas bloquean el paso, otras se mueven si interactúas con ciertos Tonales del bosque.",
		"team": [
			{"nombre": "Folimp",  "id": 1003, "nivel": 30, "es1": "Grass", "es2": ""},
			{"nombre": "Spidrel", "id": 1015, "nivel": 33, "es1": "Bug", "es2": "Poison"},
			{"nombre": "Folivian","id": 1004, "nivel": 36, "es1": "Grass", "es2": "Bug"},
		],
		"recompensa_dinero": 3600,
		"entrenadores": [
			{"nombre": "Botánico Félix",   "dialogo": "¿Qué onda, cuate? ¿Nunca habías visto un bosque así? ¡Qué chido, verdad!"},
			{"nombre": "Herborista Lila",  "dialogo": "Ahorita vengo — tengo que regar las telarañas. Sí, se riegan. Silvia dice que también tienen sed."},
		],
	},
	{
		"id":          "santuario_rayo",
		"numero":      4,
		"nombre":      "Santuario Rayo",
		"ciudad":      "Tlaltecuhtli",
		"guardián":    "Volta Cienfuegos",
		"npc_id":      "volta",
		"esencia1":    "Electric",
		"esencia2":    "Steel",
		"sello":       "Sello Rayo",
		"nivel_min":   38,
		"nivel_max":   44,
		"descripcion": "Una fábrica de energía reconvertida en lugar de prueba. Eficiente. Fría. Perfecta.",
		"estetica":    "Industrial. Cables por todos lados. Plataformas metálicas. Arcos de Tesla. Luces que parpadean en batalla.",
		"puzzle":      "4 interruptores numerados. Activar en orden correcto (3→1→4→2). Orden incorrecto = descarga al inicio.",
		"team": [
			{"nombre": "Aquellux", "id": 1008, "nivel": 39, "es1": "Water", "es2": "Electric"},
			{"nombre": "Voltux",   "id": 1018, "nivel": 44, "es1": "Electric", "es2": "Steel"},
		],
		"recompensa_dinero": 4400,
		"entrenadores": [
			{"nombre": "Técnico Ferran",   "dialogo": "La energía que generamos aquí alimenta tres ciudades. Volta lo hace posible."},
			{"nombre": "Guardia Eléctrico", "dialogo": "Volta dice que el Santuario no es espectáculo. Pero a mí me parece bastante espectacular."},
			{"nombre": "Técnico Senior",   "dialogo": "La jefa lleva dos semanas más seria de lo normal. Algo le pesa."},
		],
	},
	{
		"id":          "santuario_cempa",
		"numero":      5,
		"nombre":      "Santuario Cempa",
		"ciudad":      "Valle Cempa",
		"guardián":    "Señor Mortem",
		"npc_id":      "mortem",
		"esencia1":    "Ghost",
		"esencia2":    "Dark",
		"sello":       "Sello Cempa",
		"nivel_min":   44,
		"nivel_max":   52,
		"descripcion": "Un jardín de tumbas cálido y melancólico. Aquí no se llora — se recuerda con alegría.",
		"estetica":    "Flores de cempasúchil por todos lados. Velas. Mariposas monarca. Murales de personas y Tonales ya partidos. Luz dorada.",
		"puzzle":      "6 lápidas con pistas. Libro central con 3 preguntas. Responder correctamente abre el camino.",
		"team": [
			{"nombre": "Necroveil", "id": 1010, "nivel": 48, "es1": "Ghost", "es2": "Dark"},
			{"nombre": "Spectryn",  "id": 1019, "nivel": 51, "es1": "Ghost", "es2": "Psychic"},
			{"nombre": "Bonehound", "id": 1013, "nivel": 52, "es1": "Ghost", "es2": "Normal"},
		],
		"recompensa_dinero": 5200,
		"entrenadores": [
			{"nombre": "Florista Amara",     "dialogo": "¿Primera vez en Valle Cempa? No tengas miedo. Los que duermen aquí están en paz."},
			{"nombre": "Guardiana Celta",    "dialogo": "Mortem dice que la batalla es un ritual. Que los Latidos se reconocen."},
			{"nombre": "Devoto Isak",        "dialogo": "¿Ves ese mural? Dicen que duró tres días la batalla más grande de Valle Cempa."},
			{"nombre": "Guardián Mayor Rone","dialogo": "Mortem conoció a alguien hace tiempo. No habla de ello. Pero a veces mira hacia el norte."},
		],
		"nota_especial": "Mortem fue el último en ver a Mara Solís. Hay una foto sin nombre en su arena.",
	},
]

# ── API pública ────────────────────────────────────────────────────────────────

static func get_all() -> Array:
	return _santuarios

static func get_santuario(santuario_id: String) -> Dictionary:
	for s in _santuarios:
		if s["id"] == santuario_id:
			return s
	return {}

static func get_by_numero(numero: int) -> Dictionary:
	for s in _santuarios:
		if s["numero"] == numero:
			return s
	return {}

static func get_guardián(santuario_id: String) -> String:
	return get_santuario(santuario_id).get("guardián", "???")

static func get_sello_nombre(santuario_id: String) -> String:
	return get_santuario(santuario_id).get("sello", "Sello ???")

## ¿El jugador ya ganó el Sello de este Santuario?
static func tiene_sello(santuario_id: String) -> bool:
	return santuario_id in GameManager.badges

## Registrar victoria de Sello
static func ganar_sello(santuario_id: String) -> void:
	if not tiene_sello(santuario_id):
		GameManager.badges.append(santuario_id)
		print("SantuarioData: ¡Sello ganado! → " + santuario_id)
