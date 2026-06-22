## MoveSelectMenu — Menú de selección de movimientos en batalla.
## Adjunto al nodo MoveSelectMenu en move_select_menu.tscn.
## Emite señales hacia BattleScene; no contiene lógica de batalla.
extends Control
class_name MoveSelectMenu

signal move_chosen(index: int)
signal run_pressed
signal bag_pressed
signal switch_pressed

@onready var _grid     : GridContainer = $grid
@onready var _run_btn  : Button        = $run_btn
@onready var _bag_btn  : Button        = $bag_btn
@onready var _switch   : Button        = $switch_btn
@onready var _info_lbl : Label         = $move_info

var _move_buttons : Array = []   # Array[Button]

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_move_buttons.clear()
	for i in 4:
		var btn : Button = _grid.get_node_or_null("move_%d" % i)
		if btn:
			_move_buttons.append(btn)
			var idx := i
			btn.pressed.connect(func(): _on_move_pressed(idx))
			btn.mouse_entered.connect(func(): _on_move_hover(idx))

	_run_btn.pressed.connect(func(): run_pressed.emit())
	_bag_btn.pressed.connect(func(): bag_pressed.emit())
	_switch.pressed.connect(func(): switch_pressed.emit())

## Rellena los botones con los movimientos de la criatura activa.
## creature es un CreatureInstance.
func setup(creature: Object) -> void:
	for i in 4:
		var btn : Button = _move_buttons[i] if i < _move_buttons.size() else null
		if btn == null:
			continue
		if i < creature.moves.size():
			var move = creature.moves[i]
			var pp   : int = creature.moves_pp[i] if i < creature.moves_pp.size() else move.pp_max
			btn.text     = "%s\n%s  PP %d/%d" % [move.move_name, move.type_name(), pp, move.pp_max]
			btn.disabled = (pp <= 0)
		else:
			btn.text     = "—"
			btn.disabled = true
	_info_lbl.text = ""

## Habilita o deshabilita toda la UI (evita doble input).
func set_active(active: bool) -> void:
	for btn in _move_buttons:
		if btn: btn.disabled = not active
	_run_btn.disabled  = not active
	_bag_btn.disabled  = not active
	_switch.disabled   = not active

# ─────────────────────────────────────────────────────────────────────────────
func _on_move_pressed(index: int) -> void:
	move_chosen.emit(index)

func _on_move_hover(index: int) -> void:
	if _info_lbl == null:
		return
	var creature = _get_active_creature()
	if creature == null or index >= creature.moves.size():
		_info_lbl.text = ""
		return
	var move = creature.moves[index]
	_info_lbl.text = "%s | Poder: %d | Precisión: %d%%" % [move.description, move.power, move.accuracy]

# ── Acceso a criatura activa via BattleManager (grupo) ────────────────────────
func _get_active_creature():
	var bm = get_tree().get_first_node_in_group("battle_manager")
	if bm and "player_creature" in bm:
		return bm.player_creature
	return null
