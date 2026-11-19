# species_import

Adds the Gen 3–5 Pokémon (national #252–649) to this pokecrystal16 ROM.
It uses Gen 5 stats and types (no Fairy type, no Gen 6+ stat changes) and
Black 2/White 2 learnsets. Any move that doesn't exist in Crystal is replaced
with the closest Gen 2 move. Data comes from the free
[PokeAPI CSV dump](https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv),
and sprites come from `tools/sprite_convert/`.

## Run order

```bash
# 1. sprites (once per source set)
tools/sprite_convert/.venv/bin/python tools/sprite_convert/convert.py --source-dir ~/romhacking/sprite_sources
# 2. species data + tables (re-runnable; regenerates everything it owns)
tools/sprite_convert/.venv/bin/python tools/species_import/import_species.py
# 3. wild encounters (re-runnable; restores the original slots first)
tools/sprite_convert/.venv/bin/python tools/species_import/place_wild.py
# 4. build and check the ROM's tables the way the game reads them
make && tools/sprite_convert/.venv/bin/python tools/species_import/verify_rom.py
```

The PokeAPI CSVs are cached in `data/` (gitignored). To re-download them,
delete `data/` and rerun the curl loop from this tool's commit, or fetch
the files that `pokedata.py` reads.

## What you can tweak

- **Move substitutions:** see `move_substitutions.csv` (all 308 moves and the
  reason each was picked). To override one, create `move_overrides.csv` with
  `identifier,crystal_move` (e.g. `x-scissor,MEGAHORN`) and rerun step 2.
- **Judgment calls** (evolution substitutes, dropped held items, shortened
  Pokédex text and categories, capped base exp) are listed in `report.md`.
- **Wild placements:** listed per species in `wild_placements.md`. Every
  changed line in `data/wild/*.asm` ends in `; gen3-5 (was X)`.

## Engine/layout changes this needed

- **Species tables** that outgrew their banks now have their own floating
  sections: names, cries, menu icons, palettes, first stages, frame pointers,
  animation scripts/bitmasks. "Pics 1" and "Evolutions and Attacks 1" also
  float now.
- **Base data, learnsets and egg moves** get one indirect sub-table per region
  (Hoenn, Sinnoh, Unova).
- **Palettes:** `_GetMonPalettePointer` copies the species' 8 palette bytes
  into `wMonPalBuffer` (WRAM0, carved out of the unused map buffer), because
  the table no longer shares the color code's bank.
- **Menu icons**: one per species, from `tools/menu_icons/make_icons.py`.
- **Footprints** for species after Celebi come from `Footprints2`. They're
  blank placeholders in `gfx/footprints/<name>.png`, so you can draw over them.
- **Pokédex seen/caught flags** (2 × 82 bytes) no longer fit in WRAM bank 1.
  They moved to `SECTION "Pokedex Flags"` in bank 5, and every access goes
  through `home/pokedex_flags.asm` (`PokedexFlagAction`,
  `CountPokedexFlags16`). They're saved as `sPokedexFlags` and
  `sBackupPokedexFlags`, inside the checksummed save blocks. **Saves made
  before this change are not compatible.**
- **Animations:** single-frame species share `StaticMonAnimation`,
  `StaticMonAnimationIdle`, `StaticMonBitmasks` and `StaticMonFrames`.
  To animate one, give it its own `anim.asm` and frames like any vanilla
  species.

## Known limitations

- **Cries:** Gen 3+ cries can't play on the Game Boy, so each species reuses a
  vanilla cry base with its own pitch and length.
- **Menu icons** are shrunk from each front sprite by `tools/menu_icons/make_icons.py`; rerun it after changing sprites.
- **Missing mechanics:** abilities, natures, Fairy and Gen 4 items don't exist.
  Evolution items and locations are substituted, as listed in `report.md`.
- **Breeding:** Incense babies (Azurill, Wynaut, Budew…) don't hatch from their
  parents, the same as Crystal without incense. Vanilla breeding is unchanged.
- **Legendaries** are 1% wild encounters in endgame maps, not events.
- **Zekrom's** blue accents were lost when its sprite was shrunk. It needs a hand
  touch-up (`verify_rom.py` warns about it).

## Gen Select (Pokégear)

The Pokégear's fifth card, **GEN**, picks which encounter set the wild uses:
DEFAULT (the mixed tables from `place_wild.py`), or GEN 1 to GEN 5 (that
generation only). Options unlock at 1, 3, 5, 7 and 8 gym badges (Johto and
Kanto badges both count). The choice is saved.

```bash
tools/sprite_convert/.venv/bin/python tools/species_import/gen_tables.py   # regenerate the 5 gen-only sets
```

- **Data:** `data/wild/gen1.asm` … `gen5.asm` hold grass and surf for each
  generation; `fish_gens.asm` and `treemons_gens.asm` hold fishing and
  Headbutt/Rock Smash. They are all built from the vanilla layout, so levels,
  rates and odds are unchanged. `gen_placements.md` lists the species per set.
- **Grass and surf:** in a Gen mode, `_GrassWildmonLookup` and
  `_WaterWildmonLookup` jump to `home/gen_select.asm`. It finds the map in that
  generation's tables and copies the entry to `wGenWildBuffer`.
- **Fishing and Headbutt:** these now live in their own sections and pick
  their table with `GetGenFishGroups` / `GetGenTreeMons`.
- **Swarms** are skipped in Gen modes.
- **Saved data:** the choice is `wGenSelect` in WRAM0, saved to `sGenSelect` in
  the padding after the save block, so older saves still load (as DEFAULT).
- **Still on the default tables:**
  - the Pokédex AREA map
  - phone callers' "I saw a…" Pokémon
  - Oak's radio show
  - the Bug-Catching Contest
  - the roaming legendary beasts

## Fairy type

**Type:** `FAIRY` comes after `DARK` (type 28). Gen 2 decides physical/special
by type, and Fairy is in the special range.
- **Matchups:** Gen 6 rules, in `data/types/type_matchups.asm`. Fairy is
  strong against Fighting, Dragon and Dark, weak to Poison and Steel, and
  immune to Dragon.
- **Pokédex search:** FAIRY is one of the type options.
- **Hidden Power:** can't be Fairy (as in later games).
- **Held items:** none boost Fairy. Pink Bow and Polkadot Bow still boost Normal.

**Moves:**
- **Retyped as Fairy:** Charm, Sweet Kiss and Moonlight.
- **New:** Moonblast, Dazzling Gleam, Play Rough, Draining Kiss, Disarming
  Voice and Fairy Wind. Each uses Gen 6 power, accuracy and PP, the closest
  Crystal effect, and a reused animation.

**Pokémon:** `fairy.py` gives every species #1–649 that is Fairy from Gen 6
on its Gen 6 types. It also adds the new moves to each level-up learnset
that has them in Omega Ruby/Alpha Sapphire. The details are in
`fairy_report.md`.

**Gen 1 trading (Time Capsule):** Fairy becomes the Pokémon's other type
(pure Fairy becomes Normal), and incoming Gen 1 Clefairy, Jigglypuff and
Mr. Mime are accepted.

**Run order** whenever species data is regenerated:

```bash
tools/sprite_convert/.venv/bin/python tools/species_import/import_species.py
tools/sprite_convert/.venv/bin/python tools/species_import/fairy.py        # after import_species
tools/sprite_convert/.venv/bin/python tools/species_import/place_wild.py
tools/sprite_convert/.venv/bin/python tools/species_import/gen_tables.py
tools/sprite_convert/.venv/bin/python tools/species_import/scale_trainer_levels.py --restore  # before gym_teams
tools/sprite_convert/.venv/bin/python tools/species_import/gym_teams.py
tools/sprite_convert/.venv/bin/python tools/species_import/scale_trainer_levels.py           # last
make && tools/sprite_convert/.venv/bin/python tools/species_import/verify_rom.py
```

`place_wild.py` and `gen_tables.py` only put a Pokémon in a map's grass if it
fits the map's theme (`themes.py`). `scale_trainer_levels.py` raises every
trainer Pokémon to min(100, floor(level^1.05)), evolves by level, lets bosses
evolve up to 5 levels early, and upgrades explicit move sets; its changes are
listed in `trainer_levels.md`.
