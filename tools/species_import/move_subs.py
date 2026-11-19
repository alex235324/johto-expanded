"""Map every Gen 3-5 move (ids 252-559) to the closest existing Gen 2 move.

Priority: move_overrides.csv (yours, optional) > CURATED (below) > automatic.
Automatic rule for damaging moves: same type, nearest power, overshooting
penalised 50 %, and "special behaviour" moves (rampage, two-turn, recharge,
self-KO, fixed-damage, drain, OHKO) are only picked when the new move shares
that behaviour. Status moves fall back to their stat change / ailment.
Writes move_substitutions.csv for review.
"""

from __future__ import annotations

import csv
from pathlib import Path

import pokedata as P

HERE = Path(__file__).resolve().parent

# Gen 2 moves never chosen automatically (odd mechanics). Curated entries may still use them.
SPECIAL = {"SELFDESTRUCT", "EXPLOSION", "DREAM_EATER", "SNORE", "HYPER_BEAM", "SOLARBEAM", "SKY_ATTACK",
           "SKULL_BASH", "RAZOR_WIND", "FLY", "DIG", "BIDE", "COUNTER", "MIRROR_COAT", "SEISMIC_TOSS",
           "NIGHT_SHADE", "DRAGON_RAGE", "SONICBOOM", "SUPER_FANG", "PSYWAVE", "FALSE_SWIPE", "FUTURE_SIGHT",
           "THRASH", "PETAL_DANCE", "OUTRAGE", "ROLLOUT", "FURY_CUTTER", "PRESENT", "MAGNITUDE", "RETURN",
           "FRUSTRATION", "HIDDEN_POWER", "BEAT_UP", "PURSUIT", "GUILLOTINE", "HORN_DRILL", "FISSURE",
           "ABSORB", "MEGA_DRAIN", "GIGA_DRAIN", "LEECH_LIFE", "STRUGGLE", "TRIPLE_KICK", "SPIT_UP",
           "FIRE_SPIN", "WRAP", "BIND", "CLAMP", "WHIRLPOOL", "RAGE", "METRONOME", "MIRROR_MOVE",
           "SKETCH", "MIMIC", "SUBSTITUTE", "TRANSFORM", "CONVERSION", "CONVERSION2", "CURSE", "SPITE",
           "PAIN_SPLIT", "SLEEP_TALK", "FLAIL", "REVERSAL", "BATON_PASS", "ENCORE", "PERISH_SONG",
           "DESTINY_BOND", "THIEF", "RAPID_SPIN", "TRI_ATTACK", "SWIFT", "QUICK_ATTACK", "MACH_PUNCH",
           "EXTREMESPEED", "HI_JUMP_KICK", "JUMP_KICK", "AEROBLAST", "SACRED_FIRE", "TWINEEDLE_", "BONEMERANG_", "COMET_PUNCH", "PIN_MISSILE_", "SPIKE_CANNON_"}
DRAINS = {"ABSORB", "MEGA_DRAIN", "GIGA_DRAIN", "LEECH_LIFE"}

CURATED = {
    # gen 3
    "fake-out": "QUICK_ATTACK", "uproar": "THRASH", "stockpile": "DEFENSE_CURL", "spit-up": "BODY_SLAM",
    "swallow": "RECOVER", "hail": "MIST", "torment": "DISABLE", "flatter": "SWAGGER", "will-o-wisp": "CONFUSE_RAY",
    "memento": "CHARM", "focus-punch": "DYNAMICPUNCH", "follow-me": "PROTECT", "nature-power": "TRI_ATTACK",
    "charge": "FOCUS_ENERGY", "taunt": "DISABLE", "helping-hand": "FOCUS_ENERGY", "trick": "THIEF",
    "role-play": "MIMIC", "wish": "SOFTBOILED", "assist": "METRONOME", "ingrain": "SYNTHESIS",
    "magic-coat": "PROTECT", "recycle": "FOCUS_ENERGY", "yawn": "SING", "knock-off": "THIEF",
    "endeavor": "SUPER_FANG", "eruption": "FIRE_BLAST", "skill-swap": "MIMIC", "imprison": "DISABLE",
    "refresh": "HEAL_BELL", "grudge": "DESTINY_BOND", "snatch": "MIMIC", "dive": "SURF",
    "arm-thrust": "DOUBLE_KICK", "camouflage": "CONVERSION", "tail-glow": "GROWTH", "feather-dance": "CHARM",
    "teeter-dance": "SUPERSONIC", "blaze-kick": "FIRE_PUNCH", "mud-sport": "SAND_ATTACK", "ice-ball": "ROLLOUT",
    "slack-off": "SOFTBOILED", "blast-burn": "FIRE_BLAST", "hydro-cannon": "HYDRO_PUMP",
    "frenzy-plant": "PETAL_DANCE", "aromatherapy": "HEAL_BELL", "fake-tears": "SCREECH",
    "odor-sleuth": "FORESIGHT", "metal-sound": "SCREECH", "grass-whistle": "SLEEP_POWDER", "tickle": "GROWL",
    "cosmic-power": "BARRIER", "water-spout": "HYDRO_PUMP", "sheer-cold": "BLIZZARD", "iron-defense": "BARRIER",
    "block": "MEAN_LOOK", "howl": "MEDITATE", "bulk-up": "MEDITATE", "bounce": "FLY", "covet": "THIEF",
    "water-sport": "MIST", "calm-mind": "AMNESIA", "dragon-dance": "AGILITY", "doom-desire": "FUTURE_SIGHT",
    "psycho-boost": "PSYCHIC_M", "volt-tackle": "THUNDER", "rock-blast": "ROCK_THROW",
    # gen 4
    "roost": "RECOVER", "gravity": "MIST", "miracle-eye": "FORESIGHT", "healing-wish": "HEAL_BELL",
    "feint": "QUICK_ATTACK", "tailwind": "AGILITY", "acupressure": "FOCUS_ENERGY", "metal-burst": "COUNTER",
    "close-combat": "CROSS_CHOP", "embargo": "DISABLE", "psycho-shift": "MIMIC", "trump-card": "SWIFT",
    "heal-block": "DISABLE", "power-trick": "SHARPEN", "gastro-acid": "DISABLE", "lucky-chant": "SAFEGUARD",
    "me-first": "MIRROR_MOVE", "copycat": "MIRROR_MOVE", "power-swap": "PSYCH_UP", "guard-swap": "PSYCH_UP",
    "worry-seed": "LEECH_SEED", "sucker-punch": "QUICK_ATTACK", "toxic-spikes": "SPIKES",
    "heart-swap": "PSYCH_UP", "aqua-ring": "MIST", "magnet-rise": "AGILITY", "rock-polish": "AGILITY",
    "vacuum-wave": "MACH_PUNCH", "focus-blast": "DYNAMICPUNCH", "switcheroo": "THIEF",
    "giga-impact": "HYPER_BEAM", "nasty-plot": "GROWTH", "bullet-punch": "METAL_CLAW",
    "ice-shard": "POWDER_SNOW", "thunder-fang": "THUNDERPUNCH", "ice-fang": "ICE_PUNCH",
    "fire-fang": "FIRE_PUNCH", "defog": "HAZE", "trick-room": "AMNESIA", "draco-meteor": "OUTRAGE",
    "leaf-storm": "PETAL_DANCE", "power-whip": "PETAL_DANCE", "rock-wrecker": "HYPER_BEAM",
    "captivate": "CHARM", "stealth-rock": "SPIKES", "defend-order": "BARRIER", "heal-order": "RECOVER",
    "roar-of-time": "OUTRAGE", "lunar-dance": "MOONLIGHT", "magma-storm": "FLAMETHROWER",
    "dark-void": "HYPNOSIS", "seed-flare": "SOLARBEAM", "shadow-force": "SHADOW_BALL",
    "aqua-jet": "WATER_GUN", "shadow-sneak": "LICK", "double-hit": "DOUBLESLAP",
    # gen 5
    "hone-claws": "SHARPEN", "wide-guard": "PROTECT", "quick-guard": "DETECT", "guard-split": "PSYCH_UP",
    "power-split": "PSYCH_UP", "wonder-room": "AMNESIA", "psyshock": "PSYCHIC_M", "autotomize": "AGILITY",
    "rage-powder": "SWEET_SCENT", "telekinesis": "KINESIS", "magic-room": "AMNESIA", "quiver-dance": "GROWTH",
    "soak": "MIST", "coil": "SHARPEN", "acid-spray": "ACID", "simple-beam": "DISABLE", "entrainment": "MIMIC",
    "after-you": "MIMIC", "ally-switch": "TELEPORT", "shell-smash": "SWORDS_DANCE", "heal-pulse": "RECOVER",
    "sky-drop": "FLY", "shift-gear": "AGILITY", "quash": "DISABLE", "reflect-type": "CONVERSION",
    "final-gambit": "COUNTER", "bestow": "BATON_PASS", "work-up": "GROWTH", "cotton-guard": "BARRIER",
    "horn-leech": "GIGA_DRAIN", "drain-punch": "SUBMISSION", "tail-slap": "DOUBLESLAP",
    "bug-buzz": "MEGAHORN", "x-scissor": "FURY_CUTTER", "attack-order": "MEGAHORN",
}

# status fallbacks: (stat_id, sign/size) -> move; stat ids 1 hp 2 atk 3 def 4 spa 5 spd 6 spe 7 acc 8 eva
RAISE = {2: "SHARPEN", 3: "HARDEN", 4: "GROWTH", 5: "AMNESIA", 6: "AGILITY", 7: "LOCK_ON", 8: "DOUBLE_TEAM"}
RAISE2 = {2: "SWORDS_DANCE", 3: "BARRIER", 4: "GROWTH", 5: "AMNESIA", 6: "AGILITY", 8: "MINIMIZE"}
LOWER = {2: "GROWL", 3: "LEER", 4: "GROWL", 5: "SCREECH", 6: "STRING_SHOT", 7: "SAND_ATTACK", 8: "SWEET_SCENT"}
LOWER2 = {2: "CHARM", 3: "SCREECH", 4: "CHARM", 5: "SCREECH", 6: "SCARY_FACE", 7: "SMOKESCREEN"}
AILMENT = {"1": "THUNDER_WAVE", "2": "HYPNOSIS", "4": "CONFUSE_RAY", "5": "POISONPOWDER", "6": "CONFUSE_RAY",
           "7": "ATTRACT", "8": "MEAN_LOOK", "9": "NIGHTMARE", "13": "DISABLE", "14": "HYPNOSIS",
           "17": "FORESIGHT", "18": "LEECH_SEED", "20": "PERISH_SONG"}


def gen2_moves():
    """Gen 2 move pool with Crystal's own power/type/accuracy (read from data/moves/moves.asm),
    not PokeAPI's current-generation values."""
    import re
    names = P.crystal_moves()
    pool = []
    for line in open(P.REPO / "data/moves/moves.asm"):
        m = re.match(r"\s*move (\w+),\s*(\d+),\s*(\w+),\s*(\d+),\s*(\d+),\s*\d+\s*;\s*(\w+)", line)
        if m:
            eff, power, typ, acc, pp, _comment = m.groups()
            pool.append({"const": names[len(pool) + 1], "effect": eff, "power": int(power) or None, "type": typ,
                         "accuracy": int(acc), "pp": int(pp)})
    assert len(pool) == len(names), (len(pool), len(names))
    return pool


def special_of(m: dict) -> set[str]:
    """behaviour tags of a new move, so we only match like with like."""
    tags = set()
    if (m.get("drain") or 0) > 0:
        tags.add("drain")
    if m.get("max_hits") and m["max_hits"] not in ("", "1"):
        tags.add("multi")
    return tags


def auto_damage(m: dict, pool: list[dict]) -> tuple[str, str]:
    power = m["power"] or 60
    tags = special_of(m)
    cands = [c for c in pool if c["power"] and c["type"] == m["type"]]
    if "drain" in tags and any(c["const"] in DRAINS for c in cands):
        cands = [c for c in cands if c["const"] in DRAINS]
    else:
        cands = [c for c in cands if c["const"] not in SPECIAL]
    why = "same type, nearest power"
    if not cands:
        cands = [c for c in pool if c["power"] and c["type"] == "NORMAL" and c["const"] not in SPECIAL]
        why = "no same-type match; Normal, nearest power"

    def cost(c):
        d = c["power"] - power
        return abs(d) + (0.25 * d if d > 0 else 0) + 0.5 * (100 - (c["accuracy"] or 100))
    best = min(cands, key=cost)
    return best["const"], f"{why} ({power} -> {best['power']})"


def auto_status(m: dict, pool: list[dict]) -> tuple[str, str]:
    ch = m.get("stat_changes") or []
    if ch:
        stat, change = max(ch, key=lambda sc: (abs(sc[1]), sc[0] in (2, 4)))
        if change > 0:
            table = RAISE2 if change >= 2 else RAISE
        else:
            table = LOWER2 if change <= -2 else LOWER
        if stat in table:
            return table[stat], f"stat change {stat}:{change:+d}"
    if m.get("ailment") in AILMENT:
        return AILMENT[m["ailment"]], f"ailment {m['ailment']}"
    if (m.get("healing") or 0) > 0:
        return "RECOVER", "heals user"
    same = [c for c in pool if c["type"] == m["type"] and not c["power"] and c["const"] not in SPECIAL]
    if same:
        return same[0]["const"], "unique effect; first same-type status move"
    return "FOCUS_ENERGY", "unique effect; generic fallback"


def build(write_csv: bool = True) -> dict[int, str]:
    pool = gen2_moves()
    valid = {c["const"] for c in pool}
    overrides = {}
    ov = HERE / "move_overrides.csv"
    if ov.exists():
        for r in csv.DictReader(open(ov, newline="")):
            if r.get("identifier") and r.get("crystal_move"):
                overrides[r["identifier"].strip()] = r["crystal_move"].strip().upper()
    out, report = {}, []
    for i, m in sorted(P.moves_table().items()):
        if not 252 <= i <= 559:
            continue
        ident = m["identifier"]
        if ident in overrides:
            sub, why = overrides[ident], "move_overrides.csv"
        elif ident in CURATED:
            sub, why = CURATED[ident], "curated"
        elif m["class"] != "1" and (m["power"] or m.get("meta") in ("0", "4", "6", "7", "8")):
            sub, why = auto_damage(m, pool)
        else:
            sub, why = auto_status(m, pool)
        if sub not in valid:
            raise SystemExit(f"{ident}: substitute {sub} is not a Crystal move")
        out[i] = sub
        report.append([i, ident, m.get("name", ident), m["type"], m["power"] or "", m["class"], sub, why])
    if write_csv:
        with open(HERE / "move_substitutions.csv", "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["id", "identifier", "name", "type", "power", "class(1=status)", "crystal_move", "reason"])
            w.writerows(report)
    return out


def resolve(move_id: int, subs: dict[int, str]) -> str:
    """national move id -> Crystal move constant."""
    names = P.crystal_moves()
    if move_id in names:
        return names[move_id]
    return subs[move_id]


if __name__ == "__main__":
    s = build()
    print(f"{len(s)} moves mapped -> move_substitutions.csv")
