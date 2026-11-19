#!/usr/bin/env python3
"""Raise every trainer Pokémon's level to min(100, floor(level ** 1.05)).

Then, using this ROM's own evolution and learnset data:
  * a Pokémon evolves (by level or stat-based level evolution; the first listed
    method wins) while its evolution level is at or below its new level;
  * gym leaders, the Elite Four, the Champion, Red, Blue, the rival and the Rocket
    executives ("bosses") also evolve when the next evolution is at most 5 levels
    away: their Pokémon are raised to that evolution level first;
  * for parties with explicit moves (TRAINERTYPE_MOVES / ITEM_MOVES), level-up
    moves the (evolved) species learns between the old and new level are added,
    filling empty slots first and then replacing the earliest-learned level-up
    move only when a newly learned attack is stronger (STAB counts x1.5) than a
    level-up attack it knows (the weakest goes); new status moves only fill empty
    slots. Status moves, fixed-damage moves (Sonicboom, Night Shade, Super Fang...)
    and moves it can't have learned by leveling (TMs, egg moves) stay.
Stone, trade and happiness evolutions are left alone.

Re-runnable: changed lines end in "; lv (was N)", "; evo (was X)" or
"; moves (was ...)" and are restored before scaling. Pass --restore to only
restore (run that before gym_teams.py, whose patterns expect the plain lines).
Writes tools/species_import/trainer_levels.md.
"""

from __future__ import annotations

import math
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PARTIES = REPO / "data/trainers/parties.asm"
BOSS_GROUPS = {
    "Falkner", "Whitney", "Bugsy", "Morty", "Pryce", "Jasmine", "Chuck", "Clair",
    "Brock", "Misty", "LtSurge", "Erika", "Janine", "Sabrina", "Blaine",
    "Will", "Bruno", "Karen", "Koga", "Champion", "Red", "Blue",
    "Rival1", "Rival2", "ExecutiveM", "ExecutiveF",
}
LV_TAG = re.compile(r"\s*; lv \(was (\d+)\)$")
EVO_TAG = re.compile(r"\s*; evo \(was (\w+)\)$")
MOVES_TAG = re.compile(r"\s*; moves \(was ([^)]*)\)$")


def new_level(n):
    return min(100, math.floor(n ** 1.05))


def load_evos_learnsets():
    consts = []
    for line in open(REPO / "constants/pokemon_constants.asm"):
        m = re.match(r"\s*const (\w+)", line)
        if m:
            consts.append(m.group(1))
        if "DEF NUM_POKEMON" in line:
            break
    labels, text = [], ""
    for f in ("kanto", "johto", "hoenn", "sinnoh", "unova"):
        t = (REPO / f"data/pokemon/evos_attacks_{f}.asm").read_text()
        labels += re.findall(r"^\tdw (\w+EvosAttacks)$", t, re.M)
        text += t + "\n"
    assert len(labels) == len(consts), (len(labels), len(consts))
    by_label = dict(zip(labels, consts))
    evos, learn = {}, {}
    for m in re.finditer(r"^(\w+EvosAttacks):\n(.*?)^\tdb 0 ; no more evolutions\n(.*?)^\tdb 0", text, re.M | re.S):
        sp = by_label[m.group(1)]
        e = []
        for line in m.group(2).splitlines():
            lv = re.match(r"\tdbbw EVOLVE_LEVEL, (\d+), (\w+)", line) or re.match(r"\tdbbbw EVOLVE_STAT, (\d+), \w+, (\w+)", line)
            if lv:
                e.append((int(lv.group(1)), lv.group(2)))
        evos[sp] = e[0] if e else None
        learn[sp] = [(int(a), b) for a, b in re.findall(r"^\tdbw (\d+), (\w+)", m.group(3), re.M)]
    return evos, learn


FIXED_DAMAGE = {"EFFECT_STATIC_DAMAGE", "EFFECT_LEVEL_DAMAGE", "EFFECT_SUPER_FANG", "EFFECT_PSYWAVE"}


def move_data():
    """move constant -> (effect, base power, type), from data/moves/moves.asm."""
    rows = re.findall(r"^\tmove (\w+),\s*(\d+),\s*(\w+),[^;]*;(\w+)", (REPO / "data/moves/moves.asm").read_text(), re.M)
    return {name: (eff, int(pw), typ) for eff, pw, typ, name in rows}


def species_types(sp):
    f = REPO / f"data/pokemon/base_stats/{sp.lower()}.asm"
    m = re.search(r"\tdb (\w+), (\w+) ; type", f.read_text()) if f.exists() else None
    return {m.group(1), m.group(2)} if m else set()


def restore(text):
    out = []
    for line in text.split("\n"):
        if (m := LV_TAG.search(line)):
            line = re.sub(r"db \d+", f"db {m.group(1)}", LV_TAG.sub("", line), count=1)
        elif (m := EVO_TAG.search(line)):
            line = re.sub(r"dw \w+", f"dw {m.group(1)}", EVO_TAG.sub("", line), count=1)
        elif (m := MOVES_TAG.search(line)):
            line = re.sub(r"dw [^;]*?(?=\s*;|$)", f"dw {m.group(1)}", MOVES_TAG.sub("", line), count=1)
        out.append(line)
    return "\n".join(out)


def main():
    text = restore(PARTIES.read_text())
    if "--restore" in sys.argv:
        PARTIES.write_text(text)
        print("restored")
        return
    evos, learn = load_evos_learnsets()
    mdata = move_data()

    def strength(mv, types):
        eff, pw, typ = mdata.get(mv, ("", 0, ""))
        if eff in FIXED_DAMAGE:
            return None  # never swapped out, never counts as an upgrade
        return pw * (1.5 if typ in types else 1)

    def learn_level(sp_chain, move):
        lv = [lvl for sp in sp_chain for lvl, mv in learn.get(sp, []) if mv == move]
        return min(lv) if lv else None

    lines = text.split("\n")
    group, ttype, report = None, None, []
    i = 0
    while i < len(lines):
        line = lines[i]
        if (m := re.match(r"(\w+)Group:", line)):
            group = m.group(1)
        if (m := re.match(r'\tdb "([^"]*)@", (TRAINERTYPE_\w+)', line)):
            ttype, tname = m.group(2), m.group(1)
        lm = re.match(r"\tdb (\d+)$", line)
        sm = re.match(r"\tdw (\w+)(.*)$", lines[i + 1]) if lm and i + 1 < len(lines) else None
        if not (lm and sm):
            i += 1
            continue
        old_lv, old_sp = int(lm.group(1)), sm.group(1)
        lv, sp, chain = new_level(old_lv), old_sp, [old_sp]
        boss = group in BOSS_GROUPS
        while evos.get(sp):
            elv, nxt = evos[sp]
            if elv <= lv:
                pass
            elif boss and elv <= lv + 5 and elv <= 100:
                lv = elv
            else:
                break
            sp = nxt
            chain.append(sp)
        if lv != old_lv:
            lines[i] = f"\tdb {lv} ; lv (was {old_lv})"
        if sp != old_sp:
            lines[i + 1] = f"\tdw {sp}{sm.group(2)} ; evo (was {old_sp})"
        note = ""
        if "MOVES" in ttype:
            k = i + 3 if "ITEM" in ttype else i + 2
            mm = re.match(r"\tdw ([^;]*?)(\s*;.*)?$", lines[k])
            moves = [x.strip() for x in mm.group(1).split(",")]
            before = list(moves)
            gained = [mv for lvl, mv in learn.get(sp, []) if old_lv < lvl <= lv and mv not in moves]
            for mv in gained[-4:]:
                if mv in moves:
                    continue
                if "NO_MOVE" in moves:
                    moves[moves.index("NO_MOVE")] = mv
                    continue
                types = species_types(sp)
                p = strength(mv, types) or 0
                cands = [(strength(x, types), n) for n, x in enumerate(moves)
                         if strength(x, types) and strength(x, types) < p and (learn_level(chain, x) or 999) <= old_lv]
                if cands:
                    moves[min(cands)[1]] = mv
            if moves != before:
                lines[k] = f"\tdw {', '.join(moves)}{mm.group(2) or ''} ; moves (was {', '.join(before)})"
                note = f" — moves {', '.join(before)} → {', '.join(moves)}"
        if boss or sp != old_sp:
            report.append(f"| {group} | {tname} | {old_sp} Lv{old_lv} | {sp} Lv{lv}{note} |")
        i += 2
    PARTIES.write_text("\n".join(lines))
    md = ["# Trainer levels (generated by scale_trainer_levels.py)", "",
          "New level = min(100, floor(old ** 1.05)). Listed: every boss Pokémon and every Pokémon that evolved.", "",
          "| Group | Trainer | Before | After |", "|---|---|---|---|"] + report
    (Path(__file__).resolve().parent / "trainer_levels.md").write_text("\n".join(md) + "\n")
    print(f"{len(report)} report rows; see tools/species_import/trainer_levels.md")


if __name__ == "__main__":
    main()
