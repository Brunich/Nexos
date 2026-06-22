# Assets not in git

## `world_building_tiles/`

Local Godot import cache for map tiles (~440 MB). Not tracked so the repo stays under GitHub limits.

After clone: open the project in Godot 4.6 once. The editor rebuilds imports from `recursos/mapas/` and scene references.

## Sprites and audio

Creature sprites live in `Sprites_Nexos/`. Battle cries and BGM are under `audio/`. Both are included in the repo.

Optional PokeAPI sprite download (legacy placeholders):

```bash
python descargar_sprites.py
python descargar_datos.py
```
