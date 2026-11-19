# Changes from vanilla Pokémon Crystal

This lists what is different from the base ROM: pret's [pokecrystal](https://github.com/pret/pokecrystal) disassembly at commit `95f3d3c09` (2025-11-18), which builds the original English Crystal.

It covers `master` at `d2702492a` (2026-11-19). That includes every other line of work: `master` → `expand-move-ID` (= `dev`) → sprite converter → encounters/Pokégear → eccentric trader → menu sprites → QoL pass → rival rewrite.

The changes come in three layers:

1. **pokecrystal16 `master`**: quality-of-life refactors (no gameplay change)
2. **pokecrystal16 16-bit index engine** (`expand-mon-ID` + `expand-move-ID`): no gameplay change on its own
3. **This hack's content**: new species, mechanics, NPCs and balance changes

> ⚠️ **Save compatibility:** saves from vanilla Crystal, or from builds made before the Pokédex flags moved to SRAM, do **not** load. The bigger bag and 24 PC boxes change the save layout again, so saves from before those commits are not recognised either (the title screen offers New Game). Most other changes keep the save layout.
>
> **Build flags:** most QoL changes sit behind `QOL_*` flags in `constants/qol_flags.asm`, all on by default. Turning one off (e.g. `make QOL_FLAGS="-DQOL_MORE_BOXES=0"`) builds that part as before.

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
| Moves | 57 moves use **Gen 8** power, accuracy and PP |
| Exp. | **All-party Exp. Share** (Gen 6 style), toggled with the Exp.Share item |
| Evolution | Trade evolutions happen on level-up (holding the item, or at level 37) |
| Legendaries | Suicune roams; uncaught legendaries respawn after the Elite Four; a locator NPC on every Center 2F |
| Wild | Blissey 5% in the grass on every route numbered a multiple of 3 |
| Storage | Bag pockets 30/16/30, START sorts a pocket; 24 PC boxes |
| TMs | Reusable |
| QoL | Faster Centers and saves, Repel re-use prompt, field poison stops at 1 HP, fewer phone calls, safer Yes/No defaults |
| Rival | Rewritten as a spoiled heir with a Team Rocket father; he trashes Elm's Lab and gets a Gible |
| Trainers | Every trainer Pokémon levelled to `floor(level^1.05)`, evolved and given moves to match |
| Gyms | Every gym leader has a Gen 3–5 Pokémon swapped in, plus one extra Pokémon |
| Wild | Gen 3–5 species in grass/water/fishing/trees, placed by map theme; legendaries are 1% endgame encounters |
| Pokégear | Map Card from the start; new **GEN** card picks which generation's wild Pokémon appear |
| Overworld | **Running Shoes** (hold B); **cut trees stay cut** |
| Starters | 15 starters (Kanto, Johto, Hoenn, Sinnoh, Unova) in Elm's Lab; a bonus pick for every win against Red |
| NPCs | Move Reminder/Deleter and legendary locator (Pokémon Center 2F); New Bark Town Collector who buys Pokémon for tokens |
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
- **Gen 8 move stats** (`QOL_MODERN_MOVES`): 57 moves use Sword/Shield power, accuracy and PP, e.g. Flamethrower/Thunderbolt/Ice Beam/Surf 90, Fire Blast/Blizzard/Thunder/Hydro Pump 110, Outrage 120, Toxic 90%. Effects and types are unchanged. Overrides live in `data/moves/modern_moves.asm`; `moves.asm` keeps the vanilla values.
- **All-party Exp. Share** (`QOL_EXP_SHARE_ALL`): Pokémon that battled share exp. as before; every other non-fainted party member gets half the full amount each, plus half stat exp. Using the Exp.Share from the bag turns it off or on; off means vanilla held-item behaviour.
- **Trade evolutions without trading** (`QOL_SOLO_TRADE_EVOS`): item trade evolutions happen on level-up while holding the item (the item is used up); itemless ones happen at level 37+. Everstone still blocks it; link trades work as before.

### 3.4 Trainers

- **Gym leaders:** each one's first non-ace Pokémon is replaced with a Gen 3–5 Pokémon that fits the gym, and each gets one more Gen 3–5 Pokémon before their ace (e.g. Falkner: Starly and Taillow; Morty: Shuppet and Drifblim; Clair: Shelgon and Flygon). Full list: `tools/species_import/gym_teams.md`.
- **Level scaling:** every trainer Pokémon's level becomes `min(100, floor(level^1.05))`. Pokémon evolve if their new level allows it. Gym leaders, the Elite Four, Champion, Red, Blue, the rival and Rocket executives also evolve when the next stage is within 5 levels. Custom move sets pick up the level-up moves learned along the way. Full list: `tools/species_import/trainer_levels.md`.
- **Battle Tower** parties and texts updated for the new names and text style.

### 3.5 Wild Pokémon

- Gen 3–5 species are added to grass, surfing, fishing and Headbutt/Rock Smash tables. Each map has a theme (towers, caves, ice, forest, marsh, ranch, mountain, urban, ...) and a species only appears there if it fits by type, habitat or a short allow list (`tools/species_import/themes.py`). Each changed line ends in `; gen3-5 (was X)`.
- **Legendaries** are 1% encounters in the highest-level map that fits them.
- Levels, encounter rates and odds are unchanged from vanilla.
- **Pokégear GEN card:** a fifth Pokégear card picks the wild Pokémon set: **DEFAULT** (the mixed tables above) or **GEN 1** to **GEN 5** (only that generation's species). Options unlock at 1, 3, 5, 7 and 8 badges (Johto and Kanto both count). The choice is saved. Swarms are skipped in Gen modes. The Pokédex area map, phone callers, Oak's radio show, the Bug-Catching Contest and the roaming beasts still use the default tables.
- **Blissey routes** (`BLISSEY_EVERY_THIRD_ROUTE`): on Routes 3, 6, 9, ... 45, each grass encounter has a 5% chance to be a Blissey at the rolled slot's level. Applies with DEFAULT and GEN 2 sets. Done in `ChooseWildEncounter`, so the Pokédex area map doesn't list it.
- **Roaming Suicune** (`QOL_ROAMING_SUICUNE`): in Tin Tower Suicune flees instead of battling and roams Johto at level 40 from Route 38. Eusine's lines are updated; the Rainbow Wing and Ho-Oh work as before.
- **Legendary respawns** (`QOL_RESPAWN_LEGENDARIES`): each Elite Four win brings back Lugia and Ho-Oh, and puts fainted roaming beasts back to roaming, unless that species is already caught.

### 3.6 Overworld and items

- **Running Shoes:** the Guide Gent in Cherrygrove gives Running Shoes instead of the Map Card. Hold B on foot to move at bike speed (the walking animation speeds up too). Saves that already did the tour get the shoes from him in his house.
- **Map Card from the start:** Mom's Pokégear already has the map.
- **Permanent Cut:** every cut tree (40 of them) stays cut, tracked by its own event flag. Cut grass still grows back.
- **Buy/sell quantity:** each press changes the quantity by one; holding a direction no longer auto-repeats. The buy picker tops out at what the player can afford (`QOL_MART_MAX_AFFORDABLE`).
- **Reusable TMs** (`QOL_REUSABLE_TMS`): teaching a TM doesn't use it up, the TM pocket shows no count, and marts sell at most one of each TM.
- **Bigger bag** (`QOL_BIGGER_BAG`): Items 30 (was 20), Balls 16 (was 12), Key Items 30 (was 25). PC item storage stays at 50.
- **Bag sort** (`QOL_BAG_SORT`): START sorts the Items, Balls or Key Items pocket by item ID.
- **24 PC boxes** (`QOL_MORE_BOXES`, was 14): needs 64 KB of SRAM (8 banks). mGBA handles it; real MBC3 hardware only has 4 RAM banks.
- **Repel re-use:** when a Repel wears off and the bag has another of the same kind, the game asks "Use another?".
- **Field poison** (`QOL_POISON_SURVIVE`): stops at 1 HP and cures itself (Gen 5 behaviour); it can no longer white the player out.
- **TM shops:**
  - Goldenrod Dept. Store 5F: a different 14-TM lineup each day of the week (the elemental punches, Headbutt and Rock Smash plus nine daily specials; Saturday is the strongest). Headbutt and Rock Smash are sold from the start.
  - Celadon Dept. Store 3F: post-game TMs (Hyper Beam, Earthquake, Psychic, Thunder, Blizzard, Fire Blast, Shadow Ball, ...).
  - 20 Poké Marts across Johto and Kanto each sell two or three TMs that suit the town (Ecruteak ghost, Mahogany ice, Vermilion electric, ...).
  - Bug fix: the mart price buffer held 10 items while a mart list can hold 14.

### 3.7 New and changed NPCs and events

- **Elm's Lab:** the lab is wider and holds **15 starter balls**: Bulbasaur, Charmander, Squirtle, Chikorita, Cyndaquil, Totodile, Treecko, Torchic, Mudkip, Turtwig, Chimchar, Piplup, Snivy, Tepig, Oshawott. Pick any one as your starter.
- **Bonus starters from Red:** Red can be rematched in Silver Cave once beaten. Each win gives one pick of another starter from Elm's tables (level 5 with a Berry, sent to the PC if the party is full). The first win saves the game before the credits so the pick isn't lost.
- **Rival:** rewritten as a smug nepo baby whose Team Rocket father gets him any Pokémon he wants. He doesn't steal a starter: none of the 15 were good enough, so he trashes Elm's Lab and his father gets him a Gible. Every rival scene, the lab officer, Elm's aide, the Rocket B2F grunt and the Dragon Shrine elder are rewritten to match.
- **Move Reminder:** a receptionist on every Pokémon Center 2F re-teaches, for free, any level-up move a Pokémon has forgotten or skipped (any move in its learnset at or below its level). With `QOL_CENTER_MOVE_DELETER` she opens with "Remember a move / Forget a move"; forgetting uses the Blackthorn Move Deleter's flow (he is unchanged).
- **Legendary locator** (`QOL_LEGENDARY_LOCATOR`): a gentleman behind the top-left counter of every Pokémon Center 2F says where each roaming legendary (Raikou, Entei, Suicune) was last seen.
- **New Bark Town Collector:** a new house in New Bark Town. The eccentric collector buys Pokémon for **Collector Tokens** (up to 9,999). The offer is `base + floor(level/20) + min(5, floor(max(0, happiness − 70)/37))`, doubled for shinies, so 140 at most (`data/events/collector_values.asm`). Tokens buy items in three categories:
  - Held items: Leftovers, Lucky Egg, King's Rock, Scope Lens, Focus Band, type-boosting items, ...
  - Training: Rare Candy (10 Tokens), PP Up and vitamins (8), Max Revive, Max Elixer
  - Special: Master Ball, evolution stones, Up-Grade, Dragon Scale, ...
  - Selling his items at a Mart pays at most 50 yen per Token they cost; buy prices are unchanged.
- **Dance Theater (Ecruteak):** two new Kimono Girls, **Hana** (Leafeon) and **Yuki** (Glaceon), join the five vanilla ones so all seven Gen 1–4 eeveelutions appear. The Gentleman gives HM03 Surf only after all seven are beaten.

### 3.8 Text, fonts and menus

- **Mixed-case text:** all on-screen text is converted from ALL CAPS to Title Case ("POKéMON" → "Pokémon", "POTION" → "Potion", "THUNDERPUNCH" → "ThunderPunch") by `tools/text_case/convert.py`. Acronyms and status tags stay uppercase (TM, HP, PSN, ...). Covers names, items, moves, places, trainer classes, menus, dialogue, phone calls and credits.
- **Font option:** the Options menu's PRINT (Game Boy Printer brightness) entry is replaced with **Font**: Normal, Narrow or Bold (`tools/fonts/make_fonts.py`). It changes right away.
- **Menu Account removed:** the start menu's description box option is gone; the box is always off. The start menu is one tile wider.
- **Shortened intro:** after picking boy/girl, the game sets the clock and asks for your name. Oak's speech and the Wooper demonstration are gone.

### 3.9 Pacing and prompts

- **Faster Pokémon Center** (`QOL_FAST_POKECENTER`): no time-of-day welcome, one box for healed + goodbye, script pauses removed, heal machine places balls every 10 frames (was 30). With `QOL_NURSE_TURN_AWAY` the player then turns away, so mashing A doesn't restart her dialogue.
- **Faster save** (`QOL_FAST_SAVE`): the game carries on while the save jingle plays.
- **Fewer phone calls** (`QOL_FEWER_PHONE_CALLS`): 25% call chance (was 50%) and at least an hour between calls. With `QOL_PHONE_REMATCH_MARKS` the Pokégear phone list shows "!" next to contacts with a rematch or gift waiting.
- **Safer Yes/No defaults:** at a level-up, "delete an older move?" and "stop learning?" open on No, so mashing A loops between them instead of skipping the new move. Shift mode's "Will <PLAYER> change Pokémon?" opens on No (`QOL_SHIFT_DEFAULT_NO`). TMs, the Move Tutor and the Move Reminder keep the vanilla defaults.

### 3.10 Bug fixes made in this hack

- Hana and Yuki's parties were loading the Twins' teams.
- Mart price buffer overflow for lists longer than 10 items.

### 3.11 Temporary / debug

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
