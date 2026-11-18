# DARKSTAR — Modular Sprite System Specification (64×64 base module)

**Doc ID:** ART-002 · **Version:** 1.0 · **Date:** 2026-11-12 · **Owner:** Art + Tech Art
**Source of truth for:** module grid, part kits, sockets, naming, atlases, animation tags, runtime mutation, Godot import settings.
**Related:** `ART_BIBLE.md` (look), `ASSET_PIPELINE.md` (how files are produced), `assets/sprites/SPRITE_MANIFEST.csv` (what exists).

---

## 1. The base module

| Rule | Value |
|---|---|
| **Base module canvas** | **64 × 64 px**, transparent background, PNG-24/32 (no colour profile) |
| **Grid** | 1 unit = 64 px. Composites are multiples: 64, 128, 192, 256, 320, 384, 448, **512**. Everything in the game is built from 64 px modules — including the entity, the geodes, the UI, the logo. |
| **Pivot** | Centre of the module = **(32, 32)**. All part offsets are measured from the composite's module-grid origin (top-left) or from a named socket. |
| **Safe area** | 60×60 inside the module (2 px padding). Outline pixels may occupy the padding but no *gameplay-visual* content may. |
| **Outline** | 1 px `VOID-0` on all kits; entity kit uses 2 px (NULL outer + VOID-0 inner) |
| **Max colours per sprite** | 10 |
| **Internal resolution** | 640×360. The player ship core occupies 48 px of its 64 px module → the ship is 1/7.5 of the screen height. The entity (20 segments, see §5) is 512×256 → it *cannot* fit the whole screen: it must be partly off-screen, which is the scale-dread rule |
| **Filtering** | Nearest. Never anti-aliased, never mipmapped (`texture_filter = Nearest`, `filter_clip_content = true`) |

## 2. Naming convention (mandatory, machine-checked)

```
ds_<kit>_<part>[_<variant>][_<role>][__f<frame>|_anim<name><frame>]
```

| Token | Meaning | Examples |
|---|---|---|
| `ds` | DARKSTAR asset prefix (never omit) | — |
| `<kit>` | the kit id (§4 list) | `vigil`, `grub`, `acolyte`, `entity`, `geode`, `sepulchre`, `fx`, `ui`, `compass`, `hub` |
| `<part>` | part id inside the kit | `core`, `armA`, `armB`, `eye`, `maw`, `censer`, `veil`, `hull` |
| `_<variant>` | optional 2-digit variant for palette/shape swap | `geode_core_03` |
| `__fNN` | animation frame (zero-padded) | `grub_core__f01` |
| `_anim<name>NN` | named tagged cycle frame | `acolyte_censer_animswing02` |

Composite (assembled) exports use `ds_<kit>_ASSEMBLED_<name>`, e.g. `ds_entity_ASSEMBLED_awake.png`.
Reference/mood files use `ref_` and live only in `assets/reference/`.
**Never** use spaces, camels, or non-ASCII in filenames. **Never** name an asset after the 1983 inspiration.

## 3. Kit folder layout (source of truth on disk)

```
assets/
  palettes/darkstar_palette.json          # the 32-colour source of truth (+ .gpl copy)
  sprites/
    source/     # per-kit working PNGs (one file per part, one file per kit sheet)
    generated/  # output of the pipeline (do not hand-edit; regenerate instead)
      <kit>/    # one folder per kit
    atlas/      # packed atlases consumed by the engine (1024x1024, 8 px gutter)
    SPRITE_MANIFEST.csv   # every asset: id, kit, part, w, h, frames, palette, status, path
  reference/    # mood studies (no shipped content)
tools/pixel-art/
  palette/      # palette json used by the generator
  src/          # the generator (core library + one script per kit)
  out/          # scratch output (git-ignored)
  run_all.ps1   # regenerates everything + contact sheets + manifest
```

Rule: `assets/sprites/generated/**` is **never edited by hand after it is used in-game** — fixes go into the generator script (deterministic, re-runnable) or into `assets/sprites/source/**` for hand-authored overlays, then re-export. This keeps the art set reproducible from a clean checkout.

## 4. Kits (the kit id table)

| Kit id | Unit / family | Module count | Canvas | Base parts (ids) |
|---|---|---:|---|---|
| `vigil` | player ship | 5 modules (composite 128×64 nominal, 64×64 core) | 64 core + 4 add-ons | `core`, `hull`, `bow`, `flankL`, `flankR`, `stern`, `lampGlobe`, `lampGlobeDim`, `wingUp`, `wingDark`, `cowl` |
| `grub` | Oubliette Grub (worker) | 1 | 64×64 | `core`, `armA`, `armB`, `armC`, `armD`, `shell`, `hood`, `shardCarry`, `genuflect` |
| `acolyte` | Acolyte / Censer Knight (warrior) | 2 | 64×128 | `core`, `veil`, `shoulderL`, `shoulderR`, `censer`, `censerChain`, `thurible`, `haloBroken`, `cowl` |
| `deacon` | Deacon of Lies | 1 | 64×64 | `core`, `paperSkin`, `falseVigil`, `falseGrub`, `shadowWrong` |
| `deceiver` | Grave-Tide Deceiver | 2 | 128×64 | `core`, `armLong`, `hook`, `offeringLamp`, `sleeve` |
| `penitent` | The Penitent (bonus) | 1 | 64×64 | `core`, `hood`, `tears`, `ringBroken`, `foldedHands` |
| `matron` | Choir Matron (mini-boss) | 6 | 192×192 | `apse`, `navel`, `doorway`, `pillar`, `rose`, `banner`, `grubBirth` |
| `listener` | The Listener | 1 | 64×128 | `core`, `dish`, `earFanL`, `earFanR`, `ribCage` |
| `herald` | Heralds (elites, 6 named, palette-swap + part-swap) | 3 | 128×128 | reuses `acolyte`/`vigil` parts + `mirror`, `crownWrong`, `toolCopy` |
| `geode` | geodes / planetoids / shrines | 4 (small) → 9 (large) | 64 / 128 / 192 | `core`, `cap`, `spur`, `strata`, `monolith`, `skullFace`, `coral`, `shrine`, `shroudVein` |
| `sepulchre` | build altar | 4 | 128×128 | `base`, `vertebraL`, `vertebraR`, `hollow`, `breathIn`, `sigil` |
| `entity` | **Nhael'Gharoth (the Dark Star)** | **20 segments** | **512×256 composite** (5×4 grid of 64 px modules, but each segment is drawn at 128×128 and the composite is 4×4 of those... see §5.2 for the exact build) | `seg01`…`seg20` + `facePlate`, `faceEyeL`, `faceEyeR`, `faceMaw`, `ribUpper`, `ribLower`, `veilWingL`, `veilWingR`, `tentacleCluster`, `punctum` |
| `shard` | Mourning Glass shards + charges | 0.25 module (16×16) + 1 module | 16 / 64 | `shardSmall`, `shardMed`, `shardLarge`, `chargeIdle`, `chargeTail` |
| `fx` | effects (hits, explosions, warp, chalk wards) | 1 each | 64 / 128 | `hitSpark`, `shardBurst`, `nullHole`, `chargeDetonate`, `wardPulse`, `surgelight`, `lanternFlicker`, `shroudGrow`, `warpRib`, `chalkCircle` |
| `ui` | HUD, icons, menus, arcade cabinet costume | 1 each | 64 / 128×64 | `compassFrame`, `chargePip`, `livesIcon`, `scoreDigits` (5×7 font sheet), `warpMeter`, `hourglass`, `codexBook`, `chalkDesk`, `cabinetBezel`, `cabinetTitle`, `titleLogo` (4×2 modules = 256×128) |
| `compass` | Ledger Compass markers | 0.25 (16×16) | 16 | `markPlayer`, `markGrub`, `markAcolyte`, `markGeode`, `markSepulchre`, `markEntity`, `markSeam`, `markLying` |
| `hub` | Ruins hub art (modular tiles) | 64 tiles | 64 tile grid | `floorTile`, `wallTile`, `archTile`, `pillarTile`, `windowTile`, `rubbleTile`, `treeTrunk`, `treeBranch`, `treeNodeLit`, `treeNodeDark`, `clockTile`, `deskTile`, `skyTileA`…`skyTileI` |

## 5. Assembly rules

### 5.1 How a composite is described (part descriptors)
Every kit has a JSON part descriptor (`assets/sprites/source/kits/<kit>.json`) listing, per variant: part file, offset (x, y), z-order, flip, rotation, palette override, socket parent, and whether the part is optional (mutation slot). Example shape:

```json
{ "kit": "acolyte", "variant": "base", "parts": [
  { "part": "veil",     "file": "ds_acolyte_veil.png",     "offset": [0, 48], "z": 0 },
  { "part": "core",     "file": "ds_acolyte_core.png",     "offset": [0,  0], "z": 2 },
  { "part": "haloBroken","file": "ds_acolyte_haloBroken.png","offset": [6,-10], "z": 1, "animate": "sway" },
  { "part": "censer",   "file": "ds_acolyte_censer.png",   "socket": "shoulderR", "z": 3, "pivot": [16,4], "rotate": "turret" }
]}
```
The engine (`ds_PartKit`, see `TECH_ARCHITECTURE.md`) renders the same descriptors the generator uses, so **the sprite that appears in the contact sheet is the sprite that appears in-game**.

### 5.2 Composite rules
- Composites must lie on the 64 px grid: offsets are multiples of 4 px (half-module) at minimum, ideally 8 or 16.
- **Overlap rule:** parts that connect must overlap by **≥ 4 px** at the joint so rotation/swap never leaves a seam. Rotating parts (the Acolyte's censer turret, the entity's segments) carry a 4 px "skirt" of matching colour under the joint.
- The entity: **20 segments**, each authored as a **128×128 art block** (built from 4 × 64 px sub-modules so it stays grid-honest), arranged as a **5-wide × 4-tall** block of 128 px slots = **640×512** nominal, with the outer 6 segments being veil/wings that can be torn off. Canonical layout (also the generator's `segNN` layout map):

```
row 0:  seg01 veilWingL   seg02 ribUpper   seg03 ribUpper   seg04 ribUpper    seg05 veilWingR
row 1:  seg06 tentacles    seg07 facePlate  seg08 faceEyeL   seg09 facePlate   seg10 faceEyeR    seg11 tentacles   <- face row: 7 face parts = one hit-region when awake
row 2:  seg12 ribLower     seg13 faceMaw    seg14 punctum    seg15 ribLower
row 3:  seg16 tentacles    seg17 tentacles  seg18 tentacles  seg19 tentacles   seg20 tentacles
```
  The **20 segments** are the *build counter* (Sinistar's 20 pieces → our 20 Segments). Face parts (`facePlate`, `faceEyeL/R`, `faceMaw`, plus 2 `facePlate` spares) = the 7-piece face that becomes **one hit region** once the entity is awake. Damage model: 13 Null-Iron hits to unmake (each hit removes/darkens one segment node; face region takes multi-hits).
- Geodes: 3 sizes — small (1 module), medium (2×2 = 128), large (3×3 = 192). All are assemblies of `core/cap/spur/strata` so a "mined" geode visibly loses outer modules as it takes damage.

### 5.3 Runtime mutation (the warp uses this)
At **Warp Tier ≥ 2**, the engine may add or swap optional kit parts to existing units (extra limbs, wrong eyes, added veil). Rules:
- Mutation only uses parts **already in the unit's kit** plus the shared `fx/warpRib`, `fx/shroudGrow`, `entity/tentacleCluster` crossover parts.
- Max **2 added parts** per unit; at least one anchor part (core or head) must stay unmodified so the unit stays recognizable (the "ordinary that is not ordinary" rule).
- Mutations must be **seeded and reproducible**; a mutation may be reversed by ward/deconsecrate.
- Every kit must therefore ship its mutation parts (they are not "bonus" art, they are core art).

## 6. Animation rules

| Cycle | Frames | fps | Applies to | Tag |
|---|---:|---:|---|---|
| breathe | 2 | 1.4 (slow) | every living unit (rule: living things always breathe) | `breathe` |
| crawl/procession | 6 | 8 | Grubs, Matron doorway, Penitent drift | `move` |
| swing (turret) | 4 | 6 | Acolyte censer (independent of body) | `animswing` |
| turn | 8 (45° steps) | — | only units that must not be engine-rotated (see below) | `turn` |
| hit | 2 | 12 | all, palette-swap flash to SIGNAL, not redraw | `hit` |
| death | 6 | 10 | all; death ends in `chalkDust` fx, not gore | `death` |
| deposit/genuflect | 4 | 5 | Grub (bows), Sepulchre (`breathIn`) | `piety` |

Engine-rotation policy: **most parts are engine-rotated** (Sprite2D rotation) instead of drawn at 8 angles, to keep the kit small. Drawn angle sets are only required where silhouette change matters (player's `bow` modules when the ship is hit from behind, the Acolyte's `censer` swing poses). Rule: if a part is engine-rotated, it must be drawn **bilaterally symmetric about its socket axis** and its 4 px skirt must be radially solid.
Loop rule: first and last frame must differ by ≤ 1 px of movement (no pops); cycles are tagged in `SpriteFrames` with loop flags.

## 7. Atlas, import and engine settings
- Atlas size **1024×1024**, 8 px gutter, tight-packed per kit; atlas manifest `assets/sprites/atlas/<kit>_atlas.png` + `.json`.
- Godot: `rendering/textures/canvas_textures/default_texture_filter = Nearest`; per-sprite `texture_filter = Inherit`; **no compression** on pixel atlases (`compress/mode = Lossless` at import, disable mipmaps, disable HDR); `fix_alpha_border = true` on all atlases (prevents 1 px bleeding on outline sprites).
- Import preset file: `godot/DarkStar/.import` conventions documented in `TECH_ARCHITECTURE.md` §10.
- Scaled display: internal 640×360 → integer scale to the window (2×, 3×). Never non-integer scale in the shipped default; the option exists behind an accessibility toggle with a warning.

## 8. Colour and palette locking per kit
Each kit has an allowed palette subset (enforced by the generator and by a lint script):

| Kit | Allowed ramps (max 10 colours) |
|---|---|
| `vigil` | GASLIGHT (4) + BONE (3) + VOID-0 outline |
| `grub` | CHOIR (3) + BONE (3) + VOID-0/1 outline |
| `acolyte` | CHOIR (4) + BONE (4) + VOID-0 |
| `deacon` | CHOIR (3) + BONE (2) + VOID-2 + SIGNAL (1 tell only) |
| `deceiver` | CHOIR (3) + BONE (3) + VOID-0 + GAS-1 **only as a stolen lantern prop** (explicit exception, documented) |
| `penitent` | BONE (4, alpha-stepped) + VOID-3 + GAS-4 (halo) |
| `matron` | CHOIR (4) + BONE (4) + PHOS-1 (rose window) |
| `listener` | BONE (3) + CHOIR (2) + VOID (2) |
| `herald` | as `acolyte`/`vigil` with hue-shifted variant map |
| `geode` | BONE (4) + VOID (2) + PHOSPHOR (3) + PHOS-5 core |
| `sepulchre` | BONE (3) + VOID (3) + PHOS-3 (Quickening only) |
| `entity` | VOID (5) + NULL + PHOSPHOR (4) + BONE-0 (rim only) + SIGNAL via `hit` palette-swap |
| `shard` | PHOSPHOR (4) + BONE-4 |
| `fx` | per-effect palette, ≤ 6 colours, must ship a greyscale-readable version |
| `ui` | BONE (3) + VOID (2) + GASLIGHT (2) + SIGNAL (tell) |
| `hub` | VOID (4) + BONE (4) + GASLIGHT (2) + PHOS-1 |

## 9. Deliverables per kit (definition of done)
1. Kit folder in `assets/sprites/generated/<kit>/` with every part + assembled preview PNG.
2. Kit descriptor JSON in `assets/sprites/source/kits/<kit>.json`.
3. Packed atlas + JSON in `assets/sprites/atlas/`.
4. Contact sheet in `docs/02-art/screens/kit_<kit>.png`.
5. Manifest rows in `assets/sprites/SPRITE_MANIFEST.csv` (one per part, one per unit assembled).
6. At least one in-game placement wired in the prototype, and one in-game screenshot.
7. Kit passes the greyscale-50% silhouette test (sibling-distinguishable within 2 frames).

## 10. What exists today (v0.1 pipeline pass)
Generated by `tools/pixel-art/run_all.ps1` (see `ASSET_PIPELINE.md`): `vigil`, `grub`, `acolyte`, `deceiver`, `penitent`, `geode`, `sepulchre`, `shard`, `entity` (20 segments), `fx`, `ui`, `compass`. Still to author (priority order): `matron`, `listener`, `deacon`, `herald`, `hub` tile set, `titleLogo` + font sheet polish, mutation parts. **Status is tracked per-row in the manifest, not in prose.**
