from __future__ import annotations

from pathlib import Path
import shutil

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "world_building_tiles" / "Characters" / "Nix, Main character"
OUT_DIR = ROOT / "Sprites_Nexos" / "personaje" / "overworld"
BACKUP_DIR = ROOT / "Sprites_Nexos" / "personaje" / "overworld_backup_pre_nix_worldbuilding"

WALK_SHEET = SRC_DIR / "Animaciones overwolrd Nix caminando.png"
RUN_SHEET = SRC_DIR / "Animaciones overwolrd Nix corriendo.png"

ROW_TO_DIR = {
    0: "down",
    1: "left",
    2: "right",
    3: "up",
}

FRAME_SIZE = (96, 112)
CONTENT_BOX = (80, 104)
CELL_INSET = (52, 18, 452, 520)


def backup_existing() -> None:
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    for png in OUT_DIR.glob("*.png"):
        target = BACKUP_DIR / png.name
        if not target.exists():
            shutil.copy2(png, target)


def remove_background_by_border_colors(img: Image.Image, tolerance: int = 24) -> Image.Image:
    out = img.copy().convert("RGBA")
    w, h = out.size
    px = out.load()

    seeds: list[tuple[int, int, int, int]] = []
    for x in range(w):
        seeds.append(px[x, 0])
        seeds.append(px[x, h - 1])
    for y in range(h):
        seeds.append(px[0, y])
        seeds.append(px[w - 1, y])

    unique_seeds: list[tuple[int, int, int, int]] = []
    for color in seeds:
        if not any(
            abs(color[0] - s[0]) + abs(color[1] - s[1]) + abs(color[2] - s[2]) <= 12
            for s in unique_seeds
        ):
            unique_seeds.append(color)

    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] == 0:
                continue
            score = min(abs(c[0] - s[0]) + abs(c[1] - s[1]) + abs(c[2] - s[2]) for s in unique_seeds)
            if score <= tolerance:
                px[x, y] = (c[0], c[1], c[2], 0)

    return out


def compose_frame(raw: Image.Image) -> Image.Image:
    cleaned = remove_background_by_border_colors(raw)
    bbox = cleaned.getbbox()
    if bbox is None:
        return Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))

    trimmed = cleaned.crop(bbox)
    content_w, content_h = CONTENT_BOX
    scale = min(content_w / trimmed.width, content_h / trimmed.height)
    scaled_size = (
        max(1, int(round(trimmed.width * scale))),
        max(1, int(round(trimmed.height * scale))),
    )
    scaled = trimmed.resize(scaled_size, Image.Resampling.NEAREST)

    canvas = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    x = int((FRAME_SIZE[0] - scaled.width) / 2)
    y = int(FRAME_SIZE[1] - scaled.height - 4)
    canvas.alpha_composite(scaled, (x, y))
    return canvas


def export_sheet(sheet_path: Path, prefix: str) -> None:
    sheet = Image.open(sheet_path).convert("RGBA")
    cols = 4
    rows = 4
    cell_w = sheet.width // cols
    cell_h = sheet.height // rows

    for row in range(rows):
        for col in range(cols):
            x0 = col * cell_w
            y0 = row * cell_h
            x1 = sheet.width if col == cols - 1 else (col + 1) * cell_w
            y1 = sheet.height if row == rows - 1 else (row + 1) * cell_h
            cell = sheet.crop((x0, y0, x1, y1))
            ix0, iy0, ix1, iy1 = CELL_INSET
            inner = cell.crop((ix0, iy0, min(ix1, cell.width), min(iy1, cell.height)))
            frame = compose_frame(inner)
            out_path = OUT_DIR / f"{prefix}_{ROW_TO_DIR[row]}_{col}.png"
            frame.save(out_path)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    backup_existing()
    export_sheet(WALK_SHEET, "walk")
    export_sheet(RUN_SHEET, "run")
    print("Nix overworld frames exported to", OUT_DIR)


if __name__ == "__main__":
    main()
