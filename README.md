# Johto Expanded

A Pokémon Crystal ROM hack built on [pokecrystal16](https://github.com/vulcandth/pokecrystal16), the 16-bit index
fork of pret's [pokecrystal](https://github.com/pret/pokecrystal) disassembly. It brings the 398 Gen 3–5 species
(#252–649, 649 in total) into Johto's wild areas, trainer teams and gyms, and adds the Fairy type with Gen 6
matchups and the Gen 4 physical/special split. It also uses the Gen 5 experience formula and rescales every
trainer's levels. New features include 15 starters from five regions, Running Shoes, cut trees that stay cut,
a Move Reminder, a Pokégear card that picks which generation's wild Pokémon appear, daily TM shops, a Collector
NPC who buys Pokémon for tokens and a rewritten rival. Text is in mixed case, with a choice of fonts.
See [CHANGES.md](CHANGES.md) for the full list.

## What's changed

The cliff notes. [CHANGES.md](CHANGES.md) has the details.

### Story & characters

- **Rival:** a smug Rocket executive's son whose Team Rocket father gets him any Pokémon he wants. None of the 15 starters were
  good enough, so he trashes Elm's Lab and his father gets him a Gible.
- **Elm's Lab:** 15 starters from Kanto, Johto, Hoenn, Sinnoh and Unova. Beat Red in Silver Cave for a bonus pick
  each time.
- **Dance Theater:** two new Kimono Girls (Leafeon, Glaceon), so all seven eeveelutions appear.
- **Legendaries:** Suicune roams Johto like Raikou and Entei; uncaught legendaries respawn after each Elite Four
  win; a gentleman on every Pokémon Center 2F says where the roamers were last seen.
- **Shorter intro:** set the clock, pick a name, start.

### Battle

- **Fairy type** with Gen 6 matchups, six new Fairy moves, and Charm, Sweet Kiss and Moonlight retyped.
- **Physical/Special split** per move, shown in the move menus.
- **Gen 5 experience formula** and **Gen 8 power, accuracy and PP** for 57 moves.
- **All-party Exp. Share** (Gen 6 style); use the Exp.Share item to toggle it.
- **Trade evolutions without trading:** level up holding the item, or reach level 37.

### Pokémon & trainers

- **649 species:** Gen 3–5 added, placed in the wild by map theme. Legendaries are rare endgame encounters.
- **Pokégear GEN card:** choose mixed wild Pokémon or a single generation.
- **Blissey:** 5% in the grass on every route numbered a multiple of 3.
- **Tougher trainers:** levels scaled to `floor(level^1.05)` with evolutions and moves to match; every gym leader
  gets Gen 3–5 Pokémon.

### Quality of life

| Area | Change |
| --- | --- |
| Movement | Running Shoes (hold B); cut trees stay cut |
| TMs | Reusable; daily TM lineups and themed TMs in Marts |
| Storage | Bag pockets 30/16/30, START sorts a pocket; 24 PC boxes |
| Pokémon Center | Faster healing; Move Reminder and Move Deleter on 2F |
| Saving | Doesn't wait for the save jingle |
| Phone | Fewer calls; "!" marks contacts with a rematch or gift waiting |
| Field | Repel re-use prompt; overworld poison stops at 1 HP |
| Prompts | Risky Yes/No prompts default to No |
| Text | Mixed case; Normal, Narrow or Bold font |
| Menus | A unique party icon for every species |

### Economy

- **New Bark Town Collector:** buys Pokémon for Collector Tokens and sells held items, Rare Candy, vitamins,
  evolution stones and a Master Ball for them. Selling his items at a Mart is capped, so Tokens can't be farmed
  into money.

Most quality-of-life changes sit behind `QOL_*` flags in `constants/qol_flags.asm`, all on by default.

## Status

**Work in progress.**

- Playable: _TODO: how far the game can be played (e.g. "through the 8th gym")_
- Known issues: _TODO: list known bugs_
- Saves from vanilla Crystal do **not** load in this hack, and nor do saves from builds before the bigger bag and
  24 PC boxes.

## Requirements

**No ROM is included in this repository.** You need your own legally obtained copy of Pokémon Crystal.

The source targets the English release, **Pokémon Crystal (UE) v1.0**, the same version pret's pokecrystal
reproduces. The build assembles the whole game from this source, so you don't need a base ROM file to run `make`.

## How to build

Follow the pret/pokecrystal setup in [INSTALL.md](INSTALL.md) for your OS. In short:

1. Install `make`, `gcc`, `git` and **[rgbds](https://rgbds.gbdev.io/install) 1.0.0** (the version in
   `.rgbds-version`).
2. Clone and build:

   ```bash
   git clone https://github.com/alex235324/johto-expanded
   cd johto-expanded
   make
   ```

3. The output is `pokecrystal.gbc`. It uses 64 KB of save RAM for the 24 PC boxes: mGBA and most emulators
   handle this, but real MBC3 hardware does not. To use a local rgbds instead of a global install, run
   `make RGBDS=rgbds-1.0.0/`.

Built ROMs (`*.gbc`) are gitignored. Please don't commit or share them.

## Feedback

Found a bug or have a suggestion? Please [open a GitHub Issue](https://github.com/alex235324/johto-expanded/issues)
and include:

- the build version (the commit hash, from `git rev-parse --short HEAD`)
- the emulator you used and its version (e.g. mGBA 0.10.x)
- what happened, what you expected and how to reproduce it

## Credits

- **[pret/pokecrystal](https://github.com/pret/pokecrystal)** and all its contributors, for the disassembly this is
  built on.
- **[pokecrystal16](https://github.com/vulcandth/pokecrystal16)** by [AX6](https://github.com/aaaaaa123456789) and
  [vulcandth](https://github.com/vulcandth), for the 16-bit species and move index engine and base cleanup.
- **[rgbds](https://github.com/gbdev/rgbds)**, the Game Boy assembler toolchain.
- **[PokeAPI](https://github.com/PokeAPI)**: species data comes from the
  [PokeAPI CSV dump](https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv), and Gen 3–5 battle sprites come
  from the [PokeAPI sprites repository](https://github.com/PokeAPI/sprites). Sprites are © Nintendo / Creatures Inc. /
  GAME FREAK inc. See [tools/sprite_convert/CREDITS.md](tools/sprite_convert/CREDITS.md) for per-sprite sources.
- _TODO: credit any other tutorials, tools or assets used._

## License

pokecrystal16 and pret's pokecrystal ship without a license file, and this project matches them: it adds no license
of its own. It is shared for education and fan use, on the same terms as the upstream projects.

## Legal

This is a non-commercial fan project. It is not affiliated with, endorsed or sponsored by Nintendo, Game Freak,
Creatures Inc. or The Pokémon Company. Pokémon and all related names and characters are trademarks of their
respective owners. This repository contains source code only. No copyrighted ROM data is distributed.
