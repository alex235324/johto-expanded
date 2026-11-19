#!/usr/bin/env python3
"""Convert official Gen 3-5 battle sprites into pokecrystal16's pic format.

Usage:
    .venv/bin/python convert.py mudkip munchlax snivy          # download from PokeAPI
    .venv/bin/python convert.py snivy:495 --frames 2
    .venv/bin/python convert.py --source-dir ~/romhacking/sprite_sources            # whole local set
    .venv/bin/python convert.py --source-dir ~/romhacking/sprite_sources treecko    # just some

Everything is written to staging folders next to this script:
    source/<name>/          cached downloads (front.png, back.png, shiny.png, meta.json)
    out/<name>/             drop-in folder: front.png back.png shiny.pal anim.asm anim_idle.asm
    out/_extras/<name>/     normal.pal (reference only), preview.png, report.json
    out/contact_sheet.png   batch on one image (paged into out/contact_sheets/ for big batches)
    out/summary.csv         one row per Pokémon with size, palette and warnings
Nothing under gfx/ or any .asm/.inc/data file is touched. See FORMAT.md.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import unicodedata
import urllib.error
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
SOURCE_DIR = HERE / "source"
OUT_DIR = HERE / "out"
CREDITS = HERE / "CREDITS.md"

SPRITES_RAW = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions"
SPECIES_API = "https://pokeapi.co/api/v2/pokemon-species/{}"
USER_AGENT = "sprite_convert/1.0 (pokecrystal16 local tool)"

# Preferred source game per generation of the *species*.
GAMES = {
    "emerald": ("generation-iii/emerald", "Pokémon Emerald"),
    "frlg": ("generation-iii/firered-leafgreen", "Pokémon FireRed/LeafGreen"),
    "hgss": ("generation-iv/heartgold-soulsilver", "Pokémon HeartGold/SoulSilver"),
    "bw": ("generation-v/black-white", "Pokémon Black/White"),
}

FRONT_SIZES = (40, 48, 56)
BACK_SIZE = 48
DROP_LINES_MIN_SCALE = 0.75  # below this, area-downscale first, then drop lines

# Label values used in the working index maps.
TRANSPARENT, WHITE, LIGHT, DARK, BLACK = -1, 0, 1, 2, 3


# --------------------------------------------------------------------------- fetching

def http_get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read()


def resolve_id(name: str) -> int:
    """National dex number for a species name, via PokeAPI (cached)."""
    cache_file = SOURCE_DIR / "species_ids.json"
    cache = json.loads(cache_file.read_text()) if cache_file.exists() else {}
    if name in cache:
        return cache[name]
    data = json.loads(http_get(SPECIES_API.format(name)))
    cache[name] = int(data["id"])
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file.write_text(json.dumps(cache, indent=2, sort_keys=True) + "\n")
    return cache[name]


def default_game(dex_id: int) -> str:
    if dex_id <= 386:
        return "emerald"
    if dex_id <= 493:
        return "hgss"
    if dex_id <= 649:
        return "bw"
    raise SystemExit(f"#{dex_id}: no Gen 3-5 battle sprite exists (Gen 5 ends at #649)")


def fetch_sources(name: str, dex_id: int, game: str, refetch: bool) -> dict:
    folder, game_title = GAMES[game]
    dest = SOURCE_DIR / name
    dest.mkdir(parents=True, exist_ok=True)
    urls = {
        "front": f"{SPRITES_RAW}/{folder}/{dex_id}.png",
        "back": f"{SPRITES_RAW}/{folder}/back/{dex_id}.png",
        "shiny": f"{SPRITES_RAW}/{folder}/shiny/{dex_id}.png",
    }
    for kind, url in urls.items():
        path = dest / f"{kind}.png"
        if path.exists() and not refetch:
            continue
        try:
            data = http_get(url)
        except urllib.error.HTTPError as e:
            raise SystemExit(f"{name}: download failed ({e.code}) for {url}")
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise SystemExit(f"{name}: {url} did not return a PNG")
        path.write_bytes(data)
        print(f"  fetched {kind}: {url}")
    meta = {"name": name, "id": dex_id, "game": game, "game_title": game_title, "urls": urls,
            "files": {k: str(dest / f"{k}.png") for k in urls}}
    (dest / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    return meta


# Manifest "source_game" values -> GAMES keys.
MANIFEST_GAMES = {
    "emerald": "emerald",
    "firered/leafgreen": "frlg",
    "heartgold/soulsilver": "hgss",
    "black/white": "bw",
}


def crystal_name(name: str) -> str:
    """pokecrystal folder naming: lowercase, punctuation -> underscore (ho_oh, mr__mime)."""
    return re.sub(r"[^a-z0-9]", "_", name.lower())


def local_sources(root: Path, only: list[str]) -> list[dict]:
    """Read <root>/manifest.csv (dex,name,generation,source_game,folder); each
    folder holds front.png, back.png, front_shiny.png (back_shiny.png unused:
    pokecrystal has a single shiny palette shared by front and back)."""
    rows = list(csv.DictReader(open(root / "manifest.csv", newline="")))
    wanted = {crystal_name(n) for n in only}
    metas = []
    for r in rows:
        name = crystal_name(r["name"])
        if wanted and name not in wanted and r["dex"] not in wanted:
            continue
        game = MANIFEST_GAMES.get(r["source_game"].strip().lower())
        if game is None:
            raise SystemExit(f"manifest: unknown source_game {r['source_game']!r} for {name}")
        folder, title = GAMES[game]
        dex_id = int(r["dex"])
        d = root / r["folder"]
        metas.append({
            "name": name, "id": dex_id, "game": game, "game_title": title,
            "files": {"front": str(d / "front.png"), "back": str(d / "back.png"),
                      "shiny": str(d / "front_shiny.png")},
            # where these files come from upstream (per the set's SOURCES.md)
            "urls": {"front": f"{SPRITES_RAW}/{folder}/{dex_id}.png",
                     "back": f"{SPRITES_RAW}/{folder}/back/{dex_id}.png",
                     "shiny": f"{SPRITES_RAW}/{folder}/shiny/{dex_id}.png"},
        })
    missing = wanted - {m["name"] for m in metas} - {str(m["id"]) for m in metas}
    if missing:
        raise SystemExit(f"not in manifest: {', '.join(sorted(missing))}")
    return metas


# --------------------------------------------------------------------------- color math

def srgb_to_oklab(rgb: np.ndarray) -> np.ndarray:
    """rgb: (..., 3) uint8 -> (..., 3) float OKLab."""
    c = rgb.astype(np.float64) / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929],
                   [0.2119034982, 0.6806995451, 0.1073969566],
                   [0.0883024619, 0.2817188376, 0.6299787005]])
    m2 = np.array([[0.2104542553, 0.7936177850, -0.0040720468],
                   [1.9779984951, -2.4285922050, 0.4505937099],
                   [0.0259040371, 0.7827717662, -0.8086757660]])
    lms = np.cbrt(lin @ m1.T)
    return lms @ m2.T


def to5(rgb8) -> tuple[int, int, int]:
    return tuple(int(round(v * 31 / 255)) for v in rgb8)


def to8(rgb5) -> tuple[int, int, int]:
    return tuple((c << 3) | (c >> 2) for c in rgb5)


def gbc_luma(rgb5) -> float:
    r, g, b = rgb5
    return 0.299 * r + 0.587 * g + 0.114 * b  # same formula as tools/gbcpal.c


def safe_middle(rgb5) -> tuple[int, int, int]:
    """gbcpal drops exact black/white, so a middle color may never be either."""
    if rgb5 == (0, 0, 0):
        return (1, 1, 1)
    if rgb5 == (31, 31, 31):
        return (30, 30, 30)
    return rgb5


# --------------------------------------------------------------------------- quantize

def load_rgba(path: Path) -> np.ndarray:
    return np.array(Image.open(path).convert("RGBA"))


def bbox(mask: np.ndarray):
    ys, xs = np.nonzero(mask)
    if len(ys) == 0:
        raise ValueError("sprite is fully transparent")
    return ys.min(), ys.max() + 1, xs.min(), xs.max() + 1


def color_stats(rgba: np.ndarray):
    """Unique opaque colors of an image plus per-color shape statistics.

    Returns (colors uint8 (n,3), counts, oklab (n,3), same_nb, on_edge, key map)
    where same_nb is the mean number of 4-neighbours sharing the color (about 1
    for 1px lines, about 3+ for filled areas) and on_edge is the fraction of
    the color's pixels that touch transparency.
    """
    mask = rgba[..., 3] >= 128
    key = (rgba[..., 0].astype(np.int64) << 16) | (rgba[..., 1].astype(np.int64) << 8) | rgba[..., 2]
    key[~mask] = -1
    p = np.pad(key, 1, constant_values=-1)
    h, w = key.shape
    nbs = [p[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))]
    same = sum((n == key).astype(np.int64) for n in nbs)
    edge = sum((n == -1).astype(np.int64) for n in nbs) > 0
    keys, inv, counts = np.unique(key[mask], return_inverse=True, return_counts=True)
    same_nb = np.bincount(inv, weights=same[mask]) / counts
    on_edge = np.bincount(inv, weights=edge[mask]) / counts
    colors = np.stack([(keys >> 16) & 255, (keys >> 8) & 255, keys & 255], 1).astype(np.uint8)
    return colors, counts.astype(np.float64), srgb_to_oklab(colors), same_nb, on_edge, key


def representative_color(colors: np.ndarray, counts: np.ndarray) -> tuple[int, int, int]:
    """Pick the official color that best stands for a cluster.

    A cluster mixes a body color's shades with stray accents, so neither
    the most-used single shade (often a pale highlight, which washes the
    body out) nor an average (muddy) works. Each color is scored by how
    many pixels look like it (OKLab, lightness counting for less so a
    shading ramp backs its middle), with a small bonus for chroma so a
    real body color beats a near-grey of the same weight. The best-backed
    original color wins. Tuned on the Gen 3-5 set (Swampert, Spheal,
    Throh, Kricketot, Nuzleaf, Deerling, Salamence, Marshtomp, Lileep,
    Carvanha).
    """
    lab = srgb_to_oklab(colors)
    d = lab[:, None, :] - lab[None, :, :]
    dist2 = 0.2 * d[..., 0] ** 2 + d[..., 1] ** 2 + d[..., 2] ** 2
    support = (np.exp(-dist2 / 0.06 ** 2) * counts[None, :]).sum(1)
    support *= 1 + 2 * np.hypot(lab[:, 1], lab[:, 2])
    return tuple(int(v) for v in colors[support.argmax()])


def keep_features(out: np.ndarray, idx: np.ndarray, lab: np.ndarray, final: np.ndarray) -> np.ndarray:
    """Keep small accent areas from melting into what surrounds them.

    An accent is a color whose hue is far from the palette color it got
    (Swampert's red mouth drawn in the body's dark blue). Each connected
    patch of accent pixels that ended up the same label as most of its
    non-outline border is moved one step along the shading ramp, darker if
    the original is darker than that palette color and lighter otherwise,
    so the mouth, eyes or spots still read.
    """
    chroma = np.hypot(lab[:, 1], lab[:, 2])
    hue = np.degrees(np.arctan2(lab[:, 2], lab[:, 1]))
    flab = final[np.clip(out, 0, 3)]
    fchroma = np.hypot(flab[..., 1], flab[..., 2])
    fhue = np.degrees(np.arctan2(flab[..., 2], flab[..., 1]))
    valid = idx >= 0
    pc = np.where(valid, chroma[np.clip(idx, 0, None)], 0)
    ph = np.where(valid, hue[np.clip(idx, 0, None)], 0)
    dh = np.abs((ph - fhue + 180) % 360 - 180)
    accent = valid & ((out == LIGHT) | (out == DARK)) & (pc > 0.05) & (fchroma > 0.05) & (dh > 60)
    res = out.copy()
    seen = np.zeros_like(accent)
    h, w = out.shape
    for sy, sx in zip(*np.nonzero(accent)):
        if seen[sy, sx]:
            continue
        comp, stack, border = [], [(sy, sx)], {}
        seen[sy, sx] = True
        while stack:
            y, x = stack.pop()
            comp.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if not (0 <= ny < h and 0 <= nx < w):
                    continue
                if accent[ny, nx] and out[ny, nx] == out[sy, sx]:
                    if not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
                elif out[ny, nx] in (WHITE, LIGHT, DARK):
                    border[out[ny, nx]] = border.get(out[ny, nx], 0) + 1
        here = out[sy, sx]
        if not border or max(border, key=border.get) != here:
            continue
        ys, xs = zip(*comp)
        mean_l = lab[idx[list(ys), list(xs)], 0].mean()
        res[list(ys), list(xs)] = here + 1 if mean_l < final[here, 0] else here - 1
    return res


class Quantizer:
    """Rule-based black/white + 2-means for the middle colors, in OKLab.

    Gen 3-5 sprites outline in dark *tinted* colors (navy, dark green), so
    lightness alone can't tell an outline from body shading of the same
    darkness. A color is sent to BLACK when it is very dark, or dark and
    line-shaped (few same-colored neighbours), or mostly on the silhouette
    edge. WHITE takes near-neutral highlights, including the pale tinted
    shine Gen 3-5 sprites put on bellies and heads, so cream/yellow bellies
    stay a real color but a highlight never becomes the body color.
    Everything else is split into LIGHT/DARK with a count-weighted 2-means
    (lightness weighted x2, since the four indices are a shading ramp). The
    palette color for each cluster is the official color at the center of
    its biggest color family (see representative_color), not a muddy average.
    """

    L_WEIGHT = 2.0
    BLACK_L = 0.25          # anything darker is black
    OUTLINE_L = 0.50        # dark + line-shaped -> black
    OUTLINE_SAME_NB = 1.3
    EDGE_L = 0.65           # mostly-on-silhouette + not light -> black
    EDGE_FRAC = 0.5
    WHITE_L = 0.93
    WHITE_CHROMA = 0.08
    HIGHLIGHT_L = 0.88      # pale + barely tinted -> white too
    HIGHLIGHT_CHROMA = 0.06

    def __init__(self, rgba: np.ndarray):
        self.colors, self.counts, self.lab, same_nb, on_edge, _ = color_stats(rgba)
        forced = self._forced(self.lab, same_nb, on_edge)
        free = forced < 0
        if free.sum() < 2:
            raise SystemExit("sprite has fewer than two non-outline colors; can't build a palette")
        lab, cnt = self.lab[free], self.counts[free]
        self.mid = None
        pair = self._accent_pair(self.colors[free], cnt, lab)
        if pair is not None:
            # Body color + accent color, like vanilla Pikachu's yellow and
            # red: the sprite keeps the colors you'd recognize it by, at the
            # cost of shading the body in a single color.
            self.mid = pair
            self.final = srgb_to_oklab(np.array([(255, 255, 255), *pair, (0, 0, 0)], dtype=np.uint8))
            self.labels = forced.copy()
            self.labels[free] = self._nearest_final(lab)
            return
        order = np.argsort(lab[:, 0])
        cum = np.cumsum(cnt[order]) / cnt.sum()
        self.centroids = np.array([lab[order[min(np.searchsorted(cum, q), len(order) - 1)]] for q in (0.75, 0.25)])
        for _ in range(50):
            lbl = self._nearest(lab)
            new = np.array([np.average(lab[lbl == k], axis=0, weights=cnt[lbl == k]) if (lbl == k).any()
                            else self.centroids[k] for k in (0, 1)])
            if np.allclose(new, self.centroids, atol=1e-6):
                break
            self.centroids = new
        if self.centroids[0, 0] < self.centroids[1, 0]:
            self.centroids = self.centroids[::-1].copy()
        self.labels = forced.copy()
        self.labels[free] = self._nearest(lab) + LIGHT
        # The 2-means split is by lightness, so accents of another hue
        # (Swampert's orange gills and eyes, red mouth) land in the body's
        # cluster and vanish into the body color. Once the palette is known,
        # send every free color to whichever of the four final colors it
        # looks most like, then re-pick the palette from that grouping.
        for _ in range(2):
            self._set_final()
            relabel = self._nearest_final(lab)
            if not ((relabel == LIGHT).any() and (relabel == DARK).any()):
                break
            self.labels[free] = relabel
        self._set_final()

    ACCENT_MIN_SHARE = 0.04   # accent family must cover this much of the body
    ACCENT_MIN_DIST = 0.10    # ...and sit this far from the body color (OKLab a/b)
    FAMILY_DIST = 0.07        # colors closer than this (a/b) share a family
    GREY_CHROMA = 0.04

    @classmethod
    def _families(cls, lab, cnt):
        """Group colors by tint (OKLab a/b), biggest first; near-greys form
        one group. Each family is [seed a/b or None, member indices, count]."""
        chroma = np.hypot(lab[:, 1], lab[:, 2])
        fams = []
        for i in np.argsort(-cnt):
            grey = chroma[i] < cls.GREY_CHROMA
            for f in fams:
                if (f[0] is None and grey) or (f[0] is not None and not grey
                                               and np.hypot(*(lab[i, 1:] - f[0])) < cls.FAMILY_DIST):
                    f[1].append(i)
                    f[2] += cnt[i]
                    break
            else:
                fams.append([None if grey else lab[i, 1:].copy(), [i], cnt[i]])
        fams.sort(key=lambda f: -f[2])
        return fams

    def _accent_pair(self, colors, cnt, lab):
        """(light, dark) = body color and its strongest accent, or None when
        the sprite has no accent big and different enough to be worth a slot."""
        fams = self._families(lab, cnt)
        if len(fams) < 2:
            return None
        body = fams[0]
        best, best_score = None, 0.0
        for f in fams[1:]:
            if f[2] < self.ACCENT_MIN_SHARE * cnt.sum():
                continue
            if body[0] is None or f[0] is None:
                score = f[2] * 0.5  # grey vs color: weaker than a real tint contrast
            else:
                d = float(np.hypot(*(f[0] - body[0])))
                if d < self.ACCENT_MIN_DIST:
                    continue
                score = f[2] * min(1.0, d / 0.2)
            if score > best_score:
                best, best_score = f, score
        if best is None:
            return None
        a = representative_color(colors[body[1]], cnt[body[1]])
        b = representative_color(colors[best[1]], cnt[best[1]])
        if gbc_luma(to5(a)) < gbc_luma(to5(b)):
            a, b = b, a
        return a, b

    def _set_final(self):
        light, dark = self.middle_colors()
        self.final = srgb_to_oklab(np.array([(255, 255, 255), light, dark, (0, 0, 0)], dtype=np.uint8))

    FINAL_W = (1.0, 2.0, 2.0)  # hue counts double, so accents keep contrast

    def _nearest_final(self, lab: np.ndarray) -> np.ndarray:
        w = np.array(self.FINAL_W)
        return (((lab[:, None, :] - self.final[None]) * w) ** 2).sum(-1).argmin(1)

    @classmethod
    def _forced(cls, lab, same_nb, on_edge) -> np.ndarray:
        L, C = lab[:, 0], np.hypot(lab[:, 1], lab[:, 2])
        out = np.full(len(lab), -1, dtype=np.int64)
        out[((L > cls.WHITE_L) & (C < cls.WHITE_CHROMA)) | ((L > cls.HIGHLIGHT_L) & (C < cls.HIGHLIGHT_CHROMA))] = WHITE
        black = (L < cls.BLACK_L) | ((L < cls.OUTLINE_L) & (same_nb < cls.OUTLINE_SAME_NB)) \
            | ((L < cls.EDGE_L) & (on_edge >= cls.EDGE_FRAC))
        out[black] = BLACK
        return out

    def _nearest(self, lab: np.ndarray) -> np.ndarray:
        w = np.array([self.L_WEIGHT, 1.0, 1.0])
        return (((lab[:, None, :] - self.centroids[None]) * w) ** 2).sum(-1).argmin(1)

    def middle_colors(self) -> tuple[tuple, tuple]:
        """The representative original color of each middle cluster."""
        if self.mid is not None:
            return self.mid
        out = []
        for k in (LIGHT, DARK):
            sel = np.nonzero(self.labels == k)[0]
            out.append(representative_color(self.colors[sel], self.counts[sel]))
        return out[0], out[1]

    def label_image(self, rgba: np.ndarray) -> np.ndarray:
        """Per-pixel labels for any image (also used for the back sprite):
        black/white rules are evaluated on that image's own shapes, the rest
        snap to this quantizer's LIGHT/DARK centres."""
        colors, counts, lab, same_nb, on_edge, key = color_stats(rgba)
        lbl = self._forced(lab, same_nb, on_edge)
        free = lbl < 0
        lbl[free] = self._nearest_final(lab[free])
        keys = (colors[:, 0].astype(np.int64) << 16) | (colors[:, 1].astype(np.int64) << 8) | colors[:, 2]
        out = np.full(key.shape, TRANSPARENT, dtype=np.int8)
        mask = key >= 0
        idx = np.full(key.shape, -1, dtype=np.int64)
        idx[mask] = np.searchsorted(keys, key[mask])
        out[mask] = lbl[idx[mask]]
        return keep_features(out, idx, lab, self.final)


# --------------------------------------------------------------------------- resize/place

def overlap_matrix(n_in: int, n_out: int) -> np.ndarray:
    """(n_out, n_in) matrix of the fraction of each output pixel covered by each input pixel."""
    scale = n_in / n_out
    m = np.zeros((n_out, n_in))
    for o in range(n_out):
        a, b = o * scale, (o + 1) * scale
        b = min(b, n_in)  # float error can put the last edge a hair past the image
        for i in range(int(np.floor(a)), min(int(np.ceil(b)), n_in)):
            m[o, i] = max(0.0, min(b, i + 1) - max(a, i))
    return m / scale


def downscale_labels(labels: np.ndarray, out_h: int, out_w: int, black_bias: float = 0.34) -> np.ndarray:
    """Area-coverage downscale of a label map that protects outlines.

    For each output pixel we compute how much of it each class covers. It's
    transparent if transparency covers half or more; otherwise black wins if
    it covers at least `black_bias` (so 1px outlines survive), else the
    majority class. No resampling blur, so no new colors are invented.
    """
    h, w = labels.shape
    wy, wx = overlap_matrix(h, out_h), overlap_matrix(w, out_w)
    classes = [TRANSPARENT, WHITE, LIGHT, DARK, BLACK]
    cov = np.stack([wy @ (labels == c).astype(np.float64) @ wx.T for c in classes])
    out = np.array(classes, dtype=np.int8)[cov[1:].argmax(0) + 1]
    out[cov[4] >= black_bias] = BLACK
    out[cov[0] >= 0.5] = TRANSPARENT
    return out


def drop_lines(labels: np.ndarray, out_h: int, out_w: int) -> np.ndarray:
    """Shrink pixel art by deleting its most redundant rows and columns.

    Resampling smears 1px details (eyes, mouths, outlines) at non-integer
    scales. Instead, repeatedly delete the row or column that differs least
    from its neighbour, so flat areas get thinner while every surviving
    pixel is an original one. A deleted line makes its neighbours slightly
    costlier to delete, which spreads the cuts out instead of carving one
    region away.
    """
    lab = labels.copy()
    for axis, target in ((1, out_w), (0, out_h)):
        lab = np.moveaxis(lab, axis, 0)
        penalty = np.zeros(lab.shape[0])
        while lab.shape[0] > target:
            diff = (lab[1:] != lab[:-1]).reshape(lab.shape[0] - 1, -1).sum(1).astype(np.float64)
            cost = diff + penalty[1:]
            i = int(cost.argmin()) + 1  # delete line i, keep its twin i-1
            lab = np.delete(lab, i, 0)
            penalty = np.delete(penalty, i)
            for j in (i - 1, i):
                if 0 <= j < len(penalty):
                    penalty[j] += 1.5
        lab = np.moveaxis(lab, 0, axis)
    return lab


def fit(labels: np.ndarray, max_side: int) -> tuple[np.ndarray, float]:
    h, w = labels.shape
    if max(h, w) <= max_side:
        return labels, 1.0
    s = max_side / max(h, w)
    nh, nw = max(1, round(h * s)), max(1, round(w * s))
    if s >= DROP_LINES_MIN_SCALE:
        return drop_lines(labels, nh, nw), s
    # big reductions: halve by area first, then trim the rest by dropping lines
    mid = downscale_labels(labels, max(nh, round(h * s / DROP_LINES_MIN_SCALE)), max(nw, round(w * s / DROP_LINES_MIN_SCALE)))
    return drop_lines(mid, nh, nw), s


def outline_silhouette(labels: np.ndarray) -> np.ndarray:
    """Force opaque pixels that touch transparency (4-neighbour) to black."""
    opaque = labels != TRANSPARENT
    pad = np.pad(opaque, 1, constant_values=False)
    edge = opaque & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    out = labels.copy()
    out[edge] = BLACK
    return out


def place_bottom_center(labels: np.ndarray, size: int) -> np.ndarray:
    h, w = labels.shape
    canvas = np.full((size, size), WHITE, dtype=np.uint8)
    y0, x0 = size - h, (size - w) // 2
    canvas[y0:y0 + h, x0:x0 + w] = np.where(labels == TRANSPARENT, WHITE, labels)
    return canvas


def swap_mid(idx: np.ndarray) -> np.ndarray:
    return np.choose(idx, [WHITE, DARK, LIGHT, BLACK]).astype(np.uint8)


# --------------------------------------------------------------------------- writers

def save_indexed_png(path: Path, idx: np.ndarray, palette8: list[tuple]):
    im = Image.fromarray(idx.astype(np.uint8), "P")
    flat = [v for c in palette8 for v in c]
    im.putpalette(flat, rawmode="RGB")
    # match vanilla: 4-entry PLTE + all-opaque tRNS
    # (Pillow stores 4-color images at 2 bits/pixel; vanilla files are 8-bit.
    # rgbgfx reads both the same.)
    im.save(path, transparency=b"\xff\xff\xff\xff")


def pal_text(light5, dark5) -> str:
    def line(c):
        return "\tRGB {:02d}, {:02d}, {:02d}\n".format(*c)
    return "\n" + line(light5) + line(dark5) + "\n"


ANIM_ASM = "\tframe 0, 12\n\tframe {f1}, 24\n\tendanim\n"
IDLE_ASM = "\tsetrepeat 2\n\tframe 0, 07\n\tframe {f1}, 07\n\tdorepeat 1\n\tendanim\n"


# --------------------------------------------------------------------------- previews

def font(size: int):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def ascii_label(text: str) -> str:
    """The bundled bitmap font has no accented glyphs."""
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()


def render(idx: np.ndarray, palette8, scale: int) -> Image.Image:
    rgb = np.array(palette8, dtype=np.uint8)[idx]
    im = Image.fromarray(rgb, "RGB")
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)


def panel(img: Image.Image, label: str, box: int) -> Image.Image:
    p = Image.new("RGB", (box + 8, box + 30), (200, 200, 205))
    p.paste(img, (4 + (box - img.width) // 2, 4 + box - img.height))
    ImageDraw.Draw(p).text((6, box + 8), label, fill=(20, 20, 20), font=font(14))
    return p


def source_thumb(path: Path, box: int) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    im = im.crop(im.getbbox())
    k = max(1, box // max(im.size))
    im = im.resize((im.width * k, im.height * k), Image.NEAREST)
    if max(im.size) > box:
        im.thumbnail((box, box), Image.NEAREST)
    bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
    return Image.alpha_composite(bg, im).convert("RGB")


def hstack(panels, gap=6, bg=(235, 235, 240)) -> Image.Image:
    w = sum(p.width for p in panels) + gap * (len(panels) - 1)
    h = max(p.height for p in panels)
    out = Image.new("RGB", (w, h), bg)
    x = 0
    for p in panels:
        out.paste(p, (x, 0))
        x += p.width + gap
    return out


# --------------------------------------------------------------------------- pipeline

def convert(name: str, meta: dict, frames: int, outline: bool) -> dict:
    files = meta["files"]
    warnings = []
    front = load_rgba(Path(files["front"]))
    back = load_rgba(Path(files["back"]))
    shiny = load_rgba(Path(files["shiny"]))
    if np.array_equal(front, shiny):
        warnings.append("source shiny file is identical to the normal front; shiny.pal = normal colors")

    # --- front: trim, quantize at native res, fit, outline, place
    y0, y1, x0, x1 = bbox(front[..., 3] >= 128)
    front_t = front[y0:y1, x0:x1]
    q = Quantizer(front_t)
    labels_native = q.label_image(front_t)
    labels, s = fit(labels_native, max(FRONT_SIZES))
    if s < 1:
        warnings.append(f"front downscaled {s:.2f}x ({front_t.shape[1]}x{front_t.shape[0]} -> {labels.shape[1]}x{labels.shape[0]})")
    if outline:
        labels = outline_silhouette(labels)
    size = next(sz for sz in FRONT_SIZES if max(labels.shape) <= sz)
    front_idx = place_bottom_center(labels, size)

    # --- normal palette
    light8, dark8 = q.middle_colors()
    if light8 is None or dark8 is None:
        raise SystemExit(f"{name}: could not find two middle colors")
    light5, dark5 = safe_middle(to5(light8)), safe_middle(to5(dark8))
    swapped = gbc_luma(light5) < gbc_luma(dark5)  # 5-bit snapping can flip a close pair
    if swapped:
        light5, dark5 = dark5, light5
        front_idx = swap_mid(front_idx)
    if light5 == dark5:
        dark5 = tuple(max(1, c - 4) for c in dark5)
        warnings.append("both middle colors snapped to the same GBC color; darkened one")
    if abs(gbc_luma(light5) - gbc_luma(dark5)) < 3:
        warnings.append("light and dark colors are very close in brightness; gbcpal ordering may be fragile")
    palette8 = [(255, 255, 255), to8(light5), to8(dark5), (0, 0, 0)]

    # --- shiny palette: same clusters, colors read from the shiny sprite
    shiny_t = shiny[y0:y1, x0:x1] if shiny.shape == front.shape else None
    same_shape = shiny_t is not None and np.mean((shiny_t[..., 3] >= 128) == (front_t[..., 3] >= 128)) > 0.98
    if same_shape:
        shiny_mid = []
        for k in (LIGHT, DARK):
            sel = labels_native == k
            cols, cnt = np.unique(shiny_t[sel][:, :3], axis=0, return_counts=True)
            shiny_mid.append(representative_color(cols, cnt.astype(np.float64)))
        if swapped:
            shiny_mid.reverse()
        method = "correspondence"
    else:
        warnings.append("shiny sprite doesn't line up with the normal one; clustered it on its own")
        ys0, ys1, xs0, xs1 = bbox(shiny[..., 3] >= 128)
        shiny_mid = list(Quantizer(shiny[ys0:ys1, xs0:xs1]).middle_colors())
        method = "independent"
    sl5, sd5 = safe_middle(to5(shiny_mid[0])), safe_middle(to5(shiny_mid[1]))
    if method == "independent" and gbc_luma(sl5) < gbc_luma(sd5):
        sl5, sd5 = sd5, sl5
    if (light5, dark5) == (sl5, sd5):
        warnings.append("shiny palette came out identical to normal")
    shiny_palette8 = [(255, 255, 255), to8(sl5), to8(sd5), (0, 0, 0)]

    # --- back: same clusters as the front so both PNGs share one palette
    by0, by1, bx0, bx1 = bbox(back[..., 3] >= 128)
    back_t = back[by0:by1, bx0:bx1]
    back_labels, bs = fit(q.label_image(back_t), BACK_SIZE)
    if bs < 1:
        warnings.append(f"back downscaled {bs:.2f}x ({back_t.shape[1]}x{back_t.shape[0]} -> {back_labels.shape[1]}x{back_labels.shape[0]})")
    if outline:
        back_labels = outline_silhouette(back_labels)
    back_idx = place_bottom_center(back_labels, BACK_SIZE)
    if swapped:
        back_idx = swap_mid(back_idx)

    # --- write drop-in folder
    out = OUT_DIR / name
    out.mkdir(parents=True, exist_ok=True)
    stack = np.vstack([front_idx] * frames)
    save_indexed_png(out / "front.png", stack, palette8)
    save_indexed_png(out / "back.png", back_idx, palette8)
    (out / "shiny.pal").write_text(pal_text(sl5, sd5))
    f1 = 1 if frames >= 2 else 0
    (out / "anim.asm").write_text(ANIM_ASM.format(f1=f1))
    (out / "anim_idle.asm").write_text(IDLE_ASM.format(f1=f1))

    # --- extras: reference normal.pal, preview, report
    extras = OUT_DIR / "_extras" / name
    extras.mkdir(parents=True, exist_ok=True)
    (extras / "normal.pal").write_text(pal_text(light5, dark5))
    box = 56 * 4
    preview = hstack([
        panel(render(front_idx, palette8, 4), f"front {size}x{size}", box),
        panel(render(back_idx, palette8, 4), "back 48x48", box),
        panel(render(front_idx, shiny_palette8, 4), "shiny", box),
    ])
    preview.save(extras / "preview.png")

    report = {
        "name": name, "dex_id": meta["id"], "source_game": meta["game_title"],
        "urls": meta["urls"], "files": files, "front_size": size, "frames": frames,
        "trimmed_front": [int(front_t.shape[1]), int(front_t.shape[0])],
        "trimmed_back": [int(back_t.shape[1]), int(back_t.shape[0])],
        "normal_rgb5": [light5, dark5], "shiny_rgb5": [sl5, sd5],
        "shiny_method": method, "warnings": warnings,
    }
    (extras / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def contact_sheet(names: list[str], per_page: int = 12) -> list[Path]:
    """One image for small batches; numbered pages in out/contact_sheets/ for big ones."""
    box = 56 * 4
    bg = (235, 235, 240)
    pages = [names[i:i + per_page] for i in range(0, len(names), per_page)]
    paths = []
    if len(pages) > 1:
        (OUT_DIR / "contact_sheets").mkdir(parents=True, exist_ok=True)
    for pi, page in enumerate(pages, 1):
        rows = []
        for n in page:
            rep = json.loads((OUT_DIR / "_extras" / n / "report.json").read_text())
            prev = Image.open(OUT_DIR / "_extras" / n / "preview.png")
            srcs = [panel(source_thumb(Path(rep["files"][k]), box), f"source {k}", box) for k in ("front", "back", "shiny")]
            row = hstack(srcs + [Image.new("RGB", (12, 1), bg), prev])
            head = Image.new("RGB", (row.width, 34), bg)
            flag = "  [!] " + "; ".join(rep["warnings"]) if rep["warnings"] else ""
            ImageDraw.Draw(head).text((6, 8), f"{n}  #{rep['dex_id']}  ({ascii_label(rep['source_game'])}){flag}",
                                      fill=(0, 0, 0), font=font(18))
            rows += [head, row]
        w = max(r.width for r in rows)
        h = sum(r.height for r in rows) + 10 * len(rows)
        sheet = Image.new("RGB", (w + 20, h + 20), bg)
        y = 10
        for r in rows:
            sheet.paste(r, (10, y))
            y += r.height + 10
        path = OUT_DIR / "contact_sheet.png" if len(pages) == 1 else OUT_DIR / "contact_sheets" / f"sheet_{pi:03d}.png"
        sheet.save(path)
        paths.append(path)
    return paths


def write_summary(reports: list[dict], failures: list[tuple[str, str]]) -> Path:
    path = OUT_DIR / "summary.csv"
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["dex", "name", "source_game", "front_size", "trimmed_front", "normal_rgb5", "shiny_rgb5", "warnings"])
        for r in sorted(reports, key=lambda r: r["dex_id"]):
            w.writerow([r["dex_id"], r["name"], r["source_game"], r["front_size"], "x".join(map(str, r["trimmed_front"])),
                        " / ".join(",".join(map(str, c)) for c in r["normal_rgb5"]),
                        " / ".join(",".join(map(str, c)) for c in r["shiny_rgb5"]), "; ".join(r["warnings"])])
        for name, err in failures:
            w.writerow(["", name, "", "", "", "", "", f"FAILED: {err}"])
    return path


def update_credits(reports: list[dict]):
    header = (
        "# Sprite credits\n\n"
        "Source sprites are © Nintendo / Creatures Inc. / GAME FREAK inc., from the\n"
        "[PokeAPI sprites repository](https://github.com/PokeAPI/sprites). Converted to\n"
        "pokecrystal format by `tools/sprite_convert/convert.py`. Rows are updated each time\n"
        "the converter runs.\n\n"
        "| Pokémon | Dex # | Source game | Front | Back | Shiny |\n"
        "|---|---|---|---|---|---|\n"
    )
    rows = {}
    if CREDITS.exists():
        for line in CREDITS.read_text().splitlines():
            m = re.match(r"\| (\S+) \| (\d+) \|", line)
            if m:
                rows[m.group(1)] = line
    for r in reports:
        u = r["urls"]
        rows[r["name"]] = (f"| {r['name']} | {r['dex_id']} | {r['source_game']} | "
                           f"[front]({u['front']}) | [back]({u['back']}) | [shiny]({u['shiny']}) |")
    body = "\n".join(rows[k] for k in sorted(rows, key=lambda k: int(re.match(r'\| \S+ \| (\d+)', rows[k]).group(1))))
    CREDITS.write_text(header + body + "\n")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pokemon", nargs="*", help="species name as PokeAPI spells it (e.g. mr-mime), optionally name:dexid; "
                    "with --source-dir: names or dex numbers to pick from the manifest (default: all)")
    ap.add_argument("--source-dir", type=Path, help="local sprite set with manifest.csv (no downloads)")
    ap.add_argument("--game", choices=GAMES, help="override source game when downloading (default: emerald/hgss/bw by generation)")
    ap.add_argument("--frames", type=int, choices=(1, 2), default=1,
                    help="1 = single static frame (default); 2 = duplicate it, matching kakuna's 2-frame layout")
    ap.add_argument("--no-outline", action="store_true", help="don't force the silhouette edge to black")
    ap.add_argument("--refetch", action="store_true", help="re-download sources even if cached")
    args = ap.parse_args(argv)

    if args.source_dir:
        metas = local_sources(args.source_dir.expanduser(), args.pokemon)
    else:
        if not args.pokemon:
            ap.error("give at least one Pokémon, or --source-dir")
        metas = []
        for spec in args.pokemon:
            name, _, sid = spec.lower().partition(":")
            dex_id = int(sid) if sid else resolve_id(name)
            game = args.game or default_game(dex_id)
            print(f"{name}: fetching ({GAMES[game][1]})")
            meta = fetch_sources(name, dex_id, game, args.refetch)
            meta["name"] = crystal_name(name)
            metas.append(meta)

    reports, failures = [], []
    for i, meta in enumerate(metas, 1):
        name = meta["name"]
        try:
            rep = convert(name, meta, args.frames, not args.no_outline)
        except (Exception, SystemExit) as e:  # keep going on a bad sprite; it's listed in summary.csv
            print(f"[{i}/{len(metas)}] {name}: FAILED: {e}")
            failures.append((name, str(e)))
            continue
        note = f"  ({'; '.join(rep['warnings'])})" if rep["warnings"] else ""
        print(f"[{i}/{len(metas)}] {name} #{rep['dex_id']} -> out/{name}/ front {rep['front_size']}x{rep['front_size']}{note}")
        reports.append(rep)
    if reports:
        sheets = contact_sheet([r["name"] for r in reports])
        update_credits(reports)
        print(f"contact sheet{'s' if len(sheets) > 1 else ''}: {sheets[0] if len(sheets) == 1 else sheets[0].parent}")
    print(f"summary: {write_summary(reports, failures)}  ({len(reports)} converted, {len(failures)} failed)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
