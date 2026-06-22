# Nexos

Fan RPG built in **Godot 4.6** (GDScript). Top-down overworld, turn-based battles, party management, and original creature data. Uses a Gen 3–style battle loop with custom terminology (Vínculo instead of catch, Códice instead of Pokédex).

Not affiliated with Nintendo or The Pokémon Company.

**How it works:** see [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md) for boot flow, battle phases, saves, and file map.

## Run

1. Install [Godot 4.6](https://godotengine.org/) (GL Compatibility).
2. Import `project.godot`.
3. Press F5 — starts at the title screen.

First open after clone may take a minute while the editor imports sprites and audio.

## What's in the build

### Battle

- Turn phases: intro → player menu → resolve → end
- Full type chart (18 types + Veil)
- STAB, accuracy, status (poison, burn, paralysis, sleep, freeze)
- `VinculoSystem` — capture/offering flow with wobble animation
- EXP and level-up with stat recalc
- Wild and trainer battles, run, items in battle

### Overworld

- Maps: Villa Nexo, Route 1, Ciudad Nora, clinics, houses
- Tall-grass weighted encounters
- NPC dialogue and scene transitions with spawn IDs
- Day/night and weather hooks

### Meta systems

- `GameManager` autoload — party, money, flags, badges, autosave every 3 min
- `SaveSystem` — manual + auto slots
- `InventorySystem` — balls (ofrendas), potions, antidote
- `HuellaSystem` / `LatidoSystem` — identity and bond (Tonal) mechanics
- UI: party, box, Códice, stats, options, starter select

### Content

- Custom creatures under `Sprites_Nexos/`
- JSON data: moves, types, encounters, generated creature roster
- BGM and cries in `audio/`
- Narrative docs in `narrativa/` (world bible, dialogue drafts)

### QA

Headless-style probe scenes in `qa/` for battle turns, capture, save, map entry, party switch, etc. Run individual `.tscn` files from the editor when debugging.

## Layout

```
codigo/
  autoload/     game_manager
  batalla/      battle_manager, battle_scene, type chart, exp, vinculo
  datos/        encounters, dialogue, teams
  overworld/    maps, player, NPCs, grass
  recursos/     creature_instance, move_data
  sistemas/     save, inventory, audio, day/night, weather, abilities
  ui/           menus, pokedex, party, battle UI helpers
escenas/        .tscn scenes (overworld, batalla, ui)
recursos/       themes, map JSON, generated data
Sprites_Nexos/  creature art
audio/          music + cries
narrativa/      design docs
qa/             test probes
```

## Large files

`world_building_tiles/` is gitignored (local import cache). See [docs/assets.md](docs/assets.md).

## Data credits

- Open stats reference: [PokeAPI](https://pokeapi.co/) (CC0)
- Game code and original creature designs: Bruno Salas Rodriguez

## License

Code in this repo is portfolio work by the author. Creature names, art, and narrative are original fan content — do not reuse commercially without permission.

---

**Español:** RPG fan en Godot 4.6 con overworld, batallas por turnos, captura por Vínculo, guardado y mapas jugables. Abre `project.godot` en Godot 4.6 y F5.
