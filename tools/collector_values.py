#!/usr/bin/env python3
"""Generate data/events/collector_values.asm: how many Collector Tokens each species is worth.

The eccentric collector in New Bark Town pays tokens for Pokémon.
A species' value comes from how hard it is to get in *this* ROM, read straight
from the repo's own data (re-run this after changing wild tables or evolutions):

  * Wild species: by the best encounter chance anywhere (grass slot, surf slot,
    rod, headbutt tree, bug contest or swarm table; the Gen Select
    tables are ignored because they exist to cover every species):
        >= 20%  -> 1     >= 10%  -> 2     >= 5%  -> 3     >= 2%  -> 4     < 2%  -> 6
  * Evolutions are worth more than what they evolve from: +2 per stage above
    the cheapest wild member of their line. A pre-evolution that isn't wild
    (a baby you have to breed) is worth its wild relative + 1.
  * Lines with no wild member at all (starters, gifts, static/one-off
    encounters, Game Corner prizes): 10, +2 per stage.
  * Strong species: +1 if BST >= 500; +4 for pseudo-legendary lines (final BST 600).
  * Legendaries 30, box legendaries 40, mythicals 50 (Phione 25, Arceus 60).

The game doubles the value of shiny Pokémon.
"""

from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "data/events/collector_values.asm"

# national dex numbers (species index == national dex number in this ROM)
LEGENDARY = {144, 145, 146, 243, 244, 245, 377, 378, 379, 380, 381, 480, 481, 482, 485, 486, 488,
             638, 639, 640, 641, 642, 645}
BOX_LEGENDARY = {150, 249, 250, 382, 383, 384, 483, 484, 487, 643, 644, 646}
MYTHICAL = {151, 251, 385, 386, 490, 491, 492, 494, 647, 648, 649}
SPECIAL_VALUES = {489: 25, 493: 60}  # Phione, Arceus

GRASS_SLOTS = [30, 30, 20, 10, 5, 4, 1]
WATER_SLOTS = [60, 30, 10]


def norm(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


def species_list() -> list[str]:
    out, on = [], False
    for line in open(REPO / "constants/pokemon_constants.asm"):
        if line.strip().startswith("const_def 1"):
            on = True
            continue
        if on and "NUM_POKEMON" in line:
            break
        m = re.match(r"\s*const (\w+)", line)
        if on and m:
            out.append(m.group(1))
    return out


def evolutions(species: list[str]) -> dict[str, list[str]]:
    by_norm = {norm(s): s for s in species}
    evos: dict[str, list[str]] = defaultdict(list)
    for f in sorted((REPO / "data/pokemon").glob("evos_attacks_*.asm")):
        cur, in_evos = None, False
        for line in open(f):
            m = re.match(r"(\w+)EvosAttacks:", line)
            if m:
                cur = by_norm.get(norm(m.group(1)))
                if cur is None:
                    raise SystemExit(f"can't match label {m.group(1)} to a species")
                in_evos = True
                continue
            if not in_evos:
                continue
            if re.match(r"\s*db 0\b", line):
                in_evos = False
                continue
            m = re.match(r"\s*db+w\s+EVOLVE_\w+,.*,\s*(\w+)\s*(;.*)?$", line)
            if m and cur:
                evos[cur].append(m.group(1))
    return evos


def base_stat_totals(species: list[str]) -> dict[str, int]:
    files = []
    for name in ["base_stats.asm", "base_stats_hoenn.asm", "base_stats_sinnoh.asm", "base_stats_unova.asm"]:
        for line in open(REPO / "data/pokemon" / name):
            m = re.match(r'INCLUDE "(data/pokemon/base_stats/\w+\.asm)"', line)
            if m:
                files.append(m.group(1))
    assert len(files) == len(species), (len(files), len(species))
    out = {}
    for sp, f in zip(species, files):
        for line in open(REPO / f):
            m = re.match(r"\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*$", line.split(";")[0] + "\n")
            if m:
                out[sp] = sum(int(x) for x in m.groups())
                break
    return out


def wild_rates(species: set[str]) -> dict[str, float]:
    """Best single-table encounter chance (%) for each wild species."""
    best: dict[str, float] = defaultdict(float)

    def note(table: dict[str, float]):
        for sp, pct in table.items():
            if sp in species:
                best[sp] = max(best[sp], pct)

    for f in sorted((REPO / "data/wild").glob("*.asm")):
        # Gen Select tables (gen1-5, *_gens) exist to cover every species of a
        # generation, so they'd make everything look common: rate by the default set.
        if re.match(r"gen\d|.*_gens", f.stem):
            continue
        text = open(f).read().splitlines()
        name = f.name
        if name in ("fish.asm", "fish_gens.asm"):
            prev, table = 0, defaultdict(float)
            for line in text:
                if re.match(r"\.\w+:", line):
                    note(table)
                    prev, table = 0, defaultdict(float)
                m = re.match(r"\s*dbbw\s+(\d+) percent( \+ 1)?,\s*(\d+),\s*(\w+)", line)
                if m:
                    cum = int(m.group(1))
                    if m.group(4) != "TIME_GROUP" and not m.group(4).isdigit():
                        table[m.group(4)] += cum - prev
                    prev = cum
                m = re.match(r"\s*dbwbw\s+\d+,\s*(\w+),\s*\d+,\s*(\w+)", line)
                if m:  # time-of-day fishing groups: treat as a ~20% slot
                    for sp in m.groups():
                        best[sp] = max(best[sp], 20)
            note(table)
            continue
        if name.startswith("treemons") and not name.endswith("maps.asm") and "asleep" not in name:
            table = defaultdict(float)
            for line in text:
                m = re.match(r"\s*dbbw\s+(\d+),\s*\d+,\s*(\w+)", line)
                if m:
                    table[m.group(2)] += int(m.group(1))
                elif re.match(r"\s*db -1", line):
                    note(table)
                    table = defaultdict(float)
            continue
        if name == "bug_contest_mons.asm":
            for line in text:
                m = re.match(r"\s*dbwbb\s+(\d+),\s*(\w+)", line)
                if m:
                    best[m.group(2)] = max(best[m.group(2)], int(m.group(1)))
            continue
        # grass / water tables (incl. swarms and Gen Select tables)
        mode, slot, table = None, 0, defaultdict(float)
        for line in text:
            if "def_grass_wildmons" in line or "def_water_wildmons" in line:
                note(table)
                mode = "grass" if "grass" in line else "water"
                slot, table = 0, defaultdict(float)
                continue
            m = re.match(r"\s*dbw\s+\d+,\s*(\w+)", line)
            if m and mode:
                slots = GRASS_SLOTS if mode == "grass" else WATER_SLOTS
                if mode == "grass" and slot % 7 == 0 and slot:
                    note(table)  # each time of day is its own table
                    table = defaultdict(float)
                table[m.group(1)] += slots[slot % len(slots)]
                slot += 1
        note(table)
    return best


def rate_value(pct: float) -> int:
    if pct >= 20:
        return 1
    if pct >= 10:
        return 2
    if pct >= 5:
        return 3
    if pct >= 2:
        return 4
    return 6


def main():
    species = species_list()
    dex = {sp: i + 1 for i, sp in enumerate(species)}
    evos = evolutions(species)
    bst = base_stat_totals(species)
    wild = wild_rates(set(species))

    parent: dict[str, str] = {}
    for p, kids in evos.items():
        for k in kids:
            parent.setdefault(k, p)

    def root(sp):
        while sp in parent:
            sp = parent[sp]
        return sp

    def depth(sp):
        d = 0
        while sp in parent:
            sp, d = parent[sp], d + 1
        return d

    lines = defaultdict(list)
    for sp in species:
        lines[root(sp)].append(sp)
    line_max_bst = {r: max(bst[s] for s in members) for r, members in lines.items()}

    values, why = {}, {}
    for sp in species:
        n = dex[sp]
        if n in SPECIAL_VALUES:
            values[sp], why[sp] = SPECIAL_VALUES[n], "mythical"
            continue
        if n in MYTHICAL:
            values[sp], why[sp] = 50, "mythical"
            continue
        if n in BOX_LEGENDARY:
            values[sp], why[sp] = 40, "box legendary"
            continue
        if n in LEGENDARY:
            values[sp], why[sp] = 30, "legendary"
            continue
        members = lines[root(sp)]
        wild_members = [m for m in members if m in wild]
        d = depth(sp)
        if not wild_members:
            v, w = 10 + 2 * d, "no wild member (gift/static/prize)"
        else:
            cands = []
            for m in wild_members:
                base = rate_value(wild[m])
                dm = depth(m)
                if d >= dm:
                    cands.append((base + 2 * (d - dm), m))
                else:
                    cands.append((base + 1, m))
            v, src = min(cands)  # the cheapest way to get this species
            w = f"wild {wild[src]:g}%" + (f" via {src}" if src != sp else "")
        if bst[sp] >= 500:
            v += 1
        if line_max_bst[root(sp)] >= 600:
            v += 4
            w += ", pseudo-legendary line"
        values[sp], why[sp] = v, w

    assert all(1 <= v <= 127 for v in values.values())  # doubled for shinies, must fit a byte

    with open(OUT, "w") as f:
        f.write("; Collector Tokens paid per species (shinies pay double).\n")
        f.write("; Generated by tools/collector_values.py; edit that script, not this file.\n\n")
        f.write("CollectorValues:\n")
        f.write("\ttable_width 1\n")
        for sp in species:
            f.write(f"\tdb {values[sp]:3d} ; {sp:<12} {why[sp]}\n")
        f.write("\tassert_table_length NUM_POKEMON\n")

    hist = defaultdict(int)
    for v in values.values():
        hist[v] += 1
    print(f"wrote {OUT.relative_to(REPO)}; value histogram:", dict(sorted(hist.items())))


if __name__ == "__main__":
    main()
