# DARKSTAR — Asset Pipeline (Generators)

**Doc ID:** ASSET-003 · **Version:** 2.0 · **Date:** 2026-11-18 · **Owner:** Art (tech art) · **Status:** complete-draft. It describes the pipeline as it exists on disk on 2026-11-17, plus the producer-side contract for the parts that are planned.
**Upstream:** ART-001 (`ART_BIBLE.md`: look, palette law, typography, UI states), ART-002 (`SPRITE_MODULARITY_SPEC.md`: module grid, naming, sockets, atlas geometry) · **Downstream:** TECH-001 §6 (manifest consumption, `ManifestImporter`, `AtlasTable`), TECH-001 §10 (import presets)
> **Rev 2.0 (2026-11-18, GDD-001 D-13 and D-14): the game ships no image or audio files.** Every visual is generated at runtime (vector or shader, ART-001 §14) and every sound is synthesised in code (AUDIO-001 §11). **§12 below is the current pipeline.** §1–§11 describe the retired raster pass (PowerShell generator → PNG → manifest → atlas → import). They are kept because the PNGs are the *reference look* the generators reproduce, and the manifest is still a useful inventory of parts to build. Nothing in §1–§11 feeds the game any more; `tests/test_generated_assets_only.gd` enforces that. The PNGs are local-only reference: kept on disk, **not in git** (`.gitignore`) and **ignored by Godot** (`assets/sprites/.gdignore`), so they are never imported, exported or pushed. Only `SPRITE_MANIFEST.csv` is tracked, as the inventory of parts to build (owner decision 2026-11-18). To regenerate them locally, run `tools/pixel-art/run_all.ps1`.

**Boundary.** This doc owns *how art files are produced, named, linted, versioned and handed over*. TECH-001 §6 owns *what the engine does with them*. If this doc and TECH-001 disagree on a producer-side detail, this doc wins; on a consumption detail, TECH-001 wins (TECH-001 §0.1).

---

## 0. How to read this doc

| If you are… | Read |
|---|---|
| a pixel artist starting a kit | §1, §7, §10, then ART-001 §4, §10 and ART-002 §2–§6 |
| running the generator | §2, §5, §9 |
| writing engine code that reads art | §3, §4, §6 (then TECH-001 §6) |
| changing a colour or a kit's palette | §8, never the JSON directly without it |
| something broke | §9 |

Every statement below is tagged **[auto]** (a script does it today), **[manual]** (a person does it today) or **[planned]** (specified, not built).

---

## 1. The pipeline at a glance

```
assets/palettes/darkstar_palette.json  (32 colours, kit_locks, faction_exceptions)
          │
          ▼
tools/pixel-art/src/kits/kit_*.ps1  ── Build-Kit<Name> functions (procedural, seeded)
          │   run by tools/pixel-art/run_all.ps1
          ▼
 lint (name · ≤10 colours · kit lock · faction) ──► printed report (does not fail the run)
          │
          ├─► tools/pixel-art/out/<kit>/*.png              scratch copy
          ├─► assets/sprites/generated/<kit>/*.png         canonical, engine-consumed
          ├─► assets/sprites/SPRITE_MANIFEST.csv           one row per PNG (rewritten every run)
          └─► docs/02-art/screens/kit_<kit>.png            contact sheet for art QA

Hand-authored path (Aseprite, via the aseprite-ai-artist MCP):
assets/sprites/source/<kit>/*.aseprite ─► export PNG ─► assets/sprites/generated/<kit>/   [manual, §7]

Engine side (TECH-001 §6):
manifest + PNGs ─► atlas packer [planned] ─► assets/sprites/atlas/<kit>_atlas.png + .json
                ─► ManifestImporter [planned] ─► generated/sprite_table.gd (AtlasTable)
```

| Stage | Today | Owner |
|---|---|---|
| Procedural generation of 8 kits | **[auto]** `run_all.ps1` | tech art |
| Name, colour, kit-lock and faction lint | **[auto]**, report only, never fails the run | tech art |
| Manifest write | **[auto]**, full rewrite each run (§3.4) | tech art |
| Contact sheets | **[auto]** | tech art |
| Hand-drawn art (fonts, UI kit, polish) | **[manual]** in Aseprite (§7) | artist |
| Socket, outline, silhouette, breathe-loop QA | **[manual]** (ART-001 §10) | art lead |
| Atlas packing | **[planned]** (§6) | tech art |
| `ManifestImporter` → `generated/sprite_table.gd` | **[planned]** (TECH-001 §6.3) | engineering |
| CI palette lint (`palette_lint`) | **[planned]** (TECH-001 §1.4) | engineering |

Inventory on 2026-11-17: **83 manifest rows, 8 kits** (`vigil` 17, `sepulchre` 14, `shard` 14, `geode` 13, `acolyte` 10, `grub` 7, `deceiver` 4, `penitent` 4), all status `generated`. `assets/sprites/source/` and `assets/sprites/atlas/` are empty.

---

## 2. The generator (`tools/pixel-art/`)

### 2.1 Files
| File | Role |
|---|---|
| `run_all.ps1` | the driver: loads the libraries and kit scripts, maps kit ids to build functions, seeds the RNG per kit, lints, writes the PNGs, the manifest and the contact sheets |
| `src/ds_pixcore.ps1` | the core library: palette load (`DsLoadPalette` reads `assets/palettes/darkstar_palette.json`), palette-indexed canvas (`New-DS`, `Set-DS`, `Get-DS`), deterministic RNG (`DsSeed`, `DsRand`: Park–Miller, multiplier 48271), shapes (`DsRect`, `DsDisc`, `DsEllipse`, `DsLine`, `DsLimb`, `DsPoly`, `DsSpiral`), symmetry (`DsMirrorX`/`Y`, `DsRotate90`, `DsRadial`), composition (`DsBlit`, `DsTrim`), the 1 px silhouette outline (`DsSilhouetteOutline`), banded shading (`DsShade`, `DsShadeRadial`), texture (`DsSpeckle`, `DsDither`, `DsWarpNoise`), anatomy helpers (`DsEye`, `DsMandible`), I/O (`Save-DSPng`, `Load-DSPng` with nearest-palette snapping, `Scale-DSC`, `Save-DSThumbnail`, `Save-DSContactSheet`) |
| `src/ds_pixextras.ps1` | extra strokes and props: `DsArc`, the chalk-line family (`DsChalk`, `DsChalkCircle`, `DsChalkArc`), `DsBlob`, `DsVeins`, `DsShard`, `DsCrack`, and a prototype 5 × 7 bitmap font (`FONT5x7`, `DsText`, `New-DSTextCanvas`) |
| `src/kits/kit_vigil.ps1` | `Build-KitVigil` |
| `src/kits/kit_choir.ps1` | `Build-KitGrub`, `Build-KitAcolyte`, `Build-KitDeceiver`, `Build-KitPenitent` |
| `src/kits/kit_world.ps1` | `Build-KitGeode`, `Build-KitSepulchre`, `Build-KitShard` |
| `fix_comma_precedence.ps1`, `fix_nested_points.ps1` | one-off source rewrites kept for the record (§9, T-06). Not part of a normal run |
| `out/` | scratch copy of every generated PNG (git-ignored since 2026-11-17) |
| `backup_*`, `_verify_backup/`, `_hash_before.txt` | local safety copies from the fix scripts and a hash list from a byte-stability check; git-ignored |

### 2.2 How a kit is built
A build function returns a list of items. Each item is `@{ name; part; c; frames; note }`: `c` is a palette-indexed canvas (`-1` = transparent, `0–31` = palette index), `name` is the ART-002 §2 asset id. The driver handles everything after that: lint, save, manifest row, contact sheet. A kit script never writes files itself.

Colour is chosen **by palette index, never by RGB**. The PNG writer converts indices to the JSON's hex values at save time, so a palette hex change (§8) re-colours every kit on the next run with no script edits.

### 2.3 Determinism
- Each kit is seeded from its id: `DsSeed(|hash(kit) × 2654435761| mod 2·10⁹ + 7)`, so a kit renders byte-identically on every run, and regenerating one kit never changes another.
- **Caveat [important]:** the seed uses .NET `String.GetHashCode()`. That is stable under **Windows PowerShell 5.1** (.NET Framework), which produced the current files: the manifest's UTF-8 BOM is 5.1's signature. Under **PowerShell 7** (.NET Core), string hashes are randomised per process, so output would change on every run. **Run the pipeline with Windows PowerShell 5.1** until the seed uses a stable hash (§11, request A-03).

### 2.4 Commands
```
powershell -NoProfile -ExecutionPolicy Bypass -File tools\pixel-art\run_all.ps1                  # all kits
powershell -NoProfile -ExecutionPolicy Bypass -File tools\pixel-art\run_all.ps1 -Kits vigil,grub  # some kits
powershell -NoProfile -ExecutionPolicy Bypass -File tools\pixel-art\run_all.ps1 -NoSheet -Quiet   # no contact sheets, no per-kit lines
```
Output ends with `TOTAL <n> assets`, then either `LINT clean` or `LINT (<n>):` followed by one line per violation.
**Warning:** a partial run (`-Kits`) still rewrites the manifest with **only** the kits it built (§3.4). After a partial run, run the full set before committing.

The script's root path is hard-coded to `E:\GameDev\ProjectDarkstar` in `run_all.ps1` and in `ds_pixcore.ps1` (`$script:PALPATH`). On any other checkout path, edit both or apply request A-02 first.

---

## 3. The manifest (`assets/sprites/SPRITE_MANIFEST.csv`)

### 3.1 Format
CSV, comma-separated, every field double-quoted, header row, **UTF-8 with BOM** (written by `Export-Csv -Encoding UTF8` under PowerShell 5.1). Consumers must strip a leading BOM before reading the header (the first header cell otherwise reads `\uFEFF"id"`). Rows are sorted by `kit`, then `part`, then `id`. One row per PNG file: an animation frame is its own row.

### 3.2 Columns

| # | Column | Type | Meaning | Rules |
|---|---|---|---|---|
| 1 | `id` | string | the asset id, identical to the file's base name | ART-002 §2 grammar; unique; ASCII; `ds_` prefix |
| 2 | `kit` | string | kit id | one of ART-002 §4 / the `kit_locks` keys |
| 3 | `part` | string | part id inside the kit; `ASSEMBLED` for composite previews | camelCase allowed inside the token (`offeringLamp`) |
| 4 | `w` | int | width in px | multiple of 64 for modules and composites (ART-002 §1); props and frame strips may be smaller |
| 5 | `h` | int | height in px | as `w` |
| 6 | `frames` | int | number of frames in the cycle this file belongs to (each frame file carries the cycle length; `1` = still) | matches ART-002 §6 tag tables |
| 7 | `colours` | int | unique palette indices actually used | ≤ 10, except `*_ASSEMBLED_*` (ART-001 §4 law 6) |
| 8 | `palette_lock` | string | comma-separated palette indices of the kit's lock pool at generation time; `kit-default` if the kit has no lock | copied from `kit_locks`; it records history, so the lint uses the JSON, not this column |
| 9 | `path` | string | repo-relative path (= `res://` path, ruling R-08) | forward slashes; under `assets/sprites/` |
| 10 | `status` | enum | lifecycle state (§3.3) | |
| 11 | `note` | string | free text for humans: role, socket, cycle | the generator writes sockets as `socket=<name>`; a consumer may parse that key |

### 3.3 Status vocabulary
Today the generator writes only `generated`. The full lifecycle below is the contract for hand work and for TECH-001 §6:

| Status | Meaning | Engine behaviour (TECH-001 §6) |
|---|---|---|
| `planned` | row reserved, no file yet | missing-art placeholder, logged once |
| `wip` | file exists, not reviewed | loads in dev builds only |
| `generated` | produced by the generator, lint run | loads |
| `hand-authored` | drawn or edited in Aseprite (§7) | loads |
| `approved` | passed ART-001 §10 (and §11.9 / §12.10 where relevant) | loads; release builds require this for every placed asset ✱ |
| `cut` | kept for history, must not ship | excluded from atlases and the AtlasTable |

### 3.4 Who writes rows
- **[auto]** `run_all.ps1` rebuilds the whole manifest from the kits it ran. Rows it did not generate are **dropped**. Hand-authored rows therefore do not survive a generator run today.
- **[manual]** Until the merge fix (request A-01) lands, hand-authored rows live in a second file, `assets/sprites/SPRITE_MANIFEST_HAND.csv` (same columns, same rules). It is created with its first row, does not exist yet, and gets the same `keep` import (§4). The planned `ManifestImporter` reads both files and fails on a duplicate `id`.

---

## 4. Import rules (Godot side of the handover)

| Rule | Why | Source |
|---|---|---|
| The project root is the repo root, so `assets/...` = `res://assets/...` | one path everywhere; no `godot/DarkStar/` folder | ruling R-08, ART-002 §7 |
| **Every `.csv` under `assets/` imports with importer `keep`**, never `csv_translation` | Godot treats any `.csv` as a translation table by default. The manifest was being imported as one, emitting 10 `SPRITE_MANIFEST.<column>.translation` files and registering bogus translations | ruling R-19 |
| PNG sprites: `compress/mode = Lossless`, mipmaps off, HDR off, `process/fix_alpha_border = true`; filtering comes from the project default (Nearest) | pixel-perfect, no outline bleed | ART-002 §7; presets live in TECH-001 §10 |
| `.import` files **are** committed; `.godot/` and `*.translation` are not | import settings are source; caches are not | `.gitignore` |
| `docs/`, `tools/` carry `.gdignore` | Godot must never import the generator's scratch or the Aseprite build's own PNGs | TECH-001 §10 |

How to set `keep` on a CSV: in the editor, select the file → Import dock → *Import As: Keep File (No Import)* → Reimport. Or set `importer="keep"` in its `.import`.

---

## 5. Lints

### 5.1 What the generator lints today **[auto]**
| Code | Check | Exceptions |
|---|---|---|
| `NAME` | asset id starts with `ds_<kit>` | — |
| `COLOUR` | ≤ 10 unique colours | `*_ASSEMBLED_*` composites |
| `LOCK` | every colour is in the kit's `kit_locks` pool | composites (their parts were linted) |
| `FACTION` | GASLIGHT (indices 24–29) on a Choir or entity kit part only where `faction_exceptions.allowed` lists that part and index | the three salvaged-lantern parts (ART-001 §4, ruling R-06) |
| `FACTION` (composite) | a Choir composite may carry only GASLIGHT that some exception part is allowed | — |
| `FACTION` (GAS-5) | index 29 never on any Choir or entity asset, composites included | none, ever |
| `FACTION` (player) | CHOIR (indices 12–17) never on a `vigil` asset | none |

Choir and entity kits for the faction rules: `grub acolyte deceiver penitent matron listener deacon herald entity`.

### 5.2 Limits
- The lint **prints**. It does not set an exit code, so nothing stops a dirty run from being committed. Read the last lines of the output before committing (request A-04 makes it fail).
- Not linted: the full ART-002 §2 grammar (only the prefix), sockets and the 4 px overlap, outline integrity, the ART-001 §6 900-pixel detail budget, breathe-loop first/last frame, greyscale readability. These are manual ART-001 §10 checks.
- The `palette_lint` CI step in TECH-001 §1.4 is the planned build-time version of §5.1 over the manifest. Until it exists, this generator lint is the only enforcement.

---

## 6. Export conventions and atlases

### 6.1 Files
- PNG, 32-bit RGBA, transparent background, no colour profile, no metadata. Every opaque pixel is an exact palette hex (the generator guarantees this; Aseprite exports must keep it, §7).
- Animation: one PNG per frame, named `…__fNN` (generic frames) or `…_anim<name>NN` (tagged cycles), zero-padded from `00` (ART-002 §2, §6).
- Composite previews: `ds_<kit>_ASSEMBLED_<name>`. They are for QA and the store page, not runtime assembly (runtime composites are built from parts, ART-002 §5).
- Fonts and the UI kit (ART-001 §11.8, §12.5): glyph sheets and 9-slice sources under kit `ui`, ids `ds_ui_font<Face>`, `ds_ui_button_<state>`, `ds_ui_icon_<name>` and so on.

### 6.2 Atlas packing **[planned]**
Contract for the packer the engine will consume (TECH-001 §6.3):
- One atlas per kit, `assets/sprites/atlas/<kit>_atlas.png`, **1024 × 1024**, 8 px gutter, tight-packed, no rotation of sprites (ART-002 §7).
- A JSON sidecar `<kit>_atlas.json`: `{ "kit": "<kit>", "palette_version": "<x.y>", "size": [1024,1024], "regions": { "<id>": { "x":0, "y":0, "w":64, "h":64 } } }`. Every key in `regions` is a manifest `id`.
- A kit that overflows one atlas splits into `<kit>_atlas_0`, `_1` … in manifest order. Splitting a kit is a warning to the art lead (the kit is too big), not an error.
- Rows with `status = cut` are never packed.

---

## 7. Hand-authored art: Aseprite and the `aseprite-ai-artist` MCP

### 7.1 Setup
- Aseprite is a licensed local install at `tools/aseprite/` (the executable, its `data/` folder and the CLI helper `gen.exe`). It is **not in git** (`.gitignore`). Each artist installs their own licensed copy.
- `tools/aseprite/ai-artist/` holds the project's agent rules (`AGENTS.md`) and the MCP registration for VS Code (`.vscode/mcp.json`, which runs the `@pebbly/aseprite-ai-artist` server through `npx`).

### 7.2 Live vs headless
| Mode | Draws into | Use when | Rule |
|---|---|---|---|
| **live** (default) | the Aseprite window open on the artist's machine | an artist is present and reviewing | never fall back to editing `.aseprite`/`.png` files on disk while a live window is the target: the artist would not see the change and their next save would overwrite it |
| **headless** | an in-memory batch Aseprite | batch jobs with no window, e.g. exporting tagged frames | nothing reaches disk until an explicit save or export; save before finishing |

Session rules (from `AGENTS.md`, binding): `preflight` first and stop if not ready; `sprite_info` before the first edit (layers, frames and palette come from the document); batch operations into one `draw` call; `look` at the result before calling anything done; keep the palette (snap to the document palette, ask before widening); `validate` before declaring done.

### 7.3 Document conventions **[manual]**
- Colour mode **Indexed**, palette loaded from `darkstar_palette.json` (32 entries in index order 0–31, so index N is the same colour in Aseprite and in the generator). Until the `.gpl` export exists (request A-05), build the palette from the JSON's `index` list.
- Canvas sizes per ART-002 §1 (64 × 64 modules; composites in multiples of 64). Fonts per ART-001 §11.2 cell grids.
- Layers: `outline`, `body`, `shade`, `detail`, plus `socket_<name>` guide layers (hidden, never exported).
- Tags = ART-002 §6 cycle tags (`breathe`, `move`, `animswing`, `turn`, `hit`, `death`, `piety`), so frame exports name themselves.
- Save to `assets/sprites/source/<kit>/<id>.aseprite`. Export PNGs to `assets/sprites/generated/<kit>/` and add rows to `SPRITE_MANIFEST_HAND.csv` with status `hand-authored` (§3.4). If a hand-authored file shares an id with a generator output, the generator will overwrite it on its next run: pick a new id or move the asset out of the generator (remove its item from the kit script).

---

## 8. Palette versioning

The palette file of record is `assets/palettes/darkstar_palette.json`.

| Field | Rule |
|---|---|
| `index` (32 colours) | **locked** (ART-001 §4). Changing a hex value is a palette version bump, needs an art-lead sign-off, and re-runs every kit |
| `ramps`, `specials` | derived views of `index`; edit together with it |
| `kit_locks` | a kit's colour **pool**. Widening is allowed with a `lock_history` entry explaining which existing art needed it. Narrowing requires a full regeneration and a clean lint first |
| `faction_exceptions` | changes only with a **ruling** recorded in TECH-001 §11.2 and ART-001 §4. Today: three salvaged-lantern parts; GAS-5 never |
| `version`, `date` | bump `version` (minor for lock/exception changes, major for an `index` change) and `date` on every edit |
| `lock_history` | append-only; one entry per version with the reason |

Current: **v1.2 (2026-11-17)** — applied by the main session under owner-delegated rulings R-06/R-09:
1. `ui` pool: add VOID-3, BONE-0, BONE-1, GAS-4, PHOS-3, PHOS-4, all required by ART-001 §12; keep SIGNAL for HUD danger tells only.
2. `herald` pool: GAS-0..GAS-3 **removed**. Heralds mirror the Vigil's silhouette, not its colour.

---

## 9. Troubleshooting

| ID | Symptom | Cause | Fix |
|---|---|---|---|
| T-01 | `*.translation` files appear next to `SPRITE_MANIFEST.csv`; odd keys show up as translations | the CSV was imported as a translation table | set the import to `keep` (§4); delete the `.translation` files |
| T-02 | Code reading the manifest finds no `id` column | UTF-8 BOM before the first header | strip `\uFEFF` before parsing (§3.1) |
| T-03 | Regenerated art differs on every run | run under PowerShell 7 (randomised string hashes) | run with Windows PowerShell 5.1 (§2.3) until A-03 |
| T-04 | `Cannot find path 'E:\GameDev\...'` | hard-coded root in `run_all.ps1` and `ds_pixcore.ps1` | edit both paths, or apply A-02 |
| T-05 | A kit listed in `run_all.ps1` produces nothing, with no error | the driver skips kits whose `Build-Kit*` function does not exist (`entity fx ui compass hub matron listener deacon` today) | write the build function in `src/kits/`; the silent skip is request A-06 |
| T-06 | Geometry silently wrong in a new kit script (arrays of the wrong length) | in this PowerShell, `@(x, x+4)` parses as array concatenation, not two elements | parenthesise every computed element: `@(x, (x+4))`; flatten nested point lists. History: `fix_comma_precedence.ps1`, `fix_nested_points.ps1` |
| T-07 | Hand-authored rows vanished from the manifest | `run_all.ps1` rewrites the manifest from scratch (§3.4) | keep hand rows in `SPRITE_MANIFEST_HAND.csv` until A-01 |
| T-08 | Text drawn with `DsText` shows a vertical bar where spaces should be; letters vary in width | the prototype `FONT5x7` space glyph contains lit pixels and some glyphs are 6 px wide | do not ship `DsText` output; the Cabinet face (ART-001 §11.2) replaces it |
| T-09 | A lint line appears but the run "succeeded" | the lint never fails the run (§5.2) | read the `LINT` block before committing; A-04 |
| T-10 | `tools/pixel-art/out/` doubles every PNG in git | was tracked | **fixed 2026-11-17**: git-ignored and untracked (A-07) |

---

## 10. Adding a kit end to end

1. **Ids.** Pick the kit id (ART-002 §4) and part ids. Check the name against the ART-002 §2 grammar and the GDD-001 §19 glossary.
2. **Palette pool.** If `kit_locks` has no entry for the kit, propose one (§8) with a `lock_history` line. Choir and entity kits get no GASLIGHT.
3. **Generator route (procedural kits).** Write `Build-Kit<Name>` in the right `src/kits/kit_*.ps1`, returning `@{ name; part; c; frames; note }` items. Register it in `$BUILDS` in `run_all.ps1`. Run `-Kits <kit>` while iterating, then the full set.
4. **Aseprite route (hand-drawn kits: fonts, UI, polish).** Follow §7.3. Export to `generated/<kit>/` and add rows to `SPRITE_MANIFEST_HAND.csv`.
5. **Lint.** `LINT clean`, or every remaining line justified in the PR description.
6. **QA.** ART-001 §10 checklist on the contact sheet `docs/02-art/screens/kit_<kit>.png`; for fonts ART-001 §11.9; for UI ART-001 §12.10.
7. **Import.** Open the editor or run `--headless --import`. Check that the PNG imports use the §4 flags and that no `.translation` files appeared.
8. **Hand-off.** Status → `approved` once QA passes. The engine side (TECH-001 §6) places it; an unplaced sprite is not done (ART-001 §10.8).

---

## 11. Requests to other owners

| ID | To | Request |
|---|---|---|
| A-01 | tech art | `run_all.ps1`: merge into the manifest instead of rewriting; preserve rows whose status ≠ `generated` and rows of kits not in this run |
| A-02 | tech art | derive the root path from `$PSScriptRoot` in `run_all.ps1` and `ds_pixcore.ps1` |
| A-03 | tech art | replace `String.GetHashCode()` in the per-kit seed with a stable hash (e.g. FNV-1a over the kit id), then regenerate once and record the new hashes |
| A-04 | tech art | exit non-zero when the lint reports anything, with a `-AllowLint` switch for exploration |
| A-05 | tech art | export the palette as `assets/palettes/darkstar_palette.gpl` (index order 0–31) for Aseprite |
| A-06 | tech art | warn, not skip silently, when a `$BUILDS` entry has no function |
| A-07 | main session | **done 2026-11-17**: `tools/pixel-art/out/` git-ignored and untracked |
| A-08 | main session | **done 2026-11-17**: `SPRITE_MANIFEST.csv.import` set to `keep`; stray `.translation` files deleted (ruling R-19). **Superseded 2026-11-18:** the whole folder is Godot-ignored, so the manifest is not imported at all |
| A-09 | owner (delegated) | **done 2026-11-17**: palette JSON v1.2 — `ui` pool widened; `herald` loses GAS-0..3 (Heralds are Choir elites, law 1) |
| A-10 | engineering | build `palette_lint` (TECH-001 §1.4) over the manifest with the §5.1 rules and a failing exit code |

## 12. The current pipeline: generators (D-13, D-14)

| Kind | Where | What it produces | Status |
|---|---|---|---|
| Palette | `core/ui/pal.gd` (`Pal`), checked against `assets/palettes/darkstar_palette.json` by a test | the 32 colours as constants; the JSON stays the file of record | built |
| Vector parts (Act 0 costume) | `features/cabinet/sim/*.gd` (each layer's `_draw`), `features/cabinet/maw_view.gd` | the Vigil, geodes, glass, Grubs, Acolytes, the Sepulchre, the Dark Star, VFX, the maw and the true body inside it | built |
| Vector parts (Act 1+) | `core/gfx/parts/<kit>_<part>.gd` | parametric parts per ART-002 kit, with sockets and the ART-001 §14.4 tier ladder | planned |
| Shader parts | `shaders/parts/*.gdshader` | SDF bodies, flesh, veins, glass, Shroud; output quantised to the palette | planned |
| Post | `shaders/crt.gdshader` (built); WarpComposer passes (TECH-001 §5.1) | costume, tear, desaturation, tier distortion | partly built |
| Type | `core/ui/pixel_text.gd` (Cabinet face, built); Ledger and Litany glyph data (planned) | all game text | partly built |
| Sound | `core/audio/sfx_synth.gd` + `autoload/audio_service.gd` (built: arcade cues, chant bed); music sequencer, voice and soundscape synthesis (planned, AUDIO-001 §11) | every sound | partly built |

**Adding a part:**
1. Write the generator class with ART-002's id and sockets.
2. Take colours only from its kit pool in `Pal`.
3. Make it deterministic from `seed`.
4. Give it a T0 costume form and a tier sweep (ART-001 §14.4).
5. Add a render test (ART-001 §14.7).

The raster PNG with the same id, if one exists, is the visual target.

**What must never happen:** a `Texture2D`, image, font or audio file referenced from `features/`, `scenes/`, `core/`, `autoload/` or `data/`. The test above fails the build if it does. `assets/sprites/` carries a `.gdignore`, so Godot never imports or exports it; `assets/reference/` is not in git (TECH-001 §10).
