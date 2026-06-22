# How Nexos runs

Quick map of what happens when you press Play. All paths are under `res://` in Godot.

## Boot sequence

```
title_screen.tscn
  → new game / continue
  → starter_select (pick first creature)
  → GameManager.setup_new_adventure()
  → overworld (villa_nexo.tscn by default)
```

Autoloads loaded before any scene (`project.godot`):

| Autoload | Role |
|----------|------|
| `GameManager` | Party, money, flags, scene changes, autosave timer |
| `SaveSystem` | Read/write save slots |
| `InventorySystem` | Items and balls (ofrendas) |
| `AudioManager` | BGM + SFX routing |
| `GameOptions` | Volume, text speed |
| `DayNightSystem` | Time-of-day tint on maps |

## Overworld loop

1. **Player** moves on a tile/grid map (`player_controller.gd`).
2. **Tall grass** areas roll encounters from `encounter_table.gd`.
3. On encounter → `GameManager` stores return position and loads `battle_scene.tscn`.
4. **NPCs** use `npc_controller.gd` + `dialogue_box.gd`; some set story `flags`.
5. **Doors / exits** call `GameManager.request_scene_change(path, spawn_id)`.

Maps are separate `.tscn` files under `escenas/overworld/` (Villa Nexo, Route 1, clinics, etc.).

## Battle loop

`battle_scene.gd` owns the UI. `battle_manager.gd` owns rules.

```
INTRO → PLAYER_MENU → RESOLVING → (repeat or BATTLE_END)
```

Player menu options:

- Fight → pick move (`move_select_menu.tscn`)
- Ofrenda → `VinculoSystem` capture roll (replaces classic catch)
- Item → target ally/enemy depending on item
- Run → only in wild battles

Damage uses Gen 3+ formula in `battle_manager.gd` with `TYPE_CHART` multipliers, STAB, and status checks.

On **win**: EXP via `experience_system.gd`, possible level-up popup, return to overworld.  
On **catch/vinculo success**: creature added to party or box, battle ends.  
On **loss**: black-out flow → respawn at last checkpoint (see `defeat_respawn` QA probe).

## Save / load

- Manual save from menu → `SaveSystem.save_slot(n)`
- Autosave every 3 minutes once `nana_intro_done` flag is set
- Saves: party, box, inventory, flags, position, playtime

Save files live in `user://` (OS app data folder), not in the repo.

## Data files

| Path | Contents |
|------|----------|
| `recursos/datos/` | Creature stats, moves, type chart JSON |
| `recursos/datos/generated/` | Generated creature roster |
| `Sprites_Nexos/` | Front/back battle sprites |
| `codigo/datos/encounter_table.gd` | Per-route wild tables |

## QA probes

Under `qa/`, each `.tscn` runs one scenario headless-friendly from the editor (battle turn order, capture, house entry/exit, save round-trip). Use them when you change battle or overworld code.

Example: open `qa/battle_turn_probe.tscn` → F6 to run only that scene.

## Terminology (in-game)

| Old fan-game habit | Nexos UI/code |
|--------------------|---------------|
| Catch | Vínculo / Ofrenda |
| Pokédex | Códice |
| Gym | Santuario |

See `narrativa/world_bible.html` for lore; this file is only mechanics.
