# Changes from vanilla Pokémon Crystal

This lists what is different from the base ROM: pret's [pokecrystal](https://github.com/pret/pokecrystal) disassembly at commit `95f3d3c09` (2025-11-18), which builds the original English Crystal.

It covers the current playable build, branch `claude/pokemon-menu-sprites-bcf65a` at `e7b26d7a5`. That branch includes every other line of work: `master` → `expand-move-ID` (= `dev`) → sprite converter → encounters/Pokégear → eccentric trader → menu sprites.

The changes come in three layers:

1. **pokecrystal16 `master`**: quality-of-life refactors (no gameplay change)
2. **pokecrystal16 16-bit index engine** (`expand-mon-ID` + `expand-move-ID`): no gameplay change on its own
3. **This hack's content**: new species, mechanics, NPCs and balance changes

> ⚠️ **Save compatibility:** saves from vanilla Crystal, or from builds made before the Pokédex flags moved to SRAM, do **not** load. Most changes made after that keep the save layout.

---

## Gameplay changes at a glance

| Area | Change |
|---|---|
| Pokémon | +398 species (Gen 3–5, #252–649); 649 in total |
| Types | New **Fairy** type with Gen 6 matchups |
| Moves | +6 Fairy moves; Charm, Sweet Kiss and Moonlight are now Fairy |
| Battle | **Physical/Special split** by move (Gen 4+); move category shown in battle and on the move screen |
| Battle | **Gen 5 experience formula** (scales with the level difference) |
| Battle | B in a wild battle jumps to RUN, and B again runs |
| Trainers | Every trainer Pokémon levelled to `floor(level^1.05)`, evolved and given moves to match |
| Gyms | Every gym leader has a Gen 3–5 Pokémon swapped in, plus one extra Pokémon |
| Wild | Gen 3–5 species in grass/water/fishing/trees, placed by map theme; legendaries are 1% endgame encounters |
| Pokégear | Map Card from the start; new **GEN** card picks which generation's wild Pokémon appear |
| Overworld | **Running Shoes** (hold B); **cut trees stay cut** |
| Starters | 15 starters (Kanto, Johto, Hoenn, Sinnoh, Unova) in Elm's Lab; a bonus pick for every win against Red |
| NPCs | Move Reminder (Pokémon Center 2F); New Bark Town Collector who buys Pokémon for tokens |
| Dance Theater | Two new Kimono Girls (Leafeon, Glaceon); HM03 needs all seven wins |
| Marts | Daily TM lineups at Goldenrod 5F, post-game TMs at Celadon 3F, themed TMs in 20 Poké Marts |
| Text | Mixed-case text everywhere ("Pokémon", "Potion"); choice of Normal, Narrow or Bold font |
| Graphics | Unique party menu icon for every species |
| Intro | Oak's speech and Wooper removed: set the clock, pick a name, start |

---

## 1. pokecrystal16 `master`: base cleanup

From AX6's and vulcandth's pokecrystal16. These are developer QoL changes, meant to play the same as vanilla.

- **Build:** version differences (Crystal 1.1, Australian, debug ROMs), the SHA1 compare target, CI and unused tools removed. One ROM, `pokecrystal.gbc`, plus an optional Virtual Console patch.
- **[1] Pic banks:** Pokémon pics no longer need fixed banks per species.
- **[2]** `PokemonPicPointers` and `UnownPicPointers` are separate.
- **[3]** Footprints stored normally instead of split.
- **[4]** Dummy items between and after the TMs/HMs removed.
- **[5]** Stone-evolution check buffer grows from 9 to 18 entries.
- **[6]** `EVOLVE_STAT` and `EVOLVE_ITEM` can be mixed on one species.
- **[7]** All of WRAM is cleared at boot, not only banks 0–1.
- **[8]** Move grammar table removed.
- **[9]** Fast saving.
- **[10]** Trainer data restructured so it can span banks.
- **[11]** Pokémon animations can use up to 255 tiles.
- **[12]** Wasted home-bank space freed.
- **[13]** Faster multiplication (`AddNTimes`).
- **[14]** Unused and debug files removed.
- **[15]** Animation-frame banks no longer tied to the National Dex number.
- **[16]** Better name handling.
- **[17]** Pokédex entry banks no longer tied to the species ID.
- **Bug fixes:** the Ditto assumption bug and some sprite/object bugs.

## 2. pokecrystal16: 16-bit species and move indexes

Lets the game hold more than 253 species and 255 moves. Each Pokémon/move has a 16-bit "index" and the game converts it to an 8-bit ID through a table saved in SRAM.

- Indirection-table macros and functions, plus WRAM/SRAM structures for the conversion tables
- ROM reorganized and unused parts removed to make room
- Base data, evolutions, learnsets, egg moves, pics, animations, names, palettes, cries, Pokédex entries and footprints all looked up by 16-bit index
- Trainer parties get a length byte and 16-bit species and moves; Battle Tower parties too
- `EGG` moved from 253 to `$FFFD`; dummy species constants removed
- Wild data, Pokédex, Hall of Fame, map scripts and Bill's PC (other boxes) use 16-bit IDs
- Move names, descriptions, attributes, animations, TM/HM lists and misc. move lists use 16-bit indexes
- Link trades/battles send and receive 16-bit indexes
- Garbage collection for the conversion tables; tables cleared on New Game
- `FarPlaceString` moved to the home bank

---

## 3. This hack's content

### 3.1 Gen 3–5 Pokémon (398 new species)

- National #252–649 added with **Gen 5 base stats and types**, **Black 2/White 2 learnsets** and egg moves. Generated by `tools/species_import/`.
- Moves that don't exist in Crystal are swapped for the closest Gen 2 move (`tools/species_import/move_substitutions.csv`).
- **Sprites:** converted from Emerald, FireRed/LeafGreen, HGSS and BW sprites by `tools/sprite_convert/`. Each sprite gets a body color plus an accent color, and faces and markings are kept. Shiny palettes included. Most new species have a single-frame (static) animation.
- **Cries:** Gen 3+ cries can't play on the Game Boy, so each new species reuses a vanilla cry with its own pitch and length.
- **Footprints:** blank placeholders for species after Celebi.
- **Pokédex:** entries, height/weight and categories for all new species (long categories shortened to fit). New and A–Z dex orders include them.
- **Judgment calls** (`tools/species_import/report.md`): base exp capped at 255, evolution methods and locations swapped for ones Crystal has, some held items dropped.
- **Not added:** abilities, natures and Gen 4+ items. Incense babies don't hatch from their parents. Legendaries are wild encounters, not events.
- **Engine changes this needed:**
  - Species tables moved to their own floating sections; base data, learnsets and egg moves get one sub-table per region (Hoenn, Sinnoh, Unova).
  - Pokémon palettes are copied into a WRAM buffer (`wMonPalBuffer`).
  - **Pokédex seen/caught flags moved to SRAM bank 5** (`sPokedexFlags`) since 649 × 2 bits don't fit in WRAM. Older saves are not compatible.
- **Party menu icons:** each species has its own 16×16 icon, shrunk from its front sprite (`tools/menu_icons/make_icons.py`). The ~40 shared vanilla icon shapes are gone. Eggs keep the vanilla egg icon. Used in the party menu, naming screen, Fly menu, trades and the Day Care.

### 3.2 Fairy type and moves

- **`FAIRY` type** (after Dark) with Gen 6 matchups: Fairy attacks are super effective on Fighting, Dragon and Dark, and not very effective on Fire, Poison and Steel. Fairy Pokémon resist Fighting, Bug and Dark, are weak to Poison and Steel, and are immune to Dragon.
- Every species #1–649 that is Fairy from Gen 6 on gets its Gen 6 typing (e.g. Clefairy, Togepi, Snubbull, Marill, Gardevoir; see `tools/species_import/fairy_report.md`).
- **Retyped to Fairy:** Charm, Sweet Kiss, Moonlight.
- **New moves** (Gen 6 power/accuracy/PP, closest Crystal effect, reused animation):

  | Move | Power | Acc | PP | Effect |
  |---|---|---|---|---|
  | Moonblast | 95 | 100 | 15 | 30% lower Sp. Atk |
  | Dazzling Gleam | 80 | 100 | 10 | — |
  | Play Rough | 90 | 90 | 10 | 10% lower Attack |
  | Draining Kiss | 50 | 100 | 10 | Drains HP |
  | Disarming Voice | 40 | — | 15 | Never misses |
  | Fairy Wind | 40 | 100 | 30 | — |

- Added to the level-up learnsets of species that learn them in ORAS.
- Pokédex type search includes Fairy. Hidden Power can't be Fairy. No held item boosts Fairy (Pink Bow and Polkadot Bow still boost Normal).
- **Time Capsule (Gen 1 trades):** Fairy becomes the Pokémon's other type (pure Fairy becomes Normal), so Clefairy, Jigglypuff and Mr. Mime can still go to Gen 1.

### 3.3 Battle mechanics

- **Physical/Special split:** each move has its own category (`data/moves/categories.asm`) instead of going by type. Used in damage calculation, Counter, Mirror Coat and the enemy AI.
- The battle move menu and the party move screen show the category (`phy` / `spc` / `sta`) where vanilla showed `TYPE/`.
- **Gen 5 experience formula:** `exp = floor(b·L/5 · ((2L+10)/(L+Lp+10))^2.5) + 1`, so beating higher-level Pokémon gives more and lower-level ones less. Trainer battles, traded Pokémon and Lucky Egg each give ×1.5. Capped at 65,535.
- **B in the battle menu:** in a wild battle you can run from, B moves the cursor to RUN; pressing B again runs. In trainer battles, link battles or when trapped, B does nothing.

### 3.4 Trainers

- **Gym leaders:** each one's first non-ace Pokémon is replaced with a Gen 3–5 Pokémon that fits the gym, and each gets one more Gen 3–5 Pokémon before their ace (e.g. Falkner: Starly and Taillow; Morty: Shuppet and Drifblim; Clair: Shelgon and Flygon). Full list: `tools/species_import/gym_teams.md`.
- **Level scaling:** every trainer Pokémon's level becomes `min(100, floor(level^1.05))`. Pokémon evolve if their new level allows it. Gym leaders, the Elite Four, Champion, Red, Blue, the rival and Rocket executives also evolve when the next stage is within 5 levels. Custom move sets pick up the level-up moves learned along the way. Full list: `tools/species_import/trainer_levels.md`.
- **Battle Tower** parties and texts updated for the new names and text style.

### 3.5 Wild Pokémon

- Gen 3–5 species are added to grass, surfing, fishing and Headbutt/Rock Smash tables. Each map has a theme (towers, caves, ice, forest, marsh, ranch, mountain, urban, ...) and a species only appears there if it fits by type, habitat or a short allow list (`tools/species_import/themes.py`). Each changed line ends in `; gen3-5 (was X)`.
- **Legendaries** are 1% encounters in the highest-level map that fits them.
- Levels, encounter rates and odds are unchanged from vanilla.
- **Pokégear GEN card:** a fifth Pokégear card picks the wild Pokémon set: **DEFAULT** (the mixed tables above) or **GEN 1** to **GEN 5** (only that generation's species). Options unlock at 1, 3, 5, 7 and 8 badges (Johto and Kanto both count). The choice is saved. Swarms are skipped in Gen modes. The Pokédex area map, phone callers, Oak's radio show, the Bug-Catching Contest and the roaming beasts still use the default tables.

### 3.6 Overworld and items

- **Running Shoes:** the Guide Gent in Cherrygrove gives Running Shoes instead of the Map Card. Hold B on foot to move at bike speed (the walking animation speeds up too). Saves that already did the tour get the shoes from him in his house.
- **Map Card from the start:** Mom's Pokégear already has the map.
- **Permanent Cut:** every cut tree (40 of them) stays cut, tracked by its own event flag. Cut grass still grows back.
- **Buy/sell quantity:** each press changes the quantity by one; holding a direction no longer auto-repeats.
- **TM shops:**
  - Goldenrod Dept. Store 5F: a different 14-TM lineup each day of the week (the elemental punches, Headbutt and Rock Smash plus nine daily specials; Saturday is the strongest). Headbutt and Rock Smash are sold from the start.
  - Celadon Dept. Store 3F: post-game TMs (Hyper Beam, Earthquake, Psychic, Thunder, Blizzard, Fire Blast, Shadow Ball, ...).
  - 20 Poké Marts across Johto and Kanto each sell two or three TMs that suit the town (Ecruteak ghost, Mahogany ice, Vermilion electric, ...).
  - Bug fix: the mart price buffer held 10 items while a mart list can hold 14.

### 3.7 New and changed NPCs and events

- **Elm's Lab:** the lab is wider and holds **15 starter balls**: Bulbasaur, Charmander, Squirtle, Chikorita, Cyndaquil, Totodile, Treecko, Torchic, Mudkip, Turtwig, Chimchar, Piplup, Snivy, Tepig, Oshawott. Pick any one as your starter.
- **Bonus starters from Red:** Red can be rematched in Silver Cave once beaten. Each win gives one pick of another starter from Elm's tables (level 5 with a Berry, sent to the PC if the party is full). The first win saves the game before the credits so the pick isn't lost.
- **Move Reminder:** a receptionist on every Pokémon Center 2F re-teaches, for free, any level-up move a Pokémon has forgotten or skipped (any move in its learnset at or below its level).
- **New Bark Town Collector:** a new house in New Bark Town. The eccentric collector buys Pokémon for **Collector Tokens** (up to 9,999). The offer is the species' value plus bonuses for level and happiness, doubled for shinies (`data/events/collector_values.asm`). Tokens buy items in three categories:
  - Held items: Leftovers, Lucky Egg, King's Rock, Scope Lens, Focus Band, type-boosting items, ...
  - Training: Rare Candy, PP Up, vitamins, Max Revive, Max Elixer
  - Special: Master Ball, evolution stones, Up-Grade, Dragon Scale, ...
- **Dance Theater (Ecruteak):** two new Kimono Girls, **Hana** (Leafeon) and **Yuki** (Glaceon), join the five vanilla ones so all seven Gen 1–4 eeveelutions appear. The Gentleman gives HM03 Surf only after all seven are beaten.

### 3.8 Text, fonts and menus

- **Mixed-case text:** all on-screen text is converted from ALL CAPS to Title Case ("POKéMON" → "Pokémon", "POTION" → "Potion", "THUNDERPUNCH" → "ThunderPunch") by `tools/text_case/convert.py`. Acronyms and status tags stay uppercase (TM, HP, PSN, ...). Covers names, items, moves, places, trainer classes, menus, dialogue, phone calls and credits.
- **Font option:** the Options menu's PRINT (Game Boy Printer brightness) entry is replaced with **Font**: Normal, Narrow or Bold (`tools/fonts/make_fonts.py`). It changes right away.
- **Menu Account removed:** the start menu's description box option is gone; the box is always off. The start menu is one tile wider.
- **Shortened intro:** after picking boy/girl, the game sets the clock and asks for your name. Oak's speech and the Wooper demonstration are gone.

### 3.9 Bug fixes made in this hack

- Hana and Yuki's parties were loading the Twins' teams.
- Mart price buffer overflow for lists longer than 10 items.

### 3.10 Temporary / debug

- ⚠️ **Route 27:** the ledge south of the Sandstorm House is removed for testing (commit `a3c0406d0`, marked DEBUG). Revert before a release.

---

## Developer tools added

| Tool | Purpose |
|---|---|
| `tools/sprite_convert/` | Convert Gen 3–5 battle sprites to Crystal's pic format |
| `tools/species_import/` | Import species data, Fairy typing, wild placement, Gen Select tables, gym teams, trainer level scaling, cut trees, move categories, ROM verification |
| `tools/menu_icons/make_icons.py` | Make a 16×16 menu icon for every species (hand-drawn overrides supported) |
| `tools/text_case/` | ALL CAPS → mixed-case text pass |
| `tools/fonts/make_fonts.py` | Build the Narrow and Bold fonts |
| `tools/collector_values.py` | Build the Collector's per-species token values |
| `tools/gen5_exp_table.py` | Build the Gen 5 experience lookup table |
