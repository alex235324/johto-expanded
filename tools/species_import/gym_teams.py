#!/usr/bin/env python3
"""Give every gym leader Pokémon from other generations that fit their type.

Each leader: one non-ace Pokémon is replaced (two if the team already has six,
in which case nothing is added) and one Pokémon is added just before the ace
at the ace's level. Replacements keep the replaced Pokémon's level and slot.
The ace is the highest-level Pokémon (the last one on a tie).

A pick is given as the first stage of its line; it is evolved while the next
level-up evolution in this ROM's data happens at or below level + 5. Moves are
the last four it learns by that level (this ROM's learnsets).

Re-runnable: changed lines are tagged "; gym (was X)" and restored first.
"""

from __future__ import annotations

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TYPE = {"Falkner": "FLYING", "Bugsy": "BUG", "Whitney": "NORMAL", "Morty": "GHOST", "Chuck": "FIGHTING",
        "Jasmine": "STEEL", "Pryce": "ICE", "Clair": "DRAGON", "Brock": "ROCK", "Misty": "WATER",
        "LtSurge": "ELECTRIC", "Erika": "GRASS", "Janine": "POISON", "Sabrina": "PSYCHIC_TYPE",
        "Blaine": "FIRE", "Blue": None}  # Blue: each Pokémon's own type
PARTIES = REPO / "data/trainers/parties.asm"

# leader group: (replacements [(species to replace, first stage of the new line)], first stage of the added line)
PLAN = {
    "Falkner": ([("PIDGEY", "STARLY")], "TAILLOW"),
    "Bugsy":   ([("METAPOD", "KRICKETOT")], "NINCADA"),
    "Whitney": ([("CLEFAIRY", "LILLIPUP")], "ZIGZAGOON"),
    "Morty":   ([("GASTLY", "SHUPPET")], "DRIFLOON"),
    "Chuck":   ([("PRIMEAPE", "MAKUHITA")], "TIMBURR"),
    "Jasmine": ([("MAGNEMITE", "ARON")], "BRONZOR"),
    "Pryce":   ([("SEEL", "SPHEAL")], "VANILLITE"),
    "Clair":   ([("DRAGONAIR", "BAGON")], "TRAPINCH"),
    "Brock":   ([("GRAVELER", "CRANIDOS")], "ARCHEN"),
    "Misty":   ([("GOLDUCK", "BUIZEL")], "FEEBAS"),
    "LtSurge": ([("ELECTRODE", "BLITZLE")], "SHINX"),
    "Erika":   ([("TANGELA", "SHROOMISH")], "CACNEA"),
    "Janine":  ([("WEEZING", "TRUBBISH")], "SKORUPI"),
    "Sabrina": ([("MR__MIME", "RALTS")], "GOTHITA"),
    "Blaine":  ([("MAGCARGO", "NUMEL")], "DARUMAKA"),
    "Blue":    ([("PIDGEOT", "STARLY"), ("RHYDON", "DRILBUR")], None),
}


def load_rom_data():
    """species const -> (level-up evolutions [(level, target)], learnset [(level, move)])"""
    data = {}
    for f in sorted((REPO / "data/pokemon").glob("evos_attacks_*.asm")):
        label_to_const = {}
        for line in f.read_text().splitlines():
            pass
        for block in re.split(r"\n(?=\w+EvosAttacks:)", f.read_text()):
            m = re.match(r"(\w+)EvosAttacks:", block)
            if not m:
                continue
            evos = [(int(lv), t) for lv, t in re.findall(r"dbbw EVOLVE_LEVEL, (\d+), (\w+)", block)]
            evos += [(int(lv), t) for lv, t in re.findall(r"dbbbw EVOLVE_STAT, (\d+), \w+, (\w+)", block)]
            learn = [(int(lv), mv) for lv, mv in re.findall(r"dbw (\d+), (\w+)", block)]
            data[m.group(1)] = (evos, learn)
    return data


def label_of(const):
    return "".join(p.capitalize() for p in const.lower().split("_") if p)


def resolve(first_stage, level, rom):
    sp = first_stage
    while True:
        evos = rom.get(label_of(sp), ([], []))[0]
        nxt = [t for lv, t in evos if lv <= level + 5]
        if not nxt:
            return sp
        sp = nxt[0]


def crystal_moves():
    """move const -> (type, power) from data/moves/moves.asm (index order = constant order)"""
    names = re.findall(r"\s*const (\w+)", (REPO / "constants/move_constants.asm").read_text().split("NUM_ATTACKS")[0])[1:]
    rows = re.findall(r"move \w+,\s*(\d+),\s*(\w+),", (REPO / "data/moves/moves.asm").read_text())
    return {n: (t, int(pw)) for n, (pw, t) in zip(names, rows)}


SKIP_DAMAGE = {"SELFDESTRUCT", "EXPLOSION", "DREAM_EATER", "HYPER_BEAM", "SKY_ATTACK", "SKULL_BASH",
               "RAZOR_WIND", "SOLARBEAM", "FUTURE_SIGHT", "BIDE"}


def species_type(sp):
    m = re.search(r"db (\w+), (\w+) ; type", (REPO / f"data/pokemon/base_stats/{sp.lower()}.asm").read_text())
    return m.group(1)


def moves_at(sp, level, rom, want_type=None):
    """last four level-up moves; guarantees one damaging move of want_type"""
    mv = crystal_moves()
    learned = []
    for lv, m in rom[label_of(sp)][1]:
        if lv <= level:
            if m in learned:
                learned.remove(m)
            learned.append(m)
    known = learned[-4:]
    want_type = want_type or species_type(sp)

    def stab(m):
        return mv[m][0] == want_type and mv[m][1] > 0 and m not in SKIP_DAMAGE
    if not any(stab(m) for m in known):
        pick = next((m for m in reversed(learned) if stab(m)), None)
        if pick is None:  # nothing in its learnset yet: strongest sensible move of that type for the level
            cap = 60 if level < 20 else 80 if level < 35 else 999
            pool = [m for m in mv if stab(m) and mv[m][1] <= cap]
            pick = max(pool, key=lambda m: mv[m][1]) if pool else None
        if pick:
            # replace the oldest non-damaging move (or the oldest move)
            victim = next((m for m in known if mv[m][1] == 0), known[0] if len(known) == 4 else None)
            if victim:
                known[known.index(victim)] = pick
            else:
                known.append(pick)
    return known + ["NO_MOVE"] * (4 - len(known))


def main():
    rom = load_rom_data()
    text = PARTIES.read_text()
    # restore earlier runs
    text = re.sub(r"\tdb (\d+)\n\tdw \w+ ; gym added\n\tdw [^\n]*\n", "", text)
    text = re.sub(r"\tdw (\w+) ; gym \(was (\w+)\)\n\tdw [^\n]*; moves were: ([^\n]*)\n",
                  lambda m: f"\tdw {m.group(2)}\n\tdw {m.group(3)}\n", text)
    report = []
    for leader, (repls, add) in PLAN.items():
        start = text.index(f"{leader}Group:")
        end = text.index("end_list_items", start)
        block = text[start:end]
        mons = re.findall(r"\tdb (\d+)\n\tdw (\w+)\n\tdw ([^\n]*)\n", block)
        assert mons, leader
        levels = [int(l) for l, _, _ in mons]
        ace_i = max(range(len(mons)), key=lambda k: (levels[k], k))
        ace_lv, ace_sp = levels[ace_i], mons[ace_i][1]
        new_block = block
        for old, first in repls:
            idx = next(k for k, (_, s, _) in enumerate(mons) if s == old and k != ace_i)
            lv, _, oldmoves = mons[idx]
            sp = resolve(first, int(lv), rom)
            mv = ", ".join(moves_at(sp, int(lv), rom, TYPE[leader]))
            entry = f"\tdb {lv}\n\tdw {old}\n\tdw {oldmoves}\n"
            assert new_block.count(entry) >= 1
            new_block = new_block.replace(entry, f"\tdb {lv}\n\tdw {sp} ; gym (was {old})\n\tdw {mv} ; moves were: {oldmoves}\n", 1)
            mons[idx] = (lv, sp, mv)
            report.append(f"{leader}: {old} Lv{lv} -> {sp} Lv{lv} ({mv})")
        if add:
            assert len(mons) < 6, leader
            sp = resolve(add, ace_lv, rom)
            mv = ", ".join(moves_at(sp, ace_lv, rom, TYPE[leader]))
            ace_entry = f"\tdb {ace_lv}\n\tdw {ace_sp}\n"
            pos = new_block.rindex(ace_entry)
            new_block = new_block[:pos] + f"\tdb {ace_lv}\n\tdw {sp} ; gym added\n\tdw {mv}\n" + new_block[pos:]
            report.append(f"{leader}: + {sp} Lv{ace_lv} ({mv}), before ace {ace_sp}")
        text = text[:start] + new_block + text[end:]
    PARTIES.write_text(text)
    (Path(__file__).resolve().parent / "gym_teams.md").write_text(
        "# Gym leader changes (generated by gym_teams.py)\n\n" + "\n".join(f"- {r}" for r in report) + "\n")
    print("\n".join(report))


if __name__ == "__main__":
    main()
