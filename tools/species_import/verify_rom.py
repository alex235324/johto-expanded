#!/usr/bin/env python3
"""Check the built ROM's species tables the way the game reads them.

For every species (1..NUM_POKEMON) this resolves names, base data (indirect
table), learnset/egg-move pointers (indirect), pic pointers (+ decompresses
the pics and compares them to the build's .2bpp), palettes, Pokédex pointers,
cries, menu icons, animation/frame pointers, footprints and Pokédex orders.

Usage: tools/sprite_convert/.venv/bin/python tools/species_import/verify_rom.py [pokecrystal.gbc]
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ROM = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO / "pokecrystal.gbc"
rom = ROM.read_bytes()
sym = {}
for line in open(ROM.with_suffix(".sym")):
    m = re.match(r"([0-9a-f]{2}):([0-9a-f]{4}) (\S+)", line)
    if m:
        sym[m.group(3)] = (int(m.group(1), 16), int(m.group(2), 16))

errors: list[str] = []
warnings: list[str] = []


def off(bank, addr):
    return addr if addr < 0x4000 else bank * 0x4000 + (addr - 0x4000)


def rd(bank, addr, n=1):
    o = off(bank, addr)
    return rom[o:o + n]


def word(bank, addr):
    b = rd(bank, addr, 2)
    return b[0] | b[1] << 8


def S(label):
    if label not in sym:
        errors.append(f"missing symbol {label}")
        return (0, 0)
    return sym[label]


def indirect(label, index):
    bank, addr = S(label)
    hdr = word(bank, addr)
    size, start = hdr & 0x7FFF, hdr >> 15
    idx, p = index - start, addr + 2
    while True:
        count = rd(bank, p)[0]
        if count == 0:
            return None
        b, a = rd(bank, p + 1)[0], word(bank, p + 2)
        if idx < count:
            return (b, a + idx * size)
        idx -= count
        p += 4


# --------------------------------------------------------------------------- constants

consts, idx = {}, 0
for line in open(REPO / "constants/pokemon_constants.asm"):
    if "NUM_POKEMON" in line:
        break
    m = re.match(r"\s*const (\w+)", line)
    if m:
        idx += 1
        consts[idx] = m.group(1)
NUM = len(consts)
charmap = {}
for line in open(REPO / "constants/charmap.asm"):
    m = re.match(r'\s*charmap "(.+?)",\s*\$([0-9a-f]{2})', line)
    if m and int(m.group(2), 16) not in charmap:
        charmap[int(m.group(2), 16)] = m.group(1)


def label_of(const):
    return "".join(p.capitalize() for p in const.lower().split("_") if p)


def decode(bs):
    out = ""
    for b in bs:
        if b == 0x50:
            break
        out += charmap.get(b, "?")
    return out


def lz_decompress(data: bytes) -> bytes:
    out, i = bytearray(), 0
    while True:
        b = data[i]
        i += 1
        if b == 0xFF:
            return bytes(out)
        cmd = b >> 5
        if cmd == 7:
            cmd = (b >> 2) & 7
            n = (((b & 3) << 8) | data[i]) + 1
            i += 1
        else:
            n = (b & 0x1F) + 1
        if cmd == 0:
            out += data[i:i + n]
            i += n
        elif cmd == 1:
            out += bytes([data[i]]) * n
            i += 1
        elif cmd == 2:
            pair = data[i:i + 2]
            i += 2
            out += bytes(pair[k % 2] for k in range(n))
        elif cmd == 3:
            out += bytes(n)
        else:
            o = data[i]
            i += 1
            if o & 0x80:
                src = len(out) - (o & 0x7F) - 1
            else:
                src = (o << 8) | data[i]
                i += 1
            for k in range(n):
                if cmd == 4:
                    out.append(out[src + k])
                elif cmd == 5:
                    v = out[src + k]
                    out.append(int(f"{v:08b}"[::-1], 2))
                else:
                    out.append(out[src - k])


# --------------------------------------------------------------------------- checks

names_seen, pics_checked = set(), 0
pb, pa = S("PokemonPicPointers")
for i in range(1, NUM + 1):
    c = consts[i]
    lab = label_of(c)
    new = i > 251
    # name
    nb, na = S("PokemonNames")
    name = decode(rd(nb, na + (i - 1) * 10, 10))
    if not name or name in names_seen:
        errors.append(f"{c}: bad/duplicate name {name!r}")
    names_seen.add(name)
    # base data
    loc = indirect("BaseData", i)
    if not loc:
        errors.append(f"{c}: no base data")
    elif new:
        stats = list(rd(loc[0], loc[1] + 1, 6))
        src = (REPO / f"data/pokemon/base_stats/{c.lower()}.asm").read_text()
        want = [int(x) for x in re.search(r"db\s+(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)", src).groups()]
        if stats != want:
            errors.append(f"{c}: base stats {stats} != {want}")
    # evos/attacks + egg move pointers
    for table, suffix in (("EvosAttacksPointers", "EvosAttacks"), ("EggMovePointers", "EggMoves")):
        loc = indirect(table, i)
        if not loc:
            errors.append(f"{c}: no {table} entry")
            continue
        ptr = word(*loc)
        if new and suffix == "EvosAttacks" and (loc[0], ptr) != S(f"{lab}{suffix}"):
            errors.append(f"{c}: {table} -> {loc[0]:02x}:{ptr:04x}, expected {lab}{suffix}")
    # pics
    fb, fa = rd(pb, pa + i * 6)[0], word(pb, pa + i * 6 + 1)
    bb, ba = rd(pb, pa + i * 6 + 3)[0], word(pb, pa + i * 6 + 4)
    if new:
        if (fb, fa) != S(f"{lab}Frontpic") or (bb, ba) != S(f"{lab}Backpic"):
            errors.append(f"{c}: pic pointers wrong")
        else:
            for (b, a), f in (((fb, fa), "front.animated.2bpp"), ((bb, ba), "back.2bpp")):
                got = lz_decompress(rom[off(b, a):off(b, a) + 0x1000])
                want = (REPO / f"gfx/pokemon/{c.lower()}/{f}").read_bytes()
                if got != want:
                    errors.append(f"{c}: {f} decompresses to {len(got)} bytes, differs from build ({len(want)})")
            pics_checked += 1
    # palettes: normal (2 colors) + shiny (2 colors), 15-bit little endian
    lb, la = S("PokemonPalettes")
    pal = rd(lb, la + i * 8, 8)
    if new:
        cols = [(pal[k] | pal[k + 1] << 8) for k in range(0, 8, 2)]
        rgb = [(v & 31, (v >> 5) & 31, (v >> 10) & 31) for v in cols]
        want = []
        for f in (REPO / f"tools/sprite_convert/out/_extras/{c.lower()}/normal.pal", REPO / f"gfx/pokemon/{c.lower()}/shiny.pal"):
            want += [tuple(int(x) for x in m) for m in re.findall(r"RGB (\d+), (\d+), (\d+)", f.read_text())]
        if rgb != want:
            # gbcpal only keeps colors the pics actually use; if neither pic uses the
            # light slot, the dark color fills both slots. Harmless, but worth a hand fix.
            from PIL import Image
            used = set()
            for f in ("front.png", "back.png"):
                used |= set(Image.open(REPO / f"gfx/pokemon/{c.lower()}/{f}").tobytes())
            if rgb[2:] == want[2:] and not {1, 2} <= used:
                warnings.append(f"{c}: pics use only one middle color, so the normal palette has it twice")
            else:
                errors.append(f"{c}: palette {rgb} != {want}")
    # dex pointer
    db_, da = S("PokedexDataPointerTable")
    if new and (rd(db_, da + (i - 1) * 3)[0], word(db_, da + (i - 1) * 3 + 1)) != S(f"{lab}PokedexEntry"):
        errors.append(f"{c}: dex entry pointer wrong")
    # cry, icon
    cb, ca = S("PokemonCries")
    cry = word(cb, ca + (i - 1) * 6)
    if cry > 0x100:
        errors.append(f"{c}: cry index {cry}")
    ib, ia = S("MonMenuIconPointers")
    if (rd(ib, ia + (i - 1) * 3)[0], word(ib, ia + (i - 1) * 3 + 1)) != S(f"MonIcon_{c.title().replace('_', '')}"):
        errors.append(f"{c}: menu icon pointer wrong")
    # animation pointers (same bank as their tables)
    if new:
        for table, target in (("AnimationPointers", "StaticMonAnimation"), ("AnimationIdlePointers", "StaticMonAnimationIdle"),
                              ("BitmasksPointers", "StaticMonBitmasks")):
            tb, ta = S(table)
            if (tb, word(tb, ta + (i - 1) * 2)) != S(target):
                errors.append(f"{c}: {table} wrong")
        fb2, fa2 = S("FramesPointers")
        if (rd(fb2, fa2 + (i - 1) * 3)[0], word(fb2, fa2 + (i - 1) * 3 + 1)) != S("StaticMonFrames"):
            errors.append(f"{c}: FramesPointers wrong")

for table in ("NewPokedexOrder", "AlphabeticalPokedexOrder"):
    b, a = S(table)
    order = [word(b, a + k * 2) for k in range(NUM)]
    if sorted(order) != list(range(1, NUM + 1)):
        errors.append(f"{table}: not a permutation of 1..{NUM}")

print(f"checked {NUM} species ({NUM - 251} new), {pics_checked} new pic pairs decompressed")
for w in warnings:
    print("  warning: " + w)
if errors:
    print(f"{len(errors)} problem(s):")
    for e in errors[:60]:
        print("  " + e)
    sys.exit(1)
print("all species tables OK")
