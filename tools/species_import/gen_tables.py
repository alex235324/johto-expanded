#!/usr/bin/env python3
"""Generate the five gen-locked wild encounter sets used by the Pokégear's Gen Select.

For each generation N (1..5) this writes, from the *vanilla* layout of the tables
(levels, rates and probabilities kept; only species change):
  data/wild/gen{N}.asm      SECTION "Wild Mons Gen N": Johto/Kanto grass + water
  data/wild/fish_gens.asm   FishGroupsGen1..5 (included in the Fishing section)
  data/wild/treemons_gens.asm  TreeMonsGen1..5 (included in the Tree Mons section)

Rules per generation:
  * only that generation's species; no Unown; legendaries/mythicals only in the 1%
    grass slot of the highest-level maps (Lv 40+), except Gen 2's, which are story Pokémon
  * evolved forms only at or above the level they can first exist at
    (their evolution level, or 25/35 for item/trade/friendship evolutions)
  * every first stage of the generation appears at least once
  * grass slots only take species that fit the map's theme (themes.py), unless
    nothing in the generation does, then the old scoring picks
  * placement favours type overlap with the map's vanilla Pokémon, Dark/Ghost/
    Psychic/Poison/Bug at night, the evolution stage that fits the level, and spreads
    species out; water and fishing slots take Water types (Dratini's line can be fished)
Writes tools/species_import/gen_placements.md.
"""

from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pokedata as P  # noqa: E402
import themes as T  # noqa: E402
from place_wild import const_name, never_wild, restore, vanilla_consts  # noqa: E402

REPO = P.REPO
WILD = REPO / "data/wild"
GENS = {1: range(1, 152), 2: range(152, 252), 3: range(252, 387), 4: range(387, 494), 5: range(494, 650)}
NIGHT = {"DARK", "GHOST", "PSYCHIC_TYPE", "POISON", "BUG"}
TREE_TYPES = {"BUG", "NORMAL", "GRASS", "FLYING", "ELECTRIC"}
FISHABLE_EXTRA = {147, 148}  # Dratini, Dragonair
NOT_ON_LAND_SHAPES = {"3", "10"}
STORY_LEGENDS = {243, 244, 245, 249, 250, 251}


def main():
    sp = P.species_table()
    evo = P.evolutions()
    V = vanilla_consts()
    C = {i: const_name(sp[i]["identifier"]) for i in range(252, 650)}
    C.update({i: c for c, i in V.items()})
    ID = {c: i for i, c in C.items()}
    types = {i: set(sp[i]["types"]) for i in range(1, 650)}

    # ---------------------------------------------------------------- vanilla layout
    text = {f: "".join(restore(open(WILD / f).readlines()))
            for f in ("johto_grass.asm", "kanto_grass.asm", "johto_water.asm", "kanto_water.asm", "fish.asm", "treemons.asm")}
    tf = re.findall(r"dbwbw (\d+), (\w+),\s+(\d+), (\w+)", text["fish.asm"])  # TimeFishGroups rows

    slots = []  # (file, nth species line in file, level, map, kind, time, slot)
    for f in ("johto_grass.asm", "kanto_grass.asm", "johto_water.asm", "kanto_water.asm"):
        kind = "grass" if "grass" in f else "water"
        cur, n, k = None, 0, 0
        for line in text[f].splitlines():
            m = re.match(r"\s*def_\w+_wildmons (\w+)", line)
            if m:
                cur, n = m.group(1), 0
            m = re.match(r"\s*dbw (\d+), (\w+)", line)
            if m:
                time, slot = (n // 7, n % 7) if kind == "grass" else (None, n)
                slots.append(dict(file=f, k=k, level=int(m.group(1)), map=cur, kind=kind, time=time, slot=slot, old=m.group(2)))
                n += 1
                k += 1
    label, k = None, 0
    fish_lines = text["fish.asm"].split("TimeFishGroups:")[0]
    for line in fish_lines.splitlines():
        m = re.match(r"\.(\w+):", line)
        if m:
            label = m.group(1)
        m = re.match(r"\s*dbbw ([^,]+),\s*(\d+), (\w+)", line)
        if m:
            lvl, old = int(m.group(2)), m.group(3)
            if old == "TIME_GROUP":
                lvl, old = int(tf[lvl][0]), tf[lvl][1]
            slots.append(dict(file="fish.asm", k=k, level=lvl, map=label, kind="fish", time=None, slot=None, old=old))
            k += 1
    label, k = None, 0
    for line in text["treemons.asm"].splitlines():
        m = re.match(r"(TreeMonSet_\w+):", line)
        if m:
            label = m.group(1)
        m = re.match(r"\s*dbbw\s+\d+,\s*(\d+), (\w+)", line)
        if m:
            slots.append(dict(file="treemons.asm", k=k, level=int(m.group(1)), map=label, kind="tree", time=None, slot=None, old=m.group(2)))
            k += 1

    map_types = defaultdict(set)
    for s in slots:
        if s["old"] in ID:
            map_types[s["map"]] |= types[ID[s["old"]]]

    # ---------------------------------------------------------------- species facts
    def stage(i):
        return 1 if not sp[i]["evolves_from"] else 1 + stage(sp[i]["evolves_from"])

    def minlvl(i):
        pre = sp[i]["evolves_from"]
        if not pre or sp[pre]["baby"]:
            return 1
        c = next((x for x in evo.get(i, []) if x["trigger"] != "shed"), None)
        if c and c["min_level"]:
            return c["min_level"]
        return max(minlvl(pre) + 5, 25 if stage(i) == 2 else 35)

    def root(i):
        while sp[i]["evolves_from"] and not sp[sp[i]["evolves_from"]]["baby"]:
            i = sp[i]["evolves_from"]
        return i

    def final_bst(i):
        kids = [j for j in sp if sp[j]["evolves_from"] == i and j <= 649]
        return max([final_bst(j) for j in kids], default=sum(sp[i]["stats"]))

    family = defaultdict(list)
    for i in range(1, 650):
        family[root(i)].append(i)

    report = ["# Gen Select encounter tables (generated by gen_tables.py)", ""]
    fish_out, tree_out = [], []
    for g, rng in GENS.items():
        legend = [i for i in rng if (sp[i]["legendary"] or sp[i]["mythical"]) and i not in STORY_LEGENDS]
        pool = [i for i in rng if not (sp[i]["legendary"] or sp[i]["mythical"]) and i != 201 and not never_wild(sp, i)]
        bases = [i for i in pool if root(i) == i]
        power = {i: final_bst(root(i)) for i in pool}

        def eligible(i, s, themed=True):
            L = s["level"]
            if L < minlvl(i) - 1:
                return False
            if s["kind"] in ("water", "fish"):
                return "WATER" in types[i] or i in FISHABLE_EXTRA
            if s["kind"] == "tree":
                return bool(types[i] & TREE_TYPES)
            return sp[i]["shape"] not in NOT_ON_LAND_SHAPES and (not themed or T.fits(sp, i, s["map"]))

        land = sorted(s["level"] for s in slots if s["kind"] in ("grass", "tree"))
        ranked = sorted(bases, key=lambda i: (power[i], i))
        target = {i: land[min(len(land) - 1, int(r / max(1, len(ranked) - 1) * (len(land) - 1)))] for r, i in enumerate(ranked)}

        def score(i, s):
            L = s["level"]
            sc = 0 if types[i] & map_types[s["map"]] else 6
            if s["time"] == 2:
                sc += -3 if types[i] & NIGHT else 2
            fam = family[root(i)]
            best = max((stage(j) for j in fam if j in pool and minlvl(j) <= L - 6), default=1)
            sc += 4 * abs(best - stage(i))
            sc += abs(L - target[root(i)]) / 4 if root(i) in target else 0
            return sc

        # legendaries: 1% slot of the highest-level grass maps, one per time of day
        grass_maps = defaultdict(list)
        for s in slots:
            if s["kind"] == "grass":
                grass_maps[s["map"]].append(s)
        by_level = sorted(grass_maps, key=lambda m: -max(x["level"] for x in grass_maps[m]))
        assign, count = {}, defaultdict(int)
        leg_sorted = sorted(legend, key=lambda i: -sum(sp[i]["stats"]))
        top = by_level[:max(1, len(leg_sorted) // 3 + 8)]
        slot6 = [x for mp in top for x in grass_maps[mp] if x["slot"] == 6]
        for lid in leg_sorted:
            free6 = [x for x in slot6 if id(x) not in assign]
            s = next((x for x in free6 if T.fits(sp, lid, x["map"])), None) or next(iter(free6), None)
            if s:
                assign[id(s)] = (lid, max(s["level"], 40))

        used = defaultdict(set)  # (map, time) -> species

        def key(s):
            return (s["map"], s["time"])

        free = [s for s in slots if id(s) not in assign]
        # coverage: every first stage once (hardest to place first)
        for i in sorted(bases, key=lambda i: (sum(eligible(i, s) for s in free), power[i])):
            cands = [s for s in free if id(s) not in assign and eligible(i, s) and i not in used[key(s)]]
            if not cands:
                continue
            s = min(cands, key=lambda s: score(i, s))
            assign[id(s)] = (i, s["level"])
            count[i] += 1
            used[key(s)].add(i)
        # fill: common slots first so the strongest fits go there
        for s in sorted(free, key=lambda s: (s["slot"] if s["slot"] is not None else 9, s["level"])):
            if id(s) in assign:
                continue
            cands = ([i for i in pool if eligible(i, s) and i not in used[key(s)]] or [i for i in pool if eligible(i, s)]
                     or [i for i in pool if eligible(i, s, False) and i not in used[key(s)]])
            if not cands:  # nothing in this generation can live here at this level: use the youngest that can
                cands = sorted([i for i in pool if s["kind"] in ("grass", "tree") or "WATER" in types[i]], key=minlvl)[:3]
            i = min(cands, key=lambda i: score(i, s) + 3 * count[i])
            assign[id(s)] = (i, max(s["level"], minlvl(i)) if s["level"] < minlvl(i) - 1 else s["level"])
            count[i] += 1
            used[key(s)].add(i)

        # ------------------------------------------------------------ write grass/water
        def rewrite(f, glabel):
            ss = [s for s in slots if s["file"] == f]
            it = iter(ss)
            out = []
            for line in text[f].splitlines():
                m = re.match(r"(\s*dbw )(\d+), (\w+)(.*)$", line)
                if m:
                    s = next(it)
                    sid, lvl = assign[id(s)]
                    line = f"{m.group(1)}{lvl}, {C[sid]}"
                line = re.sub(r"^(Johto|Kanto)(Grass|Water)WildMons:", glabel + "::", line)  # exported: read from home/gen_select.asm
                out.append(line)
            return "\n".join(out) + "\n"

        body = [f"; Gen {g}-only wild Pokémon (Gen Select). Generated by tools/species_import/gen_tables.py.", "",
                f'SECTION "Wild Mons Gen {g}", ROMX', ""]
        for f, lab in (("johto_grass.asm", f"JohtoGrassWildMonsGen{g}"), ("johto_water.asm", f"JohtoWaterWildMonsGen{g}"),
                       ("kanto_grass.asm", f"KantoGrassWildMonsGen{g}"), ("kanto_water.asm", f"KantoWaterWildMonsGen{g}")):
            body.append(rewrite(f, lab))
        (WILD / f"gen{g}.asm").write_text("\n".join(body))

        # ------------------------------------------------------------ fishing
        ss = iter([s for s in slots if s["file"] == "fish.asm"])
        out = []
        for line in fish_lines.splitlines():
            if line.startswith(("DEF TIME_GROUP", "MACRO", "ENDM", "; chance", "\tdb \\1", "\tdw \\2")):
                continue
            m = re.match(r"(\s*dbbw [^,]+,\s*)(\d+), (\w+)", line)
            if m:
                s = next(ss)
                sid, lvl = assign[id(s)]
                line = f"{m.group(1)}{lvl}, {C[sid]}"
            line = line.replace("FishGroups:", f"FishGroupsGen{g}:")
            out.append(line)
        fish_out.append("\n".join(out).strip("\n") + "\n")

        # ------------------------------------------------------------ headbutt / rock smash
        ss = iter([s for s in slots if s["file"] == "treemons.asm"])
        out = []
        for line in text["treemons.asm"].splitlines():
            m = re.match(r"(\s*dbbw\s+\d+,\s*)(\d+), (\w+)", line)
            if m:
                s = next(ss)
                sid, lvl = assign[id(s)]
                line = f"{m.group(1)}{lvl}, {C[sid]}"
            line = re.sub(r"\bTreeMonSet_(\w+)", rf"TreeMonSet_\1_Gen{g}", line)
            line = line.replace("TreeMons:", f"TreeMonsGen{g}:")
            out.append(line)
        tree_out.append("\n".join(out).strip("\n") + "\n")

        placed = defaultdict(int)
        for i, _ in assign.values():
            placed[i] += 1
        missing = [sp[i]["name"] for i in bases if not placed[i]]
        report += [f"## Gen {g}", "",
                   f"{len(set(i for i, _ in assign.values()))} different species across {len(assign)} slots; "
                   f"first stages not placed: {', '.join(missing) or 'none'}.", "",
                   ", ".join(f"{sp[i]['name']} ×{n}" for i, n in sorted(placed.items())), ""]
        print(f"Gen {g}: {len(set(i for i, _ in assign.values()))} species, missing first stages: {missing}")

    (WILD / "fish_gens.asm").write_text("; Gen Select fishing tables (generated by gen_tables.py)\n\n" + "\n".join(fish_out))
    (WILD / "treemons_gens.asm").write_text("; Gen Select headbutt/rock tables (generated by gen_tables.py)\n\n" + "\n".join(tree_out))
    (Path(__file__).resolve().parent / "gen_placements.md").write_text("\n".join(report) + "\n")


if __name__ == "__main__":
    main()
