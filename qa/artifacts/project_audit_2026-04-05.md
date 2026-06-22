# Auditoria 2026-04-05

## Hallazgos principales

- `pokedex_data.gd` ya no tiene 19 Nexos: el catalogo llega hasta `1039`, pero el encabezado del archivo seguia describiendo solo la base vieja.
- El menu rapido con `T` existia en codigo, pero las escenas activas del overworld no instanciaban ni `game_menu` ni `quick_menu`.
- Las escenas actuales `villa_nexo.tscn`, `ruta_1.tscn` y `ciudad_nora.tscn` si usan assets nuevos de `world_building_tiles`, pero siguen montadas de forma manual con `ColorRect` + `Sprite2D` recortados + colisiones rectangulares. No es un pipeline de tilemap real todavia.
- Habia mismatch entre nombres de zona del overworld (`ruta_1`, `ciudad_nora`, `villa_nexo`) y las tablas de encuentros (`route1`, `nora`, `pielago_central`).
- La integracion de sprites estaba partida: varios sistemas seguian buscando en `res://sprites/nexos/`, pero el proyecto real usa `res://Sprites_Nexos/`.
- `npc_controller.gd` y `dialogue_box.gd` dependian de nodos internos que las escenas nuevas no traian, provocando errores al cargar.
- Los assets nuevos de `world_building_tiles` necesitaban reimportacion real para que Godot dejara de marcarlos como inexistentes desde consola.

## Cambios aplicados

- Reimportados assets del proyecto con Godot `--import`.
- `overworld_controller.gd` ahora monta automaticamente `game_menu` y `quick_menu` en escenas jugables.
- Creada escena `escenas/ui/quick_menu.tscn`.
- `encounter_table.gd` ahora normaliza aliases de zona para mapas actuales.
- `npc_controller.gd` crea su `exclaim_label` si la escena no lo trae.
- `dialogue_box.gd` ahora construye su UI si la escena solo tiene el nodo vacio.
- `runtime_texture_loader.gd` ahora resuelve sprites por `id`, busca en `Sprites_Nexos` incluso en subcarpetas y entrega placeholder si falta arte fuente.
- Actualizados consumidores de sprites en batalla, Nexodex, caja, stats y starter select.
- Limpiados warnings de tipado que estaban rompiendo carga en `battle_scene.gd`, `battle_manager.gd` y `stats_screen.gd`.
- Actualizados probes de QA para overworld, menu rapido, sprites y encuentros.

## Verificaciones que pasaron

- `res://qa/overworld_ui_audit_probe.tscn`
- `res://qa/quick_menu_input_probe.tscn`
- `res://qa/encounter_zone_audit_probe.tscn`
- `res://qa/route_encounter_probe.tscn`
- `res://qa/sprite_resolution_probe.tscn`
- `res://qa/exp_stats_balance_probe.tscn`
- `res://qa/level_up_ui_probe.tscn`
- `res://qa/battle_turn_probe.tscn`

## Deuda real que sigue

- El overworld sigue siendo visualmente manual, no un sistema de `TileMapLayer/TileSet`. Eso significa mas riesgo de colisiones incoherentes y mapas dificiles de mantener.
- `battle_turn_probe` aun deja un warning de `ObjectDB instances leaked at exit` al terminar la prueba. La batalla entra bien al turno del jugador, pero el teardown de prueba o algun recurso de batalla sigue quedando vivo al cerrar.
- El encabezado de algunos archivos sigue desactualizado respecto al estado real del proyecto.
