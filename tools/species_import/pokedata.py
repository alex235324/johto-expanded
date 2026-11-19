"""Read PokeAPI CSVs (data/) and the repo's own constants into plain Python data.

Everything Gen 5-specific is resolved here: stats/types are taken as they
were in Gen 5 (pokemon_stats_past / pokemon_types_past), learnsets come from
Black 2/White 2 (version group 14).
"""

from __future__ import annotations

import csv
import re
from collections import defaultdict
from functools import lru_cache
from pathlib import Path

HERE = Path(__file__).resolve().parent
DATA = HERE / "data"
REPO = HERE.parent.parent

EN = "9"
VG_B2W2 = 14
GEN5_VERSION_GROUPS = {"5", "6", "7", "8", "9", "10", "11", "12", "13", "14"}  # RS..B2W2 (gens 3-5)
FLAVOR_VERSIONS = ["21", "22", "17", "18", "14", "13", "16", "15", "10", "11", "12", "9", "8", "7"]  # B2,W2,B,W,Pt,..


def rows(name: str):
    with open(DATA / f"{name}.csv", newline="", encoding="utf-8") as f:
        yield from csv.DictReader(f)


# --------------------------------------------------------------------------- repo constants

@lru_cache(None)
def crystal_moves() -> dict[int, str]:
    """national move id -> Crystal constant (Gen 2 ids 1..251 match the national ids)."""
    out, idx = {}, -1
    for line in open(REPO / "constants/move_constants.asm"):
        if "NUM_ATTACKS" in line and idx >= 0:
            break
        if line.strip().startswith("const_def"):
            idx = 0
            continue
        m = re.match(r"\s*const (\w+)", line)
        if m and idx >= 0:
            if idx > 0:
                out[idx] = m.group(1)
            idx += 1
    return out


@lru_cache(None)
def crystal_tm_moves() -> list[str]:
    out = []
    for line in open(REPO / "constants/item_constants.asm"):
        m = re.match(r"\s*add_(?:tm|hm|mt)\s+(\w+)", line)
        if m:
            out.append(m.group(1))
    return out


@lru_cache(None)
def crystal_items() -> set[str]:
    out = set()
    for line in open(REPO / "constants/item_constants.asm"):
        m = re.match(r"\s*const (\w+)", line)
        if m:
            out.add(m.group(1))
    return out


def item_const(identifier: str) -> str | None:
    c = identifier.upper().replace("-", "_")
    alias = {"THUNDER_STONE": "THUNDERSTONE", "KINGS_ROCK": "KINGS_ROCK", "UPGRADE": "UP_GRADE",
             "DEEP_SEA_TOOTH": None, "DEEP_SEA_SCALE": None, "BRIGHT_POWDER": "BRIGHTPOWDER",
             "SILK_SCARF": "SILK_SCARF", "BLACK_GLASSES": "BLACKGLASSES", "TWISTED_SPOON": "TWISTEDSPOON",
             "NEVER_MELT_ICE": "NEVERMELTICE", "SILVER_POWDER": "SILVERPOWDER", "MIRACLE_SEED": "MIRACLE_SEED",
             "PARALYZE_HEAL": "PARLYZ_HEAL", "ORAN_BERRY": "BERRY", "SITRUS_BERRY": "GOLD_BERRY",
             "LUM_BERRY": "MIRACLEBERRY", "PERSIM_BERRY": "BITTER_BERRY", "CHERI_BERRY": "PRZCUREBERRY",
             "CHESTO_BERRY": "MINT_BERRY", "PECHA_BERRY": "PSNCUREBERRY", "RAWST_BERRY": "BURNT_BERRY",
             "ASPEAR_BERRY": "ICE_BERRY", "LEPPA_BERRY": "MYSTERYBERRY", "STARDUST": "STARDUST",
             "LUCKY_PUNCH": "LUCKY_PUNCH", "METAL_POWDER": "METAL_POWDER", "QUICK_CLAW": "QUICK_CLAW"}
    c = alias.get(c, c)
    return c if c and c in crystal_items() else None


# --------------------------------------------------------------------------- PokeAPI helpers

@lru_cache(None)
def types_by_id() -> dict[str, str]:
    crystal = {"normal": "NORMAL", "fighting": "FIGHTING", "flying": "FLYING", "poison": "POISON",
               "ground": "GROUND", "rock": "ROCK", "bug": "BUG", "ghost": "GHOST", "steel": "STEEL",
               "fire": "FIRE", "water": "WATER", "grass": "GRASS", "electric": "ELECTRIC",
               "psychic": "PSYCHIC_TYPE", "ice": "ICE", "dragon": "DRAGON", "dark": "DARK", "fairy": "FAIRY"}
    return {r["id"]: crystal.get(r["identifier"], r["identifier"].upper()) for r in rows("types")}


@lru_cache(None)
def moves_table() -> dict[int, dict]:
    out = {}
    for r in rows("moves"):
        i = int(r["id"])
        if i > 10000:
            continue
        out[i] = {"id": i, "identifier": r["identifier"], "gen": int(r["generation_id"]),
                  "type": types_by_id().get(r["type_id"]), "power": int(r["power"]) if r["power"] else None,
                  "accuracy": int(r["accuracy"]) if r["accuracy"] else None, "pp": int(r["pp"] or 0),
                  "priority": int(r["priority"] or 0), "class": r["damage_class_id"],  # 1 status 2 phys 3 spec
                  "effect": r["effect_id"]}
    for r in rows("move_meta"):
        i = int(r["move_id"])
        if i in out:
            out[i].update(meta=r["meta_category_id"], ailment=r["meta_ailment_id"],
                          min_hits=r["min_hits"], max_hits=r["max_hits"], drain=int(r["drain"] or 0),
                          healing=int(r["healing"] or 0))
    stat = defaultdict(list)
    for r in rows("move_meta_stat_changes") if (DATA / "move_meta_stat_changes.csv").exists() else []:
        stat[int(r["move_id"])].append((int(r["stat_id"]), int(r["change"])))
    for i, s in stat.items():
        if i in out:
            out[i]["stat_changes"] = s
    for r in rows("move_names"):
        if r["local_language_id"] == EN and int(r["move_id"]) in out:
            out[int(r["move_id"])]["name"] = r["name"]
    return out


def gen5_value(current: dict, past: dict, key):
    """past[key] = [(generation, value)]: value applied *up to and including* generation."""
    cands = sorted(g for g, _ in past.get(key, []) if g >= 5)
    if cands:
        return dict(past[key])[cands[0]]
    return current[key]


@lru_cache(None)
def species_table() -> dict[int, dict]:
    """species id -> everything we need, Gen 5 values."""
    sp = {}
    for r in rows("pokemon_species"):
        i = int(r["id"])
        sp[i] = {"id": i, "identifier": r["identifier"], "gen": int(r["generation_id"]),
                 "evolves_from": int(r["evolves_from_species_id"]) if r["evolves_from_species_id"] else None,
                 "chain": int(r["evolution_chain_id"]) if r["evolution_chain_id"] else None,
                 "gender_rate": int(r["gender_rate"]), "capture_rate": int(r["capture_rate"]),
                 "hatch_counter": int(r["hatch_counter"]), "growth_rate": r["growth_rate_id"],
                 "shape": r["shape_id"], "color": r["color_id"], "legendary": r["is_legendary"] == "1",
                 "mythical": r["is_mythical"] == "1", "baby": r["is_baby"] == "1"}
    # default-form pokemon rows have id == species id for 1..649
    for r in rows("pokemon"):
        i = int(r["id"])
        if i in sp:
            sp[i]["base_exp"] = int(r["base_experience"] or 0)
            sp[i]["height_dm"] = int(r["height"])
            sp[i]["weight_hg"] = int(r["weight"])
    cur_stats, past_stats = defaultdict(dict), defaultdict(lambda: defaultdict(list))
    for r in rows("pokemon_stats"):
        cur_stats[int(r["pokemon_id"])][int(r["stat_id"])] = int(r["base_stat"])
    for r in rows("pokemon_stats_past"):
        past_stats[int(r["pokemon_id"])][int(r["stat_id"])].append((int(r["generation_id"]), int(r["base_stat"])))
    cur_types, past_types = defaultdict(dict), defaultdict(lambda: defaultdict(dict))
    for r in rows("pokemon_types"):
        cur_types[int(r["pokemon_id"])][int(r["slot"])] = r["type_id"]
    for r in rows("pokemon_types_past"):
        past_types[int(r["pokemon_id"])][int(r["generation_id"])][int(r["slot"])] = r["type_id"]
    tmap = types_by_id()
    for i, d in sp.items():
        d["stats"] = [gen5_value(cur_stats[i], past_stats[i], s) for s in (1, 2, 3, 6, 4, 5)]  # hp atk def spd sat sdf
        gens = sorted(g for g in past_types[i] if g >= 5)
        slots = past_types[i][gens[0]] if gens else cur_types[i]
        t1 = tmap[slots[1]]
        d["types"] = [t1, tmap[slots[2]] if 2 in slots else t1]
    eggs = defaultdict(list)
    for r in rows("pokemon_egg_groups"):
        eggs[int(r["species_id"])].append(int(r["egg_group_id"]))
    names = {}
    for r in rows("egg_groups"):
        names[int(r["id"])] = {"monster": "EGG_MONSTER", "water1": "EGG_WATER_1", "bug": "EGG_BUG",
                               "flying": "EGG_FLYING", "ground": "EGG_GROUND", "fairy": "EGG_FAIRY",
                               "plant": "EGG_PLANT", "humanshape": "EGG_HUMANSHAPE", "water3": "EGG_WATER_3",
                               "mineral": "EGG_MINERAL", "indeterminate": "EGG_INDETERMINATE",
                               "water2": "EGG_WATER_2", "ditto": "EGG_DITTO", "dragon": "EGG_DRAGON",
                               "no-eggs": "EGG_NONE"}[r["identifier"]]
    for i, d in sp.items():
        g = [names[e] for e in sorted(eggs[i])] or ["EGG_NONE"]
        d["egg_groups"] = (g + g)[:2]
    for r in rows("pokemon_species_names"):
        if r["local_language_id"] == EN and int(r["pokemon_species_id"]) in sp:
            sp[int(r["pokemon_species_id"])]["name"] = r["name"]
            sp[int(r["pokemon_species_id"])]["genus"] = r["genus"]
    flav = defaultdict(dict)
    for r in rows("pokemon_species_flavor_text"):
        if r["language_id"] == EN:
            flav[int(r["species_id"])][r["version_id"]] = r["flavor_text"]
    for i, d in sp.items():
        d["flavor"] = [flav[i][v] for v in FLAVOR_VERSIONS if v in flav[i]]
    items = defaultdict(list)
    item_ident = {r["id"]: r["identifier"] for r in rows("items")}
    for r in rows("pokemon_items"):
        if r["version_id"] in ("21", "22", "17", "18"):  # B2W2, then BW
            items[int(r["pokemon_id"])].append((r["version_id"], item_ident[r["item_id"]], int(r["rarity"])))
    for i, d in sp.items():
        best = {}
        for v, it, rar in sorted(items[i]):
            best.setdefault(it, rar)
        d["held_items"] = sorted(best.items(), key=lambda x: -x[1])
    return sp


@lru_cache(None)
def learnsets():
    """species -> {'level': [(lvl, move_id)], 'egg': [ids], 'any_gen3_5': set(ids)}"""
    out = defaultdict(lambda: {"level": [], "egg": [], "any": set()})
    for r in rows("pokemon_moves"):
        pid = int(r["pokemon_id"])
        if pid > 649:
            continue
        vg, mid, method = r["version_group_id"], int(r["move_id"]), r["pokemon_move_method_id"]
        if vg in GEN5_VERSION_GROUPS or vg in {"3", "4"}:  # gens 2-5 for TM compatibility
            out[pid]["any"].add(mid)
        if int(vg) == VG_B2W2:
            if method == "1":
                out[pid]["level"].append((int(r["level"]), int(r["order"] or 0), mid))
            elif method == "2":
                out[pid]["egg"].append(mid)
    for d in out.values():
        d["level"] = [(lvl, mid) for lvl, _, mid in sorted(d["level"])]
        d["egg"] = sorted(set(d["egg"]))
    return out


@lru_cache(None)
def evolutions():
    """evolved species id -> list of condition dicts"""
    out = defaultdict(list)
    trig = {r["id"]: r["identifier"] for r in rows("evolution_triggers")}
    item_ident = {r["id"]: r["identifier"] for r in rows("items")}
    loc = {r["id"]: r["identifier"] for r in rows("locations")}
    for r in rows("pokemon_evolution"):
        out[int(r["evolved_species_id"])].append({
            "trigger": trig.get(r["evolution_trigger_id"]),
            "item": item_ident.get(r["trigger_item_id"]), "min_level": int(r["minimum_level"] or 0),
            "gender": r["gender_id"], "location": loc.get(r["location_id"]),
            "held_item": item_ident.get(r["held_item_id"]), "time": r["time_of_day"],
            "known_move": int(r["known_move_id"]) if r["known_move_id"] else None,
            "known_move_type": r["known_move_type_id"], "happiness": int(r["minimum_happiness"] or 0),
            "beauty": r["minimum_beauty"], "physical": r["relative_physical_stats"],
            "party_species": int(r["party_species_id"]) if r["party_species_id"] else None,
            "trade_species": int(r["trade_species_id"]) if r["trade_species_id"] else None,
        })
    return out
