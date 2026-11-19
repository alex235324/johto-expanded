#!/usr/bin/env python3
"""Mixed-case text pass: turn the game's ALL-CAPS words into Title Case.

Vanilla Crystal writes names, items, moves, places and menus in capitals
("POKéMON", "PROF.ELM", "POTION"). This rewrites every on-screen string
literal (text/line/para/db/dname/li/... arguments, see common.py) so that
each run of 2+ capitals becomes Title Case ("Pokémon", "Prof.Elm", "Potion"),
except:

  * KEEP: acronyms and status tags that stay uppercase (TM, HP, PSN...)
  * CAMEL: run-together compounds (THUNDERPUNCH -> ThunderPunch); Pokédex
    categories squeezed by the species import (TINYRACCOON -> TinyRaccoon)
    are rebuilt from PokeAPI's genus names when its CSV cache is available
  * small words (of, the, and...) are lowercase unless they start the string
  * "#MON" (the # glyph prints "Poké") becomes "#mon"

Strings keep their length, so fixed-width tables and menus still line up.
Safe to re-run: Title Case words are left alone.

Usage: python3 tools/text_case/convert.py [--dry-run]
"""

import csv
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import REPO, WORD_RE, asm_files, outside_tags, text_strings  # noqa: E402

KEEP = {
    "TM", "HM", "HP", "PP", "PC", "OK", "TV", "DJ", "ID", "OT", "KO", "GS", "AM", "PM",
    "DNA", "UFO", "IQ", "HQ", "CD", "DST", "HOF", "PKMN", "NPC", "BG", "AI",
    "BRN", "FRZ", "PSN", "SLP", "PAR", "FNT", "TOX",
}
SMALL = {"OF", "THE", "AND", "TO", "IN", "ON", "AT", "FOR", "OR", "AN"}

CAMEL = {
    # moves
    "ANCIENTPOWER": "AncientPower", "BUBBLEBEAM": "BubbleBeam", "DOUBLESLAP": "DoubleSlap",
    "DRAGONBREATH": "DragonBreath", "DYNAMICPUNCH": "DynamicPunch", "EXTREMESPEED": "ExtremeSpeed",
    "POISONPOWDER": "PoisonPowder", "SMOKESCREEN": "SmokeScreen", "SOFTBOILED": "Softboiled",
    "THUNDERPUNCH": "ThunderPunch", "THUNDERSHOCK": "ThunderShock", "SOLARBEAM": "SolarBeam",
    "SONICBOOM": "SonicBoom", "VICEGRIP": "ViceGrip", "SELFDESTRUCT": "Selfdestruct",
    "DRAININGKISS": "DrainingKiss", "FEATHERDANCE": "FeatherDance", "GRASSWHISTLE": "GrassWhistle",
    "SMELLINGSALT": "SmellingSalt",
    # items
    "BLACKGLASSES": "BlackGlasses", "BRIGHTPOWDER": "BrightPowder", "ENERGYPOWDER": "EnergyPowder",
    "MIRACLEBERRY": "MiracleBerry", "MYSTERYBERRY": "MysteryBerry", "NEVERMELTICE": "NeverMeltIce",
    "PRZCUREBERRY": "PrzCureBerry", "PSNCUREBERRY": "PsnCureBerry", "RAGECANDYBAR": "RageCandyBar",
    "SECRETPOTION": "SecretPotion", "SILVERPOWDER": "SilverPowder", "SLOWPOKETAIL": "SlowpokeTail",
    "SLOWPOKETAILS": "SlowpokeTails", "TINYMUSHROOM": "TinyMushroom", "TWISTEDSPOON": "TwistedSpoon",
    "LITEBLUEMAIL": "LiteBlueMail", "PORTRAITMAIL": "PortraitMail", "SQUIRTBOTTLE": "SquirtBottle",
    "SILPHSCOPE": "SilphScope", "BLACKBELT": "BlackBelt", "MOOMOO": "MooMoo", "BLUESKY": "BlueSky",
    "POLKADOT": "PolkaDot", "BERRYJUICE": "BerryJuice", "GOLDBERRY": "GoldBerry",
    "TMS": "TMs", "HMS": "HMs",
}

BADGE = re.compile(r"^([A-Z]+)BADGE$")


def load_genus_overrides():
    """TINYRACCOON -> TinyRaccoon, from PokeAPI's English genus names (if cached)."""
    out = {}
    for base in (REPO, REPO.parent):
        for csv_path in base.glob("**/species_import/data/pokemon_species_names.csv"):
            with open(csv_path, newline="", encoding="utf-8") as f:
                for row in csv.DictReader(f):
                    if row["local_language_id"] != "9" or not row["genus"]:
                        continue
                    words = row["genus"].replace(" Pokémon", "").replace("-", " ").split()
                    if len(words) < 2:
                        continue
                    key = "".join(words).upper().replace("É", "é")
                    out[key] = "".join(w[:1].upper() + w[1:].lower() for w in words)
            return out
    return out


GENUS = load_genus_overrides()


def convert_word(word, first):
    core = word.rstrip("'")
    suffix = word[len(core):]
    return _convert_core(core, first) + suffix


def _convert_core(core, first):
    if core in KEEP:
        return core
    if core in CAMEL:
        return CAMEL[core]
    if core in GENUS:
        return GENUS[core]
    m = BADGE.match(core)
    if m:
        return m.group(1).capitalize() + "Badge"
    if not first and core in SMALL:
        return core.lower()
    return core[0] + core[1:].lower()


def convert_string(s):
    out, last, first = [], 0, True
    for a, b in outside_tags(s):
        out.append(s[last:a])
        seg = s[a:b]
        pieces, i = [], 0
        for m in WORD_RE.finditer(seg):
            w = m.group()
            pieces.append(seg[i:m.start()])
            i = m.end()
            if len(w.replace("'", "")) < 2:
                pieces.append(w)  # single letters ("A", "I", "X") stay
            elif m.start() > 0 and seg[m.start() - 1] == "#":
                pieces.append(w.lower())  # "#MON" -> "#mon" (# prints "Poké")
            else:
                pieces.append(convert_word(w, first))
            first = False
        pieces.append(seg[i:])
        out.append("".join(pieces))
        last = b
    out.append(s[last:])
    return "".join(out)


def convert_line(line):
    spans = list(text_strings(line))
    for a, b in reversed(spans):
        line = line[:a] + convert_string(line[a:b]) + line[b:]
    return line


def main():
    dry = "--dry-run" in sys.argv
    changed_files = changed_lines = 0
    for path, rel in asm_files():
        text = path.read_text(encoding="utf-8")
        lines = text.split("\n")
        new = [convert_line(l) for l in lines]
        n = sum(a != b for a, b in zip(lines, new))
        if n:
            changed_files += 1
            changed_lines += n
            if not dry:
                path.write_text("\n".join(new), encoding="utf-8")
    print(f"{'would change' if dry else 'changed'} {changed_lines} lines in {changed_files} files"
          f" ({len(GENUS)} genus overrides)")


if __name__ == "__main__":
    main()
