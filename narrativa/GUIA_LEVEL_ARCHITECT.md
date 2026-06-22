# LevelArchitect — Guía de uso en Godot 4.6

## ¿Qué es?

LevelArchitect es un plugin de editor que te permite **pintar props decorativos directamente
en el viewport 2D** con un clic. Cada prop se crea con:
- `Sprite2D` con pivote en la base (correcto para Y-sort)
- `StaticBody2D + CollisionShape2D` en el zócalo inferior
- Y-sort habilitado

---

## Paso 1 — Activar el plugin

`Project → Project Settings → Plugins`

Busca **"Level Architect"** y cambia el estado a **Enable**.

Si no aparece, verifica que exista el archivo:
```
addons/level_architect/plugin.cfg
addons/level_architect/level_architect_plugin.gd
```

---

## Paso 2 — El nodo LevelArchitect en la escena

Las tres escenas ya lo tienen al final del árbol de nodos:
- `villa_nexo.tscn` → nodo `LevelArchitect`
- `ruta_1.tscn`     → nodo `LevelArchitect`
- `ciudad_nora.tscn` → nodo `LevelArchitect`

En el **Inspector** del nodo verás estas propiedades:

| Grupo | Propiedad | Valor por defecto | Para qué sirve |
|---|---|---|---|
| Origen de tiles | `Res Tile Folder` | `res://world_building_tiles` | Carpeta que escanea |
| Origen de tiles | `Scan Subfolders` | ✓ | Entra en subcarpetas |
| Brocha | `Brush Enabled` | ✓ | Activa/desactiva pintura |
| Brocha | `Require Shift` | ✓ | Exige Shift para pintar |
| Brocha | `Snap To Grid` | ✓ | Snap al grid |
| Brocha | `Snap Grid Px` | 16 | Tamaño de celda del snap |
| Escala normalizada | `Normalize To Px` | 32 | Ver sección de resolución |
| Colisión | `Collision Bottom Ratio` | 0.2 | % del alto que ocupa la colisión |
| Catálogo | `Selected Asset` | enum desplegable | El tile que se va a pintar |

---

## Paso 3 — Elegir el tile a pintar

Con el nodo `LevelArchitect` **seleccionado** en el árbol, abre el Inspector y busca la
propiedad **Selected Asset**. Aparecerá un desplegable con todas las imágenes encontradas en
`res://world_building_tiles/` (nombre de archivo sin extensión).

Selecciona la imagen que quieres colocar, por ejemplo `Objetos Nora`.

> **Nota:** los sheets completos (ej. "Objetos Nora.png" de 1920×2196) se colocarán como un
> sprite completo. Para extraer tiles individuales de esos sheets, usa la herramienta de
> región en Godot (`region_rect`) o recorta el sheet en imágenes separadas y ponlas en
> `world_building_tiles/tiles_individuales/`.

---

## Paso 4 — Pintar en el viewport

1. Selecciona el nodo `LevelArchitect` en el árbol de la escena
2. Abre la escena en el viewport 2D
3. Mantén **Shift** y haz **clic izquierdo** donde quieras colocar el prop
4. El prop aparece como hijo del nodo `LevelArchitect` con nombre `PlacedProp_001`, `PlacedProp_002`, etc.
5. Guarda la escena (Ctrl+S) para que los props queden en el `.tscn`

> Si no quieres usar Shift, desmarca `Require Shift For Brush` en el Inspector.

---

## Sobre las resoluciones de los tiles

Los sheets en `world_building_tiles/` tienen dos formatos mezclados:

### Sheets de 32 px/celda (grid limpio)
Ejemplos: `Details city 1.png` (2816×1536), `Edificios ciudad normal.png`
- Grid exacto de 32×32 px
- Ideal para **TileMapLayer** o para recortar en tiles individuales

### Sheets LPC-style (objetos a tamaño variable)
Ejemplos: `Objetos Nora.png` (1920×2196), `Objetos villa nexo.png`
- Los objetos tienen tamaños distintos: cactos ~80×130 px, edificios ~400×300 px
- No hay grid fijo; cada objeto ocupa lo que necesita

### ¿Qué pixels conviene usar?

El viewport del juego es **320×192** (escala 3×).
El grid de snap es **16 px** (1 tile = 1 celda).

| Tipo de prop | Tamaño recomendado en mundo | normalize_to_px |
|---|---|---|
| Tile pequeño (flor, moneda) | 16 px | 16 |
| Prop mediano (cactus, arbusto, barril) | 32 px | 32 |
| Árbol / palmera | 48 px | 48 |
| Edificio pequeño (casa) | 64–80 px | 64 |
| Edificio grande (hospital, mercado) | 96–128 px | dejar en 0 y ajustar manualmente |

**Recomendación general:** `normalize_to_px = 32` para el 90% de props decorativos.
Para edificios usa `normalize_to_px = 0` y ajusta el `scale` del Sprite2D manualmente.

---

## Botón "Generar decoraciones" (auto-generado)

Los tres scripts de mapa (`villa_nexo_map.gd`, `ruta_1_map.gd`, `ciudad_nora_map.gd`)
tienen el botón en el Inspector **cuando el nodo raíz está seleccionado**:

```
Inspector → [Generar decoraciones]
```

Al presionarlo:
1. Borra todos los nodos hijos que comiencen con `AutoProp_`
2. Vuelve a colocar el set de props decorativos predefinidos
3. Les asigna `owner` correcto para que persistan en el `.tscn`
4. Guarda la escena con Ctrl+S para que queden guardados

> Puedes editar las posiciones, region_rect y scale_factor directamente en el script de
> cada mapa para afinar los resultados.

---

## Flujo recomendado de trabajo

```
1. Abre la escena (ej. villa_nexo.tscn) en Godot
2. Selecciona el nodo raíz (VillaNexo) → Inspector → [Generar decoraciones]
   → guarda con Ctrl+S
3. Selecciona el nodo LevelArchitect
4. Elige "Selected Asset" en Inspector (ej. "Objetos villa nexo")
5. Shift+clic en viewport para pintar props adicionales
6. Ctrl+S para guardar
7. Ajusta posiciones arrastrando nodos PlacedProp_* en el árbol
```

---

## Ajustar region_rect de props existentes

Si un prop del sheet aparece con toda la imagen en lugar del objeto correcto:

1. Selecciona el nodo `PlacedProp_XXX/Sprite2D` en el árbol
2. Inspector → `Region Enabled` = ✓
3. `Region Rect` → ajusta x, y, w, h hasta recortar solo el objeto deseado
4. Usa **TextureRegion Editor** (clic en "Region Rect" en Inspector) para ver visualmente

---

## Referencia rápida de region_rects conocidas

### Objetos Nora.png

| Objeto | Rect2(x, y, w, h) | scale aprox |
|---|---|---|
| Cactus tipo A | Rect2(900, 1100, 80, 130) | 0.28 |
| Cactus tipo B | Rect2(1000, 1100, 80, 130) | 0.28 |
| Palmera tipo A | Rect2(1400, 1100, 120, 180) | 0.22 |
| Palmera tipo B | Rect2(1500, 1100, 120, 180) | 0.22 |
| Roca pequeña | Rect2(600, 800, 100, 60) | 0.3 |
| Roca tipo B | Rect2(700, 800, 100, 60) | 0.28 |
| Casa / edificio | Rect2(600, 800, 300, 250) | 0.2 |
| Mercado (grande) | Rect2(0, 1850, 550, 300) | 0.18 |
| Hospital (sheet hospital) | Rect2(350, 100, 600, 450) | 0.2 |

### Objetos villa brasa.png

| Objeto | Rect2(x, y, w, h) | scale aprox |
|---|---|---|
| Árbol tipo A | Rect2(1400, 900, 150, 200) | 0.18 |
| Árbol tipo B | Rect2(1550, 900, 150, 200) | 0.18 |
| Edificio Nana | Rect2(800, 500, 400, 300) | 0.22 |
| Casa pequeña | Rect2(1200, 500, 300, 250) | 0.2 |
