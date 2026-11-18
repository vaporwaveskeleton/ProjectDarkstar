# DARKSTAR — Visual Quality Rubric

**Doc ID:** ART-004 · **Version:** 0.1 · **Date:** 2026-11-18 · **Owner:** Art · **Status:** rubric defined; **first provisional scoring pass done 2026-11-18** (§8: one reviewer, stills only, Act 0 + UI; L0b, L1 and the zoom unbuilt)

**Companions:** ART-001 (the look and its laws: this doc *measures* against them, it never adds a second rule set), ART-002 (module grid), UI-001 (screens and control states), WARP-001 §4.5 / §5 (accessibility and effect budgets), SYS-001 §9 (feel and performance numbers), TECH-001 §8 (frame budget), §11.2 decisions D-A…D-D.

**What this doc is.** A repeatable way to score how close DARKSTAR's *presentation* is to an approved quality bar, category by category and state by state, with evidence. **What it is not.** It does not claim the project has an AAA budget, team, content volume or scope. A score is a measurement of what is on screen against the approved references, nothing more.

---

## 1. Target art direction (owner-confirmed 2026-11-18)

> DARKSTAR is a top-down 2D arcade horror shooter that begins as a 1983 neon cabinet and tears open into a luminous Victorian aether. **Act 0 is a pretence in every sense:** flat neon shapes on true black, rendered low-res with hard pixels on the cabinet screen, framed by a real-world, native-resolution, full-colour printed bezel. At the end of the arcade section the camera **zooms into the screen**, the bezel leaves for good, and THE PRETENCE tears the pixel grid away. From then on the game renders at native resolution: layered coloured fog, crystal fields, drifting life and riveted brass-and-glass machinery, lit by one warm key light — the Vigil's lantern — whose beam is where the player's agency is. Enemies are ragged, ribboned, perforated organic shapes that read as silhouettes first. The entity is the only true black, and its presence subtracts colour, fog and light. The UI is modern game-UI structure (Returnal-grade hierarchy, focus and glyphs) wearing a chalk-and-brass skin, with phosphor teal reserved for truth and corrupted text as the warp's voice. Fidelity and resolution rise with the reveal; legibility never drops: value before hue, the gameplay layer crisp in front, fog capped where play happens.

Decisions behind it: TECH-001 §11.2 D-A (resolution), D-B (bezel), D-C (UI), D-D (benchmarks). Open items it depends on: TECH-001 §11.1 Q-T21…Q-T25.

### 1.1 The three presentation layers this rubric scores

| Layer | Resolution | Palette law | Scored for |
|---|---|---|---|
| **L0 Cabinet screen** (Act 0 play, attract, credits, THE PRETENCE start) | 640×360 pixel grid, integer scale, nearest | Neon Cabinet (ART-001 §15.2), role laws hold | arcade authenticity *as our own look*, readability |
| **L0b Bezel** (Act 0 only) | native | printed-ink palette, outside screen role laws (ART-001 §12.7) | print-art quality, and staying out of the way of play |
| **L1 Aether** (T1–T5 sectors, Ruins) | native, 640×360 logical | base + derived (ART-001 §15–16) | depth, light, life, horror-by-subtraction, readability under density |
| **UI** (menus, HUD, overlays, both eras) | L0 screen text: pixel; everything else native | ART-001 §11–12 | game-UI quality (§6) |

---

## 2. Reference analysis (owner uploads, `research/reference/`, viewed 2026-11-18)

Mood, never copy (ART-001 §9, RES-001 IP guardrail). Attributions of uploaded files are this doc's identification, not the files' metadata. `research/` is git-ignored (local only). Files are named `<source>_<kind>_<what-it-shows>` and sorted (2026-11-18) into `source-1983/`, `aether-style/`, `creatures/`, `cabinet-bezels/` and `benchmarks/<game>/`; the folder names below are relative to `research/reference/`.

| Group | Files | Take | Leave |
|---|---|---|---|
| 1983 source | `source-1983/` (1) | mood: score up top, radar inset, a big empty field | its face, sprites and layout (L0 is the Neon Cabinet, not a clone) |
| Sunless Skies (style anchor for L1, **not** an AAA benchmark) | `aether-style/sunless-skies_*` (4) | headlight beam as key light and focal point; steam wake; layered fog; crystal debris; tiny craft vs vast forms; name labels attached to the ship they name; HUD confined to corners (brass ring, portraits) | high-key near-white sepia washes (`sunless-skies_clockwork_high-key-fog`: ship ≈1 % of frame, low local contrast); large pure-black masses (only the entity is black, ART-001 §16.1) |
| Gaslite illustration | `aether-style/gaslite_*` | flat layered fog bands; stepped concentric lamp halo (banded falloff); navy ↔ amber complement — the most directly *generatable* reference | — |
| Steel Empire key art | `aether-style/steel-empire_*` | riveted, hand-made Victorian machine construction (Ruins, orrery, Vigil detail) | its texture density as-is at gameplay distance |
| Creature forms | `creatures/` (3; `unidentified_perforated-colossus` source unknown) | ragged ribbons (secondary motion), too many limbs, perforation holes (rhymes with the entity's NULL holes) | their beige/brown hues: Choir stays CHOIR-hued (faction law) |
| Returnal UI (AAA benchmark, UI) | `benchmarks/returnal/returnal_ui_*` (4; the scan hologram's attribution to Returnal is unconfirmed) | list / preview / detail columns; tab bar with shoulder glyphs; bottom input-hint bar; scanline hologram scans (Codex); corrupted text with keywords left legible; one filled cream button as the focus point; chamfered panels | teal on everything (teal = truth here, palette law 2); raw-looking ids (`AST-AR-017`); decorative micro-text |
| Cabinet bezels | `cabinet-bezels/` (12; one unidentified) | marquee; side panels with instructions; illustrated framing; on 16:9 the 4:3 screen leaves side columns for the bezel | — (bezel is outside screen palette law per D-B; must still be generated, D-13) |

**Shared language:** one warm key light against darkness as the focal point; depth by layered fog with value rising only where it matters; extreme scale contrast; machine (riveted brass, glass) vs organic horror (ribbons, holes, limbs); teal ↔ amber as the master pair (= PHOS ↔ GAS); text corruption as story.

**Essential to preserve:** lantern as the brightest warm value; silhouette-first enemies; the entity as the only black; the T0 → Aether inversion; teal = truth.

**Conflicts if combined naively:** printed bezel saturation vs a quiet play field (§5 cat. 10 checks it); Returnal teal-everything vs palette law 2; Sunless Skies high-key fog vs law 4 (nothing outshines the lantern) and the fog ceiling (ART-001 §16.3); painted 1080p texture vs generated-only (D-13) — carry value, composition and light, rebuild texture as shader.

---

## 3. Benchmarks and evidence register

### 3.1 Approved comparison set (D-D)

| Benchmark | Tier | Camera match | Scored on |
|---|---|---|---|
| **Returnal** (Housemarque) | AAA | third-person 3D — mismatch | UI and menus; VFX readability under bullet density; corrupted text; horror tone; cohesion |
| **Saros** (Housemarque) | AAA | third-person 3D — mismatch | as Returnal; plus lighting mood |
| **Ball x Pit** | indie (not AAA) | top-down, dense — match | gameplay-frame readability at density; game feel; top-down composition; upgrade/choice UI flow |

Rule: a benchmark is scored only on categories its camera and medium allow (marked per category in §5). A gap to Returnal or Saros is a *presentation* gap, never "needs AAA money".

### 3.2 Evidence on file

| Source | Provided | Missing (blocks scoring) |
|---|---|---|
| Returnal (`benchmarks/returnal/`) | 3 UI screens (Databank) + 1 scan; 2 gameplay frames viewed (boss fight with HUD; co-op forest with a legal-text overlay); 1 `.avif` gameplay frame **not viewed** (format unreadable here) | a dense bullet frame; the `.avif` re-saved as PNG or JPG |
| Saros (`benchmarks/saros/`) | 5 gameplay (incl. 2 dense boss frames, 1 with HUD), 1 vista, 1 cutscene, 1 menu (Carcosan modifiers) | — |
| Ball x Pit (`benchmarks/ball-x-pit/`) | 3 gameplay (early, mid, dense), 3 UI (fusion select, fission reward, evolution recipe) | — |
| DARKSTAR current game | kit sheets in `docs/02-art/screens/` (8 PNG); **Act 0 captures taken 2026-11-18** (§8.3): attract, quiet play ×2, mid-density play ×2, THE PRETENCE start, the maw, the post-reveal stub ×4 — native 640×360 stills from `--write-movie` at 30 fps, `--no-save` | Awakening / rampage, hit/death, game over, stage clear, credits, pause, settings, confirm; a genuinely dense frame (Guard, Litany Ring, 32 units ✱); a display-size (1080p+) capture; live motion review |
| DARKSTAR L1 Aether, bezel, zoom-in | **not built** | cannot be evaluated until built |

Any state not in "Provided" is reported as **not evaluated**, never guessed.

---

## 4. Movement and animation inventory

What the finished game must communicate through motion. Numbers are SYS-001's (cited); this table owns none. "Clip" = an authored sequence; "system" = the runtime that blends, drives and syncs it. DARKSTAR has almost no authored clips: motion is procedural or shader-driven (D-13), so review is of the *system*.

| Mover | Gameplay purpose | Layers (authored / procedural / shader) | States and transitions to read | Contacts and sync | Review at gameplay distance |
|---|---|---|---|---|---|
| **Vigil** (SYS-001 §1.1–1.2) | where I am, where I face, how fast | procedural: thrust lean, 60 % hull rotation toward aim (GDD §4.1), wake trail; shader: lantern cone | idle drift → thrust (accel 2600 px/s²) → max 340 px/s → brake (0.28 s reversal); Surgelight burst 0.18 s; hit; post-hit grace 0.75 s ✱ | wake length ∝ speed; thrust SFX; screen shake ≤ 4 px (SYS-001 §9); lantern cone moves with aim | can a viewer read heading, speed band and Surgelight readiness from a 2 s clip? |
| **Lantern cone** | aim, mining, Choir detection | shader | aim-up vs aim-down (mining 100 % / 65 %; detection +180 % / −60 %) | cone = key light from T1; phosphor glints on glass | is up/down state legible without the HUD? |
| **Arc-Lance bolts** (§1.3) | my fire, its reach | vector | 6/s, 340 px/s, 14 px; pierce; geode face hit; over-fire detonation (≥ 9 in 1.2 s ✱) | hit spark (1 px chalk flecks, ART-001 §7), audio tick | bolts distinct from Choir shots in greyscale |
| **Null-Iron Charge** (§1.4) | the win condition | vector + brass-lamp trail | launch 210 px/s, homing 1.6 s, intercepted, fuse 0.9 s at a Shrine, hit entity (13 to unmake) | pip shatters on the HUD; impact on entity throws PHOS-5 shards + NULL holes closing over 6 frames | is "my Charge is in flight / was eaten / landed" readable? |
| **Shards / glass** | economy | procedural drift, magnet 96 px | float → magnetised → collected; carried by Grubs at 130 px/s | collect chime | ownership: floating vs carried vs deposited |
| **Choir units** (SYS-001 §3) | threat and telegraphs | procedural locomotion + ribbon secondary motion (ref: creature group) | Grub flee 190; Acolyte tell 21 f + turret lag 15 f; Deceiver tell 18 f; Listener tell 8 f then 380 px/s charge; Herald tell 24 f; Penitent drift | chant positional ≤ 420 px (audio); telegraph frame = audio cue frame | every tell is visible within its frame count, in greyscale, at 32 units on screen ✱ |
| **Sepulchre / entity** (§2) | the clock and the boss | modular assembly (20 modules), shader body | Procession → Guard (Litany Ring 8 nodes) → Quickening → Awakening (silence, "IT WAKES.", 3 s stagger) → rampage 150–260 px/s; repair (eat a geode, 2.0 s); module knock-off | silence in audio; camera zoom 1.0 → 1.06 by T3 (GDD §4.2) | is the assembly count readable at a glance? is rampage speed visibly below the Vigil's? |
| **Composure wick** (GDD §10) | sanity | shader flame | Clear / Frayed / Unmoored / Hollowed bands | chromatic edges ≤ 2 px at Frayed | band readable from flame height alone |
| **Camera** (GDD §4.2, SYS-001 §9) | framing | procedural | 0.12 s follow, 24 px deadzone, 1.5 % lookahead, zoom breathing at T5 | shake ≤ 4 px / 0.25 s; warp shake ≤ 2 px ✱ | never loses the Vigil or a telegraph; reduced-motion variant |
| **Act 0 → L1 zoom-in and THE PRETENCE** (D-B, GDD §6.1) — **the game's main hook** (§7.1) | the signature reveal | camera push; bezel destruction (peel, crack, decay, warp — procedural fracture, shader decay); pixel grid tears; palette morph | bezel framed → push-in begins → bezel peels/cracks/decays/warps away → through the screen → grid tears → Aether | music cut, chiptune → score stem | reduced motion = 1-frame cut, same end state (ART-001 §12.7) |
| **Aether life, fog currents** (ART-001 §16.2) | the world is alive | particles, shader | drift; flee the entity; absence as a tell | — | never mistaken for a hitbox |

---

## 5. The rubric

### 5.1 How to score

- Score each **applicable** category 1–10 per layer and per state, from evidence. Use the anchors; interpolate between them.
- **Facts vs interpretation:** every score lists observed facts (what is on screen, measurements) separately from judgement.
- **Weights** below sum to 100. For a layer where a category is "n/a", drop it and renormalise the rest.
- **Layer score** = weighted mean of its applicable categories.
- **Overall readiness** = weighted mean of layer scores (L0 20 %, L0b 5 %, L1 55 %, UI 20 % ✱ review weights) **capped at the weakest critical state + 2** (§7), so one attractive frame cannot hide an unreadable one. While L1 is unbuilt, report L0/L0b/UI readiness only and say so.
- Benchmarks are scored with the same anchors on the categories marked for them (B = Returnal/Saros, P = Ball x Pit).

### 5.2 Category table (weights)

| # | Category | Weight | L0 | L0b | L1 | UI | Benchmarks |
|---|---|---|---|---|---|---|---|
| 1 | Focal read and one-second readability | 12 | ✓ | ✓ | ✓ | ✓ | B, P |
| 2 | Silhouette and shape grammar | 8 | ✓ | ✓ | ✓ | — | P |
| 3 | Value, colour and role-law separation | 10 | ✓ | ✓ | ✓ | ✓ | B, P |
| 4 | Gameplay-state readability | 12 | ✓ | — | ✓ | ✓ | B, P |
| 5 | Action and VFX readability | 10 | ✓ | — | ✓ | — | B, P |
| 6 | Motion and animation system | 9 | ✓ | — | ✓ | ✓ | B, P |
| 7 | Aether depth, environment and world scale | 7 | — | — | ✓ | — | P (scale only) |
| 8 | Lighting (the lantern law) | 6 | — | — | ✓ | — | B |
| 9 | Camera and screen-space composition | 5 | ✓ | ✓ | ✓ | ✓ | P |
| 10 | Cross-layer cohesion and the fidelity ladder | 5 | ✓ | ✓ | ✓ | ✓ | B |
| 11 | Technical image integrity | 6 | ✓ | ✓ | ✓ | ✓ | B, P |
| 12 | Game UI and HUD presentation (§6) | 10 | — | — | — | ✓ | B, P |

### 5.3 Category definitions

Each: **measures** · anchors **1 / 5 / 8 / 10** · **AI-generated failure modes** (code- and model-generated art alike) · **objective checks**.

**1. Focal read and one-second readability** — can a player, after one glance, name: the Vigil, the current state, the immediate threat or opportunity, the available action, the likely consequence?
- 1: no focal point; the Vigil is lost. 5: Vigil found in ~1 s, threat found only by searching. 8: Vigil, nearest threat and objective in the intended order in < 1 s. 10: as 8 under worst-case density (32 units ✱, 180 shots ✱), and the eye path is designed (lantern → threat → objective).
- AI failure modes: everything equally detailed; glow on every object; symmetric centred compositions that put nothing in focus; noise "richness" that buries the player.
- Checks: 250 ms flash test with 3 viewers (name the 5 items); 8 px Gaussian-blur squint at 1080p — Vigil and SIGNAL objects still separable ✱; greyscale capture.

**2. Silhouette and shape grammar** — does each role own a shape (ART-001 §3) that survives at gameplay size and in motion?
- 1: units are blobs; roles indistinguishable. 5: roles distinct when still, merge in groups. 8: every role identifiable in black-fill silhouette at gameplay size, in a group of 6. 10: identifiable mid-motion and at half size; the entity's assembly stage readable from silhouette alone.
- AI failure modes: procedural sameness (every unit a spiky radial); detail inside the silhouette instead of on its edge; ribbons that hide the body's read.
- Checks: black-fill silhouette sheet per role at 1× gameplay size; group-of-6 overlap test; ART-001 §10 sprite DoD.

**3. Value, colour and role-law separation** — value before hue; faction hues; PHOS = truth; SIGNAL ≤ 3; GAS is the player's; L1: nothing outshines the lantern; only the entity is black.
- 1: palette laws broken; value flat. 5: laws held, but gameplay and background share value ranges. 8: gameplay layer always in the top value/contrast band; laws verified. 10: as 8 across all tiers, with fog and bloom, and in colour-blind simulation.
- AI failure modes: rainbow particles; teal used decoratively (breaks law 2); bloom raising background past the lantern; pure black used as "dark" in the Aether.
- Checks: palette test (`core/ui/tests/test_theme_palette.gd`) for UI; frame histogram: max background luminance < lantern core ✱; SIGNAL object count per frame ≤ 3; greyscale + deuteranopia/protanopia/tritanopia simulation; any `#000000` pixel outside entity masks in L1 = defect.

**4. Gameplay-state readability** — threat, target, objective, resources, danger, cooldowns, owned vs carried shards, Charges in flight, Sepulchre phase, Composure band, warp tier, valid vs invalid.
- 1: state only in numbers or not at all. 5: state readable from the HUD but not in the world. 8: each state readable in the world *and* the HUD, with a shape cue, not colour alone. 10: as 8 while the warp lies (WARP-001 §4.2) and Steady Ledger stays honest.
- AI failure modes: state shown only by colour; HUD numbers instead of diegetic cues; telegraphs indistinguishable from idle animation.
- Checks: state checklist per frame (§7); colour-removed capture still shows state; telegraph frame counts from SYS-001 §3 are visible (frame-step the capture).

**5. Action and VFX readability** — anticipation, trajectory, contact, impact, effect priority; effects never obscure a unit, shot, hazard, text or decision.
- 1: effects bury play. 5: impacts read; telegraphs sometimes lost in effects. 8: an effect priority order is visible (telegraph > enemy shot > player shot > impact > ambience); nothing occludes a hitbox. 10: as 8 at worst-case density and at T5, with photosensitivity variants equal in information.
- AI failure modes: particle spam; bloom halos larger than hitboxes; additive blending that whitens dense fights; uniform particle timing.
- Checks: "paused at 100 % and greyscale" rule (ART-001 §7); flicker ≤ 3 cycles/s (WARP-001 §4.5); shake ≤ 4 px; WARP-001 §5.2 effect ceilings measured.

**6. Motion and animation system** — weight, anticipation, follow-through, secondary motion (ribbons), procedural locomotion, transition quality, sync with audio/camera (§4).
- 1: things slide or pop. 5: motion correct but mechanical; transitions snap. 8: every §4 state has a readable transition; secondary motion adds read, not noise; audio sync on the frame. 10: motion carries character (liturgical procession, wrong symmetry) and every state reads from motion alone.
- AI failure modes: sine-wave everything; identical phase across a group; secondary motion that never settles; easing on hit-truth.
- Checks: frame-step captures at 60 fps; group phase variance; hit truth is separate from animation (CLAUDE.md §3); reduced-motion variant exists for each.

**7. Aether depth, environment and world scale** (L1) — fog layers, crystal-sphere skies, landmarks, scale references, life, biome weathers (ART-001 §16), horror-by-subtraction.
- 1: flat backdrop; black vacuum. 5: layered fog, but uniform and unlocated. 8: three depth bands, landmarks, a visible sphere curve, ambient life that flees the entity. 10: each biome a distinct weather; subtraction reads as dread; fog never hides play (§16.3 ceiling).
- AI failure modes: noise fog with no structure; repeated tiles; "space nebula" clichés; life that looks like hitboxes.
- Checks: parallax band count; fog density at play layer ≤ WarpComposer ceiling; unit-visibility test at max fog.

**8. Lighting — the lantern law** (L1) — the lantern is the key light and focal point; emitters (glass, Shroud, veins) are secondary; shadows from occluders.
- 1: no light logic. 5: lantern lights but competes with emitters. 8: lantern is always the warmest, brightest local light; emitters read as secondary; shadows ground forms. 10: lighting tells story (eaten light, dying emitters at T5) without costing readability.
- AI failure modes: global bloom; every object self-lit; light with no source.
- Checks: luminance of lantern core vs top emitter per frame ✱; light-source inventory per frame.

**9. Camera and screen-space composition** — focal placement, crop, edge safety, UI footprint, gameplay occlusion; L0b: the screen remains the focal rectangle.
- 1: HUD covers play; threats arrive from off-screen unannounced. 5: safe, but HUD heavy or arbitrary. 8: HUD ≤ corners, play area unobstructed, lookahead shows threats in time. 10: composition adapts with the camera rules (§4) and every state frame has a deliberate eye path.
- AI failure modes: centred everything; HUD panels as full-width bars; decorative frames eating play space.
- Checks: HUD footprint % of frame ✱; safe area at 200 % text (SYS-001 §9); off-screen threat indicators.

**10. Cross-layer cohesion and the fidelity ladder** — do units, environment, UI, type, VFX and light share one grammar at each tier, and does the T0 → Aether inversion read as the same world revealed?
- 1: layers look like different games. 5: consistent within a layer, disjoint across. 8: role grammar and palette roles continuous across the zoom and the morph. 10: the reveal re-reads Act 0 in hindsight.
- AI failure modes: style drift between generators; UI from a different genre; bezel art that out-shouts the screen (L0b).
- Checks: side-by-side role sheet T0 vs T1; bezel test: screen region is the highest-contrast rectangle in L0b frames ✱; nothing on the bezel moves during play.

**11. Technical image integrity** — L0: integer scale, no sub-pixel shimmer, no mixed pixel sizes, CRT pass stable. Native: anti-aliased vector edges, no banding in fog gradients, no aliasing crawl, correct transparency, stable at 1080p/1440p/4K, low-res post buffers not visibly blurry on gameplay elements.
- 1: shimmer, mixed pixel scales, banding everywhere. 5: clean at one resolution only. 8: clean at all supported resolutions and in motion. 10: as 8 with every effect at every quality preset.
- AI failure modes: mixed pixel densities in L0; gradient banding; dithering noise; blurry upscaled pxl renders in L1 (Q-T22).
- Checks: capture at 720p/1080p/1440p/2160p; motion capture for crawl; pixel-grid audit on L0 frames.

**12. Game UI and HUD presentation** — scored by the UI sub-rubric (§6); its result enters here.

---

## 6. UI sub-rubric

Read UI as **game UI, not a website**. One-second test per screen: where am I, what can I do, what matters next, am I progressing, am I in danger?

| Sub-item | Anchor 8 looks like | Failure flags |
|---|---|---|
| Hierarchy | one primary action per screen, visibly heavier; list / preview / detail where browsing (D-C) | equally weighted actions; text walls |
| Control states | all of idle, hover, focus, pressed, disabled, selected, busy, error, cooldown per ART-001 §12.2, shape-coded | unstyled engine widgets; colour-only state |
| Focus and navigation | one default focus, no dead ends, `ui_cancel` everywhere (UI-001 §4), focus ring never clipped | focus lost on scroll; mouse-only flows |
| Typography | ART-001 §11 faces; 200 % text fits the safe area | micro-text; web-sized labels |
| Icons and glyphs | chalk icons paired with labels; live input glyphs (ART-001 §12.6) | inconsistent icon styles; wrong-device glyphs |
| Semantic colour | GAS = focus/agency, PHOS = truth, never SIGNAL in menus (§12.1) | arbitrary colour; red errors |
| Skin cohesion | chalk-and-brass skin over modern structure (D-C) | generic dashboard cards; sci-fi chrome |
| Feedback and timing | audio + visual on every state change; transitions short and skippable; reduced-motion cut | decorative slow transitions |
| Player-readable text | `tr()` keys; no ids, enums, paths, raw errors (CLAUDE.md §3) | `AST-…`-style ids on screen |
| HUD | corners only; diegetic where possible (wick, pips, compass); lies authored, Ledger honest | HUD bars across play |

States reviewed per button: idle, hover, focus, pressed, disabled, selected, busy, error, cooldown (only where the control has the state).

---

## 7. Visual-state matrix

Score each state on its critical categories. **Weakest critical state** = the lowest score in any row marked critical. Fill only from evidence; otherwise "not evaluated".

| State | Layer | Critical categories | Built? | Evidence | Score |
|---|---|---|---|---|---|
| Attract / title | L0 + L0b + UI | 1, 9, 10, 12 | yes (bezel no) | §8.3 A | provisional, see §8.3 |
| Quiet play (early Procession) | L0 | 1, 3, 4 | yes | §8.3 B | provisional, see §8.3 |
| Dense play (Guard, Litany Ring) | L0 | 1, 4, 5 (critical) | yes | §8.3 C: frames are mid-density only (≤ 8 objects) | **not evaluated** for density; cat. 4 provisional |
| Awakening / rampage | L0 | 1, 4, 5, 6 (critical) | yes | not provided | not evaluated |
| Hit / death / game over | L0 + UI | 4, 5, 12 | partly (death screen planned) | not provided | not evaluated |
| Stage clear / credits | L0 + UI | 9, 10 | yes | not provided | not evaluated |
| **Zoom-in and THE PRETENCE — the hook (§7.1)** | L0b → L0 → L1 | 1, 6, 10, 11 (critical, bar ≥ 9 ✱) | zoom no; reveal partly | §8.3 D–F (stills only) | **bar not met by construction** (no bezel, no zoom); motion not evaluated |
| Pause / settings / confirm | UI | 12 (critical) | yes | not provided | not evaluated |
| Loading curtain | UI | 12 | yes | not provided | not evaluated |
| Aether quiet / dense / boss / vista | L1 | all | no | — | not evaluated |
| Ruins hub, Lantern Tree, Codex, run summary | UI | 12 | no | — | not evaluated |

### 7.1 The hook: the zoom-in (owner, 2026-11-18)

The zoom-in — bezel peeling, cracking, decaying and warping while the camera pushes through the screen into the Aether — is the game's main hook. It is scored as its **own critical state** with a higher bar: **target ≥ 9 on categories 1, 6, 10 and 11** ✱, reviewed as live motion (never stills only). Show-stopper checks:

1. **Escalation:** the destruction builds in stages (first hairline crack → peel → decay → warp → break-through), each readable on its own, not one simultaneous effect.
2. **Material truth:** the bezel breaks like what it is (printed plexi and ink: crazing, flaking print, curling decals, glass splinters, light bleeding through cracks), and the low-res screen breaks like a pixel grid — two different physics, one moment.
3. **The reveal leads the eye:** Aether light and colour bleed through the cracks *before* the break-through, so the viewer's eye is pulled into the screen.
4. **Sound and camera lock:** each stage lands on an audio beat; camera push has an ease and a hold, never a constant-speed zoom.
5. **Thumbnail and trailer test:** any 3 s slice still reads as a "what is happening to this game?" moment in a 360p capture.

Accessibility variants (reduced motion: 1-frame cut; photosensitivity: no full-field luminance steps) keep the same end state. Building it at this bar is a specialist item in the improvement plan (procedural fracture + shader decay + camera choreography).

Annotation (when frames arrive): mark intended focal path, competing focal points, occluded gameplay, unclear state indicators and the highest-impact correction on each critical frame.

---

## 8. Score sheets

### 8.1 Category comparison (first pass, 2026-11-18)

One reviewer, stills only, provisional. DARKSTAR = Act 0 (L0 screen + UI) only; L0b, L1 and the zoom are unbuilt. DARKSTAR category scores are the mean of its §8.3 state scores as re-scored in §8.6; benchmark scores come from §8.2. "n/e" = not evaluated (no evidence, or the category does not apply to that benchmark's camera, §5.2). "Gap" = best applicable benchmark minus DARKSTAR.

| # | Category | DARKSTAR | Returnal | Saros | Ball x Pit | Gap | Gap type | Smallest change to close | Realistic? |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Focal read | 7.2 (6–8) | 8 | 8 | 6.7 | 0.8 | camera, consistency | give every reveal frame a focal subject; keep banners off the focal subject | yes |
| 2 | Silhouette | 6 | n/e | n/e | 8 | 2 | asset quality | role silhouettes about 1.5× larger at 640×360, with a unique outline per Choir role | yes |
| 3 | Value / colour / roles | 8 | 8 | 9 | 7 | 1 | — (strength) | keep; the laws work | yes |
| 4 | Gameplay-state readability | 6.5 | 7 | 8 | 7 | 1.5 | UI | Sepulchre count done (§8.6); next: a Charge-in-flight cue | yes |
| 5 | Action and VFX | n/e | 7 (partial) | 9 | 7 | — | — | capture a real Guard/Litany frame before judging | — |
| 6 | Motion | n/e | n/e | n/e | n/e | — | — | live-motion review needs video | — |
| 7 | Aether depth | n/e (L1 unbuilt) | n/e | n/e | 7 (scale only) | — | — | — | — |
| 8 | Lighting | n/e (L1 unbuilt) | 8 | 9 | n/e | — | — | — | — |
| 9 | Composition | 5.7 | 8 | 8 | 8 | 2.3 | UI, camera | shrink the side HUD panels or carry real information in them (Ball x Pit gutter model) | yes |
| 10 | Cohesion / ladder | 6 | 8 | 9 | 8 | 3 | art direction | the zoom (§7.1); one type system for L0 | needs specialist for the zoom |
| 11 | Image integrity | 5.5 | n/e (web-compressed) | n/e (web-compressed) | 8 | 2.5 | technical presentation | one type style per layer; fix the blocky fog patches | yes |
| 12 | Game UI | 6 | 8 | 8 | 7 | 2 | UI | HUD type and primary button done (§8.6); next: one type system for L0 menus | yes |

Unweighted means over each column's scored cells, for orientation only (different category sets, not comparable as rankings): DARKSTAR 6.4 (5.9 before the §8.6 quick wins) · Returnal 7.8 · Saros 8.5 · Ball x Pit 7.4.

**Category 2, DARKSTAR (new this pass)** — facts: the Vigil is a yellow chevron; Choir units are small magenta glyphs; geodes are white polygon outlines; at 640×360 units read at roughly 8–16 px. Interpretation: roles separate by colour more than by shape; in greyscale the Acolyte and Grub glyphs are close.

### 8.2 Benchmark evidence (files in `research/reference/benchmarks/`)

**Returnal** (UI ×4, gameplay ×2 viewed; 1 `.avif` unviewed; no dense bullet frame).
- Facts: Databank has three columns (list, preview, detail), an L1/R1 tab bar, a bottom input-hint bar, and the selected item as the one cream-filled button; corrupted text keeps keywords in a warm accent; small all-caps ids sit above titles. In `returnal_gameplay_boss-fight_hud` the player wears a white outline that separates her from a busy boss frame; projectiles are white-yellow; HUD sits in the bottom corners. `returnal_gameplay_coop-forest_*`: a self-lit teal enemy and orange beams against a dark teal forest.
- Interpretation: player-highlight outline is the key trick for focal read in clutter (cat. 1: 8). UI anchors at 8; its ids and micro-labels would fail our player-text rule if copied. Cat. 5 is partial (7) without a dense frame.

**Saros** (gameplay ×5, vista, cutscene, menu).
- Facts: bullet types are colour-split (blue orbs vs red stars in `bullet-lanes_hud`); `boss-prophet_ring-patterns` is concentric yellow rings around a central focal point, with the player as a dark silhouette in front; `boss-bastion_dense` has hundreds of blue orbs and the boss is largely hidden behind them; HUD: boss name and bar top centre, integrity arc bottom left, counters bottom right, objective top right; the world is amber with cool-blue danger. The Carcosan modifiers menu has a tab bar with shoulder glyphs, a dial gauge as the focal point, two side columns, icon grids with lock icons on locked items, a detail card, a bottom glyph bar, and is monochrome orange.
- Interpretation: the strongest benchmark: patterns *as* composition (cat. 5: 9), warm world vs cool danger (cat. 3: 9), eclipse rim-light (cat. 8: 9). The density of `boss-bastion_dense` buries the boss (cat. 1 in that frame: 7). The menu's monochrome makes semantic colour weak; state is carried by greys and lock icons (cat. 12: 8).

**Ball x Pit** (gameplay early / mid / dense, UI ×3).
- Facts: vertical playfield centred, HUD in the side gutters (health/XP sword gauge left, level-progress column right, resources and ball inventory top left, speed buttons top right); enemies sit on block tiles in rows; large red damage numbers; danger tiles red; in `dense_ice` the player is a small dark figure low on a blue-grey floor. UI screens: four framed cards over a starfield with one action button (`Fuse!`), a reward screen with "+1 Level" labels and a "Whoa" button, a recipe screen with a framed tooltip.
- Interpretation: the closest structural match to Act 0 (vertical field, side gutters that carry real information, cat. 9: 8). Its weakness is the player getting lost at density (cat. 1 in `dense_ice`: 6). UI is clear with one primary action per screen but small type (cat. 12: 7).

### 8.3 First evidence pass: Act 0, DARKSTAR only (2026-11-18)

**Method and limits.** One reviewer (not the two §9 requires), native 640×360 stills pulled from four headless `--write-movie` runs at 30 fps (`--no-save`; stage 0 autopilot; stage 1 with `--segments=10`; stage 1 with `--segments=20 --hits=2`; attract). Stills only: **motion categories (6) and the hook's live-motion review are not evaluated.** No display-size capture, so integer-scale and blur at 1080p+ are not evaluated. Benchmarks are not scored (their gameplay frames are missing, §3.2), so there is **no gap column and no overall readiness score yet**. Scores are provisional until a second reviewer agrees. Frames live in the session scratchpad (`…/scratchpad/cap/`), not in the repo; the frame ids below are `<run>/f<frame>.png`. **Stale for states A, B and D:** these captures predate the merge of PR #1 (arcade power-on, attract instruction cards, the placeholder bezel mockup, TECH-001 Q-T20); re-capture before the next scoring pass.

| Id | State | Frame ids | Facts (observed) | Interpretation | Scores (provisional) |
|---|---|---|---|---|---|
| A | Attract / title | attract/f90 | Yellow pixel-type DARKSTAR logo centred; three equal-width buttons below; the focused one has a gold outline; "INSERT CREDIT" and "HI 0" are ~5 px type in dim grey-blue; button labels are smooth anti-aliased type, the logo and credit line are pixel type | Clear title read, focus visible and in GAS (ART-001 §12.1). Mixed pixel and smooth text inside one L0 frame (cat. 11 flag). Equal-width buttons give weak primary/secondary weight | 1: **8** · 3: **8** · 9: **6** · 11: **6** · 12: **6** |
| B | Quiet play | play/f150, play/f1200 | Yellow Vigil triangle, cyan glass geode, magenta Choir; side HUD panels ≈ 70 px each (≈ 22 % of frame width together, measured from the capture); HUD labels (VIGILS, GLASS, 1UP, HI) ≈ 5 px in dim blue on navy; "INSERT CREDIT" sits on the lower-left panel; Charge pips: cyan full, blue empty | Role colours hold (GAS player, CHOIR magenta, PHOS glass). Vigil is found at once. HUD labels are hard to read at gameplay distance. Sepulchre progress is not shown outside the minimap | 1: **7** · 3: **8** · 4: **5** · 9: **5** · 12: **4** |
| C | Mid-density play | dense/f300, dense/f900 | ≤ 8 objects on screen; orange shots, one Acolyte, a faint dotted horizontal line across the lower third in f900 (cause not identified) | **Not a dense frame.** Telegraph and effect readability at 32 units ✱ / 180 shots ✱ cannot be judged. No segment count or Sepulchre phase on the HUD | 1: **7** · 4: **4** · 5: **not evaluated** |
| D | THE PRETENCE begins | reveal/f600 | Banner "THAT WAS A PRETENCE." in large white pixel type, centred; the side panels have broken into jagged blocks; Choir glyphs and shots still around the Vigil | The panel break is the first, small hint of destruction. It reads as a glitch, not a spectacle. There is no bezel to break and no zoom | 1: **7** · 10: **5** · hook bar (§7.1): **not met** |
| E | The maw | reveal/f900 | Black disc with ring of teeth and a cyan eye, centred; a full-width black banner "ONE SKY LESS." covers its upper third; faint purple haze starts behind | Strongest frame captured: an unmistakable focal point and the "only true black is the entity" law in action. The banner hides part of the focal subject | 1: **8** · 9: **5** · 10: **7** |
| F | Post-reveal stub | reveal/f1100, f1300, f1500, f1800 | f1100 is almost empty (dark purple haze, one orange dot); later frames show a thin amber arc, a single lamp rod, a title and a prompt; vertical rectangular fog patches visible along the right edge in f1300 and f1500 | This is the Ruins stub (`ruins_stub`), not the Aether. Not scored as L1. Observations to carry forward: the first frame after the maw has no focal read, and the fog shows blocky rectangular artifacts | 1 (f1100): **2** · 11: **5** (fog blocks) · cat. 7, 8: **not evaluated** (L1 unbuilt) |

**Weakest critical state:** the hook (D to F, §7.1): the screen-to-Aether transition has no bezel, no zoom and a near-empty first frame. **Largest screen-space failure:** the Act 0 HUD, with small low-contrast labels in panels taking ≈ 22 % of the width (B). **Not evaluated:** Awakening/rampage, death, game over, stage clear, credits, pause, settings, confirm, live motion, display-size scaling, all of L1 and L0b.

**Smallest changes most likely to raise scores (all from the facts above):**
1. HUD labels in B: raise to the next type size and a BONE ramp value with clear separation from the navy; move "INSERT CREDIT" off the panel. Gap type: UI.
2. State C/B: add a segment count or phase mark to the Act 0 HUD (SYS-001 §2 phases). Gap type: UI.
3. ~~State E: move or shrink the banner so it never covers the maw's centre.~~ **Withdrawn:** ART-001 §11.5 fixes the entity's NULL band at y = 120 on purpose ("a hole torn in the frame"); it covers the maw's ring, not its eye. The rule wins; state E's cat. 9 score stands as a known, accepted trade-off.
4. State F: give the first post-reveal frame a focal subject (the lamp rod appears late; bring it in first) and replace the blocky fog patches. Gap type: technical presentation.
5. State A: make the primary button visibly heavier than Settings and Quit, and decide whether L0 menus use pixel or smooth type. Gap type: UI / consistency.
6. The hook: build the bezel, the zoom and its destruction stages (§7.1). Gap type: art direction and animation; needs a specialist.

### 8.4 Visual-readiness score (partial, 2026-11-18)

Measures presentation against the approved references only. It does not claim an AAA budget, team, content volume or scope.

| Layer | Score | How |
|---|---|---|
| Layer | First pass | After quick wins (§8.6) | How |
|---|---|---|---|
| L0 Cabinet screen | 6.0 | **6.6** | weighted mean (§5.2) over the scored categories 1, 2, 3, 4, 9, 10, 11 (weights 58 of 100); cat. 5 and 6 not evaluated |
| L0b Bezel | not evaluated | not evaluated | placeholder mockup visible in the new frames (TECH-001 Q-T20); not scored as the final bezel |
| L1 Aether | not evaluated | not evaluated | not built |
| UI | 5.0 | **6.0** | cat. 12 (§6), from attract + Act 0 HUD only |
| **Overall (L0 + UI only)** | 4.0 (capped) | **6.3** | uncapped (6.6 + 6.0) / 2 = 6.3; cap = weakest critical state + 2 = 5 + 2 = 7, so no longer binding. Weakest critical scores are now 5: THE PRETENCE cohesion (§8.3 D, cat. 10) and the fog blocks (§8.3 F, cat. 11) |

Read the 6.3 as: a solid arcade screen with a readable HUD, still without its hook. The §7.1 hook bar (≥ 9) remains **unmet by construction**: no bezel destruction and no zoom exist yet. The cap rule only catches single weak frames; it does not score a missing feature.

### 8.5 Prioritised improvement plan

**Quick wins** (hours to a day each; code-side, no new art direction) — **done 2026-11-18 except 3, see §8.6**
1. ✅ Act 0 HUD labels: next type size up, a BONE value clearly above the navy panel; move "INSERT CREDIT" off the panel. (cat. 12, 9)
2. ✅ Sepulchre segment count / phase mark on the Act 0 HUD. (cat. 4)
3. ~~Banner placement over the maw~~ — withdrawn: conflicts with ART-001 §11.5 (see §8.3 item 3).
4. ✅ First post-reveal frame: bring the lamp rod in first so the frame has a focal subject. (cat. 1, the weakest critical state)
5. ✅ Title screen: make New Vigil visibly heavier than Settings and Quit. (cat. 12)

**High-impact revisions** (days to a couple of weeks each)
1. A player-highlight treatment for the Vigil that survives clutter (Returnal's outline lesson; Ball x Pit's failure case). (cat. 1)
2. Choir role silhouettes that separate in greyscale, not by colour alone. (cat. 2)
3. Side-gutter HUD that carries real, glanceable information (Ball x Pit model) instead of empty panels. (cat. 9)
4. One type system per layer (pixel faces on the cabinet screen; chalk faces after), TECH-001 Q-T23. (cat. 11)
5. Fog shader without blocky rectangular patches; fog/post render scale and quality presets, TECH-001 Q-T24. (cat. 11)
6. Bullet-pattern language for the Choir in L1: colour-split shot types and patterns as composition (Saros lesson). (cat. 5)

**Needs a professional artist or specialist**
1. **The hook** (§7.1): ✅ the printed bezel art is built (2026-11-18, ART-001 §12.7a, TECH-001 §2.10; at 640×360 logical size, not yet re-scored, not evaluated in motion); still open: native-resolution rendering and its staged peel / crack / decay / warp during the zoom: procedural fracture, shader decay, camera choreography, audio lock. The single biggest lever on the overall score.
2. The L1 Aether look itself (fog layers, crystal spheres, lantern lighting at native resolution) to the Saros lighting bar.
3. Live-motion review of Act 0 and the hook from video, with a second reviewer (§9).

### 8.6 Re-score after the quick wins (2026-11-18)

**Changes** (code): `features/cabinet/cabinet_hud.gd` (6 px panel margin; score and hi score at PixelText 2× when the string fits 72 px, else 1×; labels BONE-4 instead of BONE-2; the blinking INSERT CREDIT only in the attract demo; a SEPULCHRE readout under the Charge lamps showing `segments/total`, or AWAKE, hidden once unmade); `features/cabinet/cabinet_game.gd` (`hud.demo`); `locale/en.po` (`CAB_SEPULCHRE`, `CAB_SEP_AWAKE`); `scenes/ruins/ruins_stub.gd` (stem and lit lamp from frame 0 with a two-band GAS-1 halo; only the branches grow); `scenes/attract/attract_mode.tscn` (Settings and Quit 128 px wide, New Vigil 160 px, an 8 px gap after it); `scenes/attract/attract_logo.gd` (logo minimum height 80 → 72 so the menu stays inside the safe area at 200 % text); new test `features/cabinet/tests/test_cabinet_hud_layout.gd`.

**Evidence:** new captures (same method as §8.3, taken after merging PR #1, so the placeholder bezel, coin plate and attract instruction card are in frame): `cap2/attract/f300`, `cap2/play/f600`, `cap2/reveal/f1100`.

| State | Facts | Old → new |
|---|---|---|
| A Attract | New Vigil 160 px and disabled until a credit is in (PR #1 behaviour); Settings and Quit 128 px; attract card in a dotted yellow frame between logo and menu; "CREDIT 0" on the left panel | cat. 12: 6 → 6 (width hierarchy present, but the primary reads weakest while it is disabled) |
| B Quiet/mid play | score "5,080" at 2× on both panels; labels brighter; "SEPULCHRE" + "2/20" at 2× under the lamps; no INSERT CREDIT during play | cat. 4: 5 → 7 · cat. 9: 5 → 6 · cat. 12: 4 → 6 |
| C Mid-density | segment count now on the HUD | cat. 4: 4 → 6 (density still not evaluated) |
| F First post-reveal frame | lit lamp with a stepped halo on a full-height stem, centred above the amber arc, from the first ruins frame | cat. 1: 2 → 6 |

**Not verified:** the run started with `--segments=10` but the HUD read 2/20 at frame 600; module knock-off by Charges (SYS-001 §2.1) would explain it, but it was not traced. Tests: 139 run, 118 pass, 21 fail, all in `test_every_cabinet_cue_has_a_chirp_render`: this worktree's `.wav` renders are Git LFS pointer files (verified: they start with `version https://git-lfs…`, the main checkout's start with `RIFF`), so the failure is environmental. Boot smoke reached route `cabinet`, exit 0, only audio-stub ERROR lines. One reviewer, stills only.

---

## 9. Review process

1. Capture: Act 0 with the capture switches (TECH-001 §2.10), always `--no-save`; same frames at each supported resolution once native rendering exists (D-A).
2. Score with two reviewers independently; disagreements > 2 points are discussed with the frames side by side.
3. Record facts, interpretation, score and smallest fix in §8; the weakest critical state goes first in the report.
4. Re-score after each art milestone; keep earlier sheets for trend.

## 10. Open items

- Benchmark gameplay frames and current-game captures (§3.2).
- Implementation guide and UI style guide updates go into ART-001 and UI-001 (no second source of truth) after the first scoring pass.
- Re-score L0b with captures of the printed bezel (built 2026-11-18, ART-001 §12.7a); the §8.6 table still refers to the placeholder.
- Quality presets for native resolution (fog/post render scale): TECH-001 Q-T24.
- ✱ marks review heuristics proposed by this doc (thresholds, review weights), not game numbers; the owner may change them.
