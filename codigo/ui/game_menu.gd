## GameMenu — Menú principal del overworld con 5 pestañas
## Cambios / Bolsa / Nexodex / Guardar / Ajustes
## Se abre/cierra con la acción "menu" (tecla E / Escape / X).
extends CanvasLayer

@onready var root_panel      = $root_panel
@onready var tab_cambios     = $root_panel/layout/tab_bar/tab_party
@onready var tab_bolsa       = $root_panel/layout/tab_bar/tab_items
@onready var tab_nexodex     = $root_panel/layout/tab_bar/tab_pokedex
@onready var tab_guardar     = $root_panel/layout/tab_bar/tab_save
@onready var tab_ajustes     = $root_panel/layout/tab_bar/tab_settings

@onready var cambios_screen   = $root_panel/layout/screens/party_screen
@onready var bolsa_screen     = $root_panel/layout/screens/items_screen
@onready var nexodex_screen   = $root_panel/layout/screens/pokedex_screen
@onready var guardar_screen   = $root_panel/layout/screens/save_screen
@onready var ajustes_screen   = $root_panel/layout/screens/settings_screen

var _is_open: bool = false

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	root_panel.visible = false
	tab_cambios.text = "CAMBIOS"
	tab_bolsa.text = "BOLSA"
	tab_nexodex.text = "NEXODEX"
	tab_guardar.text = "GUARDAR"
	tab_ajustes.text = "AJUSTES"
	add_to_group("game_menu")
	_connect_tabs()

## Abre el menú directamente en la pestaña indicada (llamado desde QuickMenu)
func open_on_tab(tab_index: int) -> void:
	if not _is_open:
		_open_menu()
	_switch_tab(tab_index)

func _connect_tabs() -> void:
	tab_cambios.pressed.connect(func(): _switch_tab(0))
	tab_bolsa.pressed.connect(func():   _switch_tab(1))
	tab_nexodex.pressed.connect(func(): _switch_tab(2))
	tab_guardar.pressed.connect(func(): _switch_tab(3))
	tab_ajustes.pressed.connect(func(): _switch_tab(4))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		if _is_open:
			_close_menu()
		elif not GameManager.dialogue_active:
			_open_menu()

# ── Abrir / Cerrar ────────────────────────────────────────────────────────────
func _open_menu() -> void:
	_is_open = true
	GameManager.dialogue_active = true
	root_panel.visible = true
	_switch_tab(0)

func _close_menu() -> void:
	_is_open = false
	GameManager.dialogue_active = false
	root_panel.visible = false

# ── Tabs ──────────────────────────────────────────────────────────────────────
func _switch_tab(index: int) -> void:
	cambios_screen.visible  = (index == 0)
	bolsa_screen.visible    = (index == 1)
	nexodex_screen.visible  = (index == 2)
	guardar_screen.visible  = (index == 3)
	ajustes_screen.visible  = (index == 4)

	tab_cambios.button_pressed  = (index == 0)
	tab_bolsa.button_pressed    = (index == 1)
	tab_nexodex.button_pressed  = (index == 2)
	tab_guardar.button_pressed  = (index == 3)
	tab_ajustes.button_pressed  = (index == 4)

	match index:
		0: if cambios_screen.has_method("refresh"):  cambios_screen.refresh()
		1: if bolsa_screen.has_method("refresh"):    bolsa_screen.refresh()
		2: if nexodex_screen.has_method("refresh"):  nexodex_screen.refresh()
		3: if guardar_screen.has_method("refresh"):  guardar_screen.refresh()
		4: if ajustes_screen.has_method("refresh"):  ajustes_screen.refresh()
