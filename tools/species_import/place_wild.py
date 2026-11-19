#!/usr/bin/env python3
"""Mix all five generations into the Johto/Kanto wild encounter tables.

What changes (levels are always kept):
  grass    slots 2-7 (30%, 20%, 10%, 5%, 4%, 1% = 70%), picked separately for
           morning, day and night; slot 1 (30%) keeps the map's vanilla Pokémon
  surf     slots 2-3 (30%, 10%); slot 1 (60%) stays vanilla
  fishing  every Good/Super Rod entry except each group's first (Old Rod untouched)
  headbutt every tree-table entry except the first
  Ruins of Alph Unown chambers are left alone.

The pool is every non-legendary first-stage Gen 3-5 species plus every species
that is wild somewhere in vanilla Crystal (Gen 1-2 move around too). Coverage
comes first: every new species, and every vanilla species that would otherwise
disappear from the wild, gets at least one slot. After that, slots are filled by
type overlap with the map's original Pokémon (habitat), a level fit (species are
ranked by their line's final BST), night favouring Dark/Ghost/Psychic/Poison/Bug,
a mild preference for Gen 3-5, and a penalty for species already used a lot.
Evolved vanilla Pokémon never appear below the level they appear at in vanilla.
Grass slots only take species that fit the map's theme (themes.py: a Burned Tower
gets Fire/Poison/Ghost/Dark, caves get Rock/Ground/Steel/..., and so on); a slot
nothing fits keeps its vanilla Pokémon.

Legendaries/mythicals: 1% grass slot of the highest-level maps whose theme fits them.
Every changed line ends in "; gen3-5 (was X)" so a re-run restores first.
Writes tools/species_import/wild_placements.md.
"""

from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pokedata as P  # noqa: E402
import themes as T  # noqa: E402

REPO = P.REPO
WILD = REPO / "data/wild"
TAG = re.compile(r"\s*; gen3-5 \(was (\w+)\)$")
NIGHT = {"DARK", "GHOST", "PSYCHIC_TYPE", "POISON", "BUG"}
TREE_TYPES = {"BUG", "NORMAL", "GRASS", "FLYING", "ELECTRIC"}
NOT_ON_LAND_SHAPES = {"3", "10"}  # fish, tentacles
# every stage of every starter line (Gens 1-5); these are never wild
STARTER_LINES = set(range(1, 10)) | set(range(152, 161)) | set(range(252, 261)) | set(range(387, 396)) | set(range(495, 504))


def never_wild(sp, i):
    """Babies (Pichu, Azurill, Munchlax...) and starter lines stay out of the wild."""
    return sp[i]["baby"] or i in STARTER_LINES


def const_name(ident):
    return re.sub(r"[^A-Z0-9]", "_", ident.upper())


def restore(lines):
    out = []
    for line in lines:
        m = TAG.search(line)
        if m:
            line = re.sub(r"(\w+)(\s*; gen3-5 \(was \w+\))$", lambda mm: m.group(1), line.rstrip("\n")) + "\n"
        out.append(line)
    return out


def vanilla_consts():
    out, idx = {}, 0
    for line in open(REPO / "constants/pokemon_constants.asm"):
        m = re.match(r"\s*const (\w+)", line)
        if m:
            idx += 1
            out[m.group(1)] = idx
        if "const CELEBI" in line:
            break
    return out


def main():
    sp = P.species_table()
    V = vanilla_consts()                       # vanilla const -> national id
    C = {i: const_name(sp[i]["identifier"]) for i in range(252, 650)}
    C.update({i: c for c, i in V.items()})
    ID = {c: i for i, c in C.items()}
    types = {i: set(sp[i]["types"]) for i in range(1, 650)}
    ids = range(252, 650)
    legend = [i for i in ids if sp[i]["legendary"] or sp[i]["mythical"]]
    # first catchable stage: no pre-evolution, or only a baby before it (Roselia, Chimecho)
    new_first = [i for i in ids if i not in legend and not never_wild(sp, i)
                 and (sp[i]["evolves_from"] is None or sp[sp[i]["evolves_from"]]["baby"])]

    def final_bst(i):
        kids = [j for j in sp if sp[j]["evolves_from"] == i and j <= 649]
        return max([final_bst(j) for j in kids], default=sum(sp[i]["stats"]))

    # ------------------------------------------------------------- read tables, collect slots
    files, slots, kept = {}, [], []          # kept: (map, species) left untouched
    vmin = defaultdict(lambda: 999)          # lowest vanilla level per species
    vwhere = defaultdict(set)                # vanilla kinds a species appears in

    def note_vanilla(kind, species, level):
        if species in ID:
            vmin[ID[species]] = min(vmin[ID[species]], level)
            vwhere[ID[species]].add(kind)

    for fname in ("johto_grass.asm", "kanto_grass.asm"):
        lines = restore(open(WILD / fname).readlines())
        files[fname] = lines
        blocks, cur = defaultdict(list), None
        for k, line in enumerate(lines):
            m = re.match(r"\s*def_grass_wildmons (\w+)", line)
            if m:
                cur = m.group(1)
                continue
            m = re.match(r"\s*dbw (\d+), (\w+)", line)
            if m and cur:
                blocks[cur].append((k, int(m.group(1)), m.group(2)))
        for mp, entries in blocks.items():
            unown_only = {e[2] for e in entries} == {"UNOWN"}
            for n, (k, lvl, spc) in enumerate(entries):
                note_vanilla("grass", spc, lvl)
                slot, time = n % 7, n // 7
                if unown_only or slot == 0:
                    kept.append((mp, spc))
                    continue
                slots.append(dict(file=fname, line=k, level=lvl, map=mp, kind="grass", slot=slot, time=time,
                                  group=(fname, mp, slot, time), old=spc))
    for fname in ("johto_water.asm", "kanto_water.asm"):
        lines = restore(open(WILD / fname).readlines())
        files[fname] = lines
        cur, n = None, 0
        for k, line in enumerate(lines):
            m = re.match(r"\s*def_water_wildmons (\w+)", line)
            if m:
                cur, n = m.group(1), 0
                continue
            m = re.match(r"\s*dbw (\d+), (\w+)", line)
            if m and cur:
                note_vanilla("water", m.group(2), int(m.group(1)))
                if n == 0:
                    kept.append((cur, m.group(2)))
                else:
                    slots.append(dict(file=fname, line=k, level=int(m.group(1)), map=cur, kind="water", slot=n,
                                      group=(fname, cur, n), old=m.group(2)))
                n += 1
    lines = restore(open(WILD / "fish.asm").readlines())
    files["fish.asm"] = lines
    label, first_done = None, False
    for k, line in enumerate(lines):
        m = re.match(r"\.(\w+):", line)
        if m:
            label, first_done = m.group(1), False
            continue
        m = re.match(r"\s*dbbw ([^,]+),\s*(\d+), (\w+)", line)
        if not m or m.group(3) == "TIME_GROUP" or not label:
            continue
        note_vanilla("fish", m.group(3), int(m.group(2)))
        if not re.search(r"_(Good|Super)$", label) or not first_done:
            kept.append((label, m.group(3)))
            first_done = True
            continue
        slots.append(dict(file="fish.asm", line=k, level=int(m.group(2)), map=label, kind="fish",
                          group=("fish.asm", label, k), old=m.group(3)))
    lines = restore(open(WILD / "treemons.asm").readlines())
    files["treemons.asm"] = lines
    label, first_done = None, False
    for k, line in enumerate(lines):
        m = re.match(r"(TreeMonSet_\w+):", line)
        if m:
            label, first_done = m.group(1), False
        if line.strip() in ("db -1", "; rare"):
            first_done = False
        m = re.match(r"\s*dbbw\s+\d+,\s*(\d+), (\w+)", line)
        if m and label:
            note_vanilla("tree", m.group(2), int(m.group(1)))
            if not first_done:
                kept.append((label, m.group(2)))
                first_done = True
                continue
            slots.append(dict(file="treemons.asm", line=k, level=int(m.group(1)), map=label, kind="tree",
                              group=("treemons.asm", label, k), old=m.group(2)))

    # species that stay wild without our help (kept slots + tables we don't edit)
    untouched = ""
    for f in ("swarm_grass.asm", "swarm_water.asm", "bug_contest_mons.asm"):
        if (WILD / f).exists():
            untouched += (WILD / f).read_text()
    still_wild = {ID[s] for _, s in kept if s in ID} | {ID[s] for s in re.findall(r"\b([A-Z][A-Z0-9_]+)\b", untouched) if s in ID}
    vanilla_pool = sorted(i for i in vmin if i <= 251 and C[i] != "UNOWN" and not never_wild(sp, i))
    pool = new_first + vanilla_pool
    power = {i: final_bst(i) for i in pool}

    # map habitat = types of the map's vanilla Pokémon
    map_types = defaultdict(set)
    for s in slots:
        if s["old"] in ID:
            map_types[s["map"]] |= types[ID[s["old"]]]
    for mp, spc in kept:
        if spc in ID:
            map_types[mp] |= types[ID[spc]]

    # ------------------------------------------------------------- legendaries
    grass_maps = defaultdict(list)
    for s in slots:
        if s["kind"] == "grass":
            grass_maps[s["map"]].append(s)
    by_level = sorted(grass_maps, key=lambda m: -max(x["level"] for x in grass_maps[m]))
    legend_sorted = sorted(legend, key=lambda i: -sum(sp[i]["stats"]))
    taken = {}
    top = by_level[:max(1, len(legend_sorted) // 3 + 8)]  # roughly as many maps as before, plus slack for theme fit
    slot6 = [x for mp in top for x in grass_maps[mp] if x["slot"] == 6]
    for lid in legend_sorted:
        free6 = [x for x in slot6 if x["group"] not in taken]
        s = next((x for x in free6 if T.fits(sp, lid, x["map"])), None) or next(iter(free6), None)
        if s:
            taken[s["group"]] = (lid, max(s["level"], 40))

    # ------------------------------------------------------------- regular assignment
    groups = defaultdict(list)
    for s in slots:
        groups[s["group"]].append(s)
    glist = [g for g in groups if g not in taken]
    glevel = {g: sum(x["level"] for x in groups[g]) / len(groups[g]) for g in groups}
    gkind = {g: groups[g][0]["kind"] for g in groups}
    gmap = {g: groups[g][0]["map"] for g in groups}
    gtime = {g: groups[g][0].get("time") for g in groups}

    def eligible(i, g):
        k, lvl = gkind[g], glevel[g]
        if i <= 251 and vmin[i] < 999 and lvl < vmin[i] - 3 and sp[i]["evolves_from"]:
            return False  # evolved vanilla Pokémon: not below their vanilla level
        if k in ("water", "fish"):
            return "WATER" in types[i] or k in vwhere[i]  # e.g. Dratini is fished up in vanilla
        if k == "tree":
            return bool(types[i] & TREE_TYPES)
        if sp[i]["shape"] in NOT_ON_LAND_SHAPES:
            return False
        if i <= 251 and vwhere[i] and vwhere[i] <= {"water", "fish"}:
            return False  # vanilla water-only Pokémon stay in the water
        return T.fits(sp, i, gmap[g])

    land_levels = sorted(glevel[g] for g in glist if gkind[g] in ("grass", "tree"))
    ranked = sorted(pool, key=lambda i: (power[i], i))
    target = {i: land_levels[min(len(land_levels) - 1, int(r / max(1, len(ranked) - 1) * (len(land_levels) - 1)))]
              for r, i in enumerate(ranked)}
    for i in vanilla_pool:  # vanilla species: also anchored to where they live now
        if vmin[i] < 999:
            target[i] = (target[i] + vmin[i]) / 2

    def score(i, g):
        s = abs(glevel[g] - target[i]) / 3
        s += 0 if types[i] & map_types[gmap[g]] else 6
        if gtime[g] == 2:
            s += -3 if types[i] & NIGHT else 2
        if i <= 251:
            s += 6  # preference for Gen 3-5
        return s

    assign, count = {}, defaultdict(int)
    on_map = defaultdict(set)
    for mp, spc in kept:
        if spc in ID:
            on_map[mp].add(ID[spc])
    must = new_first + [i for i in vanilla_pool if i not in still_wild]
    order = sorted(must, key=lambda i: (len([g for g in glist if eligible(i, g)]), power[i]))
    for i in order:  # hardest-to-place first
        cands = [g for g in glist if g not in assign and eligible(i, g) and i not in on_map[gmap[g]]]
        if not cands:
            continue
        g = min(cands, key=lambda g: score(i, g))
        assign[g] = i
        count[i] += 1
        on_map[gmap[g]].add(i)
    for g in sorted(glist, key=lambda g: (gkind[g] != "grass", glevel[g])):
        if g in assign:
            continue
        cands = [i for i in pool if eligible(i, g) and i not in on_map[gmap[g]]]
        if not cands:
            continue
        i = min(cands, key=lambda i: score(i, g) + 3.5 * count[i])
        assign[g] = i
        count[i] += 1
        on_map[gmap[g]].add(i)
    for g, (lid, _) in taken.items():
        assign[g] = lid

    # ------------------------------------------------------------- write
    changes = 0
    for g, i in assign.items():
        for s in groups[g]:
            lvl = taken[g][1] if g in taken else s["level"]
            line = files[s["file"]][s["line"]].rstrip("\n")
            if C[i] == s["old"] and g not in taken:
                continue
            if s["kind"] in ("grass", "water"):
                new = re.sub(r"dbw \d+, \w+", f"dbw {lvl}, {C[i]}", line)
            else:
                new = re.sub(r"(dbbw [^,]+,\s*)\d+, \w+", lambda m: f"{m.group(1)}{lvl}, {C[i]}", line)
            files[s["file"]][s["line"]] = f"{new} ; gen3-5 (was {s['old']})\n"
            changes += 1
    for fname, lines in files.items():
        (WILD / fname).write_text("".join(lines))

    # ------------------------------------------------------------- report
    where = defaultdict(list)
    pct = {"grass": {1: "30%", 2: "20%", 3: "10%", 4: "5%", 5: "4%", 6: "1%"}, "water": {1: "surf 30%", 2: "surf 10%"}}
    for g, i in assign.items():
        s0 = groups[g][0]
        tod = ["morning", "day", "night"][s0["time"]] + " " if s0["kind"] == "grass" else ""
        label = pct.get(s0["kind"], {}).get(s0.get("slot"), s0["kind"])
        lvl = taken[g][1] if g in taken else s0["level"]
        where[i].append(f"{s0['map']} ({tod}{label}, Lv{lvl})")
    missing_new = [sp[i]["name"] for i in new_first + legend if not where[i]]
    lost = [C[i] for i in vanilla_pool if i not in still_wild and not where[i]]
    gen_counts = defaultdict(int)
    for g, i in assign.items():
        gen_counts[sp[i]["gen"]] += 1
    rep = ["# Wild placements (generated by place_wild.py)", "",
           f"{changes} slot lines changed. Slots per generation: "
           + ", ".join(f"Gen {k}: {v}" for k, v in sorted(gen_counts.items())) + ".",
           "Grass keeps its first (30%) slot vanilla; the other six are mixed per time of day. "
           "Every Gen 3-5 first stage and every vanilla wild Pokémon is still catchable. "
           "Legendaries are 1% grass encounters on the highest-level maps (Lv 40+).", ""]
    if missing_new or lost:
        rep += [f"**Not placed:** {', '.join(missing_new + lost)}", ""]
    rep += ["| # | Pokémon | Where |", "|---|---|---|"]
    for i in sorted(where):
        rep.append(f"| {i} | {sp[i]['name']} | {'; '.join(sorted(set(where[i])))} |")
    (Path(__file__).resolve().parent / "wild_placements.md").write_text("\n".join(rep) + "\n")
    print(f"{changes} lines changed; per gen {dict(sorted(gen_counts.items()))}; "
          f"new not placed: {missing_new}; vanilla lost from the wild: {lost}")


if __name__ == "__main__":
    main()
