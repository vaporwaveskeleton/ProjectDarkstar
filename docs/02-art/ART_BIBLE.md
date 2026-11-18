# DARKSTAR — Art Bible

**Doc ID:** ART-001 · **Version:** 1.0 · **Date:** 2026-11-12 · **Owner:** Art · **Companion:** `SPRITE_MODULARITY_SPEC.md` (the technical module system), `ASSET_PIPELINE.md` (how files are made)

---

## 1. The look in one paragraph

DARKSTAR is 2D pixel art at internal resolution **640×360** (integer-scaled, nearest-neighbour, no anti-aliasing on art), lit by **one moving light source you control: the player's lantern**. Everything else in the frame is either bone-pale reflectance, bioluminescent phosphor, or the absence of light. The enemy faction is a religion, so its art is **liturgical**: processions, symmetrical vestments, cathedral geometry, chitin polished like church wood. The entity is not a monster — it is an **eclipse with anatomy**, built from 20 modular 64×64 segments that look like a reliquary assembled by something that has never seen a body but has read about one.

Mood keywords: *gaslight, wet bone, brass, chalk, choir-black, wrong symmetry, tide, reliquary, frost on a window, something enormous that is also very close.*

## 2. What "Lovecraftian" means for our art (and what it does not)

| We use | We refuse |
|---|---|
| **Scale dread**: the entity is 5–12× the player and only partly on screen; shadows of it fall across unrelated scenes | Gore, viscera, splatter, chainsaw horror |
| **Wrong count**: 7 legs on a 6-legged silhouette; an eye where an ear should be; a face with the mouth on the wrong plane | Tentacle soup (every creature covered in identical random tentacles) |
| **The ordinary that is not ordinary**: a lamp that is also a lid; a window in a wall that should not have a wall; a chair where a geode was | Jump-scare faces, red-flash menace, "edgy" sigil tattoo art |
| **Architecture as horror**: non-Euclidean corridors implied by impossible perspective, arches that meet at angles that don't close | Brown-grey desaturated mush (unreadable in a thumbnail) |
| **Absence as horror**: whole areas have no light, no sound, no parallax; the Ledger Compass goes blank | Blood-red UI, skull iconography clichés |
| **Ceremonial stillness**: Choir units *pause* in prayer mid-fight; killing them interrupts a service | Mindless swarm bugs with no culture |
| **Bodies as relics**: Choir units look like saints' bones and vestments, not insects-in-a-hive | Insect-hive sci-fi hive-mind tropes |
| **The game's own costume slipping**: the arcade CRT frame peels to reveal something underneath | Breaking the fourth wall with text alone |

**Legibility rule (hard):** every sprite must be recognizable at **50% size in greyscale**. If the greyscale silhouette of a Choir unit is not distinguishable from another Choir unit in 2 frames of a thumbnail, the design is not done. This rule exists because the reality-warp layers deliberately distort shape and colour later — silhouette is the last line of readability.

## 3. Silhouette language per role (the shape grammar)

| Role | Shape language | Signature tell |
|---|---|---|
| **Vigil** (player) | Wedge + lantern globe. Small, round-topped, brass. Symmetric, honest, *simple*. | The lamp globe is the brightest pixel in the frame and pulses with the Lantern state |
| **Oubliette Grub** (worker) | Teardrop + 4 tiny limbs + a carried shard held overhead. Cute, pitiful. | Bows when it deposits a shard (a genuflection) |
| **Acolyte** (warrior) | Tall bell/vestment shape + a **censer turret** hanging/rotating off one shoulder | Turret swings 0.25 s behind the body — a visible tell |
| **Deacon of Lies** | Flat, 2D-paper-thin shape that is somehow *larger* than its outline | Its own shadow does not match its shape |
| **Grave-Tide Deceiver** | Elongated, hook-fronted, empty-handed (theft silhouette: long arms, no tool) | Steals by offering its own lantern |
| **The Penitent** (bonus) | Weeping hooded figure, translucent, halo of a broken ring | Only lit by *your* lantern; cannot be seen in the dark |
| **Choir Matron** (mini-boss) | Nave-shaped body (a walking cathedral apse) | Grubs birth from her doorway, not from her body |
| **Listener** | Blind, no eyes, huge ear-fans, body as concave dish | Freezes when you stop firing |
| **Herald** (elites) | The unit you are winning with, mirrored back at you (a knight shaped like your own ship) | Carries the exact tool you used most |
| **Nhael'Gharoth** (entity) | A **reliquary of stacked vertebrae around a hole**; near-black with phosphor veins; a face that is almost right | The face is built from 7 segments and is *one piece too many* |
| **Geode / planetoid** | Irregular chunk with a bone shell and a phosphor glass core; over-fire cracks glow | Broken geodes reveal *teeth-like* strata at Warp ≥ 1 |
| **Sepulchre** | An altar of fused vertebrae with a cold hollow at its centre | It "inhales" deposited shards (a 4-frame breath) |

## 4. Palette (32 colors, locked — the file of record is `assets/palettes/darkstar_palette.json`)

Five ramps of six, plus two specials. **Value separation between ramps is intentional**: each ramp spans a distinct luminance band so colourblind players and greyscale captures still read the game.

### VOID (deep blue-black: space, shadow, the entity's body)
| ID | Hex | Use |
|---|---|---|
| VOID-0 | `#0A0A12` | frame background, deepest shadow |
| VOID-1 | `#131428` | background layer 2 |
| VOID-2 | `#1D2040` | parallax, distant shapes |
| VOID-3 | `#2A3057` | cool mid shadow |
| VOID-4 | `#3C4574` | cool rim light on bone |
| VOID-5 | `#56608F` | far stars, cold highlight |

### BONE (off-white to grey: chitin, stone, reliquary, player hull accents)
| ID | Hex | Use |
|---|---|---|
| BONE-0 | `#3A3B44` | bone shadow |
| BONE-1 | `#5A5C67` | stone mid |
| BONE-2 | `#8A8C93` | stone light, Choir vestment mid |
| BONE-3 | `#B9B8AE` | bone light |
| BONE-4 | `#E4DFD1` | bone highlight |
| BONE-5 | `#F7F4E8` | specular, chalk UI text |

### CHOIR (bruise magenta/violet: the faction's identity colour)
| ID | Hex | Use |
|---|---|---|
| CHOIR-0 | `#2C1230` | Choir dark, vestment shadow |
| CHOIR-1 | `#4A1C4A` | Choir body base |
| CHOIR-2 | `#6E2A64` | Choir body light |
| CHOIR-3 | `#9A3E76` | Choir trim, ritual paint |
| CHOIR-4 | `#C55A86` | Choir bright tell (edges, wounds) |
| CHOIR-5 | `#EFA6B0` | pale flesh / wax highlight |

### PHOSPHOR (bioluminescent teal: Mourning Glass, Shroud, the entity's veins, the truth)
| ID | Hex | Use |
|---|---|---|
| PHOS-0 | `#0C2A2E` | glass shadow |
| PHOS-1 | `#14514F` | glass body |
| PHOS-2 | `#1E7C71` | glass light |
| PHOS-3 | `#34A88F` | shard core |
| PHOS-4 | `#62CFA8` | shard glow |
| PHOS-5 | `#A8F0D0` | shard hot core, warp bloom |

### GASLIGHT (amber/brass: **the player only**)
| ID | Hex | Use |
|---|---|---|
| GAS-0 | `#3A2410` | brass shadow, burnt |
| GAS-1 | `#6B4415` | brass dark |
| GAS-2 | `#A8701F` | brass mid |
| GAS-3 | `#D99A2E` | brass light, flame body |
| GAS-4 | `#F2C65C` | flame bright |
| GAS-5 | `#FFEFC0` | **lantern core — the brightest warm pixel in the game** |

### Specials (2)
| ID | Hex | Use |
|---|---|---|
| NULL | `#000000` | absolute hole (the entity's punctum, voided screen areas, CRT letterbox) |
| SIGNAL | `#FF4A57` | **danger tell only**: gaze cones, incoming hit telegraphs, entity hit flash. Never a body colour, never ambient. |

### Palette law (violations are bugs)
1. **GASLIGHT never appears on Choir or entity art**; **CHOIR never appears on player art.** The two factions are distinguishable by hue even when warped.
2. PHOSPHOR belongs to *truth-telling things*: ore, glass, the entity's veins, Shroud, and warp artefacts. It is the colour of reality showing through.
3. SIGNAL is used for at most **3 simultaneous objects on screen**. If a screen needs more danger tells, they must be shape-based (cones, chevrons), not colour-based.
4. Background never exceeds VOID-5 in luminance; nothing in the background may compete with GAS-3 and above.
5. Warp Tiers re-tune *how* ramps are used (hue-shift, inversion, dither), but palette law 1 and 3 survive every tier — including T5.
6. Total unique colours per sprite ≤ **10** (a 64×64 sprite using more than 10 colours reads as mud at 1×).

## 5. Lighting rules
- **One dynamic light:** the player's lantern. Radius 260 px up / 120 px down (Lantern state). Implemented as a light mask + additive bloom pass in `PHOS-4/GAS-4`, not as realistic lighting.
- Light falls off in **3 discrete bands**, not a gradient (hard-edged light: 100%, 65%, 30% → maps to ramp steps). Hard bands keep the pixel-art identity and are cheap.
- The entity is **unlit**: it does not receive the lantern's light. It occludes it. Where the entity overlaps light, the light *bends* (a 4 px rim of VOID-4 and NULL). This one rule does more horror work than any animation.
- Shroud growths emit their own PHOS-1/2 rim; the Sepulchre emits nothing until Quickening (12 segments), when it gains a slow PHOS-3 breath pulse.

## 6. Line, texture and shading
- **Outline:** one-pixel `VOID-0` silhouette outline on all gameplay sprites. No double outlines except for the entity (2 px, NULL outer) to make it feel heavier than the frame.
- **Anti-aliasing:** none on sprites. Optional 1-pixel "corner smoothing" only on the 4 corners of round shapes, done manually per kit.
- **Shading:** light from **upper-left** by default (all kits), 3 ramp steps + 1 specular. Dithering (2×2 Bayer) only for warp tiers and Shroud surfaces; never for player or Choir body (keeps them crisp).
- **Texture density budget:** a 64×64 sprite ≤ 900 non-transparent pixels of interior detail. Chalk-scratched surfaces use sparse 1-px speckle, not noise fills.
- **Animation:** 4-frame and 8-frame cycles at 8–12 fps for idle/breathe; 6 frames for death; 2-frame "breathe" for everything alive (this is a *rule*: living things always breathe, dead stone things never do — at Warp Tier ≥ 3, stone things start breathing, and that is the horror beat).

## 7. UI and VFX art rules
- UI is **chalk on slate**: BONE-5 text on VOID-1 panels with a 1 px BONE-1 keyline and a hand-drawn (not pixel-perfect) wobble of ±1 px every 2 s.
- The Act 0 "arcade cabinet" costume is a *separate art layer*: 1983-style vector-ish sprites, a bezel, 1UP type, scanlines. It must be peelable — under it, the real UI already exists.
- VFX are **physical and small**: sparks are 1 px chalk flecks, not glows; the Null-Iron Charge leaves a brass-lamp trail; entity hits throw PHOS-5 shards + NULL "holes" that close over 6 frames.
- **Every VFX must read with the game paused at 100% and in greyscale.**
- Reality-warp VFX rules: see `docs/01-design/REALITY_WARP_ESCALATION.md`; art-side, every warp effect must have a **T0-safe fallback asset** so accessibility modes can show a non-distorting equivalent.

## 8. Modular art doctrine (why 64×64 and why parts)
Full technical rules are in `SPRITE_MODULARITY_SPEC.md`. The three artistic reasons:
1. **The boss can be built in front of you, legibly**: the entity is exactly 20 modules, so the player can count the pieces of the countdown. Segment count is a *readable game state*, not a bar.
2. **The warp can mutate units at runtime** (add/swap limbs at T2+) without new art — horror is infinite, art cost is one kit.
3. **A small team ships**: one kit covers a unit family plus its variants, elites, and its warp-mutated forms.

## 9. Reference library (mood, not copy) — see `assets/reference/`
Painters/illustrators to study for *light and dread*, not to imitate: Caspar David Friedrich (back-to-void figures, tiny human scale), John Martin (impossible architecture and scale), Henry Fuseli (pressure of a face), Zdzisław Beksiński (bone-architecture, no outlines), John Carpenter + William Friedkin's *The Thing* (cold restraint, practical scale), Sympathetic/vaporwave-adjacent CRT nostalgia for the arcade costume. Games to study for *legibility under pressure*: Hotline Miami (silhouette), Return of the Obra Dinn (1-bit value structure), Dead Cells (readable FX layering), Pathologic 2 (a faction that behaves like a culture).
**Never traced, never re-sampled, never "inspired by" into a derivative asset. All DARKSTAR art is original and generated in-project.**

## 10. Definition of done for a sprite (art QA checklist)
1. Correct kit, correct module size (64×64 unless the spec's composite rules allow otherwise), transparent background, no stray pixels.
2. ≤ 10 colours, palette-law compliant, correct outline.
3. Silhouette readable at 50% greyscale, distinguishable from every sibling in its kit within 2 frames.
4. Sockets align to the kit's socket table (4 px overlap rule satisfied); mirrored/rotated variants behave.
5. Breathe/animation tags correct; loop first-last frame rule satisfied.
6. Light-from-upper-left shading; correct light banding; no unintended dither.
7. Entry exists in `assets/sprites/SPRITE_MANIFEST.csv` with path, size, frames, kit, palette, status.
8. Placed in-game at least once (an unplaced sprite is not done), and visible in a screenshot in `docs/02-art/screens/`.
