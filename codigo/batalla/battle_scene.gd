## BattleScene — Coordinador de UI de batalla.
## Adjunto al nodo raíz BattleScene en battle_scene.tscn.
## Conecta BattleManager con las barras de HP, caja de texto y menú de movimientos.
extends Node
class_name BattleScene

const LevelUpPopup         = preload("res://codigo/ui/level_up_popup.gd")
const RuntimeTextureLoader = preload("res://codigo/util/runtime_texture_loader.gd")
const PokedexData          = preload("res://codigo/datos/pokedex_data.gd")

# ── Refs a nodos hijos ────────────────────────────────────────────────────────
@onready var overlay        : ColorRect       = $ScreenOverlay
@onready var enemy_sprite   : Sprite2D        = $enemy_sprite
@onready var player_sprite  : Sprite2D        = $player_sprite
@onready var effects        : Node            = $BattleEffects
@onready var ui             : CanvasLayer     = $ui
@onready var enemy_hp_bar   : Control         = $ui/enemy_hp_bar
@onready var player_hp_bar  : Control         = $ui/player_hp_bar
@onready var text_box       : RichTextLabel   = $ui/text_box
@onready var move_menu      : Control         = $ui/move_menu
@onready var battle_manager : Node            = $battle_manager

var _level_up_popup : CanvasLayer = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_connect_battle_manager()
	_connect_move_menu()
	if ui: ui.hide()

## Llamado por TallGrass tras cargar la escena.
func setup_wild_encounter(player_c, enemy_c) -> void:
	GameManager.dialogue_active = true
	_load_enemy_sprite(enemy_c)
	_init_hp_bars(player_c, enemy_c)
	move_menu.setup(player_c)
	move_menu.set_active(false)
	if ui: ui.show()
	_show_text("¡Un %s salvaje (Nv.%d) apareció!" % [enemy_c.display_name(), enemy_c.level])
	await get_tree().create_timer(1.2).timeout
	battle_manager.setup_wild(player_c, enemy_c)

# ── Señales del BattleManager ─────────────────────────────────────────────────
func _connect_battle_manager() -> void:
	battle_manager.phase_changed.connect(_on_phase_changed)
	battle_manager.text_queued.connect(_show_text)
	battle_manager.player_hp_changed.connect(_update_player_hp)
	battle_manager.enemy_hp_changed.connect(_update_enemy_hp)
	battle_manager.player_exp_changed.connect(_update_player_exp)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.level_up.connect(_on_level_up)
	battle_manager.catch_wobble.connect(_on_catch_wobble)

func _connect_move_menu() -> void:
	move_menu.move_chosen.connect(_on_move_chosen)
	move_menu.run_pressed.connect(_on_run_pressed)
	move_menu.bag_pressed.connect(_on_bag_pressed)

# ── HP Bars ────────────────────────────────────────────────────────────────────
func _init_hp_bars(player_c, enemy_c) -> void:
	enemy_hp_bar.set_creature_name(enemy_c.display_name())
	enemy_hp_bar.set_hp(enemy_c.hp_cur, enemy_c.hp_max)
	enemy_hp_bar.set_exp_visible(false)
	player_hp_bar.set_creature_name(player_c.display_name())
	player_hp_bar.set_hp(player_c.hp_cur, player_c.hp_max)
	var prog: Dictionary = player_c.get_exp_progress()
	player_hp_bar.set_exp_progress(prog.get("earned", 0), prog.get("needed", 1))

func _update_player_hp(hp_cur: int, hp_max: int) -> void:
	if player_hp_bar:
		effects.animate_hp_bar(player_hp_bar.get_node("bar"),
			float(hp_cur) / float(max(1, hp_max)) * float(player_hp_bar.get_node("bar").max_value), 0.35)
		player_hp_bar.set_hp(hp_cur, hp_max)

func _update_enemy_hp(hp_cur: int, hp_max: int) -> void:
	if enemy_hp_bar:
		effects.animate_hp_bar(enemy_hp_bar.get_node("bar"),
			float(hp_cur) / float(max(1, hp_max)) * float(enemy_hp_bar.get_node("bar").max_value), 0.35)
		enemy_hp_bar.set_hp(hp_cur, hp_max)

func _update_player_exp(earned: int, needed: int) -> void:
	if player_hp_bar:
		effects.animate_exp_bar(player_hp_bar.get_node("exp_bar"), float(earned), 0.45)
		player_hp_bar.set_exp_progress(earned, needed)

# ── Texto ─────────────────────────────────────────────────────────────────────
func _show_text(text: String) -> void:
	if text_box:
		text_box.text = text

# ── Fases ─────────────────────────────────────────────────────────────────────
func _on_phase_changed(phase: BattleManager.Phase) -> void:
	match phase:
		BattleManager.Phase.PLAYER_MENU:
			move_menu.set_active(true)
		_:
			move_menu.set_active(false)

# ── Acciones del jugador ──────────────────────────────────────────────────────
func _on_move_chosen(index: int) -> void:
	move_menu.set_active(false)
	battle_manager.player_use_move(index)

func _on_run_pressed() -> void:
	battle_manager.player_run()

func _on_bag_pressed() -> void:
	var ofrenda_id : String = _first_ofrenda_in_bag()
	if ofrenda_id == "":
		_show_text("No tienes Ofrendas.")
		return
	InventorySystem.remove_item(ofrenda_id, 1)
	battle_manager.player_use_ofrenda(ofrenda_id)

# ── Catch wobble ──────────────────────────────────────────────────────────────
func _on_catch_wobble(n_wobbles: int) -> void:
	effects.shake_sprite(enemy_sprite, 5.0, 0.3)

# ── Level up popup ────────────────────────────────────────────────────────────
func _on_level_up(creature_name: String, from_lv: int, to_lv: int, deltas: Dictionary) -> void:
	if _level_up_popup == null:
		_level_up_popup = (load("res://escenas/ui/level_up_popup.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(_level_up_popup)
	_level_up_popup.show_level_up(creature_name, from_lv, to_lv, deltas)

# ── Fin de batalla ────────────────────────────────────────────────────────────
func _on_battle_ended(result: BattleManager.BattleResult) -> void:
	if _level_up_popup:
		_level_up_popup.hide_popup()
	GameManager.dialogue_active = false
	await get_tree().create_timer(0.5).timeout
	var return_scene : String = GameManager.save_scene
	if return_scene == "" or not ResourceLoader.exists(return_scene):
		return_scene = "res://escenas/overworld/pielago_central.tscn"
	get_tree().change_scene_to_file(return_scene)

# ── Enemy sprite ──────────────────────────────────────────────────────────────
func _load_enemy_sprite(enemy_c) -> void:
	if enemy_sprite == null: return
	var tex := RuntimeTextureLoader.load_nexo_sprite_by_id(int(enemy_c.creature_id))
	if tex != null:
		enemy_sprite.texture = tex

# ── Bag helper ────────────────────────────────────────────────────────────────
func _first_ofrenda_in_bag() -> String:
	for key in InventorySystem.inventory.keys():
		if str(key).begins_with("ofrenda_") and int(InventorySystem.inventory[key]) > 0:
			return str(key)
	return ""
