## DialogueData — Scripts de diálogo de los Guardianes y NPCs principales
## Terminología NEXOS: Guardián (Gym Leader), Santuario (Gym), Sello (Badge),
##   Tonal (Pokémon), Arte (Move), Esencia (Type), Ofrenda (Ball), Latido (Bond)
## Uso: DialogueData.get_lines(npc_id, context)
##   Devuelve Array[String] de líneas de diálogo, en orden de aparición.

# ── Estructura de datos ────────────────────────────────────────────────────────
# {
#   npc_id: {
#     context_key: ["Línea 1", "Línea 2", ...]
#   }
# }

static var _data: Dictionary = {

	# ─────────────────────────────────────────────────────────────────────────
	# IGNAR — Guardián del Santuario Ascua
	# Esencias: Fuego / Normal  |  Sello: Ascua
	# Personalidad: Rudo por fuera, orgulloso de los suyos
	# ─────────────────────────────────────────────────────────────────────────
	"ignar": {
		"primer_encuentro": [
			"Ignar: ...Ah. Otro que viene a probarse.",
			"Ignar: La mayoría se vuelven cuando sienten el calor del Santuario. Tú llegaste hasta aquí.",
			"Ignar: Eso ya me dice algo. Pero no todo.",
			"Ignar: Mis Tonales no se dejan impresionar por el viaje. Solo por la batalla.",
			"Ignar: ¿Lista/Listo? Porque yo sí.",
		],
		"turno_1": [
			"Ignar: El fuego no perdona la indecisión. ¡Actúa!",
		],
		"jugador_tiene_ventaja": [
			"Ignar: Bien. Viniste preparada/preparado. Eso me gusta más que la suerte.",
		],
		"derrota_tonal_jugador": [
			"Ignar: No te desanimes. El fuego también forja, no solo quema.",
		],
		"ignar_pierde": [
			"Ignar: ...",
			"Ignar: ...Bien hecho.",
			"Ignar: Esto no es un trofeo. Es una promesa.",
			"Ignar: La promesa de que seguirás avanzando.",
			"Ignar: No me decepciones.",
		],
		"post_batalla": [
			"Ignar: Sigo aquí. Siempre hay más que aprender del fuego.",
			"Ignar: ¿Sabes por qué entreno tanto? Porque el día que deje de hacerlo... mis Tonales lo notarán antes que yo.",
		],
	},

	# ─────────────────────────────────────────────────────────────────────────
	# MARINA — Guardiana del Santuario Marea
	# Esencias: Agua / Hielo  |  Sello: Marea
	# Personalidad: Calmada, profunda, habla poco pero pesa cada palabra
	# ─────────────────────────────────────────────────────────────────────────
	"marina": {
		"primer_encuentro": [
			"Marina: El mar no se apresura.",
			"Marina: Tampoco yo.",
			"Marina: Pero tú llegaste rápido. Bien.",
			"Marina: El que llega rápido a veces tiene prisa por demostrar algo.",
			"Marina: ¿Qué es lo que quieres demostrar tú?",
			"Marina: No importa. La batalla me lo dirá.",
		],
		"jugador_usa_fuego_electrico": [
			"Marina: Previsible. El mar ya lo sabía.",
		],
		"jugador_tiene_ventaja": [
			"Marina: ...Interesante. Hay profundidad en ti.",
		],
		"marina_pierde": [
			"Marina: El mar retrocede. Siempre vuelve.",
			"Marina: Este Sello no es tuyo todavía. Es prestado.",
			"Marina: Tendrás que demostrar que lo mereces cada vez que lo uses.",
		],
		"post_batalla": [
			"Marina: El océano tiene memoria. Yo también.",
			"Marina: Si algún día necesitas saber algo sobre Puerto Xólotl... vuelve y pregunta.",
			"Marina: Sobre las profundidades. No de los arrecifes. Las profundidades guardan cosas que la gente prefiere no saber.",
		],
	},

	# ─────────────────────────────────────────────────────────────────────────
	# SYLVARI — Guardiana del Santuario Quetzal
	# Esencias: Planta / Bicho  |  Sello: Quetzal
	# Personalidad: Alegre, errática, profundamente conectada con el bosque
	# ─────────────────────────────────────────────────────────────────────────
	"sylvari": {
		"primer_encuentro": [
			"Sylvari: ¡AH! ¡Llegaste! ¡Lo sabía! ¡Lo SABÍA!",
			"Sylvari: Folimp me dijo esta mañana que alguien especial venía hoy. ¡Y aquí estás!",
			"Sylvari: Mira, mira — ¿ves esa telaraña? Lleva ahí tres semanas. No la toco.",
			"Sylvari: Los Tonales del bosque construyen. Nosotros solo... estamos.",
			"Sylvari: Eso es lo que vas a aprender hoy. Si puedes.",
			"Sylvari: ¡Batalla!",
		],
		"durante_batalla": [
			"Sylvari: ¡El bosque te está mirando! ¡No te pongas nervioso/a!",
		],
		"jugador_usa_fuego": [
			"Sylvari: ¡Ay! ¡Oye! ¡Eso duele! ¡Pero no me rindo!",
		],
		"sylvari_pierde": [
			"Sylvari: Sabía que ibas a ganar. Folimp lo dijo desde el principio y yo no le hice caso.",
			"Sylvari: Cuida el Sello. La araña que lo tejió tardó una semana.",
			"Sylvari: ...Es broma. Pero no del todo.",
		],
		"secreto_del_bosque": [
			"Sylvari: Oye... ¿puedo decirte algo?",
			"Sylvari: El bosque tiene memoria larga. Muy larga.",
			"Sylvari: Hace como... doce años. Pasó alguien por aquí. Una mujer. Con un Veildark.",
			"Sylvari: No se detuvo. Iba hacia el norte. Hacia La Cicatriz.",
			"Sylvari: Lo mencioné una vez. Nadie me creyó. Pero el bosque lo recuerda.",
			"Sylvari: ¡Bueno! ¿Quieres ver a Folivian hacer el baile? ¡Es increíble!",
		],
	},

	# ─────────────────────────────────────────────────────────────────────────
	# VOLTA — Guardián del Santuario Rayo
	# Esencias: Eléctrico / Acero  |  Sello: Rayo
	# Personalidad: Profesional, distante — guarda un secreto que le pesa
	# ─────────────────────────────────────────────────────────────────────────
	"volta": {
		"primer_encuentro": [
			"Volta: Un momento.",
			"Volta: Bien. ¿Vienes por el Sello Rayo?",
			"Volta: Directo al punto. Apreciado.",
			"Volta: Aquí no tenemos tiempo para ceremonias. La ciudad necesita energía. Yo produzco energía.",
			"Volta: Los Guardianes somos una tradición. Yo soy una eficiencia.",
			"Volta: Demuestra que tu Latido es real y te doy el Sello. Nada más.",
		],
		"durante_batalla": [
			"Volta: Voltux. Demuéstrale lo que hemos construido.",
		],
		"volta_pierde": [
			"Volta: ...Sí. Bien.",
			"Volta: Tómalo.",
			"Volta: Espera.",
			"Volta: ...No. Nada. Suerte.",
		],
	},

	# ─────────────────────────────────────────────────────────────────────────
	# NANA CAIS — Abuela del protagonista
	# ─────────────────────────────────────────────────────────────────────────
	"nana_cais": {
		"post_intro": [
			"Nana Cais: ¡Órale, ya tienes tu Tonal Guardián! ¡Qué chido!",
			"Nana Cais: Recuerda: el Latido necesita tiempo. No lo apresures.",
			"Nana Cais: Cuando regreses, cuéntame todo. Ahorita voy a hacer atole.",
		],
		"visita_regreso": [
			"Nana Cais: ¡Mija/Mijo! ¿Cómo está tu Tonal? ¿Sigue bien el Latido?",
			"Nana Cais: Que no se te olvide: curar a tus compañeros no es debilidad. Es lo correcto.",
			"Nana Cais: Aquí siempre habrá un lugar para descansar. Mi Temazcal está listo.",
		],
	},

	# ─────────────────────────────────────────────────────────────────────────
	# SABIO CUAUHTÉMOC — El Sabio inicial
	# ─────────────────────────────────────────────────────────────────────────
	"sabio_cuauh": {
		"encuentro_inicial": [
			"Sabio Cuauhtémoc: Pa' luego es tarde, joven Guía.",
			"Sabio Cuauhtémoc: Anahuac tiene secretos que los Códices no cuentan.",
			"Sabio Cuauhtémoc: Pero tú has elegido tu Tonal Guardián. Eso ya es saber.",
			"Sabio Cuauhtémoc: El Latido es sagrado. No lo fuerces. No lo rompas.",
			"Sabio Cuauhtémoc: Los nueve tipos de Ofrenda están en tu bolsa. Úsalos con respeto.",
		],
		"consejo_batalla": [
			"Sabio Cuauhtémoc: En batalla, el Latido habla más que cualquier Arte.",
			"Sabio Cuauhtémoc: Un Tonal con Latido Resonante da hasta lo que no tiene.",
			"Sabio Cuauhtémoc: Un Tonal con Latido Roto... actuará solo.",
		],
		"consejo_despertar": [
			"Sabio Cuauhtémoc: El Despertar no se puede forzar.",
			"Sabio Cuauhtémoc: Cuando el Tonal esté listo — cuando el Latido sea profundo — ocurrirá solo.",
			"Sabio Cuauhtémoc: ¡Está cañón verlo, te lo juro!",
		],
	},
}

# ── API pública ────────────────────────────────────────────────────────────────

## Obtiene las líneas de diálogo para un NPC en un contexto dado.
## Devuelve Array[String] o [] si no existe.
static func get_lines(npc_id: String, context: String) -> Array:
	var npc_data: Dictionary = _data.get(npc_id, {})
	return npc_data.get(context, [])

## Obtiene la primera línea de un contexto (útil para diálogos simples).
static func get_line(npc_id: String, context: String, index: int = 0) -> String:
	var lines = get_lines(npc_id, context)
	if lines.is_empty() or index >= lines.size():
		return "..."
	return lines[index]

## ¿Existe diálogo para este NPC y contexto?
static func has_dialogue(npc_id: String, context: String) -> bool:
	return not get_lines(npc_id, context).is_empty()

## Lista todos los contextos disponibles para un NPC
static func get_contexts(npc_id: String) -> Array:
	return _data.get(npc_id, {}).keys()

## Lista todos los NPCs con diálogo registrado
static func get_all_npc_ids() -> Array:
	return _data.keys()
