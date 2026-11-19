# DARKSTAR — Art Bible

**Doc ID:** ART-001 · **Version:** 1.5 · **Date:** 2026-11-18 · **Owner:** Art · **Status:** complete-draft (§11 typography and §12 UI states are specified; no glyph or UI-kit art is drawn yet) · **Companion:** `SPRITE_MODULARITY_SPEC.md` (ART-002, the technical module system), `ASSET_PIPELINE.md` (ASSET-003, how files are made)

**Rev 1.5 (2026-11-18, PM under owner autonomy grant): §15.4 the Aether tier language (what each tier should look like, one new technique per tier, three dread registers); §16.5 AETHER palette ramp approved (palette v2, pending implementation); §16.6 implementation record of the Aether gallery pass 1 (layer stack, entity exact-black rule, law checks); §14.8 pxl allowed after Act 0 for non-morphing far set pieces only (TECH-001 Q-T22).**

**Rev 1.4 (2026-11-18, owner direction): §16 the Aether — space is retro-future Victorian (aether, fog, life, crystal spheres, colour), not a black vacuum; the arcade's black is the Pretence and the only true black is the entity. Law 4 amended.**

**Rev 1.3 (2026-11-18, owner direction): §15 the visual fidelity ladder — Act 0 is neon arcade (Neon Cabinet palette, flat); from THE PRETENCE the Aether look grows past arcade limits with real lighting, fog, bloom and complex particles. §15 governs where §4–§5 or §14 read as a cap.**

**Rev 1.2 (2026-11-18, GDD-001 D-13): every image is generated in code — vector geometry or shaders. No sprite, texture or font files ship. §14 is the generation doctrine; §1–§13 still define the look.**

Rev 1.1 (2026-11-17, owner-delegated rulings R-02, R-06, R-09): palette law 1 gains its documented exception (§4); new §11 Typography; new §12 UI states and components. Earlier sections are unchanged in substance.

---

## 1. The look in one paragraph

> **Read §16 first (2026-11-18).** The game's space is **retro-future Victorian**: an aether full of fog, colour, life and crystal spheres, not a black vacuum. Act 0's black neon arcade is the lie that space is empty; the reveal shows the aether. The paragraph below still holds for the lantern, the Choir and the entity, read inside that cosmos.

DARKSTAR is 2D art. The Act 0 arcade screen is pixel art on a **256×304 portrait grid**, 4 bpp (integer-scaled, nearest-neighbour, no anti-aliasing); the bezel and everything after Act 0 render at native resolution, with 640×360 kept as the logical space (owner, 2026-11-18; the root and the screen are built, PR A and PR B; post-Act 0 camera is not, TECH-001 §1.1). The low-res look is a skin, not a technical limit. The game is lit by **one moving light source you control: the player's lantern**. Everything else in the frame is either bone-pale reflectance, bioluminescent phosphor, or the absence of light. The enemy faction is a religion, so its art is **liturgical**: processions, symmetrical vestments, cathedral geometry, chitin polished like church wood. The entity is not a monster — it is an **eclipse with anatomy**, built from 20 modular 64×64 segments that look like a reliquary assembled by something that has never seen a body but has read about one.

Mood keywords: *aether, crystal spheres, orrery, gaslight, brass, glass, fog, nocturne colour, wet bone, chalk, wrong symmetry, tide, reliquary, frost on a window, something enormous that is also very close — and black only where something has been eaten.*

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
| **Vigil** (player) | Wedge + lantern globe. Small, round-topped, brass. Symmetric, honest, *simple*. | The lamp globe is the brightest pixel in the frame and pulses with the Lantern state. Aether tier: a longer brass skiff with a keel and visible modules (§16.7) |
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
| NULL | `#000000` | absolute hole (the entity's punctum, voided screen areas; the Act 0 tube-mask edge is bezel print key black, not NULL, and there are no letterbox bars, TECH-001 §1.3) |
| SIGNAL | `#FF4A57` | **danger tell only**: gaze cones, incoming hit telegraphs, entity hit flash. Never a body colour, never ambient. |

> **Scope (§15, 2026-11-18):** this is the **base palette**: the base colours of authored art from T1 on. Act 0 uses the **Neon Cabinet palette** (§15.2), the same 32 roles in arcade neon. From T1, lighting, fog, bloom, particles and shading may derive colours beyond these 32; laws 1–4 below keep their force as *role* laws at every tier.

### Palette law (violations are bugs)
1. **GASLIGHT never appears on Choir or entity art**; **CHOIR never appears on player art.** The two factions are distinguishable by hue even when warped.
2. PHOSPHOR belongs to *truth-telling things*: ore, glass, the entity's veins, Shroud, and warp artefacts. It is the colour of reality showing through.
3. SIGNAL is used for at most **3 simultaneous objects on screen**. If a screen needs more danger tells, they must be shape-based (cones, chevrons), not colour-based.
4. Nothing in the background may out-shine the player's lantern (GAS-3 and above) or out-contrast the gameplay layer. *(Amended 2026-11-18, §16.3: the background is now a coloured aether, not black, so the old "never above VOID-5" cap no longer holds; the lantern-is-brightest rule does.)*
5. Warp Tiers re-tune *how* ramps are used (hue-shift, inversion, dither), but palette law 1 and 3 survive every tier — including T5.
6. Total unique *base* colours per authored part ≤ **10** (lighting and effects may add derived colours from T1, §15) (a 64×64 sprite using more than 10 colours reads as mud at 1×). Exception: `*_ASSEMBLED_*` composite previews may exceed it, because they combine parts that were each linted on their own (ASSET-003 §5).

**Law 1 exception — the salvaged lanterns (ruling R-06, 2026-11-17).** Exactly three Choir parts may carry GASLIGHT, and the palette file lists them by name in `faction_exceptions` (the lint enforces the list, ASSET-003 §5):

| Part | GASLIGHT allowed | What it is in the fiction |
|---|---|---|
| `ds_deceiver_offeringLamp` | GAS-0, GAS-1, GAS-2, GAS-3 | a dead Lampkeeper's lantern carried as an offering; the Deceiver baits you with the one colour you trust |
| `ds_acolyte_haloBroken` | GAS-3 | a lantern's brass ring hammered into a halo: a counterfeit sanctity made of salvage |
| `ds_penitent_ringBroken` | GAS-4 | the cracked ring the Penitent still wears; the strongest visual hint that the Penitent was once one of you (NARR-001) |

These are **trophies, not light sources**. No Choir or entity part may ever carry **GAS-5** (index 29, the lantern core): nothing in the Choir has ever *lit* a lantern, and the lint fails the build if one appears. Any further exception is a new ruling and a new `faction_exceptions` row, never a quiet palette edit. The other direction of law 1 has no exception: CHOIR never appears on player art.

**GASLIGHT exception: the lamp interior (PM under owner autonomy grant, 2026-11-18).** GASLIGHT belongs to the player. In the Aether, brass (orrery rings, meridian bands, lattices, observatory housings) is drawn in BONE and VOID mixes only. **The one exception is the T4 Inverted lamp interior.** At that tier the background *is* the inside of the Vigil's own lamp (WARP-001 W4-01), so those set pieces are the player's art. They may carry a dim **GAS-0 or GAS-1 tarnish**, and only there. They may not carry GAS-2 or higher; the lantern stays the brightest warm light (law 4). They may never carry GAS on Choir or entity art (law 1). Enforced by `features/aether/tests/test_aether_look_table.gd`: GAS is allowed only in an `AetherLook`'s `rib_accent` field, only when `tier == 4`, and only as GAS-0 or GAS-1.

**The AETHER ramp (2026-11-18, pass 2).** Six extra colours exist in code as `Pal.AETHER_0..5` (`core/ui/pal.gd`): `#2A2160 #463490 #6F5BB8 #968ED2 #E8DCD8 #80C4D0`. They are **outside the 32 base roles and outside `Pal.ALL`**, have no neon role, are post-Pretence only and never appear in Act 0. Distinctness rule: every AETHER entry is at least 30° of hue from every CHOIR entry (when chroma ≥ 0.05) and at least 0.075 Oklab ΔE from every CHOIR and SIGNAL entry, with no exceptions; `features/aether/tests/test_aether_palette.gd` enforces it. The palette file (`darkstar_palette.json` v2) and the pxl include are not yet updated (TECH-001 §11.1 Q-T61).

## 5. Lighting rules

> **§15 governs the tiers:** no lighting at all in Act 0 (the neon cabinet is flat). From T1, real 2D lighting, shadows, fog and bloom are allowed and grow with the warp. The rules below describe the Aether look once lighting exists.

- **The key light:** the player's lantern. Radius 260 px up / 120 px down (Lantern state). From T1 a real 2D light (`PointLight2D`) with occluder shadows; other emitters (Shroud, glass, the entity's veins) join it from T2 (§15.1).
- Falloff starts in **3 discrete bands** (100%, 65%, 30%) at T1 to keep the arcade memory, and softens into a continuous falloff with fog and bloom as the tiers climb (§15.1). The band count is a warp parameter, not a fixed law.
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
- The Act 0 "arcade cabinet" costume is a *separate art layer*: 1983-style vector-ish sprites, 1UP type, scanlines on the screen, plus a bezel that is a real-world object (native-resolution full-colour printed art, §12.7). Under it the real UI already exists; at the end of Act 0 the camera zooms in while the bezel peels, cracks, decays and warps out of the frame — the game's main hook (§12.7; owner, 2026-11-18).
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
*Scope note (owner, 2026-11-18, TECH-001 §11.2):* these pixel-grid and integer laws hold for `PixelText` **inside the Act 0 arcade screen**, which is integer-scaled (`ScreenFit`, TECH-001 §1.3). The attract logo is drawn at 4× (was 6×; PR B, 256-wide screen), still an integer scale, so the law holds. Text on the Act 0 bezel will be `VectorText`, a code-generated stroke-glyph table, geometry sharp at any scale (`VectorText` is built, TECH-001 §2.9a; the bezel moves to it in PR C pass 2, and the interim printed bezel uses `PixelText` until then). Post-Act 0 text is `VectorText` / `VectorLabel` (TECH-001 §2.9a).

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
| Menu hierarchy (owner D-C, 2026-11-18) | the **primary** action (e.g. New Vigil) is 160 px wide; **secondary** actions on the same menu are 128 px (two modules), with an 8 px gap after the primary. Width and position carry the hierarchy, never colour (GAS stays focus) | layout only; same button states | — |
| Panel | content margin 8 px; title row 28 px (Litany 16 px + padding) | 9-slice 16 × 16, 4 px corners, BONE-1 keyline | `ds_ui_panel_slate` |
| Dim overlay | full screen | VOID-0 at 85 % opacity (the only translucent fill in the UI) | engine-drawn |
| Choice card (Run Sigil, Relic, Pact, Codex tile) | **128 × 192** (2 × 3 modules) | 64 × 64 icon slot centred in the top 80 px; title (Ledger, 1 line) at y 88; body (Ledger BONE-2, ≤ 3 lines) at y 104; cost or rarity strip, 16 px, at the bottom | `ds_ui_card_frame`, `ds_ui_card_frameRare` |
| Progress bar | 6 px tall, any width in multiples of 4 | BONE-1 keyline; the fill is **PHOS-3** for truth readouts (Unravel progress, segments remaining) or **GAS-3** for player resources | `ds_ui_bar_frame` |
| Charge pips ("lantern magazine", GDD-001 §8.3) | each pip 12 × 16; 2 px gap; up to 13 | a glass lamp: brass cage (GAS-2) holding a glass body. **Full** = PHOS-3 glass + GAS-4 wick; **empty** = VOID-2 glass + unlit wick; **lost in flight** = the pip shatters (3 frames, BONE-4 flecks) | `ds_ui_pip_charge` |
| Composure wick (GDD-001 §10) | 64 × 16 | an oil-lamp wick whose flame height is the value; never a bar. **Band steps (Q-T119, 2026-11-19):** the height steps by Composure band only (four heights, Hollowed drawn as a hollow outline), never a readable number; built as runtime vector `ComposureWick` (TECH-001 §3.4 `ds_hud.wick.*`) | `ds_ui_wick_composure` |
| Ledger Compass frame | 64 × 64 (one module) | brass bezel, VOID-1 face, chalk tick marks. Built in M1 as runtime vector with `Pal` colours (TECH-001 §5.4; Q-T120 confirms this size over TECH-001's earlier 64×36) | kit `compass` |
| Toggle (settings rows) | 24 px row; the switch is 24 × 12 | a chalk switch: left = off (BONE-1 knob), right = on (GAS-3 knob + check) | `ds_ui_toggle` |

### 12.6 Icon language
- 16 × 16 icons (8 × 8 inline variants), drawn as **1 px chalk strokes in BONE-5** on transparency. Icons are chalk, not brass.
- Every icon is paired with a text label, except input glyphs and the Charge pip.
- Core set (v1): confirm, back, settings, Codex (open book), Lantern Tree (sapling in a lantern), Pact (chalk hand), Relic (reliquary box), Run Sigil (wax seal), lock, chalk-strike (error), save (lamp in a box), loading (three dots), Steady Ledger (open eye over a ruled line), photosensitivity (sun with a bar), text size (`Aa`), language (speech mark). Ids: `ds_ui_icon_<name>`.
- Input glyphs: keyboard and mouse and gamepad sets at 16 × 16, BONE-5 on VOID-2 keycaps, swapped live by `InputModeTracker` (UI-001 §4). Steam Input glyph art may replace the gamepad set where Steam provides it.

### 12.7 The Act 0 cabinet costume vs the real UI
- The costume is separate from the real UI (ART-001 §7): the bezel (`ds_ui_cabinetBezel`) and the screen's CRT, Cabinet-face text, 1UP and score. The CRT is the screen's material and the bezel is outside the screen viewport (TECH-001 §2.10); the old CrtLayer/BezelLayer stack is retired.
- **The real UI is complete underneath and works with the costume removed.** Nothing functional may exist only in the costume.
- Costume palette (on-screen cabinet elements only: score, 1UP, screen text, scanlines; owner, 2026-11-18): VOID-0 field, BONE-5 type, GAS-4 for the player's score and 1UP, PHOS-4 for "vector" outlines. No CHOIR, no SIGNAL.
- **The bezel** (owner, 2026-11-18): a real-world object rendered at native resolution as full-colour printed cabinet art, like a real 1980s bezel (illustrated, saturated, with instruction panels). It is **not** bound by the Neon Cabinet palette or the screen's role laws (faction hues, SIGNAL ≤ 3 apply to the screen content). It is still generated in code (D-13); instruction text goes through `tr()`. The printed bezel is built at the 640×360 logical size (design in §12.7a) and now draws at native resolution (TECH-001 §1.2, PR A). Owner direction 2026-11-18: bezel art must **not** be pixel graphics, sharp at any resolution; the Sinistar-style re-composition is in §12.7a (PR C, not built).
- **The zoom** (A0-3, GDD-001 §6.1): at the end of the arcade section the camera zooms in to the screen and the bezel leaves the frame permanently, revealing the chalk UI that was always there. **The bezel does not just slide out of frame: as the camera pushes in, it peels, cracks, decays and warps** (owner, 2026-11-18). This is **the game's main hook and must be a jaw-dropping show-stopper**: the signature clip, the trailer's centrepiece, the moment players share. It gets the highest presentation bar in the game (ART-004 §7.1). Under reduced motion it is a 1-frame cut with the same final state; under photosensitivity, no full-field luminance steps (WARP-001 §4.5).
- `INSERT CREDIT` blinks with a 1 s period (0.5 s on, 0.5 s off). Under photosensitivity it is steady.

### 12.7a The printed bezel (closes TECH-001 Q-T20; owner brief 2026-11-18)
Code: `features/cabinet/bezel_art.gd`, `bezel_piece.gd`, `bezel_print.gd`, `cabinet_bezel.gd`; inks in `data/cabinet/bezel_inks.tres` (TECH-001 §2.10).
- **Concept:** printed 1983 marketing art for the Pretence, a real-world object (D-B, TECH-001 §1.3). It is outside the Neon Cabinet palette and `Look.c`, and the CRT pass never processes it. Its inks are data (`BezelInks`): key black, navy, process blue, cyan, magenta, warm red, yellow, orange, cream, brass, chrome light/dark, smoked glass, plexi glare.
- **Print rules:** flat inks; key-black outlines; halftone shadow dots on a 3 px grid; a faint diagonal plexi glare. Saturated inks only inside illustrations; the fields are navy or black. The 256×304 portrait screen stays the brightest, highest-contrast rectangle (key-black 2 px screen lip; ART-004 §5 cat. 10). **Readouts live on the screen's 40 px HUD strip (PR B), not in bezel windows** (they keep their `Look.c` neon colours; TECH-001 §2.10). Since PR C pass 2 (2026-11-19) the bezel is one printed sheet (see "Built (pass 2)" below).
- **Layout** (constants in `cabinet_bezel.gd`, not repeated here; readout windows removed in PR B, readouts are on the screen's HUD strip): pass 2 supersedes the old cards: the big logo sits in the side-panel art, the how-to is printed on the sheet (not a separate card), the sticker is die-cut, and a backlit marquee runs above the screen. Left column = Vigil illustration and how-to; right column = Sepulchre illustration, "NEW!" slogan sticker, coin door.
- **Motifs:** the Vigil as a heroic yellow-and-red rocket-skiff diving toward the screen with a cyan lance bolt, and a small magenta-ringed planet. The Sepulchre as a cartoon reliquary moon with brass bands and **one slit eye**; it must never echo the 1983 Sinistar face (no mouth, no two eyes, no skull). Magenta Choir monks carry glass. Hidden wrongness, carrying no gameplay information: one "star" is a key-black hole with a thin cream ring; one monk faces the player.
- **Peel-ready seam:** the art is a list of `BezelPiece` (id, ink, z, pivot) so the zoom (§12.7 "The zoom"; ART-004 §7.1 bar ≥ 9) can drive pieces individually: peel from an edge about the pivot, crack along a seeded fracture graph, decay by ink fade and halftone dropout (shader). **Not built yet.**
- **Resolution:** vectors drawn in the 640×360 logical space. Since PR A (2026-11-18) the bezel renders at native resolution under `canvas_items` with MSAA 2D (TECH-001 §1.2), so it is vector-sharp and halftone dots can be round; all bezel text is `VectorText` (TECH-001 §2.9a; moved in PR C pass 2). Plate misregistration is built (pass 1, below).

**Cabinet realism direction (owner, relayed by the PM session, 2026-11-18; for PR C).** Owner's words: "the Diagetic aspects of the bezel such as the coin slot are too cartoony, they should look realistic. As if you are really infront of an old arcade cabinet. You should feel as if you could reach out and touch it's grimy surface."
- Physical cabinet parts move from cartoon to tactile realism: coin door and slot, coin return, buttons and control panel, T-molding, bezel glass, screws, metal and plastic. Worn paint, scratches, chipped edges, grime in recesses, fingerprints and smudges on the glass, specular highlights on metal and plastic, wear where hands go (round the coin slot and buttons).
- Printed art may stay comic-book (real cabinets had printed comic art) but must read as printed on a worn surface: fading, scuffs, peeling edges.
- Still generated in code only (D-13): runtime vector plus canvas shaders (procedural noise for grime, bump-style lighting, layered specular and dirt masks) or pxl renders; never photos or hand-made textures. The bezel stays native resolution and outside the screen palette and registers (§15.2a).
- Process: a coin-door prototype capture goes to the owner's delegate (PM) for yes/adjust before the rest is built.
- This supersedes the "cartoon" wording above (e.g. "cartoon reliquary moon" is a printed-art motif and stays; the physical parts follow this direction; the coin door is satin black-painted steel with dull zinc parts, not chrome, and its screws are zinc, not brass).

**Built (PR C pass 1, 2026-11-18; code and nodes in TECH-001 §2.10, values in `data/cabinet/cabinet_surface.tres`).** The material rules now in force:
- **Dull, with one bright place.** Painted and zinc steel are dull; the coin slot's lip, polished by coins, is the only bright metal. Plastic and lamp plates are translucent and lit from behind.
- **Wear is causal.** Dirt and chips sit where hands, coins, keys and feet go (round the slot, on the thumb patch of the lit plate, on the lower edge and corners), grime packs into recesses, dust settles on top edges.
- **One cabinet light.** The lit screen is the key (warm, from the hole's side), a cool dim room fill, falling into shadow toward the bottom; the lit price plate throws a little red-orange spill on its neighbours. Raised parts cast contact shadows away from the screen.
- **Printed parts are flat spot inks under glass.** They fade, mottle, scuff and flake to the white backer, with per-plate misregistration; the glass adds sheen, dust, fingerprints and fine scratches and never covers the screen hole. The comic art stays comic.
- **Physical parts are SDF shaders with height-field lighting** (coin door, vents, sticker); they are resolution independent and generated in code (D-13).
- **All colours and amounts are data** in `CabinetSurface` (✱), not in shaders or this doc.
- Converted, not cut: the NEW! starburst is a worn vinyl sticker; the white vent plates are perforated black-metal grilles, plus an apron vent under the door; the lit price plate is the reject button, with a recessed return pocket and flap, an offset lock and misaligned screws.

**Built (PR C pass 2, 2026-11-19; code and nodes in TECH-001 §2.10, values in `data/cabinet/cabinet_surface.tres`).** PM with owner authority + The Reviewer critique.
- **One printed sheet:** full-bleed art, the big logo in the side-panel art, the how-to printed on the sheet, a printed border round a rounded opening. Full plate-by-plate halftone (a piece's alpha is its tone, halftoned per plate on rotated grids with dot gain).
- **Glass front layer:** specular band, screen reflection, dust, thumb smear. **Ink loss** is sharp flakes down to the black backing (not soft fade). **Wear concentrates causally** (where hands, coins and feet go).
- **The screen lights the cabinet:** the average screen colour tints the sheet, glass, sticker and coin door (read-only; fixed when `photosensitivity` is on).
- **A real tube:** rounded mask corners (it covers about 12 corner texels of the screen grid, TECH-001 §11.2 2026-11-19, flagged for owner review) and a very faint glass layer whose alpha is clamped; the CRT and register quantize are untouched.
- **Hardware and room:** T-molding with zinc bolts, and darkness in the room beyond the sheet.
- **Backlit marquee (Q-T32 (a) built):** the top 28 units; lettering ink height about 21 units including stroke.
- **The coin door stays black** (warmth only in its highlights). **Die-cut sticker** for the NEW! slogan. **All bezel text is `VectorText`.**
- **New print strings** (the bezel tagline): `CAB_BEZEL_TAG_1` "ONE COIN." and `CAB_BEZEL_TAG_2` "ONE VIGIL."
- **Built (pass 2b):** the control panel under the screen (TECH-001 Q-T34, resolved; §2.10): three pushbuttons, NEW VIGIL a big lit start button, SETTINGS and QUIT smoked service caps; decorative in game. (Revised in pass 2c, below: SETTINGS became SERVICE and QUIT a POWER rocker.)

**Built (pass 2b polish, 2026-11-19; commit 520d874; values in `data/cabinet/cabinet_surface.tres`).** After The Reviewer's notes on pass 2.
- **Glass reads through light:** the glass band lowers contrast where it crosses the print, and the thumb smear sits in the screen glow's path and hazes with the live screen light (`cab_screen_light`).
- **UV fade:** reds and magentas fade in the sun-facing print; an unfaded edge band survives under the T-molding.
- **Causal grime, scuffs and flakes** are visible at 1:1, not only when zoomed.
- **Marquee:** a hot tube band, backlit lettering; the dark patch is a cold shadow under the plastic (blocked backlight), and warm light spills onto the bezel below.
- **Coin door:** the label is flat faded paper; the slot lip is dimmed so the lit price plate wins.
- **The room** takes a faint screen-coloured spill.

**Built (pass 2c, 2026-11-19; values in `data/cabinet/cabinet_surface.tres`).** After The Reviewer's 2c notes; the panel is period-true (TECH-001 §2.10, §11.2).
- **The panel is an angled laminate:** a bevelled top lip against the bezel, a shadow under its front edge, contact shadows under each button, its own fine grain, and palm-polish (smoother, glossier) beside START. The START decal is partly rubbed off; the SERVICE decal is lightly worn. Printed decals stay legible when a button is disabled (only the lamp goes dark).
- **Controls:** START (NEW VIGIL), a small SERVICE button, and a POWER rocker on the right cabinet side under the coin door (the apron vent there was shortened; owner confirmation open, Q-T82). A plain-language caption plate ("Settings", "Quit game") is drawn on the panel or bezel while a control has focus or the mouse is over it, never over the screen.
- **Thumb smear:** now on the bezel glass beside the left screen edge, gated by the screen light: invisible when the screen is dark, a clear haze when bright.
- **Hazard tape is printed vinyl:** a sheen, flat inks slightly out of register, edges lifting with a shadow, dirt on the adhesive edge, and a crease. The peeled flap shows the adhesive side. The tape's behaviour (peel, drag, hold, fall) is unchanged.
- **Power-off:** after POWER is confirmed the CRT collapses to a line, then a dot (a plain fade under photosensitivity or reduced motion).
- **Not done:** the room spill reaching the floor (optional). Not evaluated in motion or by The Reviewer.

**Approved re-composition (owner, 2026-11-18; PR C; built in part by pass 2, above, and pass 2b, above): Sinistar-style portrait cabinet.** The screen is a **256×304 portrait** tube (PR B, built; TECH-001 §1.3) with 28 units of thick black tube mask above and below and 192-unit side panels on the 640×360 reference; the bezel fills the whole window at any aspect (no bars). Composition: a **large emblem illustration in each side panel**, an **instruction card beside the screen**, a **thin backlit marquee** in the top 28 reference units above the screen (lettering ink height about 21 units including stroke, centred above the screen; the big logo lives in the side-panel art; it must read as a real backlit translucent sign: uneven backlight, a dead tube band, dust on the top edge; ruled 2026-11-18, TECH-001 Q-T32; built in pass 2), a **thick tube mask**, **restrained inks** (a smaller share of the ink set than the interim bezel), and a **control panel** carrying `CoinSlot` plus the NEW VIGIL / SETTINGS / QUIT buttons (one focus domain with the coin slot). **All live readouts (score, Vigils, HI, magazine, Sepulchre progress, credits) move onto the screen**, in an on-screen HUD strip; the bezel carries printed art and the coin door only. Bezel text is `VectorText` (code-generated stroke alphabet, tessellated to polygons; no font files; D-13), drawn natively, sharp at any scale, with MSAA for edges. This borrows Sinistar's layout, not its face: the §12.7a motif rule (no mouth, no two eyes, no skull) stands. The HUD strip is 40 px (Q-T31, resolved); the marquee height is resolved (Q-T32, above). **Until PR C, the printed bezel described above is the interim design.**

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

Hard rule shared with GDD-001 §10: **no variant removes information.** Every replaced effect keeps its meaning through a steady visual. No UI element may flash more than 3 times in any one second in any mode. (Owner ruling 2026-11-18: the few-pixel muzzle star is not a luminance flash under this rule; see AUDIO-001 §8.3.)

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
| **Vector** | `CanvasItem` draw calls (lines, polylines, polygons, arcs) issued by a part generator every frame | the T0 costume (all of Act 0), outlines at every tier, UI, type, HUD | coordinates on the integer grid, with 1 px strokes pixel-centred (+0.5 px; TECH-001 §1.3), plus ( the 3 px dim under-stroke for the arcade glow, `Pal.glow_polyline`); colours only from `Pal` |
| **Shader** | canvas-item shaders on a part's quad: signed-distance bodies, noise, flesh, glass, veins, eyes, Shroud growth, fog, lensing | bodies from T1 up, the entity, Shroud, VFX fields, fog, the maw | base colours come from the base palette and kit pools; lighting and effects derive freely (§15). At T0 a shader may only output Neon Cabinet entries. Sampled on the Act 0 screen grid (256×304) |
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
2. Its **base** colours come from its kit's pool (ART-002 §8); at T0 everything it outputs is a Neon Cabinet entry; from T1 lighting and effects may derive further colours (§15).
3. Deterministic: the same parameters and seed give identical pixels; a test renders it twice and compares.
4. Sweeps cleanly from T0 to T5 and through `horror` 0 → 1 with no popping, except the authored cuts.
5. Has sockets for every limb ART-002 §4 lists for its kit, and a T0 costume form.
6. Costs no more than its share of SYS-001 §9's frame budget at the on-screen cap (TECH-001 §8).

### 14.8 pxl: build-time pixel art (D-13 amendment, 2026-11-18)

[pxl](https://github.com/uilianks/pxl) (MIT) is pixel art as code: a JavaScript DSL (`.px.js`) that renders PNGs, sheets, animation strips and Godot `SpriteFrames`, with a lint for orphan pixels, jaggies and pillow shading, and a live viewer with annotate-and-send feedback. D-13 is amended to allow it: **art rendered from committed code is generated art.**

| Rule | Detail |
|---|---|
| Sources | `art/src/*.px.js`, committed. Every source starts with `include("darkstar_palette.px.js")`, which loads the 32 palette entries as keys `0`–`v` in palette-index order (the file lists the mapping). Asset names follow ART-002 §2 (`ds_<kit>_<part>…`) |
| Output | `assets/art/generated/` (`sprites/`, `scenes/`, `anims/`, sheets; `--godot` adds `SpriteFrames` `.tres`). Committed. Never hand-edited: change the source and rebuild |
| Palette | base colours come from the palette includes: `darkstar_palette.px.js` (Aether, T1+) or `neon_cabinet_palette.px.js` (T0 art, flat: no lighting). From T1, pxl's `lighting()`, `glow()`, `shades()` and true-colour effects are allowed (§15); faction-role laws still hold |
| Forbidden | `image()`: it pastes an outside PNG (a photo, a reference, a drawing) into the art |
| Previews | `assets/art/generated/_preview/`: Godot-ignored by pxl, git-ignored here |
| When to use pxl, when to generate at runtime | **pxl** for things that do not need to morph: set pieces, Ruins props, portraits, Codex illustrations, icons, key art, and **per-tier variants** of a part (render T0…T5 frames from one parametrised source, then swap). **Runtime** (§14.2) for anything that must transform continuously on screen: the Choir under warp, the entity, the Vigil, VFX, the HUD. One part may combine both: a pxl sprite inside a shader that warps it. **After Act 0 (ruling 2026-11-18, TECH-001 Q-T22):** pxl is allowed only for non-morphing far set pieces (orrery arms, telescope housings, engraving plates); fog, spheres, life, the leviathan and the entity stay runtime |

Commands (from the repo root; the tool lives in `.claude/skills/pxl/`, git-ignored, installed per README):
```
node .claude/skills/pxl/bin/pxl.js build art/src/<file>.px.js --out assets/art/generated          # add --godot for SpriteFrames
node .claude/skills/pxl/bin/pxl.js lint art/src/<file>.px.js                                     # the art critic: run before calling a sprite done
node .claude/skills/pxl/bin/pxl.js serve art/src/<file>.px.js                                    # live viewer, http://127.0.0.1:4321
```
First asset (2026-11-18): `ds_ui_paletteSwatch` (`art/src/reference.px.js`), the 32-colour palette as a swatch card, which proves the pipeline and the palette test.

## 15. The visual fidelity ladder (owner direction, 2026-11-18)

**The game starts as a neon arcade machine and becomes something richer as it reveals itself.** Act 0 looks like a classic 1983 cabinet: neon colours on black, flat vector shapes, no lighting. After THE PRETENCE the Aether look takes over (§16: retro-future Victorian space), and the graphics are allowed to *transcend* arcade limits: real 2D lighting with the lantern as the key light, shadows, fog and volumetric haze, bloom, complex particle systems, normal-mapped and shader-rich bodies. Gameplay stays top-down 2D throughout; the Act 0 screen's pixel grid is 256×304 (TECH-001 §1.1) and 640×360 is the logical space, which renders at native resolution after Act 0 (owner, 2026-11-18). This section governs; where §4–§5 or §14 read as a hard cap on colours or lighting, this section wins.

**Neon Cabinet video limits (owner, 2026-11-18; layer one only, never the bezel, never after Act 0; built 2026-11-18).** Act 0 screen colours must fit 16 RGB332 registers (`VideoRegisters`, table in §15.2a). Breaking the limit during THE PRETENCE reveal is in-fiction. The limits are: 16 colours on screen at once from a 256-colour palette (3 bits red, 3 green, 2 blue); registers writable at any time, so colour cycling and fades are register writes; frame time 16.64 ms (counter arithmetic in TECH-001 §1.1). The quantize pass runs in the CRT shaders of the arcade screen and the attract hole only; the limits fade out as `Look.t` goes 0 to 1 (THE PRETENCE).

### 15.1 The ladder

| Stage | Palette | What rendering may do | What it may not do |
|---|---|---|---|
| **T0 — Act 0 (the Cabinet)** | **Neon Cabinet palette** (§15.2), flat | vector lines and fills, the glow under-stroke, CRT scanlines and curvature, screen shake | lighting, fog, gradients, soft particles, bloom. Every pixel of the **screen** is a Neon Cabinet entry (the CRT pass aside). The screen is a low-res pixel-perfect grid in its own SubViewport (**256×304 portrait, 4 bpp**, owner 2026-11-18, PR B, TECH-001 §1.3; video limits below); the bezel is native-res vector print art outside this palette (§12.7; Sinistar-style re-composition approved, PR C, not built) |
| **THE PRETENCE (T0 → T1)** | the neon **morphs entry by entry** into the base palette (§4) | the morph, the tear, the maw | — |
| **T1 Frayed** | base palette as **base colours** | the lantern becomes a real light (soft falloff, shadows from occluders), light fog, first soft particles (dust, chalk flecks, glass motes) | — |
| **T2 Bleeding** | base + derived | bioluminescent emitters (Shroud, glass, veins) light the field; bloom; Shroud as an animated shader field; denser particle systems | — |
| **T3 Unbound** | base + derived | volumetric fog and god-rays from the lantern, distortion and lensing shaders, normal-mapped shading on bodies | — |
| **T4 Inverted** | base + derived, inverted readings | full post stack (WarpComposer), mundane-object re-skins lit like real objects | — |
| **T5 Unmaking** | base + derived, then subtraction | everything above, being taken apart: lights going out, fog swallowing, particles running backwards | — |

**What survives every rung, including neon:** the role laws. Laws 1–3 of §4 (faction hues, phosphor = truth, SIGNAL ≤ 3 objects) hold at every tier, because the Neon Cabinet palette keeps the same 32 roles. Law 4 (the background never out-shines GAS-3) and the readability rules of WARP-001 §5.1 (value before hue, nothing moves a hitbox) also hold. What changes is fidelity, never legibility.

**What "base colours" means from T1:** authored art (generator parameters, pxl sources, shader albedo) picks its colours from the base palette and its kit pool (ART-002 §8). Lighting, fog, bloom, particles and shading then produce *derived* colours freely. No per-pixel quantisation is required after T0.

### 15.2 The Neon Cabinet palette (T0)
The same 32 roles as §4, re-voiced as a 1983 arcade machine. Entry *n* here morphs into entry *n* of §4 during THE PRETENCE, so the transition is continuous and every role stays itself.

| Ramp | Neon (index 0 → 5) | Role kept |
|---|---|---|
| VOID | `#000000` `#06061E` `#0C0C3A` `#151A66` `#2633D9` `#5B6CFF` | arcade black; electric-blue stars |
| BONE | `#2B2B4D` `#4A4A80` `#8C8CC0` `#C8C8F0` `#E8E8FF` `#FFFFFF` | white vector rock and chrome |
| CHOIR | `#33002B` `#66004F` `#A8008A` `#F000C0` `#FF4DE1` `#FFB3F7` | hot magenta: the enemy |
| PHOS | `#002626` `#005A5A` `#009E9E` `#00E0E0` `#33FFF2` `#B3FFFF` | neon cyan: the glass, the truth |
| GAS | `#3A1F00` `#7A4400` `#FF8800` `#FFC400` `#FFF033` `#FFFFB3` | arcade yellow: the player |
| NULL / SIGNAL | `#000000` / `#FF1F3D` | the hole / danger |

Source of truth in code: `core/ui/look.gd` (`Look.NEON`), checked against this table and the palette file by `core/ui/tests/test_theme_palette.gd`. The cabinet draws every colour through `Look.c()`, which returns the neon entry at `Look.t = 0`, the Aether entry at `Look.t = 1`, and the blend between them during THE PRETENCE.

### 15.2a The 16 colour registers (T0 screen only; built 2026-11-18)
Source of the values: `data/cabinet/screen_registers.tres` (`ScreenRegisters`, `ds_cabinet.registers`); this table mirrors the power-on state, the data file wins. Mechanism (nearest-match assignment, write recolours every pixel on a register, alpha snaps to the nearest register): TECH-001 §1.1 and §2.10 "Video registers". Layer one only: the bezel, coin slot and any native-resolution content are never quantized.

| Reg | RGB332 colour | Reg | RGB332 colour |
|---|---|---|---|
| 0 | black `#000000` | 8 | magenta `#FF00FF` |
| 1 | deep blue `#000055` | 9 | pink `#FFB6FF` |
| 2 | blue `#2424FF` | 10 | teal `#0092AA` |
| 3 | light blue `#496DFF` | 11 | cyan `#00FFFF` |
| 4 | dim bone `#4949AA` | 12 | pale cyan `#B6FFFF` |
| 5 | light bone `#B6B6FF` | 13 | orange `#FF9200` |
| 6 | white `#FFFFFF` | 14 | yellow `#FFFF00` |
| 7 | Choir dark magenta `#B600AA` | 15 | cycling register, SIGNAL red `#FF0000` |

Pal entry to register (`pal_map`): VOID-0, VOID-1, CHOIR-0, PHOS-0, GAS-0, NULL → 0; VOID-2, VOID-3 → 1; VOID-4 → 2; VOID-5 → 3; BONE-0, BONE-1 → 4; BONE-2, BONE-3 → 5; BONE-4, BONE-5 → 6; CHOIR-1, CHOIR-2 → 7; CHOIR-3, CHOIR-4 → 8; CHOIR-5 → 9; PHOS-1, PHOS-2 → 10; PHOS-3, PHOS-4 → 11; PHOS-5 → 12; GAS-1, GAS-2 → 13; GAS-3, GAS-4, GAS-5 → 14; SIGNAL → 15. Register 15 is reserved for flashes, explosions and SIGNAL; its cycling has no caller yet.

### 15.3 Rendering toolkit from T1 (TECH-001 §5.5)
2D lights (`PointLight2D` for the lantern, emitters on Shroud, glass and veins), `LightOccluder2D` for shadows, `CanvasModulate` for ambient darkness, normal maps on generated bodies, `GPUParticles2D` with generated textures (no image files: particle sprites come from shaders or pxl renders), fog and volumetric shaders, and the 2D HDR glow/bloom post. Every effect still obeys the readability rules in §15.1 and the frame budget (SYS-001 §9, TECH-001 §8.1). Photosensitivity and Reduced Motion variants are required for every flicker or motion effect (§12, WARP-001 §4.5).

### 15.4 Aether tier language (PM-approved direction, 2026-11-18)
§15.1 says what rendering *may* do; this says what it *should look like*. One still per tier must be sortable cold (the G-2 review goal), so each tier adds **one new kind of thing**, not just "more". Horror is an undertone from T1 and overt from T3. Scale presences are never hitboxes and they flee the entity. Zero startle: every presence fades in slowly and never cuts in. No gore, and the entity never has a face. Inspiration only (Sunless Sea's dread of the unknown, Returnal's bioluminescent murk): no names, art, characters or content copied.

**The three registers of dread.**

| Register | On screen |
|---|---|
| **Vastness** | far shapes (sphere seams, leviathan backs, orrery arms) in 4 to 6 parallax bands at low scroll scale ✱, cropped by the frame edge, never seen whole. Scale comes from parallax ratio and cropping, not camera zoom (TECH-001 Q-T25) |
| **Wrongness** | a second, slightly offset seam on the crystal sphere; structures one element off-symmetry (§2); refraction showing the fog behind the sphere moving the wrong way; life schools that turn all at once |
| **Subtraction** | the entity is `#000000` with no rim, glow or outline of its own; the fog around it is drunk (density and saturation → 0), life flees, lights gutter. It has an edge because the world stops |

| Tier | What is new | Cosmic-horror beat | One new technique |
|---|---|---|---|
| **T1 Frayed** | the reveal's sky: pearl and violet fog in 3 parallax bands, the sphere's curve and a gold seam at the frame edge, glass motes, the lantern's real light as a warm pool in cool fog | something wrong you cannot name: a faint *second* seam; far off, one dark smudge in the fog that is a little too still | real light (the lantern as key light, fog lit by it) |
| **T2 Bleeding** | life: jelly-lanterns pulsing PHOS, spore drifts, lit glass veins; bloom on emitters; visible fog currents | life moves in schools that turn together, then scatters from an empty patch of fog: the absence is a tell | living emitters, bloom, flow-advected fog |
| **T3 Unbound** | depth and scale: god-rays from the lantern and through the sphere seam; a leviathan-scale silhouette crossing the far fog, darker than the fog but **not black** (VOID-1 tone, softened); lensing near the sphere | scale: it is bigger than the sector and does not notice you | refraction through the sphere, god-rays, the leviathan |
| **T4 Inverted** | inside-out light: fog lit from within (brass ribs, gaslight glass at the far layer); the sphere seen from outside; Choir hues bleed into **far** fog only, never the player | you are the thing in the jar | sky cracks, with the Aether behind the Aether visible through them |
| **T5 Unmaking** | subtraction: bands peel to chalk strokes, particles run backwards, lights go out one by one, holes of true black with hard edges and no glow open where the entity has eaten; the sphere cracks | the colour goes out like a picture being erased | chromatic subtraction (colour removed channel by channel down to NULL inside the entity mask) |

**Biome weathers** (ZONES-001 §2.1, §16.2) vary palette bias and fog motion, not the tier grammar: Pale Marches (pearl mist, BONE-3/4 frost, slow); Ossuary Belt (dust in still air, bone towers in the far band); The Litany (incense haze, CHOIR banners in the far band only); Green Rot (spore-thick PHOS murk, the most life); Drowned Observatory (tidal currents, VOID-2/3/5, lens rings and telescopes as far silhouettes, GAS-5 the brightest pixel); The Black (fog thinning toward nothing, the most dread, almost no life). The Pale Marches Presence and the one-biome damage ladder (each rung = the previous plus one more damage) are in §16.6f.

**Dominant hue and accent per tier (pass 2, `Pal.AETHER`, §4 note).** Each tier also fixes one dominant hue and one accent, so a still sorts by colour as well as by technique.

| Tier | Dominant | Accent |
|---|---|---|
| T1 | AETHER-3 lavender, with BONE-4 / AETHER-4 pearl | PHOS-4 seam |
| T2 | PHOS-1 / PHOS-2 murk | AETHER-5 sea-glass life |
| T3 | AETHER-0 / AETHER-1 deep violet | BONE-3 shafts and PHOS leviathan lights |
| T4 | AETHER-2 violet, with AETHER-4 behind the cracks | CHOIR-1 far-band incense only |
| T5 | VOID, cold | the last AETHER-4 pearl, being erased |

**Per-tier set pieces (pass 3, 2026-11-19).** Far set pieces in `features/aether/far_set_pieces.gd` (runtime vector), one per tier, flagged by `AetherLook` (TECH-001 §3.4).

| Tier | Set piece | Look flag |
|---|---|---|
| T1 | orrery armillary | `set_orrery_rings` |
| T2 | greenhouse vault with spore fuzz | `set_greenhouse` |
| T3 | dome and telescope | `set_dome` |
| T4 | lamp-interior ribs (`OrreryRibs`; the GAS-0/1 tarnish exception, §4) | `orrery` (the `OrreryRibs` layer; T4 sets no `set_*` flag) |
| T5 | ring fragments drifting apart | `set_ring_fragments` |

`set_lattice` is unused. T2's deep field is darker (`value_deep` 0.32 → 0.2 ✱) so the three value bands stay apart under the greener murk.

**The cumulative "how much is missing" cue (pass 6, 2026-11-19).** The tiers also sort by one monotonic cue: how much of the picture is gone. `AetherLook.missing` ✱ (dev placeholders 0 / 0.2 / 0.4 / 0.6 / 0.85 for T1 to T5; owner to set) drives three things together: saturation drain, star dropout and a flat VOID slice in the far layer. The slice starts inside the picture and widens by tier; it is never black and never touches the frame edge. Detail and tests: §16.6e. Known limit: the greyscale order T2 < T3 < T4 depends on reading the slice (value alone does not order them).

**Three-value structure.** Every tier's frame holds three value bands: the play band top, the fog mid, the deep background (`value_deep`) lowest. A tier that collapses two bands fails the greyscale read (§16.3).

**Budget and fallback (CH-7).** Each technique is one toggleable layer with a measured frame time. The Steam Deck / iGPU `low` preset drops detail, never information (fewer fbm octaves, half-res fog bands, static god-rays, fewer particles) and keeps the sphere curve, the entity's black and the play-band fog cap. Quality ladder and cost status: TECH-001 §8, §11.1 Q-T62 (ladder built in pass 2; §16.6 lists what no rung drops).

## 16. The Aether: retro-future Victorian space (owner direction, 2026-11-18)

**Space in DARKSTAR is not a black vacuum.** It is space as the Victorians imagined it: a luminous **aether**, thick with fog, currents, colour and drifting life, and the skies are **crystal spheres**, nested shells of glass the cosmos turns inside. Think steampunk in space and nineteenth-century astronomy taken literally: orreries, brass and glass, gaslight, observatories, celestial charts. The game is still played top-down in 2D. This is the look the fidelity ladder (§15) climbs toward from T1.

### 16.1 The inversion at the heart of the look
Act 0 shows the modern picture: **empty black space, neon shapes, a vacuum.** That is the Pretence (GDD §6.1). When the costume tears, the player learns that space was never empty: the aether was there all along, and the black was a lie. From then on **the only true black in the cosmos is the entity**: the Unborn Dark (NARR-001 §1.1), the punctum, the maw, Hollow sectors, eaten skies. Black stops being the background and becomes the horror. Every time the entity wins, the aether is *subtracted*: colour drains, fog thins, life stops, and black spreads.

### 16.2 Pillars

| Pillar | What it means on screen | Where it lives |
|---|---|---|
| **The aether is a medium** | layered coloured fog with depth and currents; it flows around the Vigil's wake, eddies behind Choir processions, glows where glass is near. Biomes are aether *weathers* (ZONES-001 §2): the Pale Marches' pearl mist, the Litany's incense haze, the Green Rot's spore-thick aether, the Drowned Observatory's tidal currents, the Black's thinning to nothing | shader fog layers (§14.2), parallax depths |
| **The skies are crystal spheres** | each of the Nine Hollow Skies is a vast glass shell: its curve, seams and refractions are visible at the edge of the field and in the far parallax. A sky going dark is a sphere clouding over; Hard Unmaking is a sphere **shattering** | far parallax layer, a refraction shader; NARR-001 cosmology |
| **Space is alive** | luminous aether-life drifts through every sector: glass motes, drifting jelly-like lanterns, slow migratory shapes far off. Ambient, never hostile, never a hitbox. It flees the entity, and its absence is a tell | particles and runtime generators (§14), ambient only |
| **Victorian technology** | brass, glass, gaslight and chalk: the Vigil is a lantern skiff, the Ruins a cathedral-observatory with an orrery, the HUD a brass-and-chalk instrument panel. Machinery looks made by hand, riveted and engraved | generators, pxl set pieces (§14.8) |
| **Colour is the truth** | rich, nocturne-painting colour: aether violets, sea-glass teals, tarnished golds, rose fogs, gaslight amber. Phosphor still marks truth and glass (palette law 2); the player's gaslight is still the warmest light in the frame | base palette §4 + derived colours from lighting and fog (§15) |
| **The horror is subtraction** | the entity is black and absence: it drinks fog, colour, light and life. Its wake is a clear, dead channel through the aether | the maw, Hollow sectors, WARP-001 tiers |

### 16.3 Readability in a full sky
A rich background must never cost legibility (GDD P5, WARP-001 §5.1 "value before hue"):
- **Depth separates play from aether.** The gameplay layer (the Vigil, Choir, glass, shots, the entity) sits in front, crisp and highest in local contrast. Aether, spheres and life sit behind, softened by fog and lower in contrast.
- **Fog density is capped where play happens.** The fog may be thick in the distance and at the edges, but never thick enough to hide a unit, a shot or a telegraph. Density is a WarpComposer parameter with a ceiling. Pass 5 enforcement of law 4 for fog is in §16.6d ("Law 4 fog cap").
- **Nothing in the background out-shines the lantern.** (Law 4, §4, amended.)
- **Every effect reads in greyscale** (§10, WARP-001 §5.1).

### 16.4 Mood references (mood, never copy; §9)
Nineteenth-century astronomical illustration and engraving (lunar and nebular plates, celestial atlases), orreries and armillary spheres, Victorian scientific instruments, aether theory diagrams, gaslit cathedrals and observatories, deep-sea plates of luminous life. Only public-domain sources go in `assets/reference/`, and nothing is traced (RES-001 §5).

### 16.5 Consequences for the palette
The 32-entry palette (§4) remains the **base** set for authored art and keeps its roles. The aether's colour fields, fog and lighting derive their colours from it under the fidelity ladder (§15). An art pass may propose an **AETHER** ramp (violet, rose, sea-glass) as a palette v2 change through ASSET-003 §8 versioning. **Approved 2026-11-18 (PM under owner autonomy grant); constants built in pass 2 (see the §4 AETHER note), palette file v2 and pxl include still pending** (TECH-001 §11.1 Q-T61 holds the six proposed entries and the test rule): the ramp opens on condition that its hues stay distinguishable from CHOIR and SIGNAL, enforced by the palette test; it has no neon role, is never used in Act 0, and lives in `Pal.AETHER`, outside `Pal.ALL` and `Look.NEON`. Until it is implemented, aether colour is built from VOID, PHOS, CHOIR-free BONE and GAS mixes under lighting.

### 16.6 Implementation record: gallery pass 1 (2026-11-18)
Built in `features/aether/` (TECH-001 §2.9), shaders in `shaders/aether/`, looks in `data/aether/` (`AetherLook`, one per biome × tier), shown in the dev-only `scenes/dev/aether_gallery/` (six exhibits: T1 Pale Marches, T2 Green Rot, T3 Drowned Observatory with leviathan, T4 Inverted (look `litany_t4`), T5 Unmaking (look `the_black_t5`), entity presence). Captures and self-scores are not part of this record.

**Layer stack** (`AetherBackdrop`, back to front; API `set_tier`, `set_drain`, `set_time`, `set_camera`, `apply_look`): far, mid and near fog bands (`aether_fog_band`); crystal sphere (`crystal_sphere`: curve, seam, refraction, glint, second seam by tier); still smudge (T1 "too still" shape); leviathan (`leviathan`, far band, VOID-1/2 tone, never black); light shafts (`light_shafts`, capped below lantern luminance); aether-life particles (`aether_life`, procedural textures, no image files); sky cracks (`sky_crack`, T4); orrery ribs (T4 far set piece, runtime for now); entity presence (`entity_presence`); grade (`aether_grade`). The gallery renders into an HDR SubViewport with `WorldEnvironment` glow, shown through a `TextureRect` at window pixel size, and `aether_present` converts linear to sRGB. Signals (EVT-001): `sphere_glinted`, `leviathan_entered`, `leviathan_closest`.

**Rules as built.**
- **Entity exact black.** Only nodes in group `entity_presence` output `0,0,0`. Every other layer's colour floor is VOID-0 `#0A0A12` (fog never goes below it). Drained areas go to desaturated thin fog first, then NULL only inside the entity mask.
- **Lantern in-scatter.** The lantern is the key light; fog near it is lit by it (in-scatter), and no far light or glow exceeds the lantern core luminance.
- **Colours come from `Pal` through `AetherLook`.** CHOIR entries are allowed only on far bands.

**Law check** (how each law is kept, and where it is checked; "capture" = windowed gallery capture, not yet automated unless noted):

| Law | How the Aether keeps it | Check |
|---|---|---|
| 1 Faction hues (GAS never on Choir or entity; CHOIR never on the player) | CHOIR only in far-band tints (Litany, T4); GAS only in the lantern's light and its own glass. Open: GAS-1 on T4 orrery ribs (TECH-001 Q-T63) | `features/aether/tests/test_aether_look_table.gd` (look-table lint; read the test for its exact assertions) |
| 2 Phosphor = truth | PHOS is glass, life's glow and the sphere's refraction; entity veins, if shown, are PHOS | role review per capture |
| 3 SIGNAL ≤ 3 | the Aether never uses SIGNAL | capture pixel check (not built) |
| 4 Lantern brightest | emitters cap below GAS-3 lantern luminance; fog capped in the play band (`play_fog_ceiling`, a design number: owner to set); bloom thresholded | `features/aether/tests/test_aether_lantern_key.gd` (structural); capture luminance check (not built) |
| Only true black is the entity | see "Entity exact black" | `features/aether/tests/test_aether_black_roles.gd` (structural); capture pixel check after glow not yet done (TECH-001 Q-T64) |
| Greyscale read | play band keeps the top value band, fog mid-low, entity the bottom | greyscale capture in every review |
| Photosensitivity / reduced motion | no flicker above 3 Hz; slow glints and pulses; a reduced-motion variant freezes drift and halves parallax (§12 variant per effect) | not verified in this pass |

### 16.6a Pass 2 rules (2026-11-18, commit e2755e6)

**Entity as subtraction.**
- The entity is a hard torn edge, a ruled cut with a square notch, and 7 tapering tendrils that grow with drain; its extent is off-frame; no halo, rim or glow.
- The world loses layers at crisp boundaries, in order: near fog, then mid fog / leviathan / rays, then stars / life / far detail. Colour goes cold VOID, never toward black (black is the entity only).
- Fog flows in; the sphere line's ends are displaced then stop; god-rays bend in; life drifts in and vanishes; T5 torn edges start at the frame borders.

**Leviathan.**
- About 60% of frame height; crosses in front of the sphere line (scale by occlusion); spine plates, 3 fins, a tail and a ray rim; PHOS-4 flank lights lit in sequence at 0.4 Hz (inside the 3 Hz rule); it shadows the god-rays and is veiled by mid fog. Crossing 70 s ✱, period 95 s ✱.
- Never black (VOID tone, §15.4) and never a hitbox.

**Sphere and set pieces.** The sphere is an orrery: a brass meridian band with graduation ticks, meridians, and up to 2 nested shells with their own parallax. Far set pieces (`features/aether/far_set_pieces.gd`, runtime vector): orrery rings (T1, T4), lattice (T2, T3), dome with telescope (T3). Brass is BONE and VOID mixes, no GAS, except the T4 lamp-interior exception (§4). Jellies have core, rim, halo and filaments; vast far jellies at T2 and T3; glints. T4 cracks are straight segments foreshortened along the sphere, hairlines at most 0.45 alpha, fog displaced per shard, with AETHER-2 / AETHER-4 behind the Aether showing its own stars and a reversed seam. T1 has a still VOID-2 vertical smudge, a stronger warm lantern pool and far-band engraving hatch. T3 shafts are BONE-3, not GAS.

**Quality ladder: never dropped at any rung** (`ds_aether.quality.*`, TECH-001 §3.4; tested in `features/aether/tests/test_aether_quality.gd`): the sphere curve, the entity's exact black, the play-band fog cap. Low drops detail only: 2 fbm octaves, warp 2, single-sample advection, half-res fog in at most 3 bands, particles ×0.4, static shafts at 0.25 resolution, no sphere refraction, no nested shells, entity edge at 2 octaves. The medium rung is not yet captured; low cost: clean desktop numbers are in TECH-001 §8.5 (Deck / iGPU still open, Q-T90); mid fog is also reduced at low (§16.6b).

### 16.6b Pass 3 rules (2026-11-19)
Supersede the matching pass 2 lines above where they differ.

**Entity: no face.** Pass 2's contour read as a human profile (The Reviewer, 2026-11-18); the entity never has a face (N4, NARR-001 §3.4).
- The contour has only a gentle large-scale warp; the character comes from creased mid and fine noise and 8 angular sheared bites. (Pass 3 had straight tendrils; pass 4 removes all hanging tendrils, §16.6c.)
- **Stepped subtraction:** three crisp nested edges, slightly offset. Outer (about 0.4 to 0.5 r out): near and mid fog, the sphere seam, the leviathan and the rays stop. Middle (about 0.19 r): stars, life and far detail gone; the far band is flat cold VOID (`mix(void_lo, void_hi, 0.22)`), never black. Inner: true black (only the entity writes 0,0,0). The straight cut is terraced.
- Face and pareidolia are checked by eye on captures at full size and at 25%. Pass 4 adds an automated guard for closed holes and hanging appendages (§16.6c); the face check stays by eye.

**Leviathan anatomy.** Long tapering head and back running off the top of the frame; the belly a long curve over the lantern that never encloses it; smooth back with a few raised broken plates; one swept pectoral vane with a V-notched trailing edge, running off-frame. Backscatter rim strongest along the belly (T3 `leviathan_rim` = AETHER_3). Flank lights follow the belly in two loose rows with staggered size, spacing and phase at about 0.35 Hz.

**Brass.** The meridian band is two-tone: brass body BONE_2, highlight edge BONE_4, engraving VOID_3. Minor and major graduations have separate weights. Major graduations carry engraved mark groups (dots and slanted strokes): decoration, never text glyphs, no `tr()`. Pass 4 replaces them with crisp numerals (§16.6c). Armillary rings are two-tone and fogged by depth, interleaved with the sphere through a back copy drawn below the sphere layer. Brass stays BONE and VOID mixes except the T4 lamp-interior exception (§4).

**T4 cracks.** Two impacts with wide gaps (10 and 8 px ✱; a third, 3.4 px ✱) showing the Aether behind with counter-parallax, its own denser and faster stars, and a reversed seam.

**Lantern in-scatter.** Gold-amber: GAS_3 at the rim to the lantern colour at the heart. The fog term takes 70% from fog brightness, so every tier's pools are warmer.

**Quality (CH-7).** Mid fog resolution is a ladder field (`mid_fog_resolution_scale` ✱: 1.0, 0.5, 0.25 at high, medium, low). Clean desktop low cost is at most 0.75 ms at 720p (TECH-001 §8.5; Deck / iGPU still unmeasured, Q-T90). The T5 ghost / skull read (Q-T93) is resolved by the §16.6c rule.

### 16.6c Pass 4 rules (2026-11-19)
Supersede the matching pass 3 lines where they differ.

**Pareidolia rule (adopted, proposed by The Reviewer; PM under owner autonomy grant):** no closed holes in organic shapes near the play centre, and no thin appendages hanging from the entity. This is the organic-shape companion to the entity face rule (N4, §16.6b; the limb rule N7 is NARR-001 §3.4). Enforcement: `features/aether/tests/test_aether_pass4.gd`: a CPU flood-fill of the fog and chalk strand maths over 3 drift directions × 2 seeds × 2 times × 4 thresholds on a 110×110 grid, with a control proving the old ring construction is caught; entity cracks bounded inside a band just outside the mass (`A_ENT_CRACK_BAND` 0.24 × grow, checked for every radius and growth the backdrop produces). Honest limits: no headless shader render (CPU mirror, double precision); the blend ring between play core and free fog, the opaque far band and colour terms are not covered.

**Pareidolia rule, extended (pass 6, PM under owner autonomy grant 2026-11-19, proposed by The Reviewer):** no closed circles in organic or fog shapes near the play centre; geometric orrery rings and crystal spheres are exempt. Implementation and test: §16.6e.

**Entity.** Hanging tendrils removed; crazed-glaze cracks inside the band instead (thin 0.9 px to a 0.35 px hairline, never free-ending). Bites are acute (32 to 66°) or obtuse (115 to 132°) wedges, never square. Terrace risers slant.

**Play-centre fog (every tier).** Built from drift-aligned strands combined with `min`, so there are no holes.

**T4.** Irregular fracture cells; open cells show a sea-green other world (behind_a PHOS_2, behind_b AETHER_5) with counter-drifting fog, sparse large warm stars (BONE_4) and a vast dim body.

**T3 vane.** A translucent membrane on four bony spines with a lit leading edge.

**Text exemption (Q-T92, resolved).** Crisp engraved Roman numerals I to XII on the meridian majors are diegetic decorative art (period engraving), exempt from `tr()` because they are art, not player text. Narrow: numerals only, never words. Behind `AetherLook.meridian_numerals` (default true). Tested: the numerals decode to exactly I to XII, and only I, V and X have stroke branches.

**Known weaknesses.** T5 far band reads as pale draped satin sheets around the lantern (not a law breach; pass 5) and is brighter than pass 3; crazing can look twiggy at mid drain; the T4 behind-world is still fairly flat; the vane spines are subtle at 25%.

**Cost.** High, 1080p, RTX 4070: 4.38 ms on the entity exhibit (TECH-001 §8.5, Q-T94: trim before M3). ✱ params are listed in TECH-001 §9.1. (Superseded by pass 5 below.)

### 16.6d Pass 5 rules (2026-11-19)
Supersede the matching pass 4 lines where they differ.

**No black strokes outside the true-black mass (adopted; proposed by The Reviewer; PM under owner autonomy grant 2026-11-19).** Companion to the pareidolia rule above. `entity_presence` writes black only where `s < 0`. World-side cracks are VOID_1 hairline gaps with thin VOID_5 lit rims fading outward, plus a few lifted fragments filled with the flat VOID middle band (`mix(VOID_1, VOID_4, 0.22)`), all inside `0 < s < A_ENT_CRACK_BAND` × grow (`A_ENT_FRAGMENTS` 0.22, `A_ENT_FRAGMENT_FROM` 0.2 ✱). Test: `features/aether/tests/test_aether_pass5.gd` (black only inside the mass). TECH-001 §11.2.

**Law 4 fog cap (enforcement note for §16.3).** Pass 4's T5 fog read as satin sheets with folds near lantern-pool brightness (The Reviewer). Fix: play-core strands are cut into short ragged streaks (`A_FOG_DASH` 9 ✱) shaded flat along the strand only (no cross-strand gradient); chalk cuts density only, never colour; every band's own light over the play core is capped at `A_PLAY_FOG_LUMA` 0.14 ✱ before lantern in-scatter. Test: an analytic bound, not a render, mirroring the fog shader's lantern, drain and band-alpha terms. Fog beside the ship (capped fog, lantern weight `BESIDE_LP` 0.5 ✱) must be at most `POOL_RATIO` 0.8 ✱ × the dimmest pool heart, and the cap under half the pool heart, for every look. Printed ratios: drowned_observatory 0.73, green_rot 0.66, litany 0.74, pale_marches 0.76, the_black 0.68. Not covered: grade, bloom, non-fog layers, the play RING (blend to free fog): TECH-001 Q-T122.

**T4.** Remaining hairlines are sparse (`A_KEEP_INNER` 0.3, `A_KEEP_FRINGE` 0.18 ✱) with varied weight; `A_DIM_PANES` 0.16 ✱ of closed panes are dim-filled with the other world (`A_DIM_ALPHA` 0.5, `A_DIM_VALUE` 0.55 ✱); no closed outline polygons.

**Cost (CH-7, Q-T94 resolved for high).** 1080p high, RTX 4070, same-session sweep (other Godot processes running): pass 4 2.956 / 2.965 / 3.387 / 2.981 / 3.362 / 4.397 ms; final 2.559 / 2.824 / 2.950 / 2.708 / 2.972 / 3.464 ms for exhibits 0 to 5, every exhibit under its pass 3 bar, but exhibits 2 and 4 by only 0.07 and 0.04 ms (noise about ±0.2 ms). Trims: loss mask every second bite (`A_LOSS_BITE_STEP` 2 ✱), skipped past `A_LOSS_REACH` 1.75 ✱ plus AA width (proven conservative, tested); free fog skipped where strip weight is full (`A_STRIP_FULL` 0.8 ✱); one fewer streak and curl octave; silver-lining sample faded then skipped. Low and medium not re-measured (TECH-001 Q-T123). Figures in TECH-001 §8.5.

**Known weaknesses (pass 5).** T5 left edge: a swirl around a hole with a crisp circular edge (reads a little like a whirlpool or eye; sits in the ring, outside the bound). T5 right ring fog is billowy and lighter (about 0.45 by eye, not measured, vs about 0.7 pool). The entity's crazed band reads as a pale mosaic or stained glass. T4: one dim pane reads as a dark blob. The 0.14 cap darkens every tier's centre a little compared with pass 4.

### 16.6e Pass 6 rules (2026-11-19)
Supersede the matching pass 5 lines where they differ. Tests: `features/aether/tests/test_aether_pass6.gd`. Evidence status: the model-viewer pilot (below) and the cost sweep are the only measurements; no human has sorted the tiers yet.

**Tier sort (G-2).** A model-viewer pilot (5 fresh AI agents, not humans; write-up in the shared notes `aether_sort_pilot_proxy.md`) gave 0 of 5 exact orders on pass 5; T5 was placed last 5 of 5; T1 was misread because of a dark orrery disc. Model-viewer pilots are evidence for direction only; the human cold-viewer sort is scheduled with the owner's M2 test round (PROD-001 §4.1, TECH-001 §11.2). The pass 6 re-run gave 0 of 5 valid exact orders, with 2 of 5 viewers invalid (label mix-ups): a smoke test only. Open (TECH-001 Q-T126): the five exhibits are five biomes, so viewers sort places by mood, not tiers by damage; proposed G-2 wording is one biome at every tier, and the principle that each tier is the previous tier plus one more kind of damage to the same elements. Owner to decide.

**Monotonic "missing" cue (§15.4).** `AetherLook.missing` ✱ (0 / 0.2 / 0.4 / 0.6 / 0.85 for T1 to T5, dev placeholders) drives: saturation drain (`A_MISS_DESAT` 0.9 ✱, luminance kept); star dropout along the same curve; and a flat VOID slice (`a_missing()` in `aether_common.gdshaderinc`) with `A_MISS_SEAM` -44, `A_MISS_X` 170, `A_MISS_LEN` (30, 130), `A_MISS_INWARD` 0.4, `A_MISS_W` (0.7, 16) ✱. The slice starts at a far-layer seam inside the picture, never the frame edge (NARR-001 N8), widens by tier, is flat VOID (`mix(void_lo, void_hi, 0.22)`), never black, and stops short of the entity's mid loss step. Tested: zero at T1 and strictly growing; drives saturation, slice and stars together; starts off-centre and never reaches the frame edge or the play core.

**T1 lit sun.** The dark orrery globe is now a lit brass sun (BONE_3 body, BONE_4 bloom); rings calmer (`ORRERY_CALM` 0.72 ✱). Rule: no dark, round, centred object in T1 (it pre-empts the entity). Open (TECH-001 Q-T124): §15.4's T1 row asks for "one dark smudge in the fog that is a little too still", while the pass 6 brief said "nothing in T1 darker than the fog". The smudge was kept pending an owner ruling.

**No closed circles (pareidolia extension, §16.6c).** Loss steps follow two spiral arms broken every half turn (`A_LOSS_ARM` 0.2 ✱) with a soft side toward the frame centre (`A_LOSS_SOFT` 0.08 ✱); the drain stretch is twisted off the radial (`A_DRAIN_TWIST` 0.5 ✱); `A_LOSS_REACH` 1.75 to 2.02 keeps the early-out provably conservative. Test: a CPU mirror of the loss boundary: at least 2 breaks per turn, no unbroken arc longer than π × 1.02, radius varies at least 0.9 × the arm. Same limits as §16.6c (CPU mirror, not a shader render).

**Entity edge.** A gradient of disintegration: crazing erodes inward (`A_ENT_ERODE` 0.42, `A_ENT_ERODE_K` 1.3 ✱) and dims inward; fragments start from 0.45 of the band (`A_ENT_FRAGMENT_FROM` 0.2 to 0.45 ✱). Black still only inside the mass (§16.6d).

**T4.** Dim panes get the same lit crack rim as open panes (tested).

**Cost (CH-7).** 1080p high, RTX 4070, same-session sweep, exhibits T1 / T2 / T3 / T4 / T5 / entity. Before pass 6: 2.561 / 3.081 / 3.006 / 2.639 / 2.865 / 3.477 ms. After: 2.549 / 2.797 / 3.011 / 2.730 / 2.990 / 3.580 ms. Pass 5 bars: 2.56 / 2.82 / 2.95 / 2.71 / 2.97 / 3.46. T5 (+0.125 vs before) and the entity (+0.10) are likely real (`A_LOSS_REACH` gives 1.33× more pixels that evaluate the shape near holes); T3 and T4 are within noise (±0.1 to 0.25). Pass 6 is over the pass 5 bar on T5 and the entity exhibit: TECH-001 Q-T125. Figures in TECH-001 §8.5.

**Known weaknesses (pass 6).**
- T5 centre and right fog reads as grey satin or curtain folds after desaturation (not brighter than the pool).
- T5 slice reads as a floating dark slab.
- T1 lit sun with its axis line may read as a scope or target.
- T4 dim pane is a fully outlined polygon.
- Greyscale sort T2 < T3 < T4 relies on reading the VOID slice; value alone does not order them (T3's leviathan is darkest).

Dev-route gating tests: `tests/test_dev_routes_gate.gd`. Backdrop and gallery load tests: `features/aether/tests/test_aether_backdrop.gd`, `scenes/dev/aether_gallery/tests/test_aether_gallery_loads.gd`.

### 16.6f M2 slice: Pale Marches (2026-11-19)
Slice part A (`AetherFarLayer`, `FrostPresence`, the reveal, the ladder; TECH-001 §2.9, §3.4). Rules in force:

**The Presence (ZONES-001 §2.3).** The Pale Marches Presence is a frost-drifting shelf of ice, bigger than the playfield (`FrostPresence` quad 1700×1000 ✱), only ever seen cropped, with a slow heartbeat of glass light (PHOS-4) travelling its veins. The leviathan stays the T3 Presence (PM ruling 2026-11-19, TECH-001 §11.2). Rules: far layer only; never a hitbox (no physics body under it); never adds light to the play layer; never black (body `far_silhouette`, `presence_pearl` AETHER-4, `presence_frost` BONE-3); it flees the entity (turns, accelerates away and dims over `FLEE_S` 6 s ✱, also on its own when the entity drains the world); heartbeat at most 1 Hz (built at one beat per 4 s ✱); under reduced motion and photosensitivity the pulse is held steady and the flee only dims in place.

**Lantern-down reveal (CH-3, ZONES-001 §2.3).** Lantern down fades the warm pool out and, over `REVEAL_FADE_S` 0.8 s ✱ (monotonic, no flicker), the far-band life (`reveal_life_count`) and the Presence's full lit pattern in. Far layer only: it changes nothing in the play layer. Lantern up, the Presence is a vague mass. The T3+ part (showing where the Aether is already gone) is not built: TECH-001 Q-T129.

**One-biome damage ladder (G-2, TECH-001 Q-T126; `data/aether/ladder/pm_t1..t5.tres`).** Each rung is the previous one plus one more kind of damage, so a still sorts cold: T1 intact (Presence here, rings turning); T2 life thinner and 1 ring stalled; T3 plus the Presence fleeing (35% gone) and the first sky crack; T4 plus the Presence gone, rings broken (1 snapped open) and panes open; T5 plus subtraction. Role laws (faction hues, phosphor = truth, SIGNAL ≤ 3) hold on every rung. The ladder is a capture aid, not the shipped tier table.

**Warp T1.** W1-01 Wrong Three and W1-03 Parallax Arrives are data on the PM-01 look; W1-06 Chromatic Edge's far-layer part is `set_chromatic_edge` (default off, never drawn under photosensitivity). WARP-001 §2.2 note.

**Known weaknesses (slice part A, by eye from the captures; needs an art pass).** (1) The Presence's ridge lines read as contour lines or a ruled grey panel rather than ice. (2) Ladder T1 and T2 are hard to tell apart at 25% scale, and T3's crack is tiny. (3) The unlit stand-in lantern shows a dark round glass at the play centre. (4) The ladder inherits tier-coded fog behaviour from other biomes. Cost: TECH-001 §8.5 (exhibit 6: high 2.259 ms, low 1.067 ms at 1080p on an RTX 4070). Tests: `features/aether/tests/test_aether_slice.gd`; captures: `aether_slice_capture` and `aether_ladder_capture` scenarios (TECH-001 §9.1); no score from The Reviewer exists for these captures.

#### The first Unmaking cinematic (slice part B, 2026-11-19)
Route `&"aether"` (`AetherArrival`, TECH-001 §2.9) plays beats 4 to 6 of the first Unmaking (GDD §6.1; timings in `UnmakingTimeline`, TECH-001 §9.1). Beat 4 (20 s): Pale Marches T1, the Presence far off with its heartbeat; a look-only tilt of at most 6 px ✱, none from beat 5. Beat 5 (40 s): the Presence turns and leaves, then the erasure front spreads. Beat 6 (22 s): the front reaches the last lamp, the lamp dims slowly, then black with one PHOS ember fading across the full 10 s, in silence. Art rules:
- **Origin.** The erasure starts off-centre, inside the picture, on the sphere seam at top left, behind where the Presence fled (never a centred iris, never from an edge).
- **Black.** The only true black is the entity (§16.1): black appears only inside the front. The sphere line ends at the front. Outside it the world keeps its colour, with a slow cold cast (drain) and no full-field step.
- **The last lamp.** `LastLamp` (a stand-in, not the Vigil) stands alone in the black: its hull hint is eaten first, the lamp dims, and one PHOS ember (truth: it was lit) fades over 10 s ✱. The lamp draws no black.
- **Zero startle.** No flash, no pop, no sudden luminance step (WARP-001 §4.5). Photosensitivity and reduced motion: no tilt; all luminance changes are monotonic and slow, bounded per frame (analytic, on the timeline: TECH-001 Q-T155; no capture with the setting on yet).
- **FrostPresence art pass.** Faceted translucent ice plates, broken ridges, PHOS crevasse light and frost haze, replacing the contour-line ridges of slice part A (its weakness 1).

**Known weaknesses (slice part B, by eye from the captures; needs an art pass).** (1) The Presence may read as crystal or rock shards rather than ice. (2) Its calving rim sits under the sphere band. (3) One sharp notch on the front's right flank at about t=50. (4) The black reaches the left frame edge about 6 s after it starts. (5) The erasure quad is very large (cost: TECH-001 §8.5, 1080p high 2.95 to 3.13 ms, low not measured). No score from The Reviewer exists for these captures.

### 16.6g The Ruins first visit (M2 slice part C, 2026-11-19)
The look of the Ruins of the Ninth Sky on the first visit (NARR-001 §5.7, GDD §6.4): a cramped, half-ruined cathedral-observatory hall, one warm lantern, deep VOID shadow, brass, glass and chalk, and the Aether felt outside. `RuinsLook` (`features/aether`) is the look only; the Ruins scene, its flow and its props belong to M1 (TECH-001 §2.9).

**Layer stack, bottom to top.** `AetherBackdrop` seen outside (a T1 Aether, veiled, with its lantern parked off-frame because the lantern is indoors); then the hall in its own canvas layer: ambient (`CanvasModulate`, VOID_3), surfaces (wall, floor, openings), set (arches, pilasters, ribs, orrery), placeholders (gallery stand-ins only), `stage` (M1's lit props), lights (`PointLight2D`s), flames, foreground, haze (light in dusty air, cool spill through the openings).

**Rules.**
- One hall lantern is the key light and is always the brightest light. Tree lamps are always below it (lantern law, as §16.3 law 4).
- The hangar mouth is lit only by Tree lamps: each lit lamp takes `mouth_share` of the darkness left (`1 − Π(1 − share × level)`), so the mouth only brightens as lamps catch.
- The Aether is felt outside, through the hangar mouth and the torn vault, always veiled so it reads far. The hall never shows it at full strength.
- No pure black anywhere (the only true black is the entity, §16). Ambient and shadow are VOID_3 and up.
- Lamps catch slowly and breathe gently (0.18 Hz, 3% depth); never a flash. Output changes by at most 0.02 per 60 Hz frame (photosensitivity bound).
- Brass is a BONE/VOID mix (§16.6a). GAS appears only in the flames, their glass and their light.
- Colours are `Pal` entries; every value is an engineering ✱ parameter (TECH-001 §3.4, `ds_aether.ruins_look`).

**Cost.** 1080p high, RTX 4070, not a clean run: about 2.9 ms GPU, mostly the full-quality Aether outside. Medium and low not measured (TECH-001 §8.5, Q-T157).

**Known weaknesses (part C).**
- The wall is a regular brick/ashlar pattern and reads more dungeon than cathedral; the cathedral read relies on the arches, pilasters and ribs.
- No occlusion shadows (`shadow_enabled` is false on every light).
- The torn vault shows mostly the navy far band of the Aether.
- Before any Tree lamp the hangar mouth is near-black by default (`mouth_veil_dark` 1.0 ✱, NARR-001 §5.7 "dark"); `mouth_aether_hint` (0..1, default 0 ✱) lets the owner bring back a faint glimpse of the Aether without code (TECH-001 Q-T156, agreed with M1, pending the owner).
- The left side is cluttered: the telescope crosses the chalk star chart.
- The orrery can read as an atom symbol.
- The flash and lantern-law tests are structural, not pixel-measured (TECH-001 §9.1, Q-T64).
- Authored for 640×360; wider aspects not designed (TECH-001 Q-T159).


### 16.7 The Aether Vigil: a brass lantern skiff with visible systems (ruled, PM under owner autonomy grant, 2026-11-19)

> **Status: ruled, PM under owner autonomy grant, 2026-11-19** (TECH-001 Q-T170; queued for the owner's later review). It goes with the Aether handling profile (GDD §4.2a, SYS-001 §1.1a). Act 0's neon Vigil (§3, §15.2) is unchanged.

**Intent.** In the Cabinet the Vigil is a simple wedge and a lamp. After THE PRETENCE the player should see the ship it always was: a hand-built Victorian lantern skiff with a keel, bellows and vanes. It is heavy, riveted and engraved, and every system the Lantern Tree brings online is a part you can see. The weight in the hands (GDD §4.2a) and the complexity in the art are the same idea.

**Silhouette.** The §3 grammar is kept and extended. It is still a wedge with a lantern globe on top and still symmetric. The **lamp globe stays the brightest pixel in the frame** (§3, palette law 4). What changes:
- **Length and keel.** The hull lengthens along a brass keel spine, so the ship has an obvious nose and an obvious heading: the keel *is* the heading tell. The composite grows from the Act 0 48×48 core toward ART-002's 128×64 nominal footprint (about 64 × 40 px of visible hull at the 640×360 frame, ✱).
- **The lamp on a gimbal.** The globe hangs in a brass gimbal above the hull and swings against acceleration: the visible sign of inertia. The Arc-Lance turret sits under the lamp and follows the aim, separately from the hull.
- **Stern drive.** Bellows and a flue at the stern, with gaslight in the flue. It brightens with thrust and dims when running dark.
- **Readability at gameplay scale.** At 640×360 the read order is: lamp (brightest), keel direction (the longest line), then everything else. Greyscale check: with the modules removed, the silhouette must still say "nose here, lamp there". Modules are small, never break the outline into noise, and never cover the lamp. The hitbox does not change (`ds_vigil.move.hitbox_circle_px` 🔒); the art grows around a small, honest core.

**Modules show the Lantern Tree** (sockets in ART-002 §4.1; node map in LOOP-001 §3.8). A bare Vigil is a hull, a keel spine, a lamp and one bellows. Each handling or survival node adds a part: trim vanes on the flanks (HULL-1, HULL-7), a keel lamp and blade (LANTERN-10, -13), extra bellows (LANTERN-1), lamp louvres (LANTERN-5), brake shutters on the cowl (HULL-3, -5, -15), a riveted plate (HULL-4), and an anchor ring and hook reel at the bow (HULL-9, ORDNANCE-1). Run Sigils keep their own reads on the sprite (LOOP-001 §4). At a glance, a veteran's ship looks different from a first launch: more systems online.

**Lamp and lantern lighting** (§5; §15.1 per tier).
- **T1:** the lantern is a real light (soft falloff, occluder shadows). Two small running lamps at the vane tips (GAS-2 glass, never brighter than GAS-3) show the heading in fog.
- **T2:** the flue glows, with bloom on the globe.
- **T3 and up:** god-rays from the lantern through the gimbal ribs, and normal-mapped brass on the hull.
- **Lantern Down:** the globe shutters to `lampGlobeDim`, the running lamps go out, and the flue dims to an ember (the drive runs weaker, GDD §4.2a). The Vigil becomes a dark brass shape in the fog. It must still read, through rim light from the fog and the phosphor Charge ring when Charges are carried.

**Instruments on the hull (the hull never lies).** These come from cosmic-horror change C-27 and are not invented here: up to 5 Charge lamps on the hull, then one phosphor ring for Charges 6–13, and a cockpit flame with 4 shape states for Composure. They sit on the sockets listed in ART-002 §4.1.

**Damage states.** The default is one hit (D-08 stays open), so the hull has only one damage read:
- **Plating (HULL-4) shears:** on the first hit the plate tears off in a GAS spark burst, and a patch of bare ribs stays for the rest of the Seam (or until HULL-14 re-arms it). Shape carries the read, not colour: the Vigil never uses SIGNAL, so the SIGNAL ≤ 3 budget stays with the threats.
- **Death:** the lamp gutters out first, then the hull goes dark and drifts. This matches the cinematic image of the unlit, drifting Vigil (M2 slice beat 6).
- **Second Vigil (HULL-6) revive:** the lamp relights before the hull does.

**Role laws** (§4 laws 1–5; §15.1 "what survives every rung"):
- No CHOIR on any Vigil part, at any tier.
- Brass is a BONE/VOID mix (§16.6a). GAS appears only in flames, glass and light.
- PHOSPHOR appears only on truth-telling things: the Charge ring and the Null-Iron Charges.
- The Vigil never uses SIGNAL.
- The lamp stays the warmest and brightest light in the frame.

**Generated only (D-13, D-14; §14).** The hull and modules are runtime vector parts (`Polygon2D` or draw calls in `Pal` colours, assembled on the ART-002 sockets), or pxl renders (`art/src/vigil_aether*.px.js`, ✱ names) for engraved static detail. The lamp swing, flue glow, shutters and plate shear change continuously, so they stay runtime. No hand-made or recorded file is used.
