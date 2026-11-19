#!/usr/bin/env python3
"""Generate a unique 16x16 party menu icon for every species.

Each icon is shrunk from the species' own front sprite
(gfx/pokemon/<name>/front.png, first frame) and written to
gfx/icons/mon/<name>.png as a 16x32 two-frame strip in the vanilla icon
format: white = transparent, light grey, dark grey (the palette color),
black. Frame 2 is frame 1 dropped by one pixel, so the icon bobs.

It also regenerates data/pokemon/menu_icon_pointers.asm and
gfx/mon_icons.asm, which the engine reads.

Hand edits: put a 16x32 PNG in tools/menu_icons/overrides/<name>.png and
it is copied as-is instead of being generated.

Run:  tools/sprite_convert/.venv/bin/python tools/menu_icons/make_icons.py
      [--sheet out.png]   also write a contact sheet of every icon
"""
import argparse
import re
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "gfx/icons/mon"
OVERRIDES = Path(__file__).resolve().parent / "overrides"

W, H = 16, 16
TRANSPARENT, LIGHT, COLOR, BLACK = 255, 170, 85, 0
SHADES = {0: TRANSPARENT, 1: LIGHT, 2: COLOR, 3: BLACK}


def species() -> list[str]:
    out = []
    for line in (REPO / "constants/pokemon_constants.asm").read_text().splitlines():
        if "NUM_POKEMON" in line:
            break
        m = re.match(r"\s*const (\w+)", line)
        if m:
            out.append(m.group(1))
    return out


def front_levels(name: str) -> np.ndarray:
    """First frame of the front sprite as shade levels 0 (white) .. 3 (black)."""
    path = REPO / f"gfx/pokemon/{name}/front.png"
    if not path.exists():  # Unown: one folder per letter
        path = REPO / f"gfx/pokemon/{name}_a/front.png"
    im = Image.open(path)
    side = im.width
    im = im.crop((0, 0, side, side))
    if im.mode == "P":
        pal = im.getpalette()[:12]
        lum = [0.299 * pal[i * 3] + 0.587 * pal[i * 3 + 1] + 0.114 * pal[i * 3 + 2] for i in range(4)]
        order = sorted(range(4), key=lambda i: -lum[i])
        rank = {idx: r for r, idx in enumerate(order)}
        a = np.vectorize(lambda v: rank.get(v, 0))(np.array(im))
    else:
        g = np.array(im.convert("L"))
        a = np.digitize(255 - g, [43, 128, 213])
    return a.astype(np.int8)


def background(levels: np.ndarray) -> np.ndarray:
    """White pixels connected to the border (white inside the body is not background)."""
    h, w = levels.shape
    bg = np.zeros_like(levels, dtype=bool)
    q = deque()
    for y in range(h):
        for x in (0, w - 1):
            q.append((y, x))
    for x in range(w):
        for y in (0, h - 1):
            q.append((y, x))
    while q:
        y, x = q.popleft()
        if bg[y, x] or levels[y, x] != 0:
            continue
        bg[y, x] = True
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not bg[ny, nx]:
                q.append((ny, nx))
    return bg


def shrink(arr: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    return np.array(Image.fromarray(arr.astype(np.float32), "F").resize(size, Image.BOX))


def despeckle(out: np.ndarray, inner: np.ndarray) -> np.ndarray:
    """Recolor lone light/color pixels inside the body to match their neighbors."""
    res = out.copy()
    h, w = out.shape
    for y, x in zip(*np.nonzero(inner)):
        v = out[y, x]
        if v == 3:
            continue
        nb = [out[y + dy, x + dx] for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))
              if 0 <= y + dy < h and 0 <= x + dx < w and inner[y + dy, x + dx] and out[y + dy, x + dx] != 3]
        if len(nb) >= 3 and v not in nb and len(set(nb)) == 1:
            res[y, x] = nb[0]
    return res


def make_frame(name: str) -> np.ndarray:
    lv = front_levels(name)
    fg = ~background(lv)
    ys, xs = np.nonzero(fg)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    lv, fg = lv[y0:y1, x0:x1], fg[y0:y1, x0:x1]
    h, w = lv.shape

    # Fit inside 16x15 (one row is left free for the bob frame).
    scale = min(W / w, (H - 1) / h)
    tw, th = max(1, round(w * scale)), max(1, round(h * scale))
    cov = shrink(fg.astype(np.float32), (tw, th))
    # Mean darkness of the body, white body pixels counting as light.
    body = np.where(fg, np.maximum(lv, 1), 0).astype(np.float32)
    dark = shrink(body, (tw, th)) / np.maximum(cov, 1e-6)
    # Share of near-black source pixels: keeps eyes and dark markings.
    black = shrink((lv == 3) & fg, (tw, th)) / np.maximum(cov, 1e-6)

    mask = cov >= 0.4
    out = np.zeros((th, tw), dtype=np.int8)
    out[mask] = np.where(dark[mask] >= 1.75, 2, 1)
    out[mask & (black >= 0.55)] = 3

    # Black outline on the silhouette's edge.
    pad = np.pad(mask, 1)
    edge = mask & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    out[edge] = 3
    out = despeckle(out, mask & ~edge)

    frame = np.zeros((H, W), dtype=np.int8)
    ox = (W - tw) // 2
    oy = (H - 1) - th  # sit on the second-to-last row
    frame[oy:oy + th, ox:ox + tw] = out
    return frame


def icon(name: str) -> Image.Image:
    f1 = make_frame(name)
    f2 = np.zeros_like(f1)
    f2[1:] = f1[:-1]
    strip = np.vectorize(SHADES.get)(np.vstack([f1, f2])).astype(np.uint8)
    return Image.fromarray(strip, "L")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", type=Path)
    args = ap.parse_args()

    mons = species()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    icons = []
    for const in mons:
        name = const.lower()
        override = OVERRIDES / f"{name}.png"
        im = Image.open(override).convert("L") if override.exists() else icon(name)
        im.save(OUT_DIR / f"{name}.png")
        icons.append(im)

    labels = [c.title().replace("_", "") for c in mons]
    (REPO / "gfx/mon_icons.asm").write_text(
        "; generated by tools/menu_icons/make_icons.py\n"
        "; 128 bytes per icon, 64 icons (8 KiB) per section\n\n"
        + "".join(
            (f'SECTION "Mon Icons {i // 64 + 1}", ROMX\n\n' if i % 64 == 0 else "")
            + f'MonIcon_{lab}: INCBIN "gfx/icons/mon/{c.lower()}.2bpp"\n'
            + ("\n" if i % 64 == 63 else "")
            for i, (c, lab) in enumerate(zip(mons, labels))
        )
    )
    (REPO / "data/pokemon/menu_icon_pointers.asm").write_text(
        "; generated by tools/menu_icons/make_icons.py\n"
        "; party menu icon graphics, indexed by species\n\n"
        "MonMenuIconPointers:\n\ttable_width 3\n"
        + "".join(f"\tdba MonIcon_{lab}\n" for lab in labels)
        + "\tassert_table_length NUM_POKEMON\n"
    )

    if args.sheet:
        cols, z = 32, 3
        rows = -(-len(icons) // cols)
        pal = {255: (232, 240, 248), 170: (248, 200, 168), 85: (216, 64, 48), 0: (16, 16, 16)}
        sheet = Image.new("RGB", (cols * 18 * z, rows * 18 * z), (255, 255, 255))
        for i, im in enumerate(icons):
            a = np.array(im)[:16]
            rgb = np.array([[pal[v] for v in row] for row in a], dtype=np.uint8)
            tile = Image.fromarray(rgb).resize((16 * z, 16 * z), Image.NEAREST)
            sheet.paste(tile, ((i % cols) * 18 * z + z, (i // cols) * 18 * z + z))
        sheet.save(args.sheet)
    print(f"wrote {len(icons)} icons")


if __name__ == "__main__":
    main()
