## MoveData — Datos de un movimiento de criatura
## Usado por CreatureInstance, SaveSystem y StatsScreen.
class_name MoveData
extends Resource

## Todos los tipos de movimiento (orden = valor int para UI lookup)
enum Type {
	Normal, Fire, Water, Grass, Electric, Ice,
	Fighting, Poison, Ground, Flying, Psychic,
	Bug, Rock, Ghost, Dragon, Dark, Steel, Fairy, Veil
}

enum Category { Physical, Special, Status }

@export var move_name: String = ""
@export var type: int = Type.Normal     ## MoveData.Type enum value
@export var category: int = Category.Physical
@export var power: int = 0
@export var accuracy: int = 100
@export var pp_max: int = 20
@export var description: String = ""
@export var priority: int = 0
@export var makes_contact: bool = true
@export var effect: String = ""   # e.g. "burn_30", "paralyze_10", "flinch_30"

func _init(name: String = "", pp: int = 20, move_type: int = Type.Normal) -> void:
	move_name = name
	pp_max    = pp
	type      = move_type

## Nombre del tipo como string (para PokedexData.type_color)
func type_name() -> String:
	return MoveData.Type.keys()[type]
