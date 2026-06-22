from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "world_building_tiles" / "buildings objects, floor etc"
OUT_DIR = ROOT / "recursos" / "mapas" / "generated"


def load_sheet(name: str) -> Image.Image:
    return Image.open(ASSET_DIR / name).convert("RGBA")


def crop(sheet: Image.Image, rect: tuple[int, int, int, int]) -> Image.Image:
    x, y, w, h = rect
    return sheet.crop((x, y, x + w, y + h)).convert("RGBA")


def distance(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> int:
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])


def remove_edge_background(img: Image.Image, tolerance: int = 42) -> Image.Image:
    out = img.copy().convert("RGBA")
    width, height = out.size
    px = out.load()

    seed_colors = {
        px[0, 0],
        px[width - 1, 0],
        px[0, height - 1],
        px[width - 1, height - 1],
    }

    visited: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited:
            continue
        visited.add((x, y))
        current = px[x, y]
        if current[3] == 0:
            continue
        if min(distance(current, seed) for seed in seed_colors) > tolerance:
            continue
        px[x, y] = (current[0], current[1], current[2], 0)
        if x > 0:
            queue.append((x - 1, y))
        if x < width - 1:
            queue.append((x + 1, y))
        if y > 0:
            queue.append((x, y - 1))
        if y < height - 1:
            queue.append((x, y + 1))

    bbox = out.getbbox()
    if bbox is None:
        return out

    trimmed = out.crop(bbox)
    padded = Image.new("RGBA", (trimmed.width + 4, trimmed.height + 4), (0, 0, 0, 0))
    padded.alpha_composite(trimmed, (2, 2))
    return padded


def scaled(img: Image.Image, factor: float) -> Image.Image:
    return img.resize(
        (max(1, int(round(img.width * factor))), max(1, int(round(img.height * factor)))),
        Image.Resampling.NEAREST,
    )


def tile_fill(canvas: Image.Image, tile: Image.Image, box: tuple[int, int, int, int]) -> None:
    x, y, w, h = box
    for oy in range(y, y + h, tile.height):
        for ox in range(x, x + w, tile.width):
            canvas.alpha_composite(tile, (ox, oy))


def paste(canvas: Image.Image, img: Image.Image, center: tuple[int, int], factor: float = 1.0) -> None:
    sprite = scaled(img, factor) if factor != 1.0 else img
    x = int(center[0] - sprite.width / 2)
    y = int(center[1] - sprite.height / 2)
    canvas.alpha_composite(sprite, (x, y))


def paste_many(canvas: Image.Image, img: Image.Image, points: list[tuple[int, int]], factor: float = 1.0) -> None:
    for point in points:
        paste(canvas, img, point, factor)


def villa_assets() -> dict[str, Image.Image]:
    villa = load_sheet("Objetos villa brasa.png")
    normal = load_sheet("Edificios ciudad normal.png")
    return {
        "grass": scaled(crop(villa, (575, 582, 182, 182)), 0.5),
        "path": scaled(crop(villa, (198, 399, 184, 182)), 0.5),
        "plaza": scaled(crop(villa, (388, 399, 184, 182)), 0.5),
        "tree_a": scaled(remove_edge_background(crop(villa, (1488, 1467, 140, 245))), 0.52),
        "tree_b": scaled(remove_edge_background(crop(villa, (1628, 1467, 140, 245))), 0.52),
        "tree_c": scaled(remove_edge_background(crop(villa, (1768, 1467, 140, 245))), 0.52),
        "flowers": scaled(remove_edge_background(crop(villa, (13, 1481, 152, 240))), 0.38),
        "garden": scaled(remove_edge_background(crop(villa, (174, 1482, 147, 239))), 0.38),
        "nana_house": scaled(remove_edge_background(crop(normal, (40, 40, 420, 620))), 0.30),
        "cafe": scaled(remove_edge_background(crop(normal, (1990, 20, 720, 620))), 0.28),
        "house_small": scaled(remove_edge_background(crop(normal, (680, 730, 700, 700))), 0.26),
        "house_red": scaled(remove_edge_background(crop(normal, (1440, 760, 640, 680))), 0.27),
    }


def nora_assets() -> dict[str, Image.Image]:
    nora = load_sheet("Objetos Nora.png")
    hospital = load_sheet("Hospital Nexo ciudad Nosa la polvosa.png")
    return {
        "sand": scaled(crop(nora, (14, 401, 181, 174)), 0.5),
        "sand_alt": scaled(crop(nora, (14, 582, 181, 174)), 0.5),
        "crack": scaled(crop(nora, (205, 400, 178, 175)), 0.5),
        "stone": scaled(crop(nora, (1153, 399, 180, 177)), 0.5),
        "stone_alt": scaled(crop(nora, (1152, 581, 181, 176)), 0.5),
        "wood": scaled(crop(nora, (1553, 582, 179, 174)), 0.5),
        "cactus_a": scaled(remove_edge_background(crop(nora, (21, 1461, 133, 143))), 0.72),
        "cactus_b": scaled(remove_edge_background(crop(nora, (168, 1461, 163, 143))), 0.72),
        "yucca": scaled(remove_edge_background(crop(nora, (506, 1485, 111, 218))), 0.55),
        "palm": scaled(remove_edge_background(crop(nora, (1075, 1481, 114, 227))), 0.5),
        "palm_b": scaled(remove_edge_background(crop(nora, (1285, 1478, 111, 225))), 0.5),
        "rocks": scaled(remove_edge_background(crop(nora, (1186, 1533, 102, 170))), 0.5),
        "market": scaled(remove_edge_background(crop(nora, (647, 1755, 433, 394))), 0.22),
        "house_a": scaled(remove_edge_background(crop(nora, (14, 815, 261, 263))), 0.3),
        "house_b": scaled(remove_edge_background(crop(nora, (281, 812, 263, 266))), 0.3),
        "house_c": scaled(remove_edge_background(crop(nora, (1102, 1855, 333, 304))), 0.22),
        "club": scaled(remove_edge_background(crop(nora, (1635, 144, 272, 207))), 0.28),
        "hospital": scaled(remove_edge_background(crop(hospital, (320, 40, 700, 520))), 0.24),
    }


def build_villa_nexo() -> Image.Image:
    assets = villa_assets()
    canvas = Image.new("RGBA", (480, 400), (0, 0, 0, 0))

    tile_fill(canvas, assets["grass"], (0, 0, 480, 400))
    tile_fill(canvas, assets["path"], (212, 0, 56, 400))
    tile_fill(canvas, assets["path"], (48, 172, 384, 56))
    tile_fill(canvas, assets["plaza"], (174, 144, 132, 112))

    paste(canvas, assets["nana_house"], (98, 98))
    paste(canvas, assets["cafe"], (370, 98))
    paste(canvas, assets["house_small"], (106, 258))
    paste(canvas, assets["house_red"], (372, 258))

    tree_points_top = [(26, 28), (74, 28), (122, 30), (170, 30), (218, 28), (266, 28), (314, 30), (362, 30), (410, 28), (454, 28)]
    tree_points_bottom = [(28, 370), (76, 370), (124, 370), (172, 370), (220, 370), (268, 370), (316, 370), (364, 370), (412, 370), (456, 370)]
    tree_points_left = [(24, 86), (24, 134), (24, 182), (24, 230), (24, 278), (24, 326)]
    tree_points_right = [(456, 86), (456, 134), (456, 182), (456, 230), (456, 278), (456, 326)]
    paste_many(canvas, assets["tree_a"], tree_points_top[::2] + tree_points_left[::2] + tree_points_right[::2], 1.0)
    paste_many(canvas, assets["tree_b"], tree_points_top[1::2] + tree_points_bottom[::2] + tree_points_left[1::2], 1.0)
    paste_many(canvas, assets["tree_c"], tree_points_bottom[1::2] + tree_points_right[1::2], 1.0)

    paste_many(canvas, assets["flowers"], [(82, 70), (396, 70), (84, 224), (392, 224)], 1.0)
    paste_many(canvas, assets["garden"], [(140, 112), (334, 112), (140, 286), (330, 286)], 1.0)

    return canvas


def build_ruta_1() -> Image.Image:
    villa = villa_assets()
    nora = nora_assets()
    canvas = Image.new("RGBA", (320, 800), (0, 0, 0, 0))

    tile_fill(canvas, villa["grass"], (0, 0, 320, 360))
    tile_fill(canvas, nora["sand"], (0, 360, 320, 440))
    tile_fill(canvas, nora["sand_alt"], (0, 520, 320, 280))
    tile_fill(canvas, villa["path"], (124, 0, 72, 360))
    tile_fill(canvas, nora["stone"], (118, 360, 84, 440))
    tile_fill(canvas, nora["stone_alt"], (126, 520, 68, 280))

    paste_many(canvas, villa["tree_a"], [(28, 52), (28, 108), (28, 164), (28, 220), (28, 276), (290, 78), (290, 134), (290, 190), (290, 246), (290, 302)], 1.0)
    paste_many(canvas, nora["cactus_a"], [(42, 444), (42, 572), (42, 700), (278, 458), (278, 586), (278, 714)], 1.0)
    paste_many(canvas, nora["cactus_b"], [(78, 490), (250, 530), (78, 664), (248, 760)], 1.0)
    paste_many(canvas, nora["yucca"], [(80, 378), (252, 404), (80, 622), (250, 680)], 1.0)
    paste_many(canvas, nora["rocks"], [(54, 326), (268, 614)], 1.0)

    grass_patch = scaled(villa["flowers"], 0.72)
    paste_many(canvas, grass_patch, [(58, 198), (242, 352), (82, 548), (250, 650)], 1.0)

    return canvas


def build_ciudad_nora() -> Image.Image:
    nora = nora_assets()
    canvas = Image.new("RGBA", (640, 520), (0, 0, 0, 0))

    tile_fill(canvas, nora["sand"], (0, 0, 640, 520))
    tile_fill(canvas, nora["sand_alt"], (0, 260, 640, 260))
    tile_fill(canvas, nora["stone"], (276, 0, 88, 520))
    tile_fill(canvas, nora["stone_alt"], (0, 216, 640, 72))
    tile_fill(canvas, nora["wood"], (0, 448, 640, 72))

    paste(canvas, nora["house_a"], (118, 118))
    paste(canvas, nora["house_b"], (520, 118))
    paste(canvas, nora["market"], (120, 364))
    paste(canvas, nora["house_c"], (520, 372))
    paste(canvas, nora["club"], (432, 254))

    paste_many(canvas, nora["cactus_a"], [(48, 480), (592, 478)], 1.0)
    paste_many(canvas, nora["palm"], [(42, 470), (598, 470)], 1.0)
    paste_many(canvas, nora["yucca"], [(248, 134), (400, 136), (246, 390), (404, 390)], 1.0)
    paste_many(canvas, nora["rocks"], [(78, 192), (560, 186)], 1.0)
    tile_fill(canvas, nora["sand"], (64, 72, 112, 96))
    tile_fill(canvas, nora["sand"], (464, 72, 112, 96))

    return canvas


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    outputs = {
        "villa_nexo_bg.png": build_villa_nexo(),
        "ruta_1_bg.png": build_ruta_1(),
        "ciudad_nora_bg.png": build_ciudad_nora(),
    }
    for name, image in outputs.items():
        image.save(OUT_DIR / name)
        print(f"generated {name}")


if __name__ == "__main__":
    main()
