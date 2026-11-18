# DARKSTAR — Art Bible

**Doc ID:** ART-001 · **Version:** 1.2 · **Date:** 2026-11-18 · **Owner:** Art · **Status:** complete-draft (§11 typography and §12 UI states are specified; no glyph or UI-kit art is drawn yet) · **Companion:** `SPRITE_MODULARITY_SPEC.md` (ART-002, the technical module system), `ASSET_PIPELINE.md` (ASSET-003, how files are made)

**Rev 1.2 (2026-11-18, GDD-001 D-13): every image is generated in code — vector geometry or shaders. No sprite, texture or font files ship. §14 is the generation doctrine; §1–§13 still define the look.**

Rev 1.1 (2026-11-17, owner-delegated rulings R-02, R-06, R-09): palette law 1 gains its documented exception (§4); new §11 Typography; new §12 UI states and components. Earlier sections are unchanged in substance.

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
6. Total unique colours per sprite ≤ **10** (a 64×64 sprite using more than 10 colours reads as mud at 1×). Exception: `*_ASSEMBLED_*` composite previews may exceed it, because they combine parts that were each linted on their own (ASSET-003 §5).

**Law 1 exception — the salvaged lanterns (ruling R-06, 2026-11-17).** Exactly three Choir parts may carry GASLIGHT, and the palette file lists them by name in `faction_exceptions` (the lint enforces the list, ASSET-003 §5):

| Part | GASLIGHT allowed | What it is in the fiction |
|---|---|---|
| `ds_deceiver_offeringLamp` | GAS-0, GAS-1, GAS-2, GAS-3 | a dead Lampkeeper's lantern carried as an offering; the Deceiver baits you with the one colour you trust |
| `ds_acolyte_haloBroken` | GAS-3 | a lantern's brass ring hammered into a halo: a counterfeit sanctity made of salvage |
| `ds_penitent_ringBroken` | GAS-4 | the cracked ring the Penitent still wears; the strongest visual hint that the Penitent was once one of you (NARR-001) |

These are **trophies, not light sources**. No Choir or entity part may ever carry **GAS-5** (index 29, the lantern core): nothing in the Choir has ever *lit* a lantern, and the lint fails the build if one appears. Any further exception is a new ruling and a new `faction_exceptions` row, never a quiet palette edit. The other direction of law 1 has no exception: CHOIR never appears on player art.

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

> D-13: every "sprite" is now a generator output. These checks apply to what the generator draws; §14.7 adds the generator-specific ones.
1. Correct kit, correct module size (64×64 unless the spec's composite rules allow otherwise), transparent background, no stray pixels.
2. ≤ 10 colours, palette-law compliant, correct outline.
3. Silhouette readable at 50% greyscale, distinguishable from every sibling in its kit within 2 frames.
4. Sockets align to the kit's socket table (4 px overlap rule satisfied); mirrored/rotated variants behave.
5. Breathe/animation tags correct; loop first-last frame rule satisfied.
6. Light-from-upper-left shading; correct light banding; no unintended dither.
7. Entry exists in `assets/sprites/SPRITE_MANIFEST.csv` with path, size, frames, kit, palette, status.
8. Placed in-game at least once (an unplaced sprite is not done), and visible in a screenshot in `docs/02-art/screens/`.

---

## 11. Typography (ruling R-02, 2026-11-17)

Status: **Cabinet face built in code** (`core/ui/pixel_text.gd`, 2026-11-18); **Ledger and Litany specified, not coded.** Until they exist as glyph data, the build uses Godot's fallback font at a provisional size (TECH-001 §11 Q-T02, UI-001 §9). Everything here is the glyph spec the glyph data must match.

### 11.1 Laws (violations are bugs, like palette law)
1. **Every face is drawn on the pixel grid** at 1× and shipped as a bitmap. No vector fonts, no hinting, no anti-aliasing, no synthetic bold or italic, no sub-pixel positioning. Glyph origins snap to whole pixels.
2. **Only integer scales.** The 200 % text setting (GDD-001 §10, SYS-001 §9) draws every glyph at exactly ×2, nearest-neighbour. A 1.5× or "fit to box" scale is forbidden. Because it is an exact ×2, large text stays pixel-perfect and needs no second set of glyphs.
3. **Three faces, three jobs, never mixed in one line.** Ledger is the voice of the instrument (UI, HUD, Codex). Litany is the voice of things larger than you (the entity, titles). Cabinet is the Act 0 costume and appears nowhere after the peel.
4. **Text is drawn in two colours at most**: fill plus one outline or shadow colour. The fill always comes from BONE or (for the player's own readouts) GASLIGHT. SIGNAL is never a text colour (§12.1).
5. **Every glyph reads at 1× in greyscale** on VOID-0, VOID-1 and the T3 warp palette. Proof is a test sheet (§11.9), not an opinion.

### 11.2 The three faces

| | **Ledger** (UI and body) | **Litany** (display and entity) | **Cabinet** (Act 0 arcade costume) |
|---|---|---|---|
| Character | chalk lettering on slate: upright, slightly narrow, honest | carved into stone: tall capitals with notched serifs, chiselled weight | a 1983 cabinet's character ROM: blocky, monospaced, cheerful |
| Case | upper and lower case | **capitals only** (entity lines are ALL CAPS, AUDIO-001 §4.2) | capitals only |
| Cell (w × h) | 8 × 12 | 14 × 20 | 6 × 8 (5 × 7 glyph + 1 px tracking column and baseline row) |
| Cap height | 7 px | 16 px | 7 px |
| x-height | 5 px | — | — |
| Ascender / descender | ascenders = cap height (7); descenders 2 px | descenders none; Q's tail sits in the 2 px below the baseline | none |
| Stroke | 1 px everywhere | 2 px verticals, 1 px horizontals (chisel contrast); serifs are 1 px notches, not slabs | 1 px |
| Width | proportional: `i l ! .` 1–2 px, most lowercase 4–5 px, `m w M W` 7 px; **digits tabular at 5 px** so HUD counters never jitter | proportional, 8–12 px; `I` 4 px; `M W` 14 px | monospaced: every glyph exactly 5 px wide |
| Tracking | 1 px | 2 px | 1 px (built into the cell) |
| Word space | 3 px | 6 px | 6 px (one cell) |
| Line height | 12 px (24 at 200 %) | 22 px (44 at 200 %) | 8 px (16 at 200 %) |
| Glyph-set ids (ART-002 §2) | `ds_ui_fontLedger`, `ds_ui_fontLedgerGlitch` | `ds_ui_fontLitany`, `ds_ui_fontLitanyGlitch` | `ds_ui_fontCabinet` |

**Ledger vertical layout inside its 12 px cell** (row 0 at the top): rows 0–1 are reserved headroom (above-cap marks, should a language with accents ever be added — L10N-001 §7); rows 2–8 hold cap height (baseline under row 8); rows 4–8 are the x-height band; rows 9–10 hold descenders; row 11 is the line gap. The 12 px cell keeps that headroom so a future extension never changes line height.

**Cabinet** normalises the existing `FONT5x7` table in `tools/pixel-art/src/ds_pixextras.ps1`. That table is a prototype: several glyphs are 6 px wide and the space glyph contains lit pixels (ASSET-003 §9). The drawn face must be strictly 5 × 7.

### 11.3 Kerning and spacing
- Ledger: the default is 1 px tracking. A small kerning table of **at most 16 pairs** may remove 1 px, never more: `LT LV LY TA Ta Te To Ty VA Va Vo YA Ya Yo r. r,` and similar diagonal-against-open pairs. Kerning may never make two glyphs touch. Digits never kern (tabular).
- Litany: hand-spaced as a word, not a string. Pairs with diagonals (`AV AW LT TA VA WA YA`) close by up to 2 px, and touching is still forbidden. Entity lines are short enough that each line in the shipped set gets a visual check (§11.9).
- Cabinet: no kerning. Monospace is the costume.

### 11.4 Colour roles

| Use | Face | Fill | Outline / shadow | Where |
|---|---|---|---|---|
| Menu and panel text | Ledger | BONE-5 | none (the panel is the contrast) | UI-001 screens |
| Secondary / hint text | Ledger | BONE-2 | none | hints, descriptions |
| Disabled text | Ledger | BONE-1 | none | §12.2 |
| HUD text over gameplay | Ledger | BONE-5 | 1 px VOID-0 outline, 8-neighbour | Ledger Compass labels, counters |
| The player's own readouts (Charges count, Ember gained) | Ledger | GAS-4 | 1 px VOID-0 outline | HUD only; the player's colour |
| "Your progress is safe" and other truth statements | Ledger | PHOS-4 | none | error and recovery screens (§12.2, palette law 2) |
| Screen titles | Litany | BONE-4 | 1 px VOID-0 drop shadow, offset (+1, +1) | menu headers |
| **The entity's lines** | Litany | BONE-5 | 1 px NULL outline, 8-neighbour, on a NULL band (§11.5) | AUDIO-001 §4.2 big type |
| Act 0 score, 1UP, INSERT CREDIT | Cabinet | BONE-5; `1UP` and the player's score in GAS-4 | none (the CRT layer adds scanlines) | the cabinet costume only |
| Codex marginalia (Ilse Marrow's hand, Iteration 2+) | Ledger | BONE-3 | none | Codex pages (NARR-001) |

### 11.5 The entity's big type (built for the thumbnail)
The entity's lines are the most screenshotted text in the game, so the layout is fixed and compositional, not decorative. It refines AUDIO-001 §4.2 (timing stays there; this is the drawing).

| Rule | Value |
|---|---|
| Face and colour | Litany, BONE-5 fill, 1 px NULL outline |
| Band | a full-width **NULL band** behind the line, line height + 8 px top and bottom (38 px at 1×). The band guarantees contrast against any warp palette and reads as a hole torn in the frame |
| Position | centred horizontally; band centre at **y = 120 of 360**, the upper third, so the line never covers the Vigil (centre of view) or the HUD strips. If the Vigil is in the upper third, the band moves to y = 240 |
| Length | 1 line preferred, 2 lines maximum, ≤ 5 words (AUDIO-001 §4) |
| Width | maximum 560 px (40 px margins). Overflow order: break at a word; then tighten tracking 2 → 1 px; then use 2 lines. **Never scale down.** `en.po` context notes carry this limit (L10N-001 §3) |
| Thumbnail test | the line must be readable when the frame is shrunk to 160 × 90 (a 25 % store or social thumbnail). At 1× a 16 px cap becomes 4 px, which is the floor; at 200 % text it is comfortable |
| Never | animated letters, per-letter colour, SIGNAL, gradients, glow. The horror is the hard cut and the silence before it (GDD-001 §12) |

### 11.6 Coverage (English only)

The game ships in English only (L10N-001 §1, owner decision 2026-11-17). Other scripts and accented Latin are deferred; if a language is added later, its coverage is specified here at that time.

| Face | Required coverage |
|---|---|
| Ledger | printable ASCII (95); typographic `‘ ’ “ ” – — …`; arrows `← → ↑ ↓`; `× •` |
| Litany | `A–Z 0–9 . , ! ? ' – …` |
| Cabinet | `A–Z 0–9 - . : ! / ' % ©` |

### 11.7 How the warp corrupts text
WARP-001 owns *when* text lies (§4.2 "Glyph" deviation class and tell family; §4.4 Steady Ledger disables glyph corruption). This section owns *how it is drawn*:
1. Corruption always operates on the **displayed, laid-out string**, glyph by glyph, never on the text key, and never by re-ordering letters.
2. A corrupted glyph is replaced by a glyph from that face's **glitch set** (`*Glitch` sheets): 12 drawn variants per face (mirrored, rotated 90°, half-erased, chalk-smeared, ink-blotted, doubled stroke). **It is never replaced by another real letter.** That prevents accidental words, including offensive ones, and keeps the value readable. That is the Glyph-class promise.
3. Corruption never changes a glyph's advance width, so lines do not reflow and anchors do not move (SYS-001 §9: warp may hide an element, never displace one).
4. Photosensitivity mode: corruption is static. A glyph may be wrong, but it never flickers.

### 11.8 Delivery format
Each face ships as **glyph data in code** (D-13, §14.5): one bitmap grid per glyph, plus a character map, drawn rect by rect at integer scale like `core/ui/pixel_text.gd` (the Cabinet face, built). Colour roles are applied at draw time. No PNG glyph sheets and no font files. The glitch set (§11.7) is glyph data too.

### 11.9 Typography QA (a face is done when)
1. Every required glyph exists on the grid and matches §11.2's metrics.
2. The **test sheet** renders: an English pangram set; every entity line from AUDIO-001 §4 in Litany; every `en.po` string in Ledger; and the glitch set. It renders on VOID-0, VOID-1, the T3 palette and in 50 % greyscale, at 1× and 2×.
3. No two glyphs touch at default tracking, including kerned pairs.
4. Tabular digits verified: a counter ticking 0–9999 never shifts its neighbours.
5. The thumbnail test of §11.5 passes for the longest shipped entity line.

---

## 12. UI states and components (ruling R-09, 2026-11-17)

Status: **specified; partly implemented** in `data/ui/darkstar_theme.tres` with placeholder geometry (UI-001 §5). No UI-kit art is drawn yet.

### 12.1 Colour principles for UI
- **The cursor is the lamp.** Focus and selection use GASLIGHT because the focused control is where the player's agency is. Palette law 1 ("GASLIGHT is the player's") is satisfied, not bent: the player's light is literally on the control.
- **SIGNAL never appears in menus.** It is reserved for gameplay danger and capped at 3 objects on screen (§4 law 3). A menu error is not danger.
- **PHOSPHOR tells the truth.** Statements of fact the player must be able to trust ("Your progress is safe", the Steady Ledger clock) use PHOS-4 (§4 law 2).
- **Colour is never the only channel.** Every state also changes shape: an outline, an icon or an offset.

### 12.2 State table (exact palette IDs)

| State | Fill | Keyline | Text | Shape cue | Motion | Sound (AUDIO-001 §6.2) |
|---|---|---|---|---|---|---|
| **idle** | VOID-1 | 1 px BONE-1 | BONE-5 | — | chalk wobble on the keyline (§12.3) | — |
| **hover** (mouse) | VOID-2 | 1 px BONE-3 | BONE-5 | — | none | I07 brass tick |
| **focus** (keys or pad) | as idle or hover | as idle or hover | BONE-5 | **focus ring** (§12.4) plus a 4 × 6 GAS-4 lamp caret 3 px left of the label | the ring is steady (no wobble) | I07 |
| **pressed** | VOID-3 | 1 px BONE-5 | BONE-5 | **GAS-2** 1 px inner underline; label offset 1 px down | 2 frames, then returns | I06 confirm (chalk tick) |
| **selected** (toggle on, current tab, chosen card) | VOID-2 | 1 px BONE-4 | BONE-5 | chalk check mark (BONE-5, 7 × 6) plus a 2 px **GAS-3** underline | none | — |
| **disabled** | VOID-0 | 1 px BONE-0 | BONE-1 | the label keeps its text; never hidden | none | none, and input is ignored |
| **busy / loading** | as idle | as idle | BONE-5 | the label's trailing slot shows a 3-dot chalk ellipsis (BONE-3) | ellipsis cycles 3 frames at 3 fps; static `…` under reduced motion | none |
| **error** | VOID-1 | **double** keyline: 1 px BONE-3, 1 px gap, 1 px BONE-3 | BONE-5 | **chalk-strike icon** (8 × 8, two crossing chalk strokes, BONE-5) before the message; the reassurance line below in **PHOS-4** | none | I06 back (chalk erase) |
| **cooldown** | VOID-2 base | as idle | BONE-5 tabular digits (seconds left) | **GAS-2** fill sweeps bottom-to-top over the VOID-2 base as time passes; empty = ready | ready state: keyline steps to GAS-4 for 2 frames; under photosensitivity, a steady BONE-5 keyline instead | — |

Rules:
- Disabled controls are skipped by focus **unless** the reason matters to the player. Then they stay focusable and show the reason in a hint line ("Unlocks in Iteration 2"). A player must never wonder why a button does nothing.
- Destructive actions (Abandon Run, delete a slot) use the chalk-strike icon next to their label, are never coloured red, and their confirmation defaults to the safe choice (UI-001 §3).
- Hover and focus can coexist; focus always wins visually (the ring is drawn last).

### 12.3 The chalk wobble (refines §7)
- Applies to **panel and button keylines only**. Never to text, never to the focus ring (low-vision players track the ring), and never to HUD elements during gameplay.
- Drawn as two alternate keyline frames (the second offsets 1 px on one or two edge segments, never the corners), swapped every 2 s. It is a frame swap, not a per-pixel jitter.
- Reduced motion: off. Photosensitivity: off.

### 12.4 Focus ring geometry
- 2 px **GAS-3**, drawn **outside** the keyline with a 1 px gap (the ring's outer edge sits 3 px beyond the control's rect).
- Corners notched: the corner pixel of each side is omitted, giving a chalk-drawn corner rather than a machined one.
- Drawn on the overlay layer, so scroll containers and panels never clip it.
- Reaching the edge of a list never hides the ring: the scroll follows focus (UI-001 `FitScrollContainer`).

### 12.5 Components on the module language
The UI uses a **4 px sub-grid** of the 64 px module (16 steps per module). Every component dimension below is a multiple of 4 and is built from 9-slice sources named per ART-002 §2.

| Component | Size at 1× | Construction | Source ids |
|---|---|---|---|
| Button | height **24 px**; minimum width 64 px (one module); 10 px horizontal padding; label in Ledger | 9-slice from a 24 × 24 source, 4 px corners | `ds_ui_button_idle`, `_hover`, `_pressed`, `_disabled`, `_selected` |
| Panel | content margin 8 px; title row 28 px (Litany 16 px + padding) | 9-slice 16 × 16, 4 px corners, BONE-1 keyline | `ds_ui_panel_slate` |
| Dim overlay | full screen | VOID-0 at 85 % opacity (the only translucent fill in the UI) | engine-drawn |
| Choice card (Run Sigil, Relic, Pact, Codex tile) | **128 × 192** (2 × 3 modules) | 64 × 64 icon slot centred in the top 80 px; title (Ledger, 1 line) at y 88; body (Ledger BONE-2, ≤ 3 lines) at y 104; cost or rarity strip, 16 px, at the bottom | `ds_ui_card_frame`, `ds_ui_card_frameRare` |
| Progress bar | 6 px tall, any width in multiples of 4 | BONE-1 keyline; the fill is **PHOS-3** for truth readouts (Unravel progress, segments remaining) or **GAS-3** for player resources | `ds_ui_bar_frame` |
| Charge pips ("lantern magazine", GDD-001 §8.3) | each pip 12 × 16; 2 px gap; up to 13 | a glass lamp: brass cage (GAS-2) holding a glass body. **Full** = PHOS-3 glass + GAS-4 wick; **empty** = VOID-2 glass + unlit wick; **lost in flight** = the pip shatters (3 frames, BONE-4 flecks) | `ds_ui_pip_charge` |
| Composure wick (GDD-001 §10) | 64 × 16 | an oil-lamp wick whose flame height is the value; never a bar | `ds_ui_wick_composure` |
| Ledger Compass frame | 64 × 64 (one module) | brass bezel, VOID-1 face, chalk tick marks | kit `compass` |
| Toggle (settings rows) | 24 px row; the switch is 24 × 12 | a chalk switch: left = off (BONE-1 knob), right = on (GAS-3 knob + check) | `ds_ui_toggle` |

### 12.6 Icon language
- 16 × 16 icons (8 × 8 inline variants), drawn as **1 px chalk strokes in BONE-5** on transparency. Icons are chalk, not brass.
- Every icon is paired with a text label, except input glyphs and the Charge pip.
- Core set (v1): confirm, back, settings, Codex (open book), Lantern Tree (sapling in a lantern), Pact (chalk hand), Relic (reliquary box), Run Sigil (wax seal), lock, chalk-strike (error), save (lamp in a box), loading (three dots), Steady Ledger (open eye over a ruled line), photosensitivity (sun with a bar), text size (`Aa`), language (speech mark). Ids: `ds_ui_icon_<name>`.
- Input glyphs: keyboard and mouse and gamepad sets at 16 × 16, BONE-5 on VOID-2 keycaps, swapped live by `InputModeTracker` (UI-001 §4). Steam Input glyph art may replace the gamepad set where Steam provides it.

### 12.7 The Act 0 cabinet costume vs the real UI
- The costume is a **separate CanvasLayer above the real UI** (ART-001 §7): the bezel (`ds_ui_cabinetBezel`), scanlines, Cabinet-face text, 1UP and score.
- **The real UI is complete underneath and works with the costume removed.** Nothing functional may exist only in the costume.
- Costume palette: VOID-0 field, BONE-5 type, GAS-4 for the player's score and 1UP, PHOS-4 for "vector" outlines. No CHOIR, no SIGNAL.
- **The peel** (A0-3, GDD-001 §6.1): the costume layer falls away in pieces along the bezel's seams, revealing the chalk UI that was always there. This is a staged reveal and one of the game's signature clips. Under reduced motion it is a 1-frame cut with the same final state.
- `INSERT CREDIT` blinks with a 1 s period (0.5 s on, 0.5 s off). Under photosensitivity it is steady.

### 12.8 Steady Ledger, visually (WARP-001 §4.4)
- While Steady Ledger is on, a 8 × 8 **open-eye-over-a-rule** icon (BONE-3) sits at the inner corner of the HUD's top strip. The player can always see that the honest HUD is active (WARP-001 §4.7: accessibility state never lies).
- The numeric run-clock that replaces the Hourglass vignette is Ledger tabular digits in **PHOS-4**.
- Eaten elements leave their empty chalk frame (BONE-1 keyline, no content). The frame is never removed.
- No glyph corruption, no migration, no mirroring (§11.7).

### 12.9 Reduced motion and photosensitivity variants
| Effect | Default | Reduced motion | Photosensitivity |
|---|---|---|---|
| Screen transitions | 150–300 ms fade (UI-001 §4) | instant cut | fade allowed (no flash) |
| Chalk wobble | on | off | off |
| Busy ellipsis | 3-frame cycle | static `…` | 3-frame cycle (not a flash) |
| Cooldown ready flash | 2-frame GAS-4 keyline | 2-frame GAS-4 keyline | steady BONE-5 keyline |
| `INSERT CREDIT` blink | 1 s period | steady | steady |
| Charge pip shatter | 3 frames | 1 frame (final state) | 3 frames, no bright flash |
| Glyph corruption | per WARP-001 | per WARP-001 | static, never flickers |

Hard rule shared with GDD-001 §10: **no variant removes information.** Every replaced effect keeps its meaning through a steady visual. No UI element may flash more than 3 times in any one second in any mode.

### 12.10 UI art definition of done
1. 9-slice sources on the 4 px sub-grid, all §12.2 states drawn, every colour a palette entry from this section.
2. Readable at 1× and 2× text, in 50 % greyscale, on VOID-0 and in a T3 palette capture.
3. Focus ring visible on every focusable component and never clipped.
4. Each state shows a shape cue as well as its colour change.
5. Manifest rows exist (ASSET-003 §3) and the theme references the sheets (UI-001).

## 13. Narrative art beats (requested by NARR-001, 2026-11-17)

Story facts that only work if the art carries them. Each is a single frame or prop, not a new kit.

| Beat | Requirement | Source |
|---|---|---|
| Sable's ring | Sable Vane's ring (a Lampkeeper's lantern band, R-06 salvaged-lantern family) is visible in exactly one frame of the Unmaking Rehearsal's beat 2 (WARP-001 §6.2), never framed as a reveal | NARR-001 §5, §14 Q-07 |
| Sable's chalk in Act 4 | the Chalk Desk's chalk is drawn in the Vigil's GASLIGHT ramp (GAS-2…GAS-4, never GAS-5) from Act 4 on — the contract-writer and the Lampkeeper write in the same colour | NARR-001 §5 |
| The maker's plate | Theodora Lune's maker's plate is visible on the Cabinet's back panel from Hard Unmaking beat 5 (Lattice); legible in the Cabinet face (§11), one line, no explanation | NARR-001 §5, §9 |
| The honour roll | the Act 0 high-score screen uses the Cabinet face; from Hard Unmaking 3 it lists `T.L. — 0 WARD 0 SURGE` beside the top score | LOOP-001 §11.6, UI-001 §1 |
| Sable's hand | Sable's whole hand is shown once, at Hard Unmaking beat 5 (Lattice) — still never the face | NARR-001 §5.6 |
| Stained-glass deaths | at beat 4 (The Cathedral Learns Your Name) the Ruins' windows show the player's own recorded deaths as stained glass, built from the death telemetry (SYS-001 §8 keys), one pane per death type | NARR-001 §5.6, §14 Q-04 |

## 14. Generated art doctrine (D-13, 2026-11-18)

**Every image in DARKSTAR is generated at runtime by code: vector geometry or shaders.** That covers the Vigil, every Choir unit, the entity, geodes, shards, terrain, VFX, the HUD, the UI and type. No sprite, texture, tile or image file ships (GDD-001 D-13). Sections 1–13 still define the *look*: palette, silhouettes, lighting, line, UI and type. This section defines how code produces that look, and why it is better for this game.

### 14.1 Why generated
The game's signature is a continuous fall from a clean 1983 arcade into cosmic horror (GDD-001 §1, §8.7). With baked sprites, every Warp Tier is an asset swap: a cut. With generators, every body is a function of parameters, so the fall is a **sweep**. The same Grub can be drawn with three chalk circles at T0, breathe at T1, grow a fourth limb at T2, and become a lamp with a face at T4. One generator per part, every tier, every frame in between.

### 14.2 The three layers

| Layer | What it is | Used for | Rule |
|---|---|---|---|
| **Vector** | `CanvasItem` draw calls (lines, polylines, polygons, arcs) issued by a part generator every frame | the T0 costume (all of Act 0), outlines at every tier, UI, type, HUD | coordinates snapped to whole pixels; 1 px strokes (plus the 3 px dim under-stroke for the arcade glow, `Pal.glow_polyline`); colours only from `Pal` |
| **Shader** | canvas-item shaders on a part's quad: signed-distance bodies, noise, flesh, glass, veins, eyes, Shroud growth | bodies from T1 up, the entity, Shroud, VFX fields, the maw | output is **quantised to the 32-colour palette** in the shader (nearest palette entry, optional ordered dither between two adjacent ramp steps), so palette law 1–6 holds for shader art too; sampled on the 640×360 grid, so it stays pixel art |
| **Post** | full-screen passes owned by `WarpComposer` (TECH-001 §5.1) | CRT costume, tears, desaturation, tier distortion | never adds a colour outside the palette except the CRT's scanline and vignette darkening, which are the costume |

### 14.3 What a part generator is
A part is a small GDScript class (`core/gfx/parts/` from Act 1; Act 0 parts live inline in `features/cabinet/sim/`). It exposes:
- **identity:** a part id that follows ART-002 §2's grammar (`ds_grub_core`, `ds_acolyte_censer`), so naming, sockets and kit palette locks carry over unchanged;
- **parameters:** `seed`, `tier` (0–5, fractional allowed), `horror` (0–1, the WarpComposer's continuous dial), `damage`, `facing`, `phase` (animation time), plus part-specific ones (limb count, eye count, glow);
- **sockets:** named attach points in the part's 64×64 local space (ART-002 §5), so `CompositeRig` assembles bodies exactly as before;
- **draw:** `draw(canvas, transform, params)` for vector parts, or a shader plus uniforms for shader parts. It is deterministic from its parameters and `seed`: the same inputs always give the same pixels (replays, tests).

### 14.4 The tier ladder (what the parameters do)

| Tier | Vector layer | Shader layer | Example: an Acolyte |
|---|---|---|---|
| **T0 Pretence** | the whole costume: 1983 outlines, glow under-stroke, ≤ 3 colours per unit | none (CRT post only) | a magenta spike, a pale face pixel, a censer on a stick |
| **T1 Frayed** | lines breathe (± 1 px, slow); one "wrong" hue may enter a ramp | first fills fade in under the outline at low `horror` | the spike gains a cloth fill that sways |
| **T2 Bleeding** | outlines start to fork; extra limbs are new sockets filled | SDF bodies with phosphor veins; Shroud grows as a shader field | a second censer arm; the veil drips |
| **T3 Unbound** | geometry distorts (vertex warp in the generator) | geometry mutation shaders, gravity lensing | the body bends as if seen through water |
| **T4 Inverted** | silhouettes re-skin as mundane objects (a lamp, a window, a face), generated from the same sockets | the inside-out palette | a standing lamp whose shade is a censer |
| **T5 Unmaking** | outlines unravel into loose chalk strokes | ribs, iris, chunked reality | only the lines of its liturgy remain |

The `horror` dial interpolates *within* a tier, so no change between tiers is ever a hard cut unless the design wants one (WARP-001's tells and the Pretence Tear are authored cuts).

### 14.5 Type
Type is generated too. The Cabinet face exists as glyph data drawn rect by rect (`core/ui/pixel_text.gd`). The Ledger and Litany faces (§11) follow the same pattern: glyph grids as data in code, drawn at integer scale. No font files are loaded, except Godot's built-in fallback font in the real UI until Ledger is coded.

### 14.6 The raster art on disk
The PNGs under `assets/sprites/` (the v0.1 PowerShell generator pass, ASSET-003) are **reference only** — the target look the generators reproduce. They are local-only reference: kept on disk, **not in git** (`.gitignore`) and **ignored by Godot** (`assets/sprites/.gdignore`), so they are never imported, exported or pushed. Only `SPRITE_MANIFEST.csv` is tracked, as the inventory of parts to build (owner decision 2026-11-18). A machine without them loses nothing the game needs. A test (`tests/test_generated_assets_only.gd`) fails the build if any scene, script or resource references an image or audio file. `assets/reference/` mood boards stay out of git (§9).

### 14.7 Definition of done for a generator (replaces §10 for parts)
1. Reads in a 160 × 90 thumbnail and in 50 % greyscale at T0 (the §10 checks still apply to the output).
2. Every colour it can output is a palette entry from its kit's pool (ART-002 §8); shader parts quantise to the palette.
3. Deterministic: the same parameters and seed give identical pixels; a test renders it twice and compares.
4. Sweeps cleanly from T0 to T5 and through `horror` 0 → 1 with no popping, except the authored cuts.
5. Has sockets for every limb ART-002 §4 lists for its kit, and a T0 costume form.
6. Costs no more than its share of SYS-001 §9's frame budget at the on-screen cap (TECH-001 §8).
