# sprite_convert

Local, free converter from official Gen 3–5 battle sprites (PokeAPI sprites
repo) to pokecrystal16's pic format. It's pure Python with Pillow and numpy and
no external services besides the two download endpoints. The target format is
documented in [FORMAT.md](FORMAT.md).

## Setup (once)

```bash
cd tools/sprite_convert
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

## Convert

```bash
.venv/bin/python convert.py mudkip munchlax snivy
```

- Names use PokeAPI spelling (`mr-mime`, `farfetchd`, `nidoran-f`). The
  converter looks up the dex number once at `pokeapi.co` and caches it in
  `source/species_ids.json`. To skip that lookup, pass `name:id`, e.g.
  `snivy:495`.
- Source game by species generation: #1–386 → Emerald, #387–493 →
  HeartGold/SoulSilver, #494–649 → Black/White. Override with
  `--game emerald|hgss|bw`.
- `--frames 2` duplicates the pose into kakuna's 2-frame layout, if you'd
  rather not rely on the zero-extra-frame case. `--no-outline` skips forcing
  the silhouette edge to black. `--refetch` ignores the download cache.

### From a local sprite set (no downloads)

```bash
.venv/bin/python convert.py --source-dir ~/romhacking/sprite_sources            # everything in manifest.csv
.venv/bin/python convert.py --source-dir ~/romhacking/sprite_sources treecko 446 # by name or dex number
```

The set needs a `manifest.csv` with `dex,name,generation,source_game,folder`
columns. Each folder holds `front.png`, `back.png` and `front_shiny.png`;
`back_shiny.png` is ignored because Crystal uses one shiny palette for front
and back. Names become pokecrystal folder names (`porygon-z` → `porygon_z`).
A sprite that fails is listed in `out/summary.csv` and the batch keeps going.
Batches of more than 12 get paged contact sheets in `out/contact_sheets/`.

## Output (all gitignored)

```
source/<name>/            front.png back.png shiny.png meta.json (cached downloads)
out/<name>/               front.png back.png shiny.pal anim.asm anim_idle.asm
out/_extras/<name>/       normal.pal (reference), preview.png (4x), report.json
out/contact_sheet.png     every Pokémon from the last run: sources | converted
CREDITS.md                (tracked) source game + URLs, updated on each run
```

`out/<name>/` has the same file set as a `gfx/pokemon/<name>/` folder. Normal
colors live inside front.png/back.png's palette, as in vanilla, so
`normal.pal` is only a readable copy and doesn't belong in `gfx/`.

## How the 4 colors are chosen

The method is rules for black and white, then a 2-means split for the middle
pair, all in OKLab space.

1. **Black**: a source color becomes black if it's very dark (L < 0.25), or
   dark (L < 0.5) and line-shaped (on average fewer than 1.3 same-colored
   neighbors), or mostly sitting on the silhouette edge. Gen 3–5 outline in
   dark *tinted* colors (Mudkip's navy, Snivy's dark green). Pure luminance
   clustering lumped those in with same-brightness body shading and erased the
   inner linework. The shape test keeps them apart.
2. **White**: only near-neutral highlights (L > 0.93, low chroma). Cream or
   yellow bellies stay a real color.
3. **Light/dark**: count-weighted 2-means on the remaining colors, with
   lightness weighted 2x because the four indices act as a shading ramp. Each
   cluster's palette color is its most-used original color, so you get an
   official color, not a blended average.
4. **Shiny**: the shiny sprite has the same pixel layout, so the shiny colors
   are the most-used shiny colors under the normal sprite's light and dark
   pixels. That keeps index 1 and 2 meaning the same body parts in both
   palettes. If the layouts don't match, the shiny is clustered on its own and
   the report says so.
5. **Back**: black and white use the same rules on the back sprite's own
   shapes; everything else snaps to the front's light/dark centers. Front and
   back must share one palette (see FORMAT.md, "Palettes").

Downscaling, used only when the sprite is bigger than 56 (front) or 48 (back),
works on the 4-class label map, not on RGB. Each output pixel takes the class
with the most coverage, but black wins at ≥34 % coverage, so 1px outlines
survive and no blended colors appear.
