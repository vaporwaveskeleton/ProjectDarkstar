# DARKSTAR — Zones & Encounters

**Doc ID:** ZONES-001 · **Version:** 1.2 · **Date:** 2026-11-18 · **Owner:** Design (levels) · **Upstream:** `GDD_DARKSTAR_v0.2.md` (GDD-001), `SYSTEMS_BIBLE_STATS.md` (SYS-001), `ART_BIBLE.md` (ART-001) · **Downstream:** `TECH_ARCHITECTURE.md` (kit scene tree, generator), `ASSET_PIPELINE.md` / `SPRITE_MANIFEST.csv` (kit art asks), `PRODUCTION_PLAN_MILESTONES.md` (kit build order)

**Rev 1.1 (2026-11-18):** cosmic horror design rev 3 applied, per PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3 (decisions CHD-02, -03, -07, -09, -10, -11, -12, -13, -16): Presences and biome grief stories (§2.3, §2.4); the uncharted reserve (§3.8, reserve marks in §3); the Passing budget note (§4.2); §4.4 rule 3 and rule 7 exemptions; death-site Penitents (§4.5); kit memory (§4.8); the Procession (§6.6); Your Own Vigil route mimicry (§7.1); Herald rumours (§8.3); the deferred Twist-deck row (§10 Q-06). **Same-day reconciliation (2026-11-18):** rekindled Penitents share the per-sector Penitent cap, precedence Coma → rekindled → other death-site (§4.5); §4.8 quotes the corrected kit-memory sim (five gate kits; DO-02 is not one).
**Rev 1.2 (2026-11-18):** PM ruling 2026-11-18 (owner grant), Act 1 vertical slice, amended after The Reviewer's notes: PM-01's Twist (§3.1) is now a vigil site (the Grubs ring the cold Sepulchre with their lit shards and wait; the deposits begin when it wakes). The 20 s ✱ value is unchanged and is now the vigil's length. §4.4 is unchanged; the M2 slice fixes Seam 1 to PM-01 for M2 only (TECH-001 §11.2).

---

## 0. How to read this doc set

| Doc | Path | What it answers |
|---|---|---|
| GDD | `docs/01-design/GDD_DARKSTAR_v0.2.md` | What the game is, every system, how it all fits |
| **Systems bible (numbers)** | `docs/01-design/SYSTEMS_BIBLE_STATS.md` | **Every stat, threat budget, rite/elite entry, corruption constant. This doc cites it; it never restates it.** |
| **This doc** | `docs/01-design/ZONES_AND_ENCOUNTERS.md` | Biomes, the 32 encounter kits, seam assembly, hazards, the Waking staging template, rite and elite placement |
| Roguelike loop & upgrade tree | `docs/01-design/ROGUELIKE_LOOP_AND_LANTERN_TREE.md` | Iterations, Run Sigils, pacts, Lantern Tree nodes |
| Reality-warp escalation | `docs/01-design/REALITY_WARP_ESCALATION.md` | Warp Tiers 0–5, edge-warp rules, eaten rules, UI-eating |
| Narrative & lore | `docs/01-design/NARRATIVE_LORE_BIBLE.md` | Biome fiction, entity lines, death lines |
| Art bible | `docs/02-art/ART_BIBLE.md` | Palette law, silhouette grammar, lighting rules — §4/§5 are binding on every kit here |
| Sprite modularity spec | `docs/02-art/SPRITE_MODULARITY_SPEC.md` | The 64×64 module kit for units and the entity (a different "kit" from an Encounter Kit; see §1.6) |
| Asset pipeline & manifest | `docs/02-art/ASSET_PIPELINE.md`, `assets/sprites/SPRITE_MANIFEST.csv` | Kit geometry asks, what exists, what is missing |
| Audio design | `docs/03-audio/AUDIO_DESIGN.md` | The chant as a positional game system; Silence budget |
| Tech architecture | `docs/04-production/TECH_ARCHITECTURE.md` | Godot scene tree, `.tres` data resources, seeded RNG, the generator and its lint |

**Number discipline (hard rule of this doc).** Every unit stat, threat band, corruption constant, rite entry and elite entry is a *reference* to SYS-001 by section. A number appearing here is one of exactly two things: (a) a SYS-001 value being cited, or (b) a **level parameter** — a count, radius, duration, waypoint distance or timer that lives in the kit's `.tres` and is marked `✱`. `✱` = first-pass level parameter, pending playtest, owner: Design (levels). No stat is invented in this file. If playtest moves a `✱`, it moves in the kit's `.tres`, not here.

**Vocabulary discipline.** World, faction and entity concepts use only the GDD §19 glossary. Kit names and Twist names are local labels for authored content and are not lore terms.

**IP discipline.** The 1983 original is referred to only as "the 1983 original" (see RES-001 §5). No name, voice line or trademark term from it appears in this file, in kit labels, or in the `.tres` files it describes.

---

## 1. Definitions

### 1.1 Seam
A **Seam** is one level of a run. A run is 5 Seams 🔒 (SYS-001 §6). A Seam presents one **sector**: **3–7 Encounter Kits stitched end to end**, each kit one screen cluster of about 640×360 (SYS-001 §6, "sector size"). Seam clear time is 4–6 min ✱ (SYS-001 §6), so a kit cluster is authored as a 50–120 s beat. Seam ordinals 1–4 are sector Seams; Seam 5 is the run's gate Seam (§4.5). A 5-Seam run draws **15–35 kit instances from a 32-kit pool**; §4.4 shows how the no-repeat rule survives that arithmetic.

### 1.2 Sector
A sector is the unit the macro map tracks: one biome, one Waking state, one Corruption state, one Ledger Compass entry. The lint (§1.5) is a **sector** check, not a per-kit check. A sector going **Hollow** (§6.5) is permanent for the iteration.

### 1.3 Encounter Kit
An **Encounter Kit** is a hand-authored, screen-sized module cluster: fixed geometry, fixed sightlines, and authored *slots* (spawn markers, geode clusters, shrine anchors, procession routes, a Sepulchre anchor, gravity anchors, light pockets). The generator may **fill and re-key slots**; it may not move geometry. This is the GDD §8.8 promise: authored kits assembled into 5-Seam runs, so readability and performance are guaranteed by construction while variety comes from assembly.

Two things are called "kit" in this set. **Encounter Kit** (this doc) = the geometry and slot set of a screen. **Sprite part kit** (ART-002) = the 64×64 module set a unit is assembled from. They are different systems; the pairing is the reuse story (§1.6).

### 1.4 Kit parameters
A kit's `.tres` resource (`kit_definition.tres`, TECH_ARCHITECTURE §6) holds:

| Parameter | Type | Notes |
|---|---|---|
| `biome`, `seam_slots`, `status` | enum/int[]/enum | §2, §3 |
| `threat_pts` | int | authored threat at T0–T1; must sit inside the Seam band, SYS-001 §4 (§1.5) |
| `spawn_markers[]` | `lit` / `unlit` / `any` typed, with `unit` and `count` | filled by the generator; the unit must exist in that Seam's Contents line, SYS-001 §4 |
| `geode_clusters[]` | position, `cluster` type, face count | shard supply derives from SYS-001 §1.3 (3 per calm kill, 4–6 detonated) |
| `procession_routes[]` | polyline, 2–4 waypoints ✱, one entry anchor | §6.1 |
| `deposit_paths[]` | route → Sepulchre anchor | §6.1 |
| `sepulchre_anchor` | position, `cold` / `active` / `prebuilt` `prebuilt_segments = 8 ✱` (BK-02 only) | SYS-001 §2 |
| `litany_ring_nodes[8]` | anchors at ring radius **140 px ✱** | 8 nodes is SYS-001 §3.1; 140 px is the smallest radius that keeps ring nodes clear of each other's 120 px hold-fire radius |
| `shrine_anchors[]` | position, `seeded` count | SYS-001 §6 corruption chain |
| `light_pockets[]` | radius **110 px ✱**, must intersect a procession route | the shard-steal beat, §6.3 |
| `unlit_corridors[]` | count ≥ 1 lint, width **96 px ✱** | SYS-001 §4 lint; 96 px ≥ shard magnet radius so shards can be collected dark |
| `escape_vectors[]` | ≥ 2 from every point (lint), authored | SYS-001 §4 |
| `gravity_anchors[]` | 4 (quadrant) ✱ or 2 (axis) ✱, `enabled_at_T` | §5.2 |
| `wrap_targets[]` | edge → edge, by Warp Tier | §5.6 |
| `warp_effect_slots = 3 ✱` | int | the Warp Effect Budget cap, GDD R-02 |
| `dark_default` | bool | whether the kit's authored lighting is unlit |
| `mirror_policy` | `horizontal` / `vertical` / `both` | §1.5 |
| `reserved_markers` | `herald`, `rite_gate`, `penitent`, `ui_eat_slot` | §7, §8, §5.4 |

### 1.5 Re-keying at Warp ≥ 3, and what threat points mean
Threat points are **per-Sector, not per-kit**. SYS-001 §4 bands a *Seam*'s threat (Seam 1 = 8–12 at T0–T1, and so on). A Seam's threat is the sum of its primary kit plus its satellite clusters. Therefore a kit's authored `threat_pts` must sit inside its slot's band **with room for ≥ 2 satellites** (§4.3). This is an explicit reading of SYS-001 §4/§6, recorded in §10 Q-01 for sign-off; nothing in this doc contradicts the band itself, and the lint is what enforces it (§4.6).

**Re-key is a re-fill, not a re-draft.** At Warp Tier ≥ 3 (GDD §8.8) the generator may only:

| Default T3 re-key pack | Effect | Bounds |
|---|---|---|
| mirror the layout | `horizontal` or `vertical` by seed parity, per kit `mirror_policy` | geometry untouched |
| go dark | all `lit` spawn markers swap to `unlit`, entry/exit anchors swap edge | kit becomes a dark kit (§4.4) |
| unit mix | Grub → Acolyte, add `Deacon of Lies` / `Listener` where the Seam's Contents line allows | SYS-001 §4 Contents is binding: no new unit type at a Seam position |
| threat lift | sector total re-drawn into the band for the tier | SYS-001 §4 band; ratio ≈ 1.7× (T2–T3), ≈ 2.15× (T4–T5), **derived from the bands, not authored per kit** |
| ring on | Litany Ring anchors activate (8 nodes) | SYS-001 §3.1 |
| wrap targets swap | edge → *other* edge, per tier | §5.6 |
| gravity anchors enable | where present | §5.2 |
| one geode cluster → Shroud | swap in Shroud growths | SYS-001 §9 (Shroud), §6 (corruption) |
| `ui_eat_slot` arm | reserve one UI element for the entity to eat | GDD §8.7 T4; WARP-001 owns the effect list |
| re-run the lint | all of §1.5-lint below | hard gate, §4.6 |

**Solvability lint** (SYS-001 §4; a generator assertion, not a suggestion). A sector fails and the assembly is rejected if any of these is false:
1. **≥ 24 shards of supply in-sector** — counted at the calm-kill yield (SYS-001 §1.3), so **≥ 8 geodes** ✱ counted across the sector's kits and satellites.
2. **≥ 2 escape vectors from every point** — raycast sample grid, 32 px pitch ✱.
3. **≥ 1 unlit corridor** — a corridor the player can traverse with the lantern down, ≥ 96 px wide ✱.
4. **Sepulchre not visible from the entry point at T ≤ 2** — sightline raycast from the entry anchor.

SYS-001 §10 lists "Threat budgets per Seam" as the tunable to move if a kit fails lint at T ≥ 3. That is the loop this doc is built for: kit → lint → re-tune the kit's spawn table, never the geometry.

### 1.6 The kit is the unit of reuse — for design *and* art
The Encounter Kit is how a level is made; the sprite part kit (ART-002, ART-001 §8) is how the things inside it are drawn. Both are reuse systems and they are why 32 kits plus one unit kit covers the whole campaign:
- **Design reuse:** 32 kits × per-tier re-key packs × mirror policy = the run variety, at zero extra geometry cost. Cut order (GDD R-03) applies to kits the same way it applies to sprites: BK-* and DO-* geometry sets land last and are the ones that ship with a `placeholder` status in §3.
- **Art reuse:** a kit asks for **geometry clusters** (bone stacks, arches, coral, lens rings — biome-level props, one set per biome) plus the unit/entity sprites already covered by the part kit. A kit never asks for a unique boss or a unique unit.
- **The horror pairing:** a kit re-keys its *slots*; the warp re-keys its *contents'* sprite parts at runtime (ART-002 §5.3). One system changes the room, the other changes what is standing in it, and neither needs new art.

### 1.7 What a kit physically is (Godot scene tree)
One kit = one PackedScene, `res://scenes/zones/kits/<KIT_ID>.tscn`, plus its `kit_definition.tres`. Names are stable and are the manifest keys for art asks.

```
EncounterKit (Node2D, script encounter_kit.gd, export kit_definition)
├── Geometry (TileMapLayer)          # authored collision, one tileset per biome geometry set
├── Art (Node2D)
│   ├── LayerBack (ParallaxLayer)    # VOID-2/3 silhouettes; off at T0 (GDD §8.7)
│   ├── Mid (Sprite2D atlas)         # biome geometry clusters: bone stacks / arches / coral / lens rings
│   ├── Fore (Sprite2D)              # foreground occluders, ≤ 12% of screen ✱ (sightline budget)
│   └── Shroud (TileMapLayer)        # StaticBody2D equivalent, HP 3 — SYS-001 §9
├── LightMask (CanvasModulate + light polygon set)   # 3 hard bands, ART-001 §5
├── Volumes (Node2D)
│   ├── LightPocket × n (Area2D)     # radius 110 px ✱ — §6.3
│   ├── UnlitCorridor × ≥1 (Area2D)  # lint item 3
│   ├── EscapeVector × ≥2 (Path2D)   # lint item 2
│   └── GravityAnchor × 4 (Node2D, disabled)         # §5.2
├── Slots (Node2D)                   # generator fills these, never Geometry
│   ├── SpawnMarkerLit × n (Marker2D + unit/count on kit_definition)
│   ├── SpawnMarkerUnlit × n
│   ├── HeraldAnchor × 2 (Marker2D, reserved)        # §8
│   ├── RiteGateAnchor × 1 (Marker2D, reserved)      # §7
│   ├── PenitentAnchor × 1 (Marker2D, reserved)      # §4.5 Coma
│   └── UiEatAnchor × 1 (Marker2D, T4+)              # GDD §8.7
├── Ore (Node2D)
│   └── GeodeCluster × n (StaticBody2D + Area2D per face, 64 px pitch ✱)
├── Sepulchre (Node2D)               # cold / active / prebuilt; absent in kits with no anchor
│   ├── SepulchreBody (static, PHOS-3 breath pulse at 12 segments — ART-001 §5)
│   ├── LitanyRingNodes[8] (Marker2D, radius 140 px ✱)
│   └── DepositPaths (Path2D × 1–2)
├── ChantSources (Node2D)            # positional emitters; audible through geometry ≤ 420 px (SYS-001 §9)
└── Edges (Node2D)
    └── WrapEdge (Area2D, wrap target per Warp Tier) # §5.6
```

Rules: a kit scene contains **no enemy instances** — only markers. A kit contains no boss art. Its light mask ships a T0-safe fallback variant (ART-001 §7). Its geometry uses one biome tileset, so 6 geometry sets cover 32 kits (art ask, ASSET_PIPELINE).

---

## 2. Biomes

Six biomes (GDD §8.8), rotated by iteration. Palette references are ART-001 §4 ramp indices; palette law 1 (GASLIGHT never on Choir, CHOIR never on player) and law 3 (SIGNAL ≤ 3 on screen at once) survive every Warp Tier, including T5, so the biases below are biases, never licences.

### 2.1 Biome table (a) — identity, look, density, pressure

| Biome | Read (one line) | Palette bias (ART-001) | Geometry signature | Geode density | Choir pressure | Shroud presence | Verticality |
|---|---|---|---|---|---|---|---|
| **Pale Marches** | The sky you grew up in; frost on a window, still mostly honest. | BONE-3/4 field, VOID-0/1 background, PHOS-3/4 shard cores, near-zero CHOIR | Open torus, low relief, drift-ice bands, sparse bone monoliths, one-screen sightlines kept long | Medium (8–10 geodes/kit) | Low — Grubs first, Acolytes late | Rare before T2; growths only on re-key | Low — shallow ledges only; no authored climbs |
| **Ossuary Belt** | A dead god's bones, mined too neatly; geode-rich and tomb-quiet. | BONE-0/1/4 dominant, PHOS-1/2 glass body, PHOS-5 hot core, CHOIR-0 trim only | Stacked vertebra walls, dead-end galleries, bone towers, dense choke points | **High** (9–14 geodes/kit; the biome's whole argument) | Medium — processions walk fixed galleries | Light: dust-shroud in galleries | Medium — two-storey stacks, no gravity play |
| **The Litany** | A cathedral caught mid-service; the Choir is not *in* the level, it **is** the level. | CHOIR-1/2/3 heavy (vestment geometry, banners), BONE-2 vestment mid, CHOIR-4 as the only bright tell, VOID-3 shadow | Naves, arches that meet at angles that do not close (ART-001 §2), symmetrical plans broken one element off-symmetry, shrines everywhere | Medium | **Highest** — rings, chants, Matrons, the most shrines per sector | Medium | Medium — galleries and choir lofts, no flips |
| **Green Rot** | A reef that is also a reliquary: it grows on the dead and calls it devotion. | PHOS-1/2 dominant (Shroud rims, living glass), PHOS-0 shadow, BONE-1, CHOIR-0 for Choir mass | Living coral arches fused to bone, Shroud lanes, island-and-bridge plans, sightlines cut by growth | Medium-high, **mostly overgrown** (needs Ward/Surgelight to reach) | Medium, but *hidden* — Choir inside Shroud | **Highest** — lanes, floors, regrowth | Low-medium — reef shelves |
| **The Drowned Observatory** | The Ruins' drowned twin, where up is a suggestion. | VOID-2/3/5 dominant, PHOS-1 rim only, near-total NULL, GAS-5 as the brightest pixel in the frame | Vertical shafts, broken domes, lens rings, telescope housings that read as turrets (ART-001 §2 "ordinary that is not ordinary") | Medium, hung high | Medium | Light | **Highest** — the only biome authored for gravity inversions |
| **The Black** | The void sky. Almost no geodes, almost no cover, and the dark has an edge. | **Desaturated**: VOID-0/1 + NULL, one PHOS-3 point per geode, BONE-0 only, no CHOIR mass on screen, SIGNAL used for tells only | Open torus at maximum range, lone geodes strung far apart, no foreground at all | **Lowest** (7–9/kit, sitting on the lint floor) | Low count, maximum exposure — no cover to break line of sight | None (nothing lives here to grow) | None — flat, which is the cruelty |

### 2.2 Biome table (b) — wrap behaviour, iterations, teaching role

| Biome | Wrap behaviour at each Warp Tier | Iterations it appears in | What the player is learning |
|---|---|---|---|
| **Pale Marches** | **T0:** classic arcade torus, left↔right and up↔down, honest and marked (ART-001 §7 cabinet layer). **T1:** same, chant audible across the seam. **T2:** shrines appear at wrap throats. **T3:** edge-warp roulette — 2 of 4 edges re-map to a random other edge (WARP-001). **T4:** the exit of a wrap is a different biome (WARP-001). **T5:** wrap is an eaten rule, `wrap_targets` returns null. | **1–9** (starter). In every Act 1 run. | Base verbs: mine, race, convert, hunt the build. Then: the lantern is a beacon; a shrine is cover and a trap; the Lantern Tree reaches into the level. |
| **Ossuary Belt** | **T0/T1:** single-edge wrap, one seam throat only. **T2:** throats choke with Shroud. **T3:** mirror + one throat sealed → wrap is a gamble. **T4:** wrap spits you into the mid-gallery. **T5:** wrap eaten. | **1–9**, weighted high from iteration 2 | Ore supply is a race: over-fire feeds the Grubs; the Choir mines too; a tower's crossfire is a lesson in tells. |
| **The Litany** | **T0:** no wrap (walled nave). **T1:** one door. **T2:** doors multiply, shrines line the throats. **T3:** every door leads to a random gallery (roulette). **T4:** a door leads to a memory of the sector. **T5:** doors no longer open. | **2–9** | The Choir is a sound mechanic: chant direction, prayer pauses, ring discipline, and that a safe route can be a corrupting one. |
| **Green Rot** | **T0:** no wrap; island bridges only. **T1:** as T0. **T2:** Shroud closes bridges behind you. **T3:** wrap roulette with a 0.4 s transit read (WARP-001, ≤ 1.5 s agency rule). **T4:** Shroud grows *through* wrap edges. **T5:** wrap eaten. | **3–9** | Terrain is a resource: Shroud blocks and lights; the Matron must be silenced; Corruption is clawed back, not mourned. |
| **The Drowned Observatory** | **T0:** no wrap, closed vertical volume. **T1:** as T0. **T2:** as T0 plus dark corridors. **T3:** **vertical wrap with gravity inversion** — leaving the floor returns you inverted from the ceiling. **T4:** the field itself wraps, not just the shaft. **T5:** wrap eaten. | **3–9** | Gravity and light are the same puzzle. Shards fall; ore falls toward whoever is below it. |
| **The Black** | **T0:** maximum-range wrap, no walls, nothing to hide on. **T1:** as T0. **T2:** as T0. **T3:** wrap roulette, and a wrap can drop you outside the entity's gaze cone — the one honest thing about it. **T4:** as T3, plus the entity may eat the HUD element of your choice. **T5:** wrap eaten and the field shrinks visibly. | **4–9** (unlocked late; the hardest sky) | Scarcity: 24 shards is a floor, not a mean; every Charge is a decision; the Herald duel is played with the build you actually brought. |

Act 0's three levels are hand-authored and are **not** kits (GDD §6.1); no kit here is reused as an Act 0 level, so the arcade costume can be torn away without touching the real level layer (ART-001 §7).

### 2.3 Presences (one per biome)

PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-03. Each biome has one **Presence**: a vast, slow, glowing silhouette in the far fog, bigger than the playfield, alive and indifferent to the player. "Presence" is a doc term (GDD §19), never shown on screen; the labels below are working labels for docs, not glossary nouns.

| Biome | Presence (working label) | What it is doing |
|---|---|---|
| **Pale Marches** | a frost-drifting thing like a migrating ice shelf, with a slow heartbeat of light | migrating |
| **Ossuary Belt** | something grazing on the dead god's far vertebrae | grazing |
| **The Litany** | a vast bell-shape that swings once a Seam; the Choir time their Litany to it | tolling |
| **Green Rot** | a reef that is breathing | breathing |
| **The Drowned Observatory** | a lens-like, eyeless disc that turns when gravity inverts (§5.2) | turning |
| **The Black** | **none.** Its absence is the Presence: the only biome where nothing lives and nothing flees | gone |

Level-side rules:
- **Never a hitbox.** A Presence lives in the far layer (`Art/LayerBack`, §1.7) only. It has no collision, blocks no sightline, counts against no foreground budget (§1.7 `Fore`) and is invisible to the lint (§1.5).
- **No extra light in the play layer.** A Presence never lights a geode, a unit, a light pocket or an unlit corridor; the ART-001 §16.3 readability rules hold.
- **It flees the entity.** A Presence leaving is the **first tell of the Passing** (§4.2; WARP-001 §2 owns the event). In The Black, which has no Presence, the Passing's tells start at the leading edge.
- **Lantern-down reveal:** with the Lantern up, the Presence is a vague mass in the fog; with it down, far-layer life and the Presence's full lit pattern show, and at T3+ so do the places where the Aether is already gone. The reveal changes nothing in the play layer, so it neither helps nor hinders aiming; it pays out through the existing dark-flight Composure gain (SYS-001 §1.5).
- The Aether art chat's "leviathan" is the **T3 Presence silhouette**. The look, the far-layer art and the T0–T5 progression are ART-001's (§16, handed to the Aether art chat); this doc owns only the rules above.

### 2.4 Biome grief stories (placement)

PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-16. Each biome tells one environmental story in art only, confirmed afterwards by a Codex entry. NARR-001 §8 owns the Codex text; the ids below are listed here so the stories can be placed.

| Biome | The story in the fog | Codex id (stamped after) |
|---|---|---|
| **Pale Marches** | an Office recruitment sign, KEEP THE VIGIL, frosted over and still lit | `cx_place_marches_sign` |
| **Ossuary Belt** | survey stakes in the vertebrae, numbered past the last one anyone mined | `cx_place_belt_stakes` |
| **The Litany** | one pew in the cathedral is lit; the others are dark (the Lampkeeper's place, kept) | `cx_place_litany_pew` |
| **Green Rot** | a Vigil hull overgrown into the reef, its lamp still lit (the same idea as death-site Penitents, §4.5) | `cx_place_rot_hull` |
| **The Drowned Observatory** | a lantern floating upward through the inverted hall, never arriving | `cx_place_observatory_lantern` |
| **The Black** | the brass ring of a Lampkeeper, unlit, turning slowly | `cx_vigil_unlit_ring` |

Placement rules: a grief story is **art only** (no collision, no hitbox, no light cast into the play layer, no lint effect), and sits in the biome's own geometry set or far layer. Any words on a prop (the Pale Marches sign) are player-visible text and go through a `tr()` key (L10N-001). Which kits of each biome carry the story, and how often it is drawn, is not yet decided (owed to Design (levels) with the Aether art chat).

---

## 3. The 32 Encounter Kits

Threat points are authored **at T0–T1** and must sit inside the Seam band for the kit's slots (SYS-001 §4) with room for ≥ 2 satellite clusters (§4.3). Shard supply is quoted at the calm-kill yield (SYS-001 §1.3: 3 shards per geode); detonation adds more but scatters it (SYS-001 §1.3, §10). The lint floor of 24 shards/sector is a sector check (§1.5), so 7-geode kits pass only inside a multi-kit sector.

**Choir mix** lists authored spawns at base. `Grub`/`Acolyte`/`Deacon`/`Deceiver`/`Listener`/`Matron`/`Herald`/`Penitent` are the catalog units (GDD §8.5, SYS-001 §3) — no new units are introduced anywhere in this doc.

**Dark** = `dark_default = true` on the kit. **L/T/S** = the Twist interacts with the lantern/lantern-darkness, the chant, or Shrines (counted in §3.7).

### 3.1 Pale Marches — 6 kits

| Kit ID | Name | Biome | Seam slots | Threat pts | Geometry (what is on screen) | Geodes / shards on offer | Choir mix | Sepulchre? | Twist (the one thing that makes this kit not-generic) | Warp re-key (T3+) | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| PM-01 | First Vigil | Pale Marches | 1 | 10 | Open torus, one low bone monolith at the throat, long honest sightlines, two wide unlit corridors | 8 geodes / 24 shards (exactly the lint floor) | 6 Grub | **Cold** — one deposit lane, ring anchors dormant | **The cold Sepulchre sits in plain sight, lit by nothing, and it is a vigil site: the Grubs gather at it and set their lit shards down in a ring around it, waiting, for the first 20 s ✱. When it wakes, the deposits begin** ("they were waiting for it") — you see the whole plan before it starts. *(Twist amended 2026-11-18, PM ruling (owner grant), Act 1 vertical slice, amended after The Reviewer's notes; was "the only Grubs in the sector walk straight past it for the first 20 s ✱"; timing value unchanged.)* | dark pack + monolith moves to the far throat; ring anchors arm | authored |
| PM-02 | Dark Throat | Pale Marches | 1, 2 | 11 | A lit geode shelf above a 96 px unlit corridor that runs the full seam edge; one light pocket | 8 geodes / 24 | 7 Grub (route), 1 Acolyte at the throat | Active | **You can walk the deposit path with your lantern down and strip shards out of a Grub procession** — detection −60% (SYS-001 §1.2) — because the only thing glowing in that corridor is the shard overhead in the Grub's claws. | dark pack is a no-op (already dark); ring on; Acolyte count ×2 | authored, **L** |
| PM-03 | Twin Drift | Pale Marches | 1, 2 | 9 | Two geode clusters straddling the left/right wrap pair, mirrored across the throat; shards drift toward the edge | 9 geodes / 27 | 5 Grub, 1 Grub pair on the return leg | **Cold** | **The two clusters are the same cluster, wrapped:** every shard you knock off the left face arrives, still drifting, on the right — and a Grub picks it up there. | mirror policy `horizontal` enforced; wrap pair → roulette pair | authored |
| PM-04 | Censer Shelf | Pale Marches | 2 | 14 | One lit shelf on a bone spur, one unlit lane below, one shrine anchor at the spur foot | 9 geodes / 27 | 1 Acolyte (turret on the spur), 5 Grub | Active | **The geodes are ore for both sides:** the Acolyte mines at 50% rate (SYS-001 §3), so every face you leave standing is a segment the Choir gets for free, and the kill order is ore-then-knight, not the reverse. | dark pack; second Acolyte; unlit lane widened | authored |
| PM-05 | Sacred Ground | Pale Marches | 2 | 15 | One geode cluster, one seeded Shrine at the cluster's edge, one light pocket, one choke | 8 geodes / 24 | 1 Grave-Tide Deceiver, 6 Grub | Active | **The Shrine is your only cover, and it is also the trap:** Choir units hold fire within 120 px of it (SYS-001 §3.1), but if you fire while standing there, the nearest geode converts to a second Shrine and Corruption ticks (GDD §8.5, SYS-001 §6). | dark pack; Deceiver count 2; a third Shrine anchor seeds at T4 | authored, **S** — **reserve** (§3.8) |
| PM-06 | Procession Cut | Pale Marches | 2, 3 | 18 | Two procession routes crossing in an X above the entry anchor; one elbow reachable only across the ice band; one Listener | 9 geodes / 27 | 8 Grub on two routes, 1 Listener | Active | **You can cut the procession's route:** the elbow is a 40 px ✱ hop across the ice band, and the 2–3 shards a route drops into the Sepulchre per lap (SYS-001 §3 carry 1, §2 shard 3 = 1 segment) are the difference between a build and a build you arrive late to. | ring on; route waypoints +1 ✱; Listener swaps to Deacon at Seam 4 | authored |

### 3.2 Ossuary Belt — 6 kits

| Kit ID | Name | Biome | Seam slots | Threat pts | Geometry (what is on screen) | Geodes / shards on offer | Choir mix | Sepulchre? | Twist | Warp re-key (T3+) | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| OB-01 | Over-Fire Gallery | Ossuary Belt | 1 | 11 | Dead-end gallery, 3 geodes stacked in a pit, a ceiling overhang, one 96 px unlit lane, Grub nest at the pit foot | 10 geodes / 30 | 7 Grub | **Cold** | **Detonating in the pit feeds the gallery:** the 140 px scatter (SYS-001 §1.3) drops the shards into the Grub nest below and the keening starts before you have turned around. | dark pack; pit becomes a light pocket at T4 (the only light is your lantern) | authored |
| OB-02 | Censer Walk | Ossuary Belt | 2 | 15 | Two bone towers on opposite galleries, a crossfire corridor between them, one unlit lane hugging the floor | 9 geodes / 27 | 2 Acolyte (one per tower), 5 Grub | **Cold** | **The towers cover each other's base:** the 0.25 s turret lag (SYS-001 §3) is the only door through the crossfire, and leading the body beats the censer — the corridor is walkable the instant you read the swing. | dark pack; 3rd Acolyte on the ceiling gallery; crossfire cone widens at T4+ (gaze cone rule, SYS-001 §2.1) | authored — **reserve** (§3.8) |
| OB-03 | Stacked Reliquary | Ossuary Belt | 2, 3 | 16 | Two-storey geode stack over a pit whose floor is the deposit path; one light pocket at the stack top | 11 geodes / 33 | 6 Grub (pit floor), 1 Acolyte (upper gallery) | Active | **Mining the stack feeds the pit:** shards fall out of your reach and land on the deposit path, where the Grubs below do not have to compete with you; the honest play is to mine the lower faces first. | gravity anchors arm (quadrant 4), pit floor becomes a ceiling at T3+; ring on | authored |
| OB-04 | Buried Lantern | Ossuary Belt | 1, 2 | 12 | A buried hollow, no ambient light, one geode cluster inside, one procession route crossing the mouth | 8 geodes / 24 | 8 Grub on the route | Active | **With the lantern up, the hollow is a lighthouse and the whole sector sees you; with it down, the only light in the frame is the shard each Grub carries overhead** — so the procession is your torch and your target at once (SYS-001 §1.2, ART-001 §3). | dark pack is a no-op; route doubles to two; Grub panic radius −40% applies (SYS-001 §3.1) | authored, **L** |
| OB-05 | Silent Procession | Ossuary Belt | 2, 3, **5 (gate)** | 18 | Three parallel galleries, one unlit, one seeded Shrine at the mid gallery's mouth, gate anchor in the far gallery | 10 geodes / 30 | 9 Grub across three routes, 1 Deacon of Lies, 1 Matron **only when hosted as a gate** (§4.5) | Active | **A real procession chants and a phantom one does not:** the Deacon's Phantoms are harmless and silent while the true route carries the chant through geometry up to 420 px (SYS-001 §3.1, §9) — so the audio alone separates ore from lie. | dark pack; phantoms persist until Warded (E9, SYS-001 §4); ring on | authored, **L S** |
| OB-06 | Quiet Gallery | Ossuary Belt | 2, 4 | 20 | The densest geode field in the pool, one unlit corridor the full length, no light pockets | 14 geodes / 42 | 1 Listener, 1 Deacon (Seam 4), 6 Grub | Active | **Sound is the sector's whole price list:** the Listener hunts gunfire in a 90° arc (SYS-001 §3) and a silent player is immune to it after 6 s, so you mine dark at 65% speed and keep your sanity, or detonate 24 shards at once and lose both. | dark pack; second Listener at T4; Deacon phantom cycle −1 s | authored, **L** |

### 3.3 The Litany — 6 kits

| Kit ID | Name | Biome | Seam slots | Threat pts | Geometry (what is on screen) | Geodes / shards on offer | Choir mix | Sepulchre? | Twist | Warp re-key (T3+) | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| LT-01 | Prayer Bell | The Litany | 2, 3, 4 | 20 | A nave; a procession route with a Shrine at the elbow; the Sepulchre on axis at the far end; one 96 px side aisle (unlit) | 10 geodes / 30 | 8 Grub on one route, 8-ring nodes on the Sepulchre, 1 Deacon (Seam 4) | Active | **The procession stops to pray:** every lap the route holds at the Shrine for 6 s ✱ — the chant cuts, the Choir holds fire within 120 px of it, and that silence is your only window to take the shards they are carrying; firing during the prayer converts a geode to a Shrine. | ring on; prayer pause −1 s ✱ per T above 2; doors multiply (roulette) | authored, **C S** |
| LT-02 | Nave of Ash | The Litany | 3, **5 (gate)** | 22 | Full-dark nave, three geode clusters in the pews, two unlit aisles, one light pocket at the transept, gate anchor in the apse | 9 geodes / 27 | 8 Grub, 1 Acolyte, ring nodes at T2+ | Active | **The Sepulchre is located by sound, not light:** chant is audible through geometry up to 420 px (SYS-001 §9), so you navigate by the Choir's own volume — and lantern up costs you +180% detection (SYS-001 §1.2) for a map you can already hear. | dark pack is a no-op; `ui_eat_slot` arms at T4; apse opens a second throat | authored, **L C** — hosts the **Matron of the Drowned Chorus** (§7) |
| LT-03 | The Doorway Birth | The Litany | 3 | 24 | Low-ceiling nave, shallow upper gallery, one 96 px unlit aisle, gate anchor under the loft | 9 geodes / 27 | 8 Grub, 2 Acolyte, ring nodes, 1 Matron-eligible | Active | **The Matron's Grubs birth from her doorway, not her body (ART-001 §3):** Ward silences her for 3 s (SYS-001 §5.1) and the doorway stays shut, so a silenced Matron is a sector with no new Grubs in it — visible in one 15-second shot. | ring on; doorway width −1 tile ✱; loft collapses to a second route at T4 | authored, **L C** — Seam-3 Matron gate host (§4.5) |
| LT-04 | Nine Altars | The Litany | 3, 4 | 26 | Nave with four seeded Shrines lining the aisles, one unlit crypt corridor, geodes behind the shrine row | 12 geodes / 36 (4 already converted to Shrines, so 8 live / 24 reachable) | 8 Grub, 2 Acolyte, ring nodes | Active | **The level has already lost ground:** the seeded Shrines are Choir ground (4 = a sector bruise, SYS-001 §6), and purging them is the capture-point layer — +1 Composure, −1 Corruption, Ember on the first purge of the biome (SYS-001 §6; Unwritten Ink retired, CHD-15) — while each geode you shoot near them adds to the bruise. | ring on; seeded Shrines 4 → 6 ✱ at T4; crypt floods with Shroud at T4 | authored, **S** — **reserve** (§3.8) |
| LT-05 | Bright Nave | The Litany | 4 | 26 | A fully lit nave: braziers every 120 px ✱, no dark volume at all, one geode cluster per bay | 12 geodes / 36 | 8 Acolyte (ring discipline), 1 Deacon | Active | **In a room already full of the Choir's light, the lantern buys you nothing and costs you everything:** you must fight the ring *dark* in a lit room, and the ring's own braziers are the only read you get on the censer swing. | dark pack forces the braziers out — at T3 this kit becomes dark by re-key, and the ring's light becomes the only light | authored, **L** — hosts **The Unnumbered** (§7) |
| LT-06 | Chant Road | The Litany | 3, 4 | 28 | Two escape vectors: one runs the chant route, one runs a Shroud-choked crypt; the Sepulchre sits between them; one light pocket | 11 geodes / 33 | 10 Grub on the chant route, 8-ring nodes, 1 Deacon, 1 Acolyte | Active | **Both exits cost Composure:** the safe route is the Choir's route, where the chant drains 0.5/s (SYS-001 §1.5), and the clean route needs Surgelight burns that cost 1 each at T ≥ 2 (SYS-001 §1.5) — you leave by paying, and the only question is in which currency. | ring on; Shroud lane regrows behind the player (§5.1); second Deacon at T4 | authored, **C L** |

### 3.4 Green Rot — 5 kits

| Kit ID | Name | Biome | Seam slots | Threat pts | Geometry (what is on screen) | Geodes / shards on offer | Choir mix | Sepulchre? | Twist | Warp re-key (T3+) | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| GR-01 | Reef Throat | Green Rot | 2 | 17 | Three Shroud lanes cut into a coral shelf, three geodes on the shelf, one unlit underlane, one light pocket | 10 geodes / 30 | 6 Grub, 1 Acolyte | Active | **The Shroud closes behind you:** a cleared lane regrows after 25 s ✱ (SYS-001 §9 clears it, nothing in SYS says it stays cleared), so the route you came in on stops counting as an escape vector, and the lint's two vectors become a timer you can watch. | dark pack; second regrowth lane; lanes start closed ✱ at T4 | authored, **L** |
| GR-02 | Undertide | Green Rot | 3, **5 (gate)** | 24 (gate kit: the rite's budget replaces it, §7) | Reef floor overgrown with Shroud, geodes under the growth, a wide water-plan arena, one unlit channel | 13 geodes / 39, mostly under Shroud | 8 Grub, 2 Acolyte, 2 Deceiver (the gate's wave contents come from SYS-001 §5.1, not from this column) | Active | **The only light in the sector is the Shroud's own rim (ART-001 §5):** every Ward slice or Surgelight burn you spend clearing a sightline also removes a light source and the Choir's cover — clearing your view blinds you. | dark pack + Shroud bloom on entry ✱; `ui_eat_slot` arms at T4 | authored, **L** — hosts **Grave Tide** (§7) |
| GR-03 | Deceiver's Pew | Green Rot | 2, 3 | 19 | One island, one bridge, one geode cluster on the island, one light pocket under the bridge, Shroud at the bridge foot | 8 geodes / 24 | 6 Grub, 1 Grave-Tide Deceiver | Active | **The Deceiver steals your Charge and walks it home along your own bridge:** each successful bait is 1 Charge (SYS-001 §3) that becomes 2 segments of the entity, and killing it drops the stolen charges back into the world — in the water, where they sink toward the Sepulchre. | dark pack; 2nd Deceiver; bridge foot grows Shroud at T4 | authored, **S** — **reserve** (§3.8) |
| GR-04 | Shroud Bloom | Green Rot | 3 | 26 | A hollow: half-built Sepulchre, Litany Ring on the hollow lip, Shroud walls all round, one unlit burrow, one light pocket, Matron at the lip | 9 geodes / 27 | 1 Matron, 8 Grub, ring nodes | Active | **The Matron can be silenced or killed, and the sector remembers which:** killing her stops the chant and *rains* the sector (SYS-001 §3: Shroud bloom, +1 Corruption), so a killed Matron fills your arena with terrain while a silenced one leaves it open — the same 12 seconds, two different rooms. | ring on; bloom radius +1 ring ✱ per T above 2; burrow becomes the only route at T4 | authored, **C** — Seam-3 Matron gate host (§4.5) |
| GR-05 | Green Silence | Green Rot | 4 | 30 | A dense Shroud maze, geodes in its pockets, one unlit burrow, no light pockets outside the maze | 12 geodes / 36 | 1 Listener, 1 Deacon, 8 Grub **inside** Shroud (not visible until their silhouette breaks the rim) | Active | **The Shroud occludes sound as well as sight:** a procession walking inside it carries no audible chant (SYS-001 §9 audio occlusion is a *through-geometry* budget), so the deposit you should have interrupted arrives finished, and the only tell is a shape moving inside a glow. | dark pack; rim tell 70 px ✱; 2nd Listener; Shroud maze grows one ring ✱ per sector held | authored, **L C** |

### 3.5 The Drowned Observatory — 5 kits

| Kit ID | Name | Biome | Seam slots | Threat pts | Geometry (what is on screen) | Geodes / shards on offer | Choir mix | Sepulchre? | Twist | Warp re-key (T3+) | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| DO-01 | Inverted Nave | Drowned Observatory | 2, 3 | 20 | A broken dome: geode clusters hung from the ceiling, floor debris, four gravity anchors, one unlit shaft, one light pocket mid-shaft | 9 geodes / 27 | 6 Grub (floor), 1 Acolyte (dome ring) | Active | **The ore is on the ceiling and the floor is the ceiling:** flipping the fourth gravity anchor puts you upright under the dome, where the shards you knocked loose are pooled and the Grubs have to walk *up* to reach them. | gravity anchors arm (quadrant, §5.2); vertical wrap on (T3, §5.6); second Acolyte inverted at T4 | authored, **L** |
| DO-02 | Lens Shaft | Drowned Observatory | 3, 5 | 22 | A full-height shaft, the deposit path is the shaft's fall line, the Sepulchre at the sump, one unlit rungs corridor, no light pockets | 8 geodes / 24 | 8 Grub (sump), 1 Acolyte (mid-shaft), ring nodes | Active | **Gravity delivers your ore to the build:** shards fall to the sump where the Choir is waiting, so your only option is to catch them in the 96 px magnet window on the way down (SYS-001 §1.4) — a mining kit where the collection *is* the timing. | ring on; two gravity anchors arm (axis); the sump gains a throat at T4 (vertical wrap) | authored, **L** — Seam-3 Matron-eligible |
| DO-03 | Chime Cupola | Drowned Observatory | 3 | 26 | A cupola ring of 6 turret housings around a lens ring, geodes in the housings, one unlit gallery | 10 geodes / 33 | 6 Acolyte turrets (1.4 s cycle), 5 Grub | Active | **The turret cycle is the only lighting:** six muzzle pulses per 1.4 s cycle (SYS-001 §5.1) carry the entire room, so you get a 0.25 s read after each volley and are blind for the rest of it. | dark pack; 2 housings relocate to the ceiling (inverted turrets at T4); ring on | authored, **C** |
| DO-04 | Drowned Bell | Drowned Observatory | 3, 4 | 28 | A tall shaft with geodes at the crown, reachable only by sustained upward fire; one unlit outer stair; no light pockets | 9 geodes / 27 | 1 Listener, 2 Acolyte, 6 Grub | Active | **Reaching the ore means making noise for six seconds:** the crown geodes need 6 lance hits (SYS-001 §1.3) fired upward while the Listener's 90° hunting arc points straight up the shaft, so the silent route is the one that leaves ore on the table. | dark pack; second Listener (E8: it hunts your lantern, SYS-001 §4); Deacon at Seam 4 | authored, **L** |
| DO-05 | Cardinal Cupola | Drowned Observatory | 4, **5 (gate)** | 30 (gate kit: the rite's budget replaces it, §7) | A cupola with 6 telescope housings holding geodes, a lens-ring walkway, one unlit gallery, gate anchor at the lens centre | 12 geodes / 36 | 6 Acolyte (housings), 6 Grub (wave contents from SYS-001 §5.1) | Active | **The turrets are loaded with your ore:** detonating a geode in a housing is the only way to put a turret dark (SYS-001 §5.1 weakness), so the ammo for the puzzle is the same Mourning Glass the Choir is carrying to the Sepulchre. | ring on; 2 housings invert at T4; vertical wrap at the sump throat | authored — hosts **The Censer Cardinal** (§7) |

### 3.6 The Black — 4 kits

| Kit ID | Name | Biome | Seam slots | Threat pts | Geometry (what is on screen) | Geodes / shards on offer | Choir mix | Sepulchre? | Twist | Warp re-key (T3+) | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| BK-01 | Void Vigil | The Black | 3, 4, **5 (gate)** | 22 (gate kit: the rite's budget replaces it, §7) | Maximum-range open torus, nine lone geodes strung on a ring, one unlit drift line, zero foreground, gate anchor at the ring centre | 9 geodes / 27 — the sector sits 3 shards above the lint floor | 1 Herald anchor (reserved), 1 Acolyte, 6 Grub on one long route | Active | **The only cover in the sector is The Penitent:** the weeping figure drifts a safe line across the open field (ART-001 §3: only lit by your lantern), and shooting it costs 1 Composure (SYS-001 §1.5) — in The Black, a shield is something you have to decide to shoot. | dark pack; ring on; wrap roulette + gaze-cone escape (§2.2); the field shrinks one ring ✱ per sector held at T4+ | authored, **L** — hosts **Your Own Vigil** (§7) |
| BK-02 | Mid-Build | The Black | 3, 4 | 30 | Sparse field, a Sepulchre already part-built at the throat, the Litany Ring already up on arrival, one unlit drift line, one light pocket | 8 geodes / 24 — exactly the lint floor | 8 ring Acolytes, 6 Grub, 1 Deacon, 1 Herald anchor (reserved) | **Prebuilt** — `prebuilt_segments = 8 ✱` | **The countdown was already running when you arrived:** you enter at Guard (SYS-001 §2, 6+ segments = ring), so the first 20 s ✱ is spent reading a build you did not watch happen, and the ring's 8 nodes are between you and the ore. | ring nodes +15% deposit per living node applies from t=0; ring on at T3; at T3 the Sepulchre is visible from entry (lint item 4 stops applying above T2, §4.3) | authored |
| BK-03 | Herald's Pew | The Black | 4 | 34 | The only full 2-screen open field in the kit pool; a duel circle with no geodes within 200 px ✱; two herald anchors; one unlit drift line | 7 geodes / 21 — passes lint only as part of a multi-kit sector | 1 Herald (SYS-001 §5.2), 2 Acolyte, 4 Grub | **Cold** | **The duel circle is bare on purpose:** a Herald counters the tool you use most (GDD §8.5), so a kit with no geodes near the circle removes the brute-force answer and forces the counter-play listed in SYS-001 §5.2 for that named Herald. | ring dormant (a duel is not a service); wrap roulette; `ui_eat_slot` arms at T4 | authored, **S** |
| BK-04 | Ninth Penitent | The Black | 3, 4 | 24 | Sparse field, 7 geodes on a ring, a cold Sepulchre, one unlit drift line, one Penitent anchor, one light pocket | 7 geodes / 21 — lint pass via satellites only | 1 Penitent, 6 Grub, 1 Acolyte, 1 Deacon | **Cold** | **This is the Coma kit:** when §4.5's mercy fires, the Penitent attaches here and every Choir unit that dies within its 160 px ✱ halo drops one shard, so the mercy is visible on screen rather than handed to you in a menu. | dark pack is a no-op; the halo follows the player at T4 (WARP-001 owns the effect); ring dormant | **placeholder** — geometry set deferred by the cut order (GDD R-03); ships after the cut-order line, and BK-04 is the first kit to be cut if the schedule breaks |

### 3.7 Kit totals and lint check

| Biome | Kits | Threat range | Dark kits | L/T/S Twists | Waking-anchored kits |
|---|---|---|---|---|---|
| Pale Marches | 6 (PM-01…06) | 9–18 | 1 (PM-02) | 3 (PM-02, PM-05, PM-06 route/chant-adjacent = 2 counted L/S) | 5 |
| Ossuary Belt | 6 (OB-01…06) | 11–20 | 2 (OB-04, OB-06) | 3 (OB-04, OB-05, OB-06) | 5 |
| The Litany | 6 (LT-01…06) | 20–28 | 1 (LT-02) | 6 (all six) | 6 |
| Green Rot | 5 (GR-01…05) | 17–30 | 1 (GR-01) | 5 (all five) | 5 |
| Drowned Observatory | 5 (DO-01…05) | 20–30 | 4 | 2 (DO-01, DO-04) | 5 |
| The Black | 4 (BK-01…04) | 22–34 | 3 | 3 (BK-01, BK-03, BK-04) | 3 |
| **Total** | **32** | 9–34 | **12** | **22 kits with a lantern / chant / Shrine Twist** (requirement: ≥ 12) | **29** |

Threat check per slot (T0–T1 bands, SYS-001 §4; a kit's number plus ≥ 2 satellites must land inside the band):

| Seam | Band (T0–T1) | Kits available | Headroom check |
|---|---|---|---|
| 1 | 8–12 | PM-01(10) PM-02(11) PM-03(9) OB-01(11) OB-04(12) | max kit 12 + 2 satellites ⇒ lint forces the satellites to supply geodes without adding threat markers, or the sector draws 1 satellite. **Reconciled in §4.3.** |
| 2 | 12–18 | PM-02(11) PM-03(9) PM-04(14) PM-05(15)† PM-06(18) OB-02(15)† OB-03(16) OB-04(12) OB-05(18) OB-06(20)* GR-01(17) GR-03(19)*† DO-01(20)* | * = Seam-2-eligible at T2+ only (threat above the T0–T1 band); the generator may not place them at Seam 1–2 below T2. † = reserve kit, not drawn before Act 2 entry (§3.8). |
| 3 | 16–22 | PM-06(18) OB-03(16) OB-05(18) LT-01(20) LT-02(22) GR-03(19)† DO-01(20) DO-02(22) BK-01(22) BK-04(24)* | BK-04 at Seam 3 requires T ≥ 2. † = reserve (§3.8). |
| 4 | 20–28 | OB-06(20) LT-01(20) LT-04(26)† LT-05(26) LT-06(28) GR-04(26) GR-05(30)* DO-03(26) DO-04(28) BK-02(30)* BK-03(34)* | GR-05/BK-02/BK-03 at Seam 4 require T ≥ 3 (their authored threat exceeds the T0–T1 band because their contents are tier-gated: Listener-maze, prebuilt ring, Herald duel). |
| 5 | Rite gate | OB-05, LT-02, GR-02, DO-05, BK-01 | gate kits replace their authored threat with the rite's budget (SYS-001 §4 "budget is the boss"). |

Every kit's threat sits inside a band it is slot-eligible for, with one deliberate exception set: kits whose *contents* are tier-gated (GR-05, BK-02, BK-03) carry threat above the T0–T1 band and are gated to T ≥ 3 by the `min_warp` parameter ✱. That is the only place where a kit's threat and a band disagree, and it is resolved by refusing the placement rather than by breaking the band.

### 3.8 The uncharted reserve (4 kits held back until Act 2)

PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-11. Four of the 32 kits are held back from the draw pool until **Act 2 entry**: **PM-05 Sacred Ground, OB-02 Censer Walk, LT-04 Nine Altars, GR-03 Deceiver's Pew** (count and unlock point: SYS-001 reserve-kit rows). They are part of the existing 32, so they add no scope; they are marked **reserve** in the §3 Status column and † in the §3.7 slot table.

- **Before Act 2 entry** a reserve kit is not drawn as a primary kit by the assembler (§4.4), including by the Coma re-roll (§4.5).
- **They arrive as rumours.** A reserve kit is announced as a Codex entry in a **title-only state**, chalked up by Sable Vane at the Chalk Desk; the entry's body is written when the player finds the place. A rumour is an unfinished Codex entry, not a new noun. The rumour state, the titles and the bodies are NARR-001 §8's.
- **Why these four:** the kit-memory sim (`tools/design_sims/kit_memory_sim.js --reserve`; research `cosmic_horror_design.md` §3.2, §10.1) shows this set leaves every Seam slot fillable. An earlier pick that held back OB-06, the only Seam-4 kit among the Iteration-1 biomes, broke Act 1 assembly; the reserve must never contain the only kit for a slot in any Iteration.

---

## 4. Seam assembly rules

### 4.1 Run shape
A run = 5 Seams 🔒 (SYS-001 §6, GDD §6.3). Seam 1–4 present one primary kit each; Seam 5 presents the **gate kit** (§4.5). A run past Act 1 always contains: ≥ 1 Waking-anchored kit (29 of 32 qualify), ≥ 1 dark kit (§4.4), ≥ 1 kit with a lantern/chant/Shrine Twist (§3.7), and exactly one Waking end encounter at Seam 5 (GDD §6.3).

### 4.2 Sector composition
One Seam = one sector = the primary kit plus **2–6 satellite clusters** ✱ drawn from that kit's own `spawn_markers` and `geode_clusters` slots, giving the 3–7 figure SYS-001 §6 uses for a sector's contents. Satellites reuse the primary kit's geometry set and never add new props, which is what keeps GDD §8.8's performance promise true: one screen cluster per kit, one tileset per biome, and the warp effect budget per sector is 3 ✱ (GDD R-02).

**Budget note: the Passing** (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-02). The Passing (W3-11, lethal to the lit, T3+) and its far-parallax echo (W2-11 Distant Passing, T2, never lethal) are WARP-001 §2 registry entries; WARP-001 owns the tells and rules. Level-side, a Passing:
- **spends warp budget the first time it occurs in a sector** (SYS-001 §2.3 `Passing warp budget cost (first per sector)`); that cost counts against the sector's warp effect budget above;
- occurs **at most once per sector** (SYS-001 Passing max-per-sector row), **never in Seam 5** (so a gate kit never hosts one, §4.5, §7), **never during a Rite**, and never while a HUD lie is live (WARP-001 §4);
- crosses the sector from one wrap edge to the other over a swath set by the SYS-001 Passing swath-width row; it adds no geometry and moves no slot, so the assembled sector's lint (§4.6) is unchanged;
- leaves a **chalk outline** where each subtracted object stood, for the rest of the sector (WARP-001 owns the look);
- **never subtracts an unshot geode.** An unbroken geode is unlit rock, and only loose shards, Shrines, units and the Vigil can be lit. So the §1.5 shard floor that the assembly lint proved still holds in play. Shards the player knocks loose during a Passing can be lost, and that's the player's choice.
- **Sectors the entity has crossed** (GDD Act 3, CHD-07: they load partly subtracted) re-run the §4.6 lint on the subtracted state before play, the same way Hollow sectors do (§6.5).

### 4.3 Threat arithmetic
`sector_threat = primary_kit.threat + Σ satellites.threat`, and that sum is validated against the Seam band for the current tier (SYS-001 §4). Rules:
- A kit is placed at a Seam only if its authored `threat_pts` ≤ the band ceiling minus a satellite floor of **2 threat** ✱ for the satellites' minimum contribution. Where a kit cannot satisfy that (the five Seam-1 kits at 11–12), the sector is drawn with **one satellite**, and the lint's shard floor is met by satellite *geodes* (which carry no unit threat) — this is why PM/OB Seam-1 kits are geode-heavy and Grub-light by design.
- `min_warp` ✱ gates the three content-heavy kits (§3.7) instead of discounting their threat.
- Re-key lifts the sector sum into the tier band (×1.7 / ×2.15 derived ratios, §1.5); the generator may not hand-pick units to exceed the ceiling.

### 4.4 Guaranteed variety
Per run, enforced by the assembler:
1. **No repeated Twist** — automatic: each of the 32 kits has exactly one Twist, so `no kit repeats in a run` is the enforced form of the rule.
2. **No repeated primary kit**, and **no kit family (same kit re-keyed) twice**.
3. **Biome spread:** at most 2 Seams share a biome; Act 1 runs use exactly 2 biomes (GDD §17 vertical slice); Act 2+ runs use 3–4. **The Seam-5 gate kit is exempt:** it counts neither toward the 2-Seams-per-biome cap nor toward the run's biome count (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-13). Without the exemption the rule cannot fill 5 Seams in Act 1, since 2 biomes × 2 Seams = 4 (sim finding F1, `tools/design_sims/kit_memory_sim.js`; research `cosmic_horror_design.md` §10.1).
4. **≥ 1 dark kit per run past Act 1** — 12 dark kits exist (§3.7), and the T3 re-key pack can turn any kit dark, so the rule never constrains the pool.
5. **≥ 1 kit per run whose Twist interacts with the lantern, the chant or Shrines** (22 kits qualify).
6. **≥ 1 unlit corridor per sector** and **≥ 1 light pocket per sector** (kit parameters; lint-checked).
7. The **same kit never appears in the same Seam ordinal across two consecutive runs** — the run seed carries the previous run's ordinal history; this is what makes the Coma mercy (§4.5) legible as *the same room again*, and why its re-roll is felt. **Waived in Iteration 1 only** (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-13): among the Iteration-1 biomes only OB-06 fits Seam 4 and only OB-05 fits Seam 5, so the rule would break on most Act 1 runs (sim finding F2, `tools/design_sims/kit_memory_sim.js`; research `cosmic_horror_design.md` §10.1). From Iteration 2 the rule applies in full.

### 4.5 Seam 3, Seam 5 and the 3-run Coma
- **Seam 3:** one Matron is present (`OB-05`, `LT-03`, `GR-04`, `DO-02` are Matron-eligible). She is **silenced, not killed** (SYS-001 §3), and the gate plays inside the kit's authored geometry with its gate anchor at the far side of the screen.
- **Seam 5:** the gate kit hosts the run's named **Rite** (§7). The **Waking** lifecycle continues underneath it: the end encounter at Seam 5 is the Waking of Nhael'Gharoth (GDD §6.3), staged in the gate kit's outer field so the Rite and the countdown are two clocks in one screen (§6.1). The entity never appears at sector start (SYS-001 §2).
- **Coma re-roll (GDD §8.9, SYS-001 §8):** on the third death in the same Seam ordinal of the same run, the assembler replaces the primary kit with another kit eligible for that Seam, from the same biome where one exists, **never** one whose Twist the run has already used, and attaches a **Penitent** to the new kit's `PenitentAnchor`. It is invisible: no menu, no message. It is reproducible — see §4.7. `BK-04` is the kit where the assist is on screen (its Twist), so when the re-roll lands on BK-04 the mercy reads as a fact of the level.
- A re-roll **does not** reset the Waking state, the Corruption state or the Hollow flag of the sector; the entity keeps its segments. Failure moves the loop forward; it does not rewind the countdown.
- **Death-site Penitents (your dead stay lit)** (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-09). Per Chronicle, every death records the kit it happened in and the position within that kit. On a **later visit to that kit**, a **Penitent** spawns at the recorded death site. It uses the existing Penitent behaviour (GDD §8.5; no new unit, no new power). The lore is NARR-001's: the Penitents you meet are you (NARR-001 §5.5).
  - **Shared cap:** death-site Penitents and the Coma Penitent above share one per-sector Penitent cap (SYS-001 death-site Penitent cap row: 1 per sector, shared with the Coma Penitent). **Rekindled Penitents** (LOOP-001 §9.6) are death-site Penitents that persist, so they share the same cap. When more than one qualifies in the same sector, precedence is: **the Coma Penitent, then a rekindled Penitent, then any other death-site Penitent.** The Coma Penitent comes first because the mercy must be reliable; a rekindled Penitent comes next because the player paid to keep it lit. A Penitent that loses the slot waits for the next visit. (Cosmic horror design call within CHD-09/CHD-15; flagged for the PM in the Phase 2 PR.)
  - **Persistence:** the death-site list is **Anchored state** and survives Hard Unmaking (LOOP-001 §2).
  - **Position:** the site is stored in kit-local coordinates and follows the kit's mirror (§1.5), so it marks the same place in the room on every visit.

### 4.6 The lint as a hard gate
No sector enters play without passing all four SYS-001 §4 lint items, evaluated on the **assembled sector** (primary kit + satellites, after re-key, after mirror). Rejection is not a warning: the assembler draws the next kit permutation. Draws are capped at 64 ✱ attempts per Seam; on cap the generator falls back to the last sector that passed and logs it — a shipped build never contains an unlinted sector, and a logged fallback is a level-design bug filed against the kit, not against the generator. `placeholder` kits are excluded from the draw pool until their geometry ships, so the pool at vertical slice is 31.

### 4.7 Seed handling
- Run seed: daily/weekly seeds, cursed seeds shared as 12-character codes (GDD §6.3), and personal seeds — all through the deterministic seeded RNG (GDD §13, TECH_ARCHITECTURE).
- **Per-kit sub-streams**, drawn deterministically from the run seed: `sub_seed_mirror` (mirror axis), `sub_seed_fill` (which spawn markers are filled), `sub_seed_satellites` (2–6 clusters and their units), `sub_seed_wrap` (roulette targets at T3+), `sub_seed_coma` (which kit the mercy re-rolls to).
- Because `sub_seed_coma` is derived from the run seed rather than from wall-clock or input, two players on the same seed who die three times in the same Seam get the **same** replacement kit and the same Penitent route. Daily challenges and clip reproducibility survive the mercy rule.
- Telemetry key `seam_deaths` (SYS-001 §8) is the input the mercy reads; `hollow_sectors` and `warp_max` feed the entity's death lines.

### 4.8 Kit memory (kits remember you)

PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-11. Each kit keeps a **per-Chronicle visit count**. A visit is the kit being entered as a Seam's primary kit. The counts are **Anchored state** and survive Hard Unmaking (LOOP-001 §2).

| Memory state | Reached at (SYS-001 kit-memory rows) | Dressing layer (what the player sees) |
|---|---|---|
| **Known** | 3 visits | the Choir have marked it: votive lamps at the player's common entry points |
| **Worn** | 6 visits | Shroud grows along the player's most-flown lanes |
| **Remembered** | 10 visits | the entity has read it: the room reads as studied, and the player's own history in it (death-site Penitents, §4.5; route mimicry, §7.1) is at its densest |

Rules:
- **Dressing, not a rebuild.** Each layer is drawn over the kit's existing geometry and placed procedurally on existing slots (entry anchors, `UnlitCorridor`, `EscapeVector`, `PenitentAnchor`; §1.7). Geometry never moves (§1.3).
- **Parametric per biome, not per kit:** 6 biomes × 3 layers = **18 dressing sets**, each placed by rule on any kit of its biome. No per-kit bespoke dressing is authored.
- **The lint is untouched.** Dressing adds no collision, removes no escape vector and puts no light source inside a `LightPocket` or `UnlitCorridor` (§6.2 condition 4, lint item 3). Worn-layer Shroud is therefore dressing (visual growth only) unless a later ruling makes it terrain, in which case it must pass the §4.6 lint like any other Shroud.
- **Never named on screen.** Known, Worn and Remembered are doc terms. The player only sees a familiar place getting stranger.
- **Deterministic:** placement draws from the run seed (§4.7) and the visit count, so two players with the same seed and the same history see the same dressing.
- **Dressing priority: the five gate kits first.** Every run that reaches Seam 5 visits a gate kit, so OB-05, LT-02, GR-02, DO-05 and BK-01 (the §3.7 Seam-5 row) are visited most and reach each state first (sim finding F3). Their dressing is built before any other kit's: the Waking arena becomes the most haunted place in the game.
- **Thresholds checked by simulation:** `tools/design_sims/kit_memory_sim.js --reserve` (deterministic, seeded; research `cosmic_horror_design.md` §10.1) has the first kit reaching Known, Worn and Remembered at about runs 4, 11 and 25, and by run 30 about 19 kits Known, 9 Worn and 2 Remembered (corrected run, 2026-11-18: five gate kits, DO-02 is not one). Those are model outputs, not playtest measurements; the thresholds are retuned at playtest in SYS-001.
- **Inputs owed:** "common entry points" and "most-flown lanes" need per-Chronicle, per-kit route telemetry, the same data Your Own Vigil reads (§7.1). No SYS-001 §8 key exists for it yet (value owed: SYS-001 row requested). The look of the 18 sets is ART-001's (handed to the Aether art chat).

---

## 5. Biome-specific hazards

### 5.1 Shroud
SYS-001 §9 is binding: blocks movement, cleared by 1 Ward slice or 1 Surgelight burn, **HP 3**; Surgelight's burn clears a 56 px sphere in 0.4 s (SYS-001 §1.1) and costs Composure at T ≥ 2 (SYS-001 §1.5). Shroud rims emit PHOS-1/2 (ART-001 §5) — it is terrain *and* light. Green Rot is where this is a system rather than a garnish: `GR-01` regrows cleared lanes after 25 s ✱, `GR-02` makes light and cover the same object, `GR-05` occludes chant inside growth. Ward Pulse also "clears 1 tile of Shroud" (GDD §4.1) — that single-tile clear is the cheap option; the burn is the fast, Composure-priced one.

### 5.2 Gravity inversions
Available only in kits carrying `gravity_anchors` (Drowned Observatory for all five; `OB-03` at re-key). Two authored layouts: **quadrant** (4 anchors, any one active) and **axis** (2 anchors, floor/ceiling) ✱. Anchor activation is a player action through a geometry feature (a lens, a broken dome rib), never a scripted cutscene. Effect on the level: shard drift, procession routes, and turret arcs re-solve — an inverted `DO-01` is a different kit at the same threat. The ≤ 1.5 s agency rule (GDD §8.7 criterion 3, SYS-001 §9) means the flip must be readable for at least 21 frames ✱ before it takes: the anchor telegraphs with a PHOS-3 bloom, and the frame of the flip is a hard light-band swap, never a fade.

### 5.3 Dark corridors
Authored dark volume is `dark_default` plus `unlit_corridors` ≥ 1 (lint). Below T3, mining in the dark is disabled without the `Dark Lantern` node (SYS-001 §1.2) — so a dark kit is only fair when it also carries ≥ 1 lit geode cluster, which all 12 dark kits do. The Sepulchre emits nothing until Quickening (ART-001 §5), which is what makes the shard-steal beat in `PM-02`/`OB-04` work: in the dark the only light is the shard in the Grub's claws and your own lantern.

### 5.4 The Black's sparse supply
SYS-001 §4's 24-shard floor is a floor, and The Black kits sit on or slightly under it (`BK-02` 24, `BK-01` 27, `BK-03`/`BK-04` 21 with lint pass only through satellites). Consequences designed in, not papered over: no foreground occluders, so no line-of-sight cover and the entity's gaze cone is unanswerable except by breaking the cone or the lantern (SYS-001 §1.2); one long procession route, so the ore race is a race against a visible clock; the 13-charge kill (SYS-001 §1.4) is only reachable in The Black if the player detonates for volume (4–6 shards, 140 px scatter, SYS-001 §1.3) and accepts the Choir getting the rest. The Black also carries the highest `min_warp` and the only kits reserved for gate and Herald duty, so a player who never reaches iteration 4 never sees the pool's sharpest end.

### 5.5 The Drowned Observatory's verticality
Verticality is not traversal flavour; it re-solves the ore economy (shards fall — `DO-02`'s entire point), the turret geometry (`DO-03`, `DO-05`), and the Listener's hunting arc (`DO-04`). Vertical sightlines are capped at 3 screens ✱ so the Ledger Compass can render a truthful column at T < 3, and every shaft carries one unlit rungs corridor to satisfy the lint's corridor item horizontally.

### 5.6 The torus edge, per biome and tier
GDD §4.2: the Pale Marches torus-wraps, and higher tiers change what wrapping *means*. WARP-001 owns the effect list; the table below is the level-side contract — what `wrap_targets` returns at each tier, and what the kit must author so the effect stays legible (GDD P3: reality is a difficulty setting you can see).

| Tier | What the edge does | Level-side requirement |
|---|---|---|
| **T0** | Honest torus: left↔right, up↔down (Pale Marches, The Black). Walled biomes have no wrap. | Edge throats marked with BONE-1 chevrons ✱; shard drift crosses edges carrying their own read. |
| **T1** | Same, plus chant audible across the throat. | Throat carries a `ChantSource`; no roulette. |
| **T2** | Same targets; Shroud may choke the throat (Green Rot). | A choked throat must still leave 2 escape vectors (lint re-check after every Shroud bloom). |
| **T3** | **Edge-warp roulette** (GDD §8.7): 2 of 4 edges remap to a random other edge; The Drowned Observatory adds vertical wrap with inversion. | Transit read of 0.4 s ✱ (≤ 1.5 s agency rule); a rim flash of PHOS-5, never SIGNAL; the target must be visible from the throat. |
| **T4** | A wrap can exit into a different biome's edge or a memory of the sector (WARP-001). | Exit biome's throat palette bias must be visible in the transit frame, so the lie is legible rather than hidden. |
| **T5** | Wrap is an **eaten rule** (SYS-001 §2.2, every 2 Hunger; WARP-001 §6 owns the list): `wrap_targets` returns null and the field visibly closes. | The closure must be animated as geometry (a closing iris, ART-001 §7), never as a wall appearing; the player must see the last wrap fail. |

---

## 6. The Waking encounter as a template

Every kit with a `sepulchre_anchor` runs the same phase table (GDD §8.4, SYS-001 §2). What this doc adds is the **geometry contract** that makes each phase playable and legible.

### 6.1 Staging the phases inside a kit
| Phase | Geometry requirement in the kit | Why |
|---|---|---|
| 0 Seed / Cold Sepulchre | Sepulchre anchor placed **off the entry sightline** (lint item 4 at T ≤ 2); deposit lane authored, ring anchors dormant | The player should be able to find it, not be shown it. |
| 1 Procession | 1–2 `procession_routes` of 2–4 waypoints ✱, each terminating at a `deposit_paths` entry; route length authored so a lap delivers `⌈route_len / (130 px/s) × 1 lap⌉` worth of shards, i.e. **3 carried shards = 1 segment** (derived from SYS-001 §3 carry 1 and §2 shard 3 = 1 segment) | A lap is a clock you can watch, not a number you are told. |
| 2 Guard | `litany_ring_nodes[8]` at 140 px radius ✱; 4+ nodes down simultaneously halts deposits 4 s (SYS-001 §3.1), so the ring must be authored with **no node shadowed by another node's fire lane** | Ring-breaking is the kit's skill expression; the geometry must not make it unfair. |
| 3 Quickening | ≥ 12 segments: the Sepulchre gains a PHOS-3 breath pulse (ART-001 §5) and the kit's `ChantSources` step up; the Ledger Compass begins to lie (SYS-001 §6) | The tell is light and sound, so a Steady Ledger player still reads it. |
| 4 AWAKENING | 20/20: 3 s stagger window, 3 hits needed (SYS-001 §2) — the kit must keep **clear air** within 520 px of the Sepulchre (the gaze cone length, SYS-001 §1.2) so the stagger is actually attemptable | A stagger window blocked by props is a kit bug. |
| 5 Rampage | The entity is unlit and occludes light (ART-001 §5); contact hitbox inset 16 px (SYS-001 §2.1); it eats geodes, Choir units and Shrines to heal (SYS-001 §2.1) | The kit's geode clusters are its supply lines, so their placement *is* the fight's terrain design. |
| 6 Unravel | Act 3–4 only; 3 rule-threads; `reserved_markers.rite_gate` doubles as a thread anchor | Latching needs a stationary anchor; the gate anchor is authored to be reachable in ≤ 4 s of flight. |

### 6.2 What "steal a shard from under a procession" requires geometrically
Four authored conditions, all lint-checked (SYS-001 §1.2 note: "the entity's Sepulchre only lights itself, so a dark player can steal shards from right under a Choir procession"):
1. **A light pocket** (radius 110 px ✱) **intersecting a procession route** — a volume with no authored or Choir light source.
2. **A Grub panic radius overlap**: Grubs in darkness take detection −40% and deposit −25% (SYS-001 §3.1), so the route's slowest, most vulnerable stretch must be inside the pocket.
3. **The deposit path must cross the pocket** — the theft has to be on the way, not off in a corner.
4. **No authored light within the pocket and no SIGNAL tell inside it** — the only pixels in the volume are the carried shard's PHOS-4 glow and, if you choose to use it, your own lantern.
Kits satisfying all four: `PM-02`, `OB-04`, `OB-05`, `LT-01`, `LT-02`, `GR-03`, `BK-02`. The 15-second read: dark corridor, a line of small glowing shards walking through it, a ship sitting in the black next to them, one Grub relieved of its load.

### 6.3 Litany Ring placement
8 nodes at 140 px radius ✱ around the Sepulchre, spaced 45°, each node's fire lane authored clear of the other seven. 140 px is the minimum that keeps every node outside the 120 px hold-fire radius (SYS-001 §3.1): a smaller ring would freeze the Choir's own fire discipline and turn phase 2 into a standstill. Where a kit's geometry cannot host a legal ring (`OB-01`, `BK-03`, `LT-05`), the re-key moves the ring to a `GateAnchor` proxy rather than shrinking the radius, and the kit's `LitanyRingNodes` are disabled with a note in the `.tres`.

### 6.4 Procession routes and deposit paths, in the scene
`procession_routes` are `Path2D` with 2–4 `PathFollow2D` waypoints ✱; a route may cross at most one other route (a crossing is a readable moment, three crossings are noise); each route carries one `ChantSource` per 200 px ✱ so the chant's 420 px audibility budget (SYS-001 §9) makes a procession audible around one corner and not three. `DepositPaths` run route-end → Sepulchre and must contain ≥ 1 unlit corridor segment: that is where the player's dark theft (§6.2) happens, and it is why the lint's unlit corridor and the deposit path are authored together rather than separately.

### 6.5 Hollow-sector aftermath
Losing the Waking encounter takes the sector **Hollow** (GDD §8.4, SYS-001 §2.1: permanent entity patrol in that biome, Hunger +1). Level-side consequences, all data-driven:
- The biome's kits carry a `hollow_patrol` flag: a Waking anchor in every **unresolved** kit of that biome flips to `active`, and the run's later Seams in that biome gain an entity patrol marker drawn from `sub_seed_fill` — the entity's rampage speed (SYS-001 §2.1, always below `max_speed` 340) is what makes the patrol survivable-but-strict.
- The kit's geode clusters are marked **eaten**: the sector's shard supply for a Hollow biome is recomputed **before** lint, so a Hollow biome can legitimately fail the lint and the assembler must then pull the sector from a different biome. That is the mechanical teeth of the war: the Choir's ground shrinks the space you can be dealt.
- The Ledger Compass drops the sector from its list (GDD §8.4), and the `Ledger Compass` lie rule (SYS-001 §6) does not apply to a sector it no longer shows — the absence is the honest signal, and the Steady Ledger toggle shows it as a hole, not a lie.
- Hollow sectors are tracked as `hollow_sectors` (SYS-001 §8) and shown in the run summary as a stat, not a warning.

### 6.6 The Procession (Act 2 funeral column)

PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-10. **The Procession** is an Act 2 Choir encounter placed in one **satellite cluster** of a sector (§4.2). It is not the Waking's phase-1 Grub laps (§6.1, §6.4), which keep their name; this doc writes "the Procession" (capital P) for the funeral column only.

- **Units (existing only, §3 intro):** four Grubs bearing one Mourning Glass body between them, led by Deacons singing (the Comforters; Deacon count: value owed, SYS-001 row requested). **No Matron:** the run's one Matron stays at Seam 3 (§4.5, §7), so a Procession never adds a second one. The column walks one of the host kit's `procession_routes` toward its Sepulchre.
- **Break it:** the body drops as shards (SYS-001 Procession shards-when-broken row) and every Choir unit in the sector goes to **full detection**.
- **Let it pass, Lantern down:** Composure rises (SYS-001 §1.5 Procession let-pass row), the column **consecrates the Sepulchre** (+1 segment, SYS-001 Procession Sepulchre-segments row), and the Codex entry `cx_choir_procession` is stamped (NARR-001 §8). Restraint helps the player's nerve and costs them in the race.
- **No prompt, no moral-choice HUD** (NARR-001 §11.3). The choice is made by play only; nothing on screen names it.
- **Level-side requirements:** the host kit needs a `sepulchre_anchor` and a procession route the column can walk; the route should cross an unlit corridor so letting it pass with the Lantern down is a real option (§6.2). The column's units count toward the sector threat sum and the sector passes the §4.6 lint with them in it (§4.3).
- **Not yet decided:** how often the Procession is drawn, which Seams may host it, and the exact "let it pass" test (owed: Design (levels) with SYS-001). The Matron conflict with §7 ("at most one Matron") is resolved by leaving the Matron out of the column (see Units).

---

## 7. Rite bosses (Seam 3 / Seam 5 gates)

Stats are SYS-001 §5.1's — cited, not restated. This section is only the staging and the arena contract. Each Rite anchors to a kit's `RiteGateAnchor`, and each kit below is the run's Seam-5 gate host **or** the Seam-3 Matron gate (§4.5). A run contains at most one Rite plus at most one Matron.

| Rite (SYS-001 §5.1) | Host kit | Arena requirement (authored) | Staging |
|---|---|---|---|
| **Matron of the Drowned Chorus** | `LT-02` primary (Seam-3 Matron gate also: `OB-05`, `LT-03`, `GR-04`, `DO-02`) | Nave volume: a doorway with ≥ 2 tiles of clear approach, a 480 px Litany radius that must not be blocked by props, and one unlit aisle the player can use to break her chant line | She walks the nave's axis, Grubs birth from her doorway (ART-001 §3), the apse keeps the Waking Sepulchre in view so the two clocks share a screen. Silence her with Ward (3 s) and re-silence; killing her is the losing move (SYS-001 §3: Shroud bloom, +1 Corruption). |
| **The Censer Cardinal** | `DO-05` | 6 turret housings placed so each can be killed by an over-fire detonation of its own geode (SYS-001 §5.1 weakness, §1.3 over-fire rule), 24 f tell visible from the entry anchor, body immune until 3 turrets are dark | The cupola is the fight: the player detonates ore inside the housings, which means spending the same Mourning Glass the Choir is hauling — the arena makes the puzzle and the economy the same decision. |
| **The Unnumbered** | `LT-05` | Full 2-screen visibility from one anchor ±20° off-centre, **no foreground occluders at all**, two authored escape lanes, and a walkway the player can circle so the boss can leave the screen | Contact damage exists only off your screen centre (SYS-001 §5.1), so the arena must make looking away *useful*: the geodes are placed behind the player's back, and mining them is what costs you. Ward freezes the re-skin for 2 s; the bright nave gives the re-skin a stage rather than a hiding place. |
| **Grave Tide** (wave event) | `GR-02` | Wide flat reef floor with geodes **on** the floor (the tide eats them, SYS-001 §5.1), 4 wave spawn rings, and Deceivers spawning on the far side so each steal is a chase | 4 waves over 150 s from `sub_seed_fill`, contents per SYS-001 §5.1 (24 Grub + 6 Acolyte + 2 Deceiver). The wave budget replaces the kit's authored threat (§4.3), which is why `GR-02` is authored light on units. Kill Deceivers first: each steal is a Charge you do not get back this wave. |
| **Your Own Vigil** | `BK-01` | A bare 2-screen open field with **no geodes within 200 px ✱** of the duel circle and ≥ 2 escape vectors: the mirror must be fought with the build you brought, not with the level | See §7.1. |

### 7.1 Your Own Vigil — mirror rules
- **Composition:** the mirror is built from the player's own run state, not from a table — same `max_speed`, same lance stats, 3 of your current Run Sigils, 1 fewer Charge (SYS-001 §5.1). Sigils are drawn from the run's actual pick history; the entity already reads your telemetry (SYS-001 §8 keys `glass_hunted`, `charges_thrown`, `charges_lost`), which is why this is the emotional and mechanical showcase the GDD §9.2 promises: the fight is a mirror of your habits.
- **Weakness is your own tell:** the mirror exploits your tells the way you exploit the Acolyte's — surgelight spam is punished by a 1.2 s counter-window (SYS-001 §5.1). The kit therefore forbids foreground: no trick shots, no cover, no reading the room instead of reading yourself.
- **Staging:** it enters through the wrap edge you used most this run (drawn from `sub_seed_wrap`), which is legible as an accusation rather than explained as a rule.
- **It flies your routes** (PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-07; the Act 3 "your habits are its vocabulary" beat, GDD §9.1): besides your build, the mirror flies the routes you have flown most **in BK-01**, read from per-Chronicle telemetry. It is a boss made of your muscle memory; the counter-play is to fly the way you never do. The route telemetry is the same per-kit data kit memory reads (§4.8); its SYS-001 §8 key is owed (value owed: SYS-001 row requested). The rule adds no geometry and needs no new slot: BK-01's bare field (§7) already leaves every route open to the mirror.
- **No gore, no jumpscares:** the mirror is your own silhouette, lit correctly, doing the things you do (ART-001 §2, "the ordinary that is not ordinary"). The dread is recognition.

### 7.2 Rite gate geometry budget
A gate kit's arena reserves: one `RiteGateAnchor`, one `PenitentAnchor`, one `UiEatAnchor` (T4+), ≥ 2 escape vectors that the Rite's own attacks cannot seal, and clear air within 520 px of the gate anchor (so an Awakening stagger or a Matron silence is always attemptable). The gate kit's authored threat is replaced by the rite's budget; its spawn markers are then used only for the rite's own adds, per SYS-001 §5.1.

---

## 8. Herald elites

Heralds are Entropy-gated elites with hard counters to the tool you use most (GDD §8.5, SYS-001 §5.2). Six named variants; their HP, threat (10–14), tells and counter-play are SYS-001 §3 / §5.2 rows — this section is placement and gating only.

### 8.1 Entropy gating
| Entropy | Heralds available per run | Notes |
|---|---|---|
| 0–3 | 0 | SYS-001 §4's Seam-4 line names a Herald at **E ≥ 4**; below that, no Herald is drawn. |
| 4–5 | 1 | Drawn from the 5 non-flagship variants; the flagship **Herald of the Ninth Sky** is not in this pool. |
| 6–7 | 2 | All six except **Herald of the Ninth Reckoning** (SYS-001 §5.2: E10 only). |
| 8–9 | 2, and a 3rd may appear in a Hollow sector of The Black or The Litany | Two per **sector** maximum — a screen with three Heralds needs more than 3 SIGNAL tells, which breaks ART-001 palette law 3. |
| 10 | 3, one of which may be the **Ninth Reckoning** | The flex clip; SYS-001 §7.3 pays for it at ×2.30 Ember (Unwritten Ink retired, CHD-15). |

Selection order: the entity's counter-behaviour picks the Herald whose counter targets your top telemetry key (SYS-001 §8), then the generator rejects any Herald that would duplicate an already-deployed counter in the same run. A Herald's counter never stacks with the same counter from the E-table (SYS-001 §4) twice in one sector — if E6 (HUD reliability) and **Herald of the Quiet Pew** would both mute your chant-cues, the Herald is re-drawn.

### 8.2 Placement rules
- Anchored to a kit's `HeraldAnchor` (2 per kit). Eligible Seam slots: 2 and 4 only — a Herald at Seam 1 reads as a wall, and at Seam 5 it competes with the gate.
- **Not** within 200 px ✱ of a geode cluster: a Herald that can be brute-forced with ore detonations wastes its counter-play, and `BK-03` authors this distance explicitly.
- **Not** inside a Litany Ring radius; the ring's 8 Acolytes plus a 10–14 threat elite would blow the sector's threat band (SYS-001 §4).
- Never placed **on** an `EscapeVector` polyline (SYS-001 §4 lint item 2): a duel must be escapable, and flight is the baseline answer to an elite you cannot yet beat. Failure still moves the loop forward (GDD §18).
- A Herald's tell (24 f, SYS-001 §3) must be visible from the entry anchor, and the kit authors a **visible counterplay cue** — the Broken Censer's 220 px intercept radius is drawn as a chalk ring, not hidden as a stat. If a counter cannot be shown, it is the wrong counter for that kit.
- Heralds contribute their threat to the sector sum and never displace Waking anchors; killing one is optional and never gates the Seam.
- Entropy reward multipliers are SYS-001 §7.3's; a run's Herald count is a KPI we track (`Choir elites / Heralds` yields, SYS-001 §7.2).

### 8.3 Herald rumours

PM ruling 2026-11-18 (owner grant), cosmic horror design rev 3, CHD-11. A Herald drawn for Seam 2 or Seam 4 is **rumoured at Seam 1's exit**: its Codex entry appears in the title-only rumour state (the same state as the reserve kits, §3.8; NARR-001 §8 owns it), so the player can pick Sigils against its counter. It is information, not a nerf: the Herald, its counter and its placement rules (§8.1, §8.2) are unchanged.
- Consequence for the assembler: the run's Herald draw for Seams 2 and 4 (§8.1 selection order) must be fixed by Seam 1's exit, so the rumour is never wrong.
- No Herald is drawn, so none is rumoured, at Entropy 0–3 (§8.1).

---

## 9. Coverage: GDD claims about zones, biomes and encounters

| GDD claim | Satisfied here |
|---|---|
| §8.8 "authored encounter kits (32 kits, each 1 screen-sized module cluster)" | §1.3, §1.7, §3 (32 kits, 6/6/6/5/5/4) |
| §8.8 kits "assembled into 5-Seam runs" | §4.1–§4.3, §1.1 |
| §8.8 "guarantees readability and performance while giving variety" | §1.6, §1.7 (one tileset per biome, foreground ≤ 12% ✱), §4.2 (warp effect budget 3 ✱/sector), §4.4 |
| §8.8 "Warp Tier ≥ 3 re-keys kit parameters (enemy mix, mirror, lighting) without breaking solvability" | §1.5 re-key pack, §3 per-kit re-key column, §4.6 |
| §8.8 "solvability lint … minimum shard supply, sightlines, escape routes" | §1.5 (four items), §4.6 (hard gate + draw cap) |
| §8.8 biomes (6, unlocked/rotated by iteration) | §2.1, §2.2 (identity, palette bias, iterations) |
| §8.8 Corruption: geodes → Shrines → sectors → Hollow, "a visible bruise", purging as the capture-point layer | §5.1, §6.5, `LT-04` (seeded shrines), `GR-04` (bloom), §3.6 (`BK-02` prebuild), SYS-001 §6 cited |
| §4.2 "the Pale Marches torus-wraps at the edges; higher tiers change what wrapping means" | §2.2 (per-biome wrap), §5.6 (per-tier contract) |
| §8.1 "a dark player can steal shards from right under a Choir procession" | §6.2 (four geometric conditions), `PM-02`, `OB-04`, `BK-02` |
| §8.5 Choir faction laws: hold fire within 120 px of a Shrine; firing near one converts a geode; chant is positional | `PM-05`, `LT-01`, `OB-05`, `GR-05`, §6.4 |
| §8.4 Waking lifecycle as the spine of every encounter | §6.1 (phase-by-phase geometry contract), §3 `Sepulchre?` column |
| §8.4 failure state: sector Hollow, permanent entity patrol, Hunger +1 | §6.5 |
| §6.3 run shape: 5 Seams + Seam-3 Hollow Vigil gate + Seam-5 Waking end encounter | §4.1, §4.5 |
| §9.2 "Choir Rites (so Act 2–3 are not one fight)", "built from the same modular kit" | §7 (5 rites staged, host kits named), §1.6 (art reuse) |
| §9.2 Your Own Vigil "using your exact build" | §7.1 |
| §8.5 Herald elites: 6 named, Entropy-gated, counter your most-used tool | §8.1, §8.2 |
| §8.9 3-run Coma mercy + Penitent assist | §4.5, `BK-04` |
| §8.7 Warp Tiers: Shroud (T2), edge-warp roulette / gravity inversions / false mini-map (T3), UI-eating (T4), rule-eating (T5) | §5.1, §5.2, §5.6, §6.5 (Compass), §7.2 (`UiEatAnchor`) |
| §16 R-02 "Warp Effect Budget per sector (max 3 novel effects/sector)" | §4.2 |
| P6 / §8.7 criterion 1: every effect reads in a 15-second clip with no context | §3 Twist column (each written as a visible sentence), §5.2 (21-frame flip tell ✱), §6.2, §8.2 (visible counterplay cue) |
| §17 vertical slice: "a 5-Seam Act 1 run with 2 biomes" | §4.4 rule 3 (Act 1 = exactly 2 biomes), §3.7 (`placeholder` kits excluded from the slice pool) |
| §6.3 seeded runs; §13 deterministic seeded RNG | §4.7 (sub-streams, reproducible Coma) |
| §11 / ART-001 §4 palette law survives every tier | §2.1 (palette bias per biome, law 1 and 3 restated as binding) |
| ART-001 §2 "we use / we refuse": scale dread, ceremonial stillness, the ordinary that is not ordinary; no gore, no jump-scare faces | `LT-01` (prayer pause), `BK-01` (Penitent as cover), `DO-05` (telescope housings as turrets), §7.1 (recognition, not revulsion) |
| §15 / §17 performance: 60 FPS at 640×360 on minimum spec | §1.7 (marker-only kits, one tileset per biome), §4.2 (foreground and satellite caps), §6.3 (ring radius keeps AI line-of-fire cheap) |
| §5 step 3 "every shard they take delays you" | §6.1 lap math derived from SYS-001 §2/§3, `PM-06`, `DO-02` |
| §19 glossary vocabulary | used throughout; kit and Twist names are local content labels, not new lore concepts |
| §18 D-08 one-hit hull kept | no kit grants HP; survivability in every Twist is avoidance or information |
| §3 anti-pillars: no energy bars, no QTE, no loot-box RNG without choice | §4.4 (choose-with-guarantees, not rolls), §6 (no timed input outside the 3 s stagger, which is SYS-001 §2's own rule), §4.5 (mercy without a menu) |
| RES-001 §5 IP guardrails | front matter; no trademark term, no original name or voice line anywhere in this doc |

No GDD claim about zones, biomes or encounter kits is left unaddressed by this doc.

---

## 10. Open questions (max 5, each with a recommendation)

| # | Question | Recommendation |
|---|---|---|
| Q-01 | **Are SYS-001 §4's threat bands per-Seam or per-kit?** SYS §4 heads the table "Seam"; SYS §6 sizes a sector at 3–7 kits. If the bands were per-kit, a 3-kit sector would exceed every band by construction. | Treat bands as **per-sector** (this doc's reading, §4.3) and have SYS-001 §4 add one column, `kit threat ceiling`, so the kit parameter is authoritative rather than inferred. If systems prefers per-kit bands, the kit count per sector drops to 1 for Seams 3–5 and SYS §6's "3–7" must change instead. |
| Q-02 | **Do Hollow sectors persist into the next iteration?** SYS §6/§8 says the map changes forever after Hard Unmaking, but does not say whether the entity's held ground survives the loop. | **Yes for the iteration in which it fell, no after Hard Unmaking** — the loop resets the board and Hunger rises (SYS §2.2). Otherwise Corruption accumulates across nine loops and the lint eventually cannot find a legal sector anywhere. |
| Q-03 | **Can the Seam-3 Matron gate and the Seam-5 named Rite be the same encounter?** GDD §6.3 puts a mini-boss gate at Seam 3; SYS §5.1 heads rites as "Seam-3/5 gates". | Keep them **separate**: Matron at Seam 3, named Rite at Seam 5 (this doc, §4.5). A single gate would put the run's two countdowns — the Rite and the Waking — in one screen twice, and it costs the run its only two beats of rest. |
| Q-04 | **How many geometry variants per kit before the mirror policy stops reading as authored?** Mirror × unlit re-key × gravity quadrant already gives 8+ layouts per kit. | Cap at **6 permutations per kit** ✱ and hand-author which ones are legal (`mirror_policy` + `min_warp` already do most of this). Past 6, the kit's own Twist stops being visible, which is the whole asset the kit exists to protect. |
| Q-05 | **Does Act 1 (iteration 1) get The Litany at all?** §2.2 starts it at iteration 2, which keeps iteration 1 to two biomes and protects the slice. | Keep **iteration 1 = Pale Marches + one of Ossuary Belt / Drowned Observatory**, and let iteration 2 introduce The Litany with its own first-run guarantee (one `LT-04`, the shrine-purge kit) so the corruption war is taught before it is punished. |
| Q-06 (deferred, M5) | **Should Twists split from kits into a Twist deck with compatibility tags?** (cosmic horror design rev 3 §3.2.1: the 32 Twists de-duplicated into a smaller reusable pool, dealt to kits at assembly.) PM ruling 2026-11-18 (owner grant), CHD-12: **deferred** to an M5 decision; no rework of §3 or §4.4 now. | Decide at M5. If adopted, it is gated by the lint, not by hand QA: each kit keeps its authored **signature Twist on its first visit** in a Chronicle, and the assembler offers only kit×Twist pairs whose tags match, with the §4.6 lint as the hard gate. Until then, one Twist per kit and §4.4 rule 1 stand. Mirrored in TECH-001 §11.1. |
