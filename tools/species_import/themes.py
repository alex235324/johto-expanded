"""Map themes for wild grass encounters.

Each grass map gets a theme: the types (and, for Gen 1-3 species, the PokeAPI
habitats) that belong there. place_wild.py and gen_tables.py only put a species
in a map's grass if it fits the theme, so a Burned Tower gets Fire/Poison/Ghost
Pokémon instead of Miltank or Tropius. Water, fishing and tree slots keep their
own rules in the generators. If nothing in the pool fits a slot, the generators
fall back to their old type-overlap scoring for that slot only.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pokedata as P  # noqa: E402

N, FI, FL, PO, GR, RO, BU, GH, ST, FR, WA, GS, EL, PS, IC, DR, DA = (
    "NORMAL", "FIGHTING", "FLYING", "POISON", "GROUND", "ROCK", "BUG", "GHOST", "STEEL",
    "FIRE", "WATER", "GRASS", "ELECTRIC", "PSYCHIC_TYPE", "ICE", "DRAGON", "DARK")

CAVE = {RO, GR, ST, DA, GH, FI}

# theme -> (types, habitats, extra species identifiers)
THEMES = {
    "sprout":     ({GH, GS, PS}, set(), set()),
    "tin":        ({GH, PS, FR}, set(), {"natu", "murkrow"}),
    "burned":     ({FR, GH, DA}, set(), {"koffing", "weezing", "grimer", "muk", "trubbish", "stunky", "zubat"}),
    "ruins":      ({PS, RO, GR, GH}, set(), set()),
    "cave":       (CAVE, {"cave"}, {"woobat", "paras", "parasect"}),
    "watercave":  (CAVE | {WA}, {"cave", "waters-edge"}, {"woobat"}),
    "deepcave":   (CAVE | {DR, WA, IC}, {"cave", "mountain"}, {"woobat", "paras", "parasect"}),
    "ice":        ({IC}, set(), set()),
    "whirl":      ({WA, IC, RO}, {"cave", "sea"}, {"woobat"}),
    "forest":     ({BU, GS}, {"forest"}, {"hoothoot", "pidgey"}),
    "park":       ({N, BU, GS, FL}, {"grassland", "forest"}, set()),
    "field":      ({N, GS, BU, FL, PO, GR, EL, FI}, {"grassland"}, set()),
    "rain":       ({N, GS, BU, FL, PO, WA}, {"grassland", "waters-edge"}, set()),
    "marsh":      ({GS, BU, WA, PO, GR}, {"waters-edge"}, {"chansey"}),
    "ranch":      ({N, GS, EL, GR}, {"grassland"}, {"pidgey", "pidove"}),
    "mountain":   ({RO, GR, FI, ST, DR, FR}, {"mountain", "rough-terrain"},
                   {"spearow", "fearow", "skarmory", "rufflet", "vullaby", "swablu", "taillow", "starly", "aerodactyl"}),
    "urban":      ({N, PS, PO, EL, ST, DA}, {"urban"}, set()),
    "power":      ({EL, ST, PO, FL}, {"urban"}, set()),
    "coast_road": ({PO, FL, DA, FI}, set(), set()),
    "seaside":    ({WA, GS, FL, PS}, {"waters-edge", "sea"}, set()),
}

MAP_THEME = {
    # Johto
    "SPROUT_TOWER_2F": "sprout", "SPROUT_TOWER_3F": "sprout",
    **{f"TIN_TOWER_{n}F": "tin" for n in range(2, 10)},
    "BURNED_TOWER_1F": "burned", "BURNED_TOWER_B1F": "burned",
    "NATIONAL_PARK": "park",
    "RUINS_OF_ALPH_OUTSIDE": "ruins",
    "UNION_CAVE_1F": "watercave", "UNION_CAVE_B1F": "watercave", "UNION_CAVE_B2F": "watercave",
    "SLOWPOKE_WELL_B1F": "watercave", "SLOWPOKE_WELL_B2F": "watercave",
    "ILEX_FOREST": "forest",
    "MOUNT_MORTAR_1F_OUTSIDE": "watercave", "MOUNT_MORTAR_1F_INSIDE": "watercave",
    "MOUNT_MORTAR_2F_INSIDE": "cave", "MOUNT_MORTAR_B1F": "watercave",
    "ICE_PATH_1F": "ice", "ICE_PATH_B1F": "ice", "ICE_PATH_B2F_MAHOGANY_SIDE": "ice",
    "ICE_PATH_B2F_BLACKTHORN_SIDE": "ice", "ICE_PATH_B3F": "ice",
    **{m: "whirl" for m in ("WHIRL_ISLAND_NW", "WHIRL_ISLAND_NE", "WHIRL_ISLAND_SW", "WHIRL_ISLAND_CAVE",
                            "WHIRL_ISLAND_SE", "WHIRL_ISLAND_B1F", "WHIRL_ISLAND_B2F", "WHIRL_ISLAND_LUGIA_CHAMBER")},
    "SILVER_CAVE_ROOM_1": "deepcave", "SILVER_CAVE_ROOM_2": "deepcave", "SILVER_CAVE_ROOM_3": "deepcave",
    "SILVER_CAVE_ITEM_ROOMS": "deepcave",
    "DARK_CAVE_VIOLET_ENTRANCE": "cave", "DARK_CAVE_BLACKTHORN_ENTRANCE": "cave",
    "ROUTE_29": "field", "ROUTE_30": "field", "ROUTE_31": "field", "ROUTE_32": "marsh", "ROUTE_33": "rain",
    "ROUTE_34": "field", "ROUTE_35": "field", "ROUTE_36": "field", "ROUTE_37": "park",
    "ROUTE_38": "ranch", "ROUTE_39": "ranch", "ROUTE_42": "mountain", "ROUTE_43": "field",
    "ROUTE_44": "marsh", "ROUTE_45": "mountain", "ROUTE_46": "mountain", "SILVER_CAVE_OUTSIDE": "mountain",
    # Kanto
    "DIGLETTS_CAVE": "cave", "MOUNT_MOON": "cave", "ROCK_TUNNEL_1F": "cave", "ROCK_TUNNEL_B1F": "cave",
    "VICTORY_ROAD": "deepcave", "TOHJO_FALLS": "watercave",
    "ROUTE_1": "field", "ROUTE_2": "park", "ROUTE_3": "mountain", "ROUTE_4": "mountain",
    "ROUTE_5": "urban", "ROUTE_6": "urban", "ROUTE_7": "urban", "ROUTE_8": "urban",
    "ROUTE_9": "mountain", "ROUTE_10_NORTH": "power", "ROUTE_11": "urban",
    "ROUTE_13": "marsh", "ROUTE_14": "marsh", "ROUTE_15": "marsh",
    "ROUTE_16": "coast_road", "ROUTE_17": "coast_road", "ROUTE_18": "coast_road",
    "ROUTE_21": "seaside", "ROUTE_22": "field", "ROUTE_24": "forest", "ROUTE_25": "park",
    "ROUTE_26": "mountain", "ROUTE_27": "mountain", "ROUTE_28": "mountain",
}

_habitat: dict[int, str | None] | None = None


def _habitats():
    global _habitat
    if _habitat is None:
        names = {r["id"]: r["identifier"] for r in P.rows("pokemon_habitats")}
        _habitat = {int(r["id"]): names.get(r["habitat_id"]) for r in P.rows("pokemon_species")}
    return _habitat


def fits(sp, i, map_name):
    """True if species i belongs in map_name's grass (maps without a theme accept anything)."""
    theme = MAP_THEME.get(map_name)
    if theme is None:
        return True
    types, habitats, extra = THEMES[theme]
    return bool(set(sp[i]["types"]) & types) or _habitats().get(i) in habitats or sp[i]["identifier"] in extra


def theme_of(map_name):
    return MAP_THEME.get(map_name, "-")
