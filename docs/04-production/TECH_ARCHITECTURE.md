# DARKSTAR — Tech Architecture

**Doc ID:** TECH-001 · **Version:** 1.2 · **Date:** 2026-11-17 · **Owner:** production · **Status:** complete-draft
**Upstream:** `GDD_DARKSTAR_v0.2.md` (GDD-001), `SYSTEMS_BIBLE_STATS.md` (SYS-001), `ZONES_AND_ENCOUNTERS.md` (ZONES-001), `ART_BIBLE.md` (ART-001), `SPRITE_MODULARITY_SPEC.md` (ART-002) · **Downstream:** every code module, every `.tres`, the CI lint, the build pipeline
**Number discipline (hard rule of this doc).** SYS-001 is the only source of numbers. A number appearing here is one of exactly two things: (a) a SYS-001 value being *cited* by section, or (b) an **engineering parameter** we invented here — budget splits, cache sizes, pool sizes, tick rates — marked `✱` and owned by production. An `✱` parameter may never compete with a SYS-001 number; where the two touch, SYS-001 wins and this doc re-cuts its split.

---

## 0. How to read this doc set

### 0.1 What each doc owns

| Doc | Path | Owns | Does **not** own |
|---|---|---|---|
| **This doc (TECH-001)** | `docs/04-production/TECH_ARCHITECTURE.md` | Engine and build config; the Godot scene tree and node ownership; the anchor-node contracts; the data-resource layout and the `ds_` key convention; the tunable-class rules and the data lint; the seeded-RNG and replay design; the shader stack and the draw-call/memory ceilings; manifest **consumption** at build time; save layout, versioning, migration, telemetry keys, Steamworks scope; the per-frame budget split; the automated-test set | Any game number (SYS-001). Any art rule (ART-001/ART-002). Any level parameter (ZONES-001). Any run-structure rule (LOOP-001). Any lore claim (NARR-001) |
| Game design document | `docs/01-design/GDD_DARKSTAR_v0.2.md` | What the game is; the pillars; the systems as fiction and as player experience; the locked decisions (GDD §18) and the glossary (GDD §19) | Numbers, scene structure, file formats |
| Systems bible | `docs/01-design/SYSTEMS_BIBLE_STATS.md` | **Every number.** Stats, threat budgets, corruption constants, Composure deltas, feel and performance constants (§9), the tunables register (§10), the save and telemetry invariants (§8) | How a number is stored, cached, ticked or rendered |
| Zones & encounters | `docs/01-design/ZONES_AND_ENCOUNTERS.md` | Biomes, the 32 Encounter Kits, kit `.tres` parameters, the seam assembler's rules, the **anchor-node names** (§1.7) and the geometry contracts each anchor carries | The node classes that implement those anchors; budgets |
| Roguelike loop & Lantern Tree | `docs/01-design/ROGUELIKE_LOOP_AND_LANTERN_TREE.md` | Iterations, Run Sigils, Pacts, Relics, the ~90 Lantern Tree nodes, the five endings | Save schema, unlock persistence mechanics |
| Reality-warp escalation | `docs/01-design/REALITY_WARP_ESCALATION.md` | Warp Tiers T0–T5 as authored content; eaten-rule list; the UI-eating and Compass-lying content | The shader that implements a tier, the tier state machine |
| Art bible | `docs/02-art/ART_BIBLE.md` | Palette roles, silhouette grammar, lighting law | File formats, atlas packing, import flags |
| Visual quality rubric | `docs/02-art/VISUAL_QUALITY_RUBRIC.md` (ART-004) | How presentation is scored against the approved benchmarks (D-D); the movement inventory; the visual-state matrix and score sheets | Any art rule (ART-001) or number (SYS-001) |
| Sprite modularity spec | `docs/02-art/SPRITE_MODULARITY_SPEC.md` | Module grid, kit ids, part ids, sockets, naming grammar, atlas geometry, Godot import settings | How a composite is instantiated, pooled or mutated in a scene |
| Asset pipeline & manifest | `docs/02-art/ASSET_PIPELINE.md` (**ASSET-003 — pending, not on disk**), `assets/sprites/SPRITE_MANIFEST.csv` | How art is produced; the generator and its scripts; per-row asset status | Anything the engine does with the output — that is §6 here |
| Production plan | `docs/04-production/PRODUCTION_PLAN_MILESTONES.md` (**pending**) | Milestones, vertical-slice definition, kit build order, schedule risk | What is technically possible, or what a milestone costs in frames |
| Audio design | `docs/03-audio/AUDIO_DESIGN.md` (AUDIO-001) | The chant as a positional system, Silence budget, music escalation | Bus layout, voice-count ceilings |
| Source research | `docs/00-research/REFERENCE_SINISTAR_SOURCE_MATERIAL.md` (RES-001) | What the 1983 original did; the IP guardrail | Any shipped name or asset |
| Signals and events | `docs/04-production/SIGNALS_AND_EVENTS.md` (EVT-001) | Every cross-node signal, its sender, payload, listeners; when to use a signal vs a call | Scene tree (here §2) |
| UI architecture | `docs/04-production/UI_ARCHITECTURE.md` (UI-001) | Menu/overlay stack, `Screen` contract, Theme, control states, focus and input rules, UI tests | HUD lie content (WARP-001 §4); palette (ART-001 §4) |
| Player text (English) | `docs/04-production/LOCALIZATION.md` (L10N-001) | Text keys, `en.po`, English fallback and formatting, text validation; localization deferred | Copy tone (GDD §10), fonts (ART-001 §11) |
| Feature workflow | `docs/04-production/ADDING_A_FEATURE.md` | Step-by-step checklist for a new feature folder | Any rule it links to |
| AI rules | `CLAUDE.md` (repo root) | Short rules every AI session loads; points here | Detail (lives in the docs above) |
| Bootstrap brief mapping | `docs/04-production/TASK_BOOTSTRAP_ARCHITECTURE.md` | How the generic bootstrap brief maps to DARKSTAR; owner answers Q1–Q6 | Anything after bootstrap |

ASSET-003 is being written by the art owner and does not exist on disk yet. Everything in §6 that would otherwise live there is stated here as a **consumer-side contract**: what TECH-001 reads, in what shape, and what it does when the read fails. If ASSET-003 contradicts §6 on a producer-side detail, ASSET-003 wins; on a consumption detail, this doc wins.

### 0.2 Conventions used in this doc

| Convention | Meaning |
|---|---|
| `🔒` | Locked by GDD-001 §18 or SYS-001; code may assert it, never vary it |
| `⚙` | Tunable in playtest; lives in a data resource; hot-reloadable |
| `✱` | Invented here, first-pass engineering parameter, owned by production, expected to move |
| `SYS-001 §n` | A citation, not a copy. If the row moves, this doc does not need to change |
| status column | Every claim about what exists is per-row. Prose never claims a system is "done" |

### 0.3 New technical vocabulary introduced by this doc

Game-world words come only from GDD §19. The following are **engineering** names and mean nothing in-fiction.

| Term | Definition | Where |
|---|---|---|
| `SectorHost` | The scene and script that own one sector's lifetime: load, populate, run, tear down | §2.1 |
| `SeamAssembler` | The run-time component that picks kits and stitches them into a Seam per ZONES-001 §4 | §2.2 |
| `KitAssembly` | The instantiated result of one Encounter Kit `.tres`: geometry plus filled slots plus anchors | §2.2 |
| `SlotFill` | One generator decision — a unit placed on a spawn marker — recorded deterministically | §2.2 |
| `AnchorNode` | A named marker/area node in a kit carrying a fixed contract (ZONES-001 §1.6) | §2.3 |
| `CompositeRig` | The runtime node graph that assembles one unit or the entity from 64×64 modules | §2.4 |
| `TunableRegistry` | The single load-time table that resolves every `ds_` key to a value plus its class and SYS-001 row | §3.2 |
| `ds_` key | The dotted, namespaced addressable name of one tunable (§3.4) | §3 |
| `ManifestImporter` | **Retired (D-13).** Was: the build step turning `SPRITE_MANIFEST.csv` into a GDScript table | §6.3 |
| `AtlasTable` | **Retired (D-13).** Was: the lookup from part id to atlas region | §6.3 |
| `WarpComposer` | The per-frame owner of which canvas-item shaders are active at the current Warp Tier | §5.1 |
| `DiegeticHud` | The HUD layer built from in-world objects so it can lie, be eaten, and be drawn by the same code as honest data | §5.2 |
| `SteadyLedger` | The accessibility option that forces the HUD honest | §5.3 |
| `RunSeed`, `SeedCode`, `ReplayVerifier` | Deterministic run identity, the 12-character shareable form, and the hash-comparison test | §4.9 |
| `SaveEnvelope` | The versioned wrapper around every persisted block | §7.1 |
| `ContactBudget` | The runtime counter enforcing SYS-001 §9's on-screen caps (contacts, units, shots) | §8.2 |
| `FrameBudget` | The per-system split of the 16.7 ms frame | §8.1 |

---

## 1. Engine and build

### 1.1 Locked by the GDD

| Item | Value | Source |
|---|---|---|
| Engine | Godot **4.7.2 stable**, 2D renderer | GDD §2, §12; D-06 |
| Language | **GDScript only** for gameplay | D-06 |
| Internal resolution | **640 × 360** pixel-perfect for the **Act 0 arcade screen only**; the bezel and everything after Act 0 render at the display's native resolution (owner, 2026-11-18, D-A). **Decided, NOT YET IMPLEMENTED**: the code still uses a 640×360 viewport everywhere | SYS-001 §0; ART-001 §1; GDD §2 |
| Filtering | nearest-neighbour, never anti-aliased, never mipmapped, on the Act 0 screen; after Act 0 the filter is per asset (open, §11.1 Q3) | ART-002 §1 |
| Scaling | Act 0 screen: integer multiples only (`window/stretch/mode = viewport`, aspect `keep`, integer snap). After Act 0: ✱ proposed (not owner-approved) `canvas_items` stretch, pixel snapping off, switched at runtime after the Act 0 zoom-in. **Not yet implemented** | §1.3 |
| Logical space | ✱ proposed: 640×360 stays the logical coordinate space after Act 0, so SYS-001 px and px/s keep their meaning (1 logical px = display height / 360). Post-Act 0 camera scale / visible world area is open (§11.1 Q5) | D-A |
| Target frame rate | 60 FPS; 60 Hz fixed logic tick | SYS-001 §0, §9 |
| Platform at 1.0 | **Windows + Steam** | GDD §2, §12 |
| Platforms after 1.0 | Linux, then Mac | GDD §2 |
| Data-driven | every table in SYS-001 maps to a `.tres`/JSON resource | D-06, SYS-001 header |
| Mono / C# | not used | D-06 |
| Multiplayer | none in the build; no `MultiplayerAPI`, no network scene, no `networking/` folder | D-09 (coop out of scope for 1.0), GDD R-07 |
| Rendering method | **Forward+** (`rendering/renderer/rendering_method = forward_plus`) | owner decision 2026-11-17 (TASK-BOOT Q2); revisit only if min-spec shows T2 warp shaders over SYS-001 §9's 1.2 ms |

**Amended (owner, 2026-11-18, D-A):** the 640×360 grid binds the Act 0 arcade screen only; the low-res look is a skin/pretence, not a technical limit. The cabinet bezel is native-resolution print art (D-B) and leaves the frame at the end of Act 0 by a camera zoom-in. Post-Act 0 behaviour is decided but **not yet implemented**; the settings in §1.2 describe the current code.

The GDD §2 row offering "512×288 **or** 640×360" is closed here: **640×360** (for the Act 0 screen and as the logical space; see above). It is the resolution SYS-001's px values are written against and the one ART-002's module grid composes against (360 px = 5.625 modules of height; the entity composite at 512×256 therefore cannot fit the frame, which is ART-001 §2's scale-dread rule working by arithmetic rather than by staging).

### 1.2 Project settings we set and never revisit

| Setting | Value | Why |
|---|---|---|
| `display/window/size/viewport_width` | 640 | §1.1 |
| `display/window/size/viewport_height` | 360 | §1.1 |
| `display/window/stretch/mode` | `viewport` (current; ✱ `canvas_items` with snapping off after Act 0 is proposed, not implemented, D-A) | pixel-perfect at any window size |
| `display/window/stretch/aspect` | `keep` | no distortion, letterboxed bars |
| `display/window/hidpi/nearest_filtering` | on | OS scaling must not re-filter art |
| `rendering/textures/canvas_textures/default_texture_filter` | `Nearest` | ART-002 §1 |
| `rendering/textures/default_textures/default_texture_filter` | `Nearest` | same, for generated sub-resources |
| physics ticks per second | 60 | SYS-001 §0 counts frames at 60 Hz |
| `physics/common/physics_ticks_frozen` | never | the game freezes *entities*, never physics (§4.4) |
| `application/boot_methods` | none | boot is a scene, so the arcade shell is the first thing drawn |
| max FPS | uncapped in menus, 60 in-sector | sector logic is tick-locked |
| vsync | on | tearing reads as a warp artefact and would be indistinguishable from content |
| `audio/driver/output_latency` | 60 ms requested | SYS-001 §9 input-to-effect ≤ 60 ms |
| `input_devices/pointing/emulate_touch_from_mouse` | off | a stray touch drag would fire the lance |
| `vr/xr` | not enabled | — |

`Physics` uses Godot's 2D default with one custom exception: geodes and the entity's segments are `StaticBody2D` with one-way `Shape2D` per module, not per composite (§2.4). This keeps a knocked-off segment's collision leaving in the same frame the module leaves the rig.

### 1.3 Integer scaling, honestly

| Window | Scale | Result |
|---|---|---|
| 1280×720 | ×2 | 1280×720, no bars |
| 1920×1080 | ×3 | 1920×1080, no bars |
| 2560×1440 | ×4 | 2560×1440, no bars |
| 1366×768 | ×2 | 1280×768 → 43 px side bars |
| Steam Deck 1280×800 | ×2 | 1280×720 → 40 px vertical bars |
| 3840×2160 | ×6 | 3840×2160 |

We refuse non-integer scaling. A fractional scale blurs a 1 px outline, and the 1 px `VOID-0` outline is the last line of legibility when the warp layers start distorting shape (ART-001 §2). The bars are drawn as part of the arcade cabinet costume in Act 0 (`ui` kit `cabinetBezel`, ART-002 §4) and as plain `VOID-0` elsewhere. A player who wants the bars gone gets a bigger integer step, not a fractional scale; the option is labelled by the multiple it produces.

### 1.4 Build targets and pipeline

| Target | Status | Notes |
|---|---|---|
| Windows x86-64, Steam Depot 1 | planned | only shipping target for 1.0 |
| Windows demo build | planned | Steam playable/demo branch, same binary, gated content flag |
| Linux x86-64 | post-1.0 | not built during development; CI does a compile-check only from month 6 ✱ |
| macOS | post-1.0 | out of scope for v1 entirely |
| Steam Deck verification | target, not gate | verified after the vertical slice; the ×2/40-bar case above is the one we test first |
| Web / console / mobile | refused | refused, not deferred |

| Build step | Runs | Output |
|---|---|---|
| `import` | every checkout, first run | Godot `.import` cache; regenerated, never committed |
| `manifest_import` | **retired** (D-13) | no raster sprites are consumed; the manifest is a reference inventory only (ASSET-003) |
| `data_lint` | pre-build, CI | every SYS-001 §10 row ↔ exactly one `ds_` key; class check (§3.3) |
| `palette_lint` | test suite | `Pal` = the palette file (built); generator render tests check kit colour pools (ART-001 §14.7, planned) |
| `localize_extract` | deferred | English only (L10N-001 §1); `locale/en.po` is edited directly |
| `export_presets` | release | `Windows Desktop` preset, PCK packed, no encryption at 1.0 |

Modders: we ship the `.tres` files loose in the PCK's `data/` folder so a player can edit a tunable in a text editor, and we ship no mod API, no loader hooks and no Steam Workshop at 1.0. Editing a `.tres` is supported as a supported-as-is affordance and is deliberately not a feature; §3.3 rejects a save that carries an out-of-class edit.

### 1.5 GDScript versus native — the honest boundary

| Work | Where it runs | Why |
|---|---|---|
| Movement, lance, charges, Composure, Warp Tier state, Hourglass Clock, spawn budgets, Choir AI state machines, Lantern Tree, save, telemetry, HUD, menus, dialogue, Codex, sector assembly | **GDScript** | all of it is state machines over small numbers, bounded by SYS-001 §3 spawn budgets and §9 contact ceilings — not by arithmetic volume |
| Per-pixel work (light masks, Shroud, warp distortion) | **canvas-item shaders**, GLSL-like Godot shader language | GPU-side; no GDScript pixel loops ever |
| Composite atlas lookups, part pooling | **GDScript**, table-driven | lookups are dictionary hits, not per-pixel work |
| Anything measured over 10,000 objects per frame | would need GDExtension/Rust or C++ | **the ceiling is never reached**: SYS-001 §9 caps on-screen Choir units, entity modules, geodes, hostile contacts, active shots and colliders per sector (all ✱ first-pass rows added 2026-11-17, ruling R-14) |
| A native collision or spatial-hash rewrite | refused for v1 | Godot's 2D physics is expected to be inside budget at SYS-001 §9's collider ceiling; §8.3 measures before we decide |
| Steamworks | GDExtension (`GDSteamworks`, community build, pinned version ✱) | the one exception we accept, because it is a binding, not gameplay code |

**We refuse to write native code for v1.** Not because GDScript is fast, but because nothing in this game's per-frame work is arithmetic-bound: the frame cost is draw calls, shader invocations and scene churn, and those are engine-side regardless of what language authors them. A GDScript hot spot found in §8 profiling gets a data-structure fix or a move to a shader first; a GDExtension rewrite is a documented, logged decision with a profile attached, and no such decision has been taken as of this doc. The single native component we will ship is the pinned Steamworks binding, which contains no game logic and can be stubbed out for non-Steam builds.

Risk we state rather than hide: GDScript is interpreted, and the two places where a naive implementation *would* break budget are the shard-magnet loop (§4.3) and the Ledger Compass redraw (§5.4). Both are designed to be table- and cache-driven in §8.4 rather than per-frame scans. If either misses budget, that is the first candidate for a §11 open question about a GDExtension exception, and it will be a decision with a profile attached, not a refactor done quietly.

---

## 2. Scene tree and node ownership

Status legend for every table below: **built** = exists and is covered by a test; **stub** = exists, minimal; **planned** = designed here, no code.

### 2.1 Top-level tree

```
root (Window, 640×360 logical)
├─ SettingsService, SaveService, SceneRouter      autoloads (§2.8)
└─ Boot  (scenes/boot/boot.tscn — main scene, lives for the whole session)
   ├─ RouteHost          exactly one route scene at a time (mounted by SceneRouter)
   │   └─ AttractMode | CabinetGame (Act 0, §2.10) | RuinsStub | SectorStub (SectorHost, Act 1 stub) | later: LanternTree…
   └─ CurtainLayer (CanvasLayer 100) / Curtain     fade between routes
```

| Node / scene | Owns | Never owns | Status |
|---|---|---|---|
| `Boot` | route host, transition curtain, `-- --smoke` boot path | game state, menus | built |
| Route scene (e.g. `AttractMode`) | its own Controls, its `ScreenStack` of overlays, an `InputModeTracker` | other routes, saves | built |
| `SectorStub` = `SectorHost` stub (`scenes/sector/`) | sector lifetime: spawn the Vigil at `VigilSpawn`, world walls, HUD readout, pause | run state (future `run` feature), persistence | stub |
| `Vigil` (`features/vigil/vigil.tscn`) | its components (§2.5, §2.6) | camera, HUD, input map | built |
| Overlays (`PauseScreen`, `SettingsScreen`, `ConfirmScreen`) | their buttons; emit intent signals | the tree's pause state (owned by the scene that pushed them) | built |

Rules: a route is addressed by id from `data/routes/route_table.tres`, never by path in code. Overlays are not routes. `get_tree().paused` is set only by the scene that owns the overlay stack (`SectorStub`), and is cleared on its `_exit_tree`. Node lookups: `%UniqueName` inside a scene, `@export` references across a scene boundary, groups for "find all of a kind" (`vigil`), never `get_node("../..")`.

### 2.2 SeamAssembler / KitAssembly — planned
Picks Encounter Kits and stitches them into a Seam per ZONES-001 §4. Runs inside `SectorHost`, never as an autoload. Records every `SlotFill` against the `RunSeed` (§4.9) so a run replays. Not built.

### 2.3 AnchorNode — planned
Anchor names and contracts are ZONES-001 **§1.7** (the kit scene tree: `GravityAnchor`, `HeraldAnchor`, `RiteGateAnchor`, `PenitentAnchor`, `UiEatAnchor`, `SpawnMarkerLit/Unlit`, `LitanyRingNodes`, `EscapeVector`, `WrapEdge`). A kit contains markers only, never unit instances (ZONES-001 §1.7). Code finds anchors by group named after the anchor type, never by path. Not built.

### 2.4 CompositeRig — planned
Assembles a unit from 64×64 **generated** parts (ART-002 §5, ART-001 §14.3: vector or shader generators with sockets, D-13). One `StaticBody2D`/`Area2D` shape per module (§1.2), so a knocked-off segment loses collision on the same frame. Not built.

### 2.5 Movement and animation — responsibility split (audit)

Audit of the approved mechanics (GDD §4, SYS-001 §1.1, §9, WARP-001 §2, ART-002 §5):

| Motion need | Applies? | Owner | Status |
|---|---|---|---|
| Vigil thrust / drag / brake / snap turn | yes (SYS-001 §1.1) | `VigilMotor` in `_physics_process` on a `CharacterBody2D` (floating mode); the body never rotates, the `Facing` node does | built |
| Surgelight dash, Anchor freeze field | yes | future `VigilMotor` states / `features/vigil` components | planned |
| Starts, stops, full reversal (0.28 s 🔒 derived) | yes | `VigilMotor.step_velocity` (pure, frame-rate independent); tested | built |
| Choir locomotion, processions | yes | per-unit motor components; paths from kit anchors | planned |
| Modular rig mutation, segment loss | yes (ART-002 §5.3) | `CompositeRig` swaps atlas regions; physics shapes per module (§2.4) | planned |
| Sprite frame animation | yes | `AnimationPlayer` (frame swaps, method tracks that *request* events) | planned |
| Lance / charge / shard VFX | yes | `GPUParticles2D` (small, physical, ART-001 §7) + pooled `Line2D` | planned |
| Per-pixel warp distortion | yes | canvas-item shaders driven by `WarpComposer` (§5.1) | planned |
| UI transitions | yes | `Tween`, 150–300 ms, instant under Reduced Motion (UI-001 §4) | built |
| Camera follow, shake, zoom | yes (SYS-001 §9) | a sector camera component; shake ≤ the SYS-001 §9 ceiling, warp shake inside it | planned (stub camera is static) |
| Jumps, landings, slopes, stairs, ladders | **N/A** — top-down space game | — | — |
| Skeletons, IK, blend spaces, `AnimationTree` | **N/A** — modular sprite rigs, no bones | — | — |
| Facial animation / lip-sync | **N/A** — entity lines are big type + audio (GDD §10) | — | — |
| Vehicles, ragdoll, cloth | **N/A** | — | — |
| Multiplayer authority | **N/A** (D-09) | — | — |

**Gameplay drives animation, never the reverse.** State lives in components (motor, health, future AI state machines). An `AnimationPlayer` reads that state to pick a clip. A method track may *request* a gameplay event (open a hitbox window, play a thruster cue, spawn a spark), but the component validates and owns the outcome. A skipped or sped-up animation can never change a hit, a timing, or a save.

Footstep-equivalents (thruster, mining ticks), audio cues (AUDIO-001 §6.2), VFX and camera feedback subscribe to gameplay signals (EVT-001), not to animation frames, except where a method track is the request source.

Reusable animation resources: animation libraries per kit under `features/<feature>/anim/` (planned). Import settings: §10. Movement/transition tests: §9.

### 2.6 Collision and hit detection (audit)

| Layer | Name | Who is on it | Masks it | Status |
|---|---|---|---|---|
| 1 | `world` | sector walls, geodes, entity segments (per module) | Vigil, Choir bodies | built (walls) |
| 2 | `vigil` | Vigil `CharacterBody2D` | — | built |
| 3 | `choir` | Choir unit bodies | — | planned |
| 4 | `vigil_shots` | Arc-Lance hitboxes / shots | `choir_hurtbox`, `world`, `shroud` | planned |
| 5 | `choir_shots` | Choir projectiles | `vigil_hurtbox` | planned |
| 6 | `pickups` | Mourning Glass | Vigil pickup area | planned |
| 7 | `interactables` | shrines, Sepulchre deposit, Chalk Desk | Vigil interact area | planned |
| 8 | `shroud` | Shroud terrain (SYS-001 §9) | Vigil body, lance | planned |
| 9 | `vigil_hurtbox` | Vigil `HurtboxComponent` | `choir_shots`, hazards | built |
| 10 | `choir_hurtbox` | Choir hurtboxes | `vigil_shots` | planned |

Source: `core/physics/physics_layers.gd` (`PhysicsLayers`) and `project.godot [layer_names]` — keep them identical.

| Need | Shape / node | Rule | Status |
|---|---|---|---|
| Vigil movement | `CircleShape2D` on `CharacterBody2D`; radius = `ds_vigil.move.hitbox_circle_px` / 2 | collision from data, never from the sprite; `move_and_slide` sweeps, so no tunnelling | built; tested at 6000 px/s |
| Vigil hurtbox | `CircleShape2D` on `HurtboxComponent` (same radius) | hurtboxes are `monitorable`, never `monitoring` | built |
| Enemy hitbox | sprite alpha ∩ 1 px inset (SYS-001 §9) → baked primitive/convex per module at import | convex only where a primitive cannot fit; no triangle mesh on anything that moves | planned |
| Walls, geodes, segments | `StaticBody2D`, rectangle/circle/convex | concave/segment shapes only for static kit geometry | built (walls) |
| Fast shots, the lance | `ShapeCast2D` / `RayCast2D` swept each physics tick from previous to current position | anything moving more than its own size per tick must sweep | planned |
| Attack windows | `HitboxComponent.open_window()/close_window()` | one hit per target per window, enforced twice (hitbox set + `HealthComponent` window key) | built |
| Moving platforms, doors, stairs, slopes, ragdolls, cloth, vehicles | **N/A** to this game | — | — |

Ownership: all hit truth resolves in `_physics_process` (60 Hz, §1.2). Animation never toggles shapes directly. Expensive bodies (future Choir) disable processing when off-screen beyond the audio-occlusion radius (SYS-001 §9) — planned, to be measured in §8. Single-player only (D-09): there is no authority or rollback layer.

Bullet-layer decision (TASK-BOOT Q1, owner 2026-11-17): Godot `Area2D`/`ShapeCast2D` first. GDD §13's custom quadtree is built only if §8 profiling shows the bullet layer missing budget at SYS-001 §9's active-shot ceiling.

### 2.7 Audio buses
`data/audio/default_bus_layout.tres`: `Master` (= AUDIO-001's `BUS-MST`; Godot requires bus 0 to be the master), `BUS-MUS`, `BUS-CHO`, `BUS-ENT`, `BUS-UI`, `BUS-FLY`, `BUS-AMB`, all sending to `Master`. Ducking sidechains (AUDIO-001 §7.2) and the never-ducked rules (§7.3) are **not wired yet**. No `AudioService` autoload exists; one needs a §2.8 row first.

### 2.8 Autoload register

An autoload exists only when the service genuinely needs a global lifetime. Adding one: add a row here first, then `project.godot`.

| Autoload | File | Why global | Must not | Status |
|---|---|---|---|---|
| `SettingsService` | `autoload/settings_service.gd` | text scale and accessibility apply before the first frame and across scenes (English only; no language setting) | hold game state; read saves | built |
| `SaveService` | `autoload/save_service.gd` | slots outlive scenes; one place enforces SYS-001 §8 cadence | decide *when* to save (callers do); store display text | built |
| `SceneRouter` | `autoload/scene_router.gd` | one top-level scene at a time; any screen may request a change | own overlays/modals or UI state | built |
| `RunSession` | `autoload/run_session.gd` | run and Iteration state (LOOP-001 §2) outlive every sector scene across 5 Seams and must be readable by the Ruins and `SaveService`; owns the Hourglass Clock tick (§4.1) | own sector nodes; write saves itself (it hands payloads to `SaveService` at allowed reasons) | **planned** (approved 2026-11-17) |
| `AudioService` | `autoload/audio_service.gd` | music stems, the chant and the entity voice cross scene changes; owns ducking (AUDIO-001 §7.2) | decide *when* a line plays (gameplay signals do) | **built** 2026-11-18: one-shot pool, chant bed, silence budget; every cue synthesised by `core/audio/sfx_synth.gd` (D-14: no recorded audio, ever) |

Refused as autoloads: a UI manager (menus use a per-scene `ScreenStack`), a game manager (state lives in features), a networking service (D-09), a global event bus (EVT-001 §3).

### 2.9 Feature folders

| Brief term | DARKSTAR folder(s) | Status |
|---|---|---|
| characters | `features/vigil`, `features/choir`, `features/sepulchre` | vigil built (move + aim + hull) |
| Act 0 arcade (the Cabinet) | `features/cabinet` | **built** — §2.10 |
| combat | `features/arc_lance`, `features/charges` | arc_lance built (M1 slice 1: `ArcLanceStats`, `LanceProjectile`, `ArcLanceEmitter`; hits by `Area2D` overlap, not ShapeCast); charges empty |
| inventory | `features/run` (Run Sigils, Relics, Pacts) — no classic inventory/equipment | empty |
| dialogue | `features/entity_voice` (big-type lines; no branching dialogue) | empty |
| quests | **N/A**; nearest: `features/lantern_tree`, `features/codex` | empty |
| interactions | `features/interactions` (shrines, Chalk Desk, Sepulchre deposit) | empty |
| (game-specific) | `features/composure`, `features/warp`, `features/sector`, `features/hud` | empty |

Each empty folder has a `README.md` naming its owner doc. Shared, feature-agnostic code lives in `core/` (`audio`, `components`, `data`, `i18n`, `math`, `physics`, `rng`, `routing`, `save`, `ui`). Menus and the bootstrap sector live in `scenes/`.

### 2.10 Act 0 — the Cabinet (`features/cabinet/`)

Act 0 (GDD §6.1) is the in-world arcade machine (NARR-001 §5: the Cabinet). It is built as its own feature because ART-001 §7 makes it a **separate, peelable costume layer**: 1983-style vector art on a 4:3 bezel (WARP-001 W0-01), not the shader-rich generated parts of Act 1+ (ART-001 §14). Status: **built** (stages A0-1 and A0-3; A0-2's beats are folded into A0-3).

```
CabinetGame (Node, cabinet_game.gd)             stage flow only: READY → play → death/respawn/game over
│                                                → stage clear → credits → THE PRETENCE → route "ruins"
├─ World (ArcadeWorld)                          torus field, camera, shake, shared services; ticks layers in order:
│   Stars · Geodes · Glass · Ritual · Grubs · Acolytes · Shots · Vigil · Fx   (each an ArcadeLayer)
├─ Autopilot (CabinetAutopilot)                 attract demo (W0-03), captures, the end-to-end test
├─ MawLayer/Maw (MawView)                        the hole that opens in the reveal; the generated "true body" assembles inside it
├─ HudLayer/Hud (CabinetHud)                     bezel, 1UP/score/lives, Charge lamps, SEPULCHRE readout, Ledger Compass
├─ CrtLayer/Crt                                  shaders/crt.gdshader: scanlines, curvature, tear, desaturation
├─ MessageLayer/Messages (CabinetMessages)       READY card, banners, captions, credits, the entity's big type
├─ Reveal (PretenceReveal)                       the scripted W0-07/W0-08 sequence (skippable once seen)
└─ Overlays (ScreenStack)                        pause
```

| Layer | Owns (rules) | Source |
|---|---|---|
| `GeodeField` | drift; calm mining (a face per `face_hits`, one shard each, calm total = 3 + 1); over-fire detonation (9 hits / 1.2 s → 4–6 shards total, scattered) | SYS-001 §1.3 |
| `GlassField` | shards, magnet, Charge pips (overflow glass stays), homing Null-Iron Charges, interception by Grubs/Acolytes/geodes | SYS-001 §1.4 |
| `SepulchreRitual` | deposits → segments (3 shards each), Guard/Quickening, Awakening (silence → "IT WAKES." → 3 s stagger window), rampage (contact death, eats to heal), 13 Charges to unmake, module knock-off before waking, Cold Sepulchre | SYS-001 §2, §2.1 |
| `GrubFlock` | claim → carry → deposit; flee the lamp unless carrying; keening on a lost deposit; rebirth from the Sepulchre | SYS-001 §3 |
| `AcolyteSquad` | hold range, censer shots on a 1.8 s cycle with a 21-frame tell, turret lag 0.25 s, mining at 50 %, Guard reinforcements | SYS-001 §3 |
| `ShotLayer` | lance bolts and censer shots, swept in ≤ 4 px steps (no tunnelling), capped at SYS-001 §9's 180 | SYS-001 §1.3, §9 |
| `VigilShip` | the Vigil in costume: **reuses `VigilMotor.step_velocity`** with SYS-001 §1.1 numbers, one-hit death, Surgelight, respawn shield | SYS-001 §1.1, §9 |
| `ScoreKeeper` | the 1983 score table, extra Vigil at 10,000 then every 20,000, cap 5 | SYS-001 §7.1, GDD §9.4 |

**Physics decision (2026-11-18):** the Cabinet does **not** use Godot physics bodies. Its field is a torus (GDD §4.2), drawn by every layer through `ArcadeWorld.to_screen()` with the short-way-round delta (`core/math/torus.gd`). Circle overlaps in torus space are exact, deterministic and cheap at Act 0 counts. Act 1+ sectors keep the §2.6 component architecture (CharacterBody2D, Area2D hurt/hitboxes).

**Boot-up and attract (owner request 2026-11-18).** `Boot` routes the first attract of a launch with params `{"power_on": true}` (not under `--smoke`); later visits pass nothing.

```
AttractMode (scenes/attract/)                   on_route_entered(params) handles power_on
├─ Frame (AttractFrame)                         bezel side panels via CabinetBezel, 1UP, CREDIT n counter
├─ Logo (attract_logo.gd)                       marquee; blink INSERT CREDIT → PRESS NEW VIGIL once a credit is in
├─ Pages (AttractPages)                         4 cards under chasing marquee bulbs: PITCH (canon NARR Cabinet attract lines), HOW TO PLAY (live bindings per device), THE MISSION, SCORE TABLE (read from CabinetTuning)
├─ CoinSlot (features/cabinet/coin_slot.gd)     focusable Control on the right bezel
└─ PowerOn (PowerOnTest)                        CRT warm-up line, scrolling garbage-RAM noise, top-down wipe, self-test lines (RAM/ROM/LAMP/GLASS … OK, SELF TEST COMPLETE); any key/click skips; noise frozen under photosensitivity or reduced motion; scrolls, never full-field flashes
```

- `CoinSlot` phases: TAPED → FALLING → OPEN → DROPPING → CREDITED; `spend()` returns to OPEN. Signals `tape_peeled`, `credit_inserted` (EVT-001). After `tape_hint_delay` a prompt says how to remove the tape (mouse: drag it off; pad/keys: hold accept while the coin door has focus), then how to insert a coin (click the slit / accept).
- New Vigil is greyed and out of the focus loop until a credit is in; one credit max; New Vigil spends it. Default focus is the CoinSlot until credited; loop = [New Vigil if credited] → Settings → Quit → CoinSlot.
- No idle demo while a credit is waiting or a peel gesture is in progress; otherwise W0-03's 30 s idle demo is unchanged.
- Tape removal is saved forever: profile key `cabinet_tape_peeled`, save reason `cabinet_tape` (§7.2), written in attract, never mid-run.
- `CabinetBezel` (`cabinet_bezel.gd`) holds the static bezel draw helpers (`SIDE` = 80, `COIN_PLATE`); `CabinetHud` and `AttractFrame` share it, and the HUD draws the open, untaped coin door. Placeholder art (§11.1 Q-T20). `CabinetHud` panel text uses a 6 px margin; score, hi score and the SEPULCHRE readout (`segments/total`, or AWAKE; hidden once unmade) draw at PixelText 2× when they fit 72 px, else 1× (`score_scale`); the blinking INSERT CREDIT shows only in the attract demo (`hud.demo`) (ART-004 §8.6, 2026-11-18).
- `InputLabels` (`core/ui/input_labels.gd`) names bindings per device from the live `InputMap`; `is_accept()` adds a pad-A fallback (§11.1 Q-T19).
- `CabinetBootTuning` (`ds_cabinet.boot`, §3.4) holds all ✱ presentation timings.
- Cues `power_on`, `tape_peel`, `coin`: AUDIO-001 §11.7. Glyph "·" added to `PixelText` for the canon line.

Data: `data/cabinet/cabinet_tuning.tres` (`CabinetTuning`, `ds_cabinet.tuning.*`, every value cites SYS-001 or is ✱) and one `CabinetStage` per level (`stage_first_vigil.tres`, `stage_last_normal_day.tres`), inside SYS-001 §4's Seam 1 T0 budget.

Art: everything is code-drawn from `Pal` (`core/ui/pal.gd`, checked against the palette file by a test). Text uses the **Cabinet face**, a 5 × 7 bitmap drawn by `PixelText` (`core/ui/pixel_text.gd`, ART-001 §11) at integer scales only. There are no exceptions (D-13): the reveal's "true body" inside the maw is a richer generator (`MawView`), not a sprite.

Capture and test switches (after `--`): `--autopilot`, `--stage=N`, `--segments=N`, `--hits=N`, `--smoke-frames=N`, `--no-save` (SaveService keeps slots in memory). Example, film the reveal:
```
tools\godot\Godot_v4.7.2-stable_win64_console.exe --path . --write-movie out\f.png --fixed-fps 30 --quit-after 1500 -- --smoke --smoke-frames=99999 --autopilot --stage=1 --segments=20 --hits=2 --no-save
```

---

## 3. Data resources and `ds_` keys

### 3.1 Layout
`data/<feature>/<name>.tres` — loose `.tres` tunables, one `TunableResource` subclass each. The class script lives with its feature (`features/vigil/vigil_move_stats.gd`) or in `core/` when shared (`core/components/health_stats.gd`). Non-tunable data (route table, theme, bus layout) also lives in `data/` but is not a `TunableResource`.

Create a **Resource** when data is shared, tuned, or authored (stats, items, abilities, Sigils, kits, dialogue lines). Create a **scene** when it needs nodes, a transform, collision or a lifetime. Never put a game number in a script constant.

### 3.2 TunableRegistry
`core/data/tunable_registry.gd`. Not an autoload: `TunableRegistry.new().scan()` walks `res://data`, loads every `TunableResource`, and maps each `ds_` key → (resource, property). Gameplay uses the typed resource directly via `@export`; the registry exists for the lint, debug tooling and save validation.

### 3.3 Data lint
`core/data/tests/test_tunable_registry.gd` fails on: a namespace not starting `ds_`, a malformed key, a duplicate key, a missing required key, a non-positive movement value, `max_hp < 1`. The SYS-001 §10 ↔ key cross-check (every register row ↔ exactly one key) is **not** built: SYS-001 defines no `ds_` keys yet (§11 Q-T03).

### 3.4 Key convention
`ds_<feature>.<group>.<property>`, lower snake case, e.g. `ds_vigil.move.max_speed`. The `.tres` sets `ds_namespace` (`ds_vigil.move`) and `source_section` (the SYS-001 row it copies). Each property comment cites its SYS-001 row and lock state (🔒 / ⚙ / ✱). Sprite ids (`ds_<kit>_<part>…`, ART-002 §2) share the prefix but use underscores, never dots, so the two never collide.

| Key | Value source | Lock |
|---|---|---|
| `ds_vigil.move.max_speed`, `.accel` | SYS-001 §1.1 | 🔒 |
| `ds_vigil.move.drag`, `.brake`, `.snap_turn` | SYS-001 §1.1 | ⚙ |
| `ds_vigil.move.hitbox_circle_px` | SYS-001 §9 hitbox policy | 🔒 (reading open, §11 Q-T04) |
| `ds_vigil.hull.max_hp` | SYS-001 §1.2 Hull HP | 🔒 base 1; D-08 A/B by data edit |
| `ds_vigil.hull.invulnerable_after_hit_s` | no SYS-001 row; 0 | ✱ |
| `ds_arc_lance.{fire_rate_per_s, projectile_speed, visual_length_px, hits_per_projectile}` (`ArcLanceStats`, `data/arc_lance/arc_lance.tres`) | SYS-001 §1.3 | 🔒 fire rate base; others ⚙ |
| `ds_arc_lance.damage`, `.lifetime_s` | SYS-001 §1.3 (derived rows, approved by owner 2026-11-18) | ✱ |
| `ds_arc_lance.muzzle_offset_px` (10) | engineering-only, no SYS-001 row | ✱ |

**D-08 runtime API (M1 slice 1).** `Vigil.set_hull_max_hp(int)` / `get_hull_max_hp()` switch the hull at runtime; they call `HealthComponent.set_max_hp`, which duplicates the stats resource (the shared `.tres` is never mutated). Post-hit grace (R-11) applies only when `max_hp >= 2`.

**D-08 launch switch (M1 slice 2, part A).** `HullMode` (`features/vigil/hull_mode.gd`) reads `--hull=1|2` from the command line; an absent or invalid value falls back to the data value `ds_vigil.hull.max_hp` (1). `Vigil._ready` applies it through `apply_hull_override`. `HullMode` has its own small `--key=` parser because `CabinetGame._arg_int` is private to the Cabinet. A persisted setting is deferred: it needs a `SettingsService` `DEFAULTS` key and a settings-screen row with `tr()` keys.
| `ds_cabinet.boot.*` (`CabinetBootTuning`, `data/cabinet/cabinet_boot_tuning.tres`): `warmup_seconds`, `noise_seconds`, `noise_scroll`, `test_line_seconds`, `test_hold_seconds`, `page_seconds`, `tape_hint_delay`, `tape_hold_seconds`, `tape_drag_px`, `tape_fall_seconds`, `coin_drop_seconds` | presentation timings, no SYS-001 row (§11.1 Q-T18) | ✱ |

---

## 4. Gameplay runtime

Status for all of §4: **designed, not built** (except where a row says otherwise). This section is the contract the first gameplay features are built against.

### 4.1 The tick
The simulation is the 60 Hz physics tick (§1.2). Every gameplay state change happens in `_physics_process`; `_process` only draws. Order inside one tick is fixed by `process_physics_priority` ✱:

| Priority | Stage | Owner | Reads | Writes |
|---|---|---|---|---|
| −20 | Clock and run timers | `RunSession` (§4.2) | wall tick | Hourglass Clock, Seam timers |
| −10 | Intent | `VigilInput`, Choir brains | devices / AI state | intent fields only |
| 0 | Motors | `VigilMotor`, unit motors | intent, stats | velocity, position (`move_and_slide`) |
| 10 | Shots | `ShotSweeper` (§4.6) | shot pool | swept hits queued |
| 20 | Hit resolution | `HitboxComponent` / `HurtboxComponent` | overlaps + queued sweeps | health, `hit_landed` |
| 30 | Economy | `ShardField` (§4.3), Sepulchre | shard pool, deposits | shard positions, segment count |
| 40 | Director | `SpawnDirector` (§4.5), `WakingController` (§4.8) | budgets, phase | spawns, stand-downs, phase changes |
| 50 | Warp | `WarpComposer` (§5.1) | tier inputs (WARP-001 §1.3) | active effect set |
| 60 | HUD model | `HudModel` (§5.2) | everything above | the honest readout |

Rule: a stage may read anything earlier in the same tick and anything from the previous tick; it may not write state owned by another stage. Signals emitted inside a stage are handled by listeners in a later stage or deferred.

### 4.2 Where state lives

| State | Class (LOOP-001 §2) | Owner | Lifetime |
|---|---|---|---|
| Seam index, seed, Sigils, Relics, Pact, Charges, Composure, in-run currency | Run | `RunSession` autoload (**planned**, §2.8) holding a `RunState` resource | New Vigil → death / run clear |
| Hourglass Clock, sky count, Hunger, corruption map, telemetry counters | Iteration | `RunSession` → `IterationState` resource | Iteration start → Hard Unmaking |
| Lantern Tree, banked currency, Codex, endings, bests | Anchored | `SaveService` profile slot, loaded into a `ProfileState` resource at boot | forever |
| Per-sector actors, shards, Sepulchre, warp effects | none (rebuilt from seed) | `SectorHost` children | one sector |

Sector scenes never own run state; they receive a `RunState` reference in `on_route_entered(params)` and write back through its methods. That is why a crash costs at most one Seam (LOOP-001 §2).

### 4.3 Shard field and the magnet loop
Shards are the one place a naive implementation scans N×M per frame (the Vigil's magnet plus every Grub looking for glass). Design:

| Piece | Design |
|---|---|
| Representation | pooled `Node2D` shards with **no physics body**; position, velocity and owner state in a packed struct-of-arrays inside `ShardField` (`PackedVector2Array` positions/velocities, `PackedInt32Array` flags) |
| Spatial index | uniform grid, **64 px cells** (one module, ART-002 §1), rebuilt incrementally on move; the sector is ≤ 7 kits of 640×360 (ZONES-001 §1.1) |
| Vigil magnet | query the cells under a circle of `SYS-001 §1.4 Shard magnet radius` (96 px → a 4×4 cell window); pull within radius; **H4** (WARP-001 §3.2) flips the sign through one data flag, no second code path |
| Grub targeting | Grubs ask the grid for the nearest free shard in their cell window once per 6 ticks ✱, not every tick |
| Worst case | 24 geodes × 5 shards (SYS-001 §9 cap; GDD §8.2 3–5 shards) = 120 shards ✱ |
| Budget | ≤ 0.3 ms per tick at the worst case ✱ (§8.1); measured by `bench_shard_field` (§8.3) |
| Render | one `MultiMeshInstance2D` for all shards (one draw call) |

### 4.4 Freezing entities, never physics
The physics server is never paused for gameplay (§1.2 `physics_ticks_frozen = never`); `get_tree().paused` is used only by the pause screen.

| Freeze source | Mechanism | What keeps running |
|---|---|---|
| Anchor field (D-11, SYS-001 §1.1 `anchor_freeze`) | `FreezeComponent.freeze(duration, source_id)` on each unit inside the field (max units per cast from SYS-001 §1.1): disables the unit's brain and motor, zeroes velocity, mutes its chant emitter | its collision shapes (a frozen unit is an obstacle), its hurtbox (it can be killed), budget counting (SYS-001 §1.1 note) |
| Elites / Heralds | same, at half duration (SYS-001 §1.1) | — |
| Sepulchre, The Penitent | excluded by data flag `freezable = false` | everything |
| Pause screen | `SceneTree.paused` | Overlays (`PROCESS_MODE_ALWAYS`) only |
| Codex / cinematics | `RunSession.clock_paused` (Hourglass Clock stops, WARP-001 §6.1 D-01); gameplay is paused by the same tree pause | — |

The freeze timer is owned by the field that cast it, so a unit leaving and re-entering a field cannot double-freeze or extend itself.

### 4.5 SpawnDirector and budgets
One `SpawnDirector` per `SectorHost`. It owns the SYS-001 §4 threat budgets and the SYS-001 §9 on-screen caps (Choir units, geodes, contacts, shots, colliders). Spawns over a cap are queued at off-screen spawn markers (ZONES-001 §1.7 `SpawnMarkerLit/Unlit`). Over the contact cap, the furthest units *stand down* (hold position, keep chanting) rather than despawning, because a vanishing enemy reads as a bug. The Coma mercy (SYS-001 §8) is a SpawnDirector rule keyed on `seam_deaths`.

### 4.6 Pooling and the shot layer
Shots, shards, sparks and chalk flecks are pooled at the SYS-001 §9 ceilings (180 shots both sides). Each shot sweeps a `ShapeCast2D`-equivalent query from its previous to its current position every tick (`PhysicsDirectSpaceState2D.cast_motion` with a pooled circle shape), so nothing tunnels (§2.6). The `ShotSweeper` batches all shots in one stage. Escalation path if it misses budget: batch fewer queries per shot type → grid broad-phase shared with §4.3 → quadtree (GDD §13 owner decision 2026-11-17) → GDExtension only with a profile and a §11 decision.

### 4.7 Choir AI
A unit is a `CompositeRig` (§2.4) + motor + `Brain` component. A `Brain` runs a small state machine whose states are `Resource`s (`state_patrol.tres`, `state_procession.tres`…), so a variant is a data edit. Unit stats and AI budgets come from SYS-001 §3; faction laws (SYS-001 §3.1: shrine ceasefire radius, Acolyte turret lag, Litany Ring) are **asserted** by tests, never left to tuning. Brains tick at 60 Hz for movement and at 10 Hz ✱ for decisions.

### 4.8 WakingController
One per sector with a Sepulchre. Owns the Waking lifecycle phases 0–6 (GDD §8.4, SYS-001 §2), the 20 segment modules and the Unravel hit count. Emits `phase_changed(phase)`, `segment_deposited(index)`, `segment_knocked_off(index)`, `entity_awakened`, `entity_unmade` (EVT-001 rows to add with the code). AUDIO-001's state lines, the HUD and the WarpComposer listen; the controller never calls them. The 1.2 s pre-Awakening silence (GDD §12) is a `phase_changed` consumer in audio, budgeted twice per run by the audio side.

### 4.9 RunSeed, SeedCode and ReplayVerifier

| Piece | Design |
|---|---|
| `RunSeed` | a 55-bit integer. Every random draw goes through a **named stream** (`map`, `kits`, `slots`, `warp`, `loot`, `ai`, `vfx`): `stream_seed = hash64(run_seed, stream_name, seam_index)`, one `RandomNumberGenerator` per stream. Adding a roll to one stream never shifts another, so content patches break fewer seeds |
| Location (Q-T28) | `core/rng/`: `Hash64` (the hash below), `RunSeed` (minting, masking, stream seeds), `SeedCode` (encode/decode, checksum). Seeds feed many features (map, warp, loot, AI, generators), so the code is feature-agnostic; `features/run` keeps `RunSession`/`RunState`. Tests in `core/rng/tests/` |
| `hash64` (Q-T26) ✱ | `hash64(...parts) -> int`: the first 8 bytes of a **SHA-256** (Godot `HashingContext.HASH_SHA256`) read as a little-endian signed 64-bit int. The hashed bytes are a canonical encoding of the domain tag `"darkstar.rng.v1"` followed by each part in order. **int** part: byte `0x01`, then 8 bytes two's-complement little-endian. **String/StringName** part: byte `0x02`, then the UTF-8 byte length as uint32 little-endian, then the UTF-8 bytes (the domain tag is encoded as a String part). The type byte keeps `5` and `"5"` apart; the length prefix keeps `("ab","c")` and `("a","bc")` apart. SHA-256 avoids GDScript integer-overflow behaviour and is identical on every platform. Changing the encoding means bumping the domain tag (`v2`) |
| Seeds and `seam_index` (Q-T26) ✱ | `run_seed` is always masked to 55 bits: `hash64(...) & (2^55 - 1)` when derived (the daily), or 55 random bits from `Crypto.generate_random_bytes` for a fresh run. `stream_seed = hash64(run_seed, stream_name, seam_index)` with `stream_name` a String from the list above and `seam_index` an **int**: `0` for run-wide draws (the run's map, world tier, Hunger preset, registry state), `1`–`5` for Seam 1–5 (LOOP-001 §2). The `map` stream uses `0` for the run's map and `1`–`5` for each Seam's layout. `stream_seed` is the full 64-bit result, assigned to `RandomNumberGenerator.seed` |
| Determinism scope | world tier, Hunger preset and the WARP-001 §3.2 registry state derive from the seed alone (SYS-001 §10 🔒). Cosmetic `vfx` draws are seeded but excluded from verification |
| `SeedCode` | 12 characters of Crockford base32 (no I, L, O, U): 55 seed bits + 5 checksum bits = 60 bits. Displayed as `XXXX-XXXX-XXXX`. A mistyped code fails the checksum and the UI says so in plain words (L10N-001 `MSG_` key) |
| `SeedCode` layout (Q-T26) ✱ | value = `(run_seed << 5) \| crc5(run_seed)`, 60 bits, written as 12 symbols **most-significant first** (symbol 1 = bits 59–55, symbol 12 = bits 4–0, so the checksum is exactly the last symbol). Alphabet in value order: `0123456789ABCDEFGHJKMNPQRSTVWXYZ`. Decoding drops `-` and spaces, ignores case, reads `I`/`L` as `1` and `O` as `0`, and rejects `U`, any other character, or a length other than 12 |
| Checksum (Q-T27) ✱ | **CRC-5**, polynomial x⁵+x²+1 (`0x05`), init `0`, no reflection, no final XOR, over the **55 seed bits** fed most-significant first. Measured with a Node reference (2026-11-18): every single-symbol error caught (744,000 cases over 2,000 seeds) and every adjacent-symbol swap caught (53,271 cases over 5,000 seeds) |
| Test vectors ✱ | From the Node reference. `hash64(0, "map", 0)` = `0x85f332188ab71254` (−8794630566336589228); `hash64(0, "map", 1)` = `0x82901f696527c177`; `hash64(12345, "loot", 3)` = `0x6cf7f2d305eb1fd0` (7852011463495065552); `hash64("hollow_vigil", "2027-01-01", 1)` = `0xf0a6997056f29fa1`. SeedCodes: seed `0` → `0000-0000-0000`; `1` → `0000-0000-0015`; `12345` → `0000-0000-C1SK`; `2^55 - 1` → `ZZZZ-ZZZZ-ZZZ4`; daily `2027-01-01`, content version 1 → seed 10864756889132961 → `9MSE-1BF5-7X1P`. `core/rng/tests/` must assert these |
| Cursed seeds | community-shared SeedCodes (GDD §6.3). A SeedCode carries no content version; the game states which content version a seed was minted on if it differs |
| Daily (post-1.0, ruling R-16) | `run_seed = hash64("hollow_vigil", utc_date, content_version) & (2^55 - 1)`, `utc_date` a String `"YYYY-MM-DD"`, `content_version` an int; fixed world tier and Hunger preset; H14 never fires (WARP-001 §6.1 D-06) |
| Replay log | seed + content hash + per-tick quantised input: move vector (2 × int8), aim angle (uint16 of a turn), button bitfield (uint16). ≈ 6 bytes per tick ✱ → ≈ 21 KB per minute before compression ✱ |
| `ReplayVerifier` | re-simulates a log headless and compares a state hash (positions rounded to 1/8 px, health, segment count, clock) every 60 ticks. Used by tests and, later, to sanity-check daily scores |
| Honest limit | Godot 2D physics is not guaranteed bit-identical across CPUs and builds. Replays are verified **same build, same platform**. Leaderboards treat verification as a cheat filter, not proof |

---

## 5. UI and HUD

Menus, overlays, Theme, focus and input rules: UI-001 (built: attract, settings, pause, confirm). This section owns the in-run HUD and the warp renderer. Status: **designed, not built**, except §5.3's setting and pause gate.

### 5.1 WarpComposer
One per sector. Single owner of which canvas-item shaders are active.

| Piece | Design |
|---|---|
| Inputs | the tier computation of WARP-001 §1.3 (iteration, sector consumed, Composure, Entropy) via `RunSession` |
| `WarpEffect` resource | `id` (W-code from WARP-001 §2), `tier`, `layer` (`world`, `units`, `hud`, `post`), `shader`, `params`, `t0_fallback` (ART-001 §7), `photosensitive_variant`, `reduced_motion_variant`, `cost_ms` (measured, §8.5), `clip_readable` (GDD §8.7 criterion 1, a review checkbox) |
| Layers | world and unit layers use per-`CanvasItem` materials; one `BackBufferCopy` + full-screen post pass at most ✱; the HUD layer has its own material so HUD warp never touches the world |
| Budget | sum of active `cost_ms` ≤ SYS-001 §9's 1.2 ms on min spec; over budget, the composer drops effects in WARP-001 §5.3's refusal ladder order and logs it (dev only) |
| Novelty cap | ≤ 3 novel effects per sector (GDD §16 R-02), enforced here |
| Determinism | effect start times come from the `warp` stream (§4.9) |
| Accessibility | photosensitivity swaps every flicker/strobe parameter for its static variant and **never** removes information (GDD §10); reduced motion swaps motion variants; both are read from `SettingsService` live |

### 5.2 DiegeticHud
Built as **model → filter → view**, so honesty is the default path and a lie is an explicit filter:

| Stage | Class | Rule |
|---|---|---|
| Model | `HudModel` | the truth from §4 state, every tick. No warp code may write to it |
| Filter | `HudLiar` | applies WARP-001 §4.2 deviation classes (Lie, Smear, Glyph, Move, Absence) with exactly one tell family per lie, the per-sector lie budget by tier (T5 = 0) and the §4.2 laws L1–L8. Elements on WARP-001 §4.7's never-lie list are typed `HonestOnly`; the filter refuses them by assertion, and a lint test walks the element table |
| View | `HudView` | 64×64-module art (GDD §10), anchored inside the 200 % safe area (SYS-001 §9) |

Eaten elements (WARP-001 §4.3) are an `Absence` with the chalk frame still drawn.

### 5.3 SteadyLedger
`SettingsService` key `steady_ledger`, default **on** (WARP-001 §4.4) — **built**. With it on, `HudLiar` is bypassed for every category WARP-001 §4.4 lists; the Migrating HUD is disabled; the Hourglass vignette becomes a numeric run clock; glyph corruption is off. The **pause gate** is built: the `pause` action opens the real pause screen whenever the overlay stack is empty (`scenes/sector/sector_stub.gd`); future warp effects that eat the pause menu (W4-07) must check `steady_ledger` and stand down, enforced by a test when they are written.

### 5.4 Ledger Compass redraw
The compass draws the sector list, corruption state and up to 8 markers ✱. Static layers (sector cells, corruption bruise) redraw into a cached texture only when the macro map changes or at most 10 Hz ✱; markers are drawn per frame by one small `_draw` Control. Lies and H16 are applied in `HudModel`/`HudLiar`, never in the drawing code. Budget ≤ 0.2 ms per frame ✱ (§8.1).

### 5.5 Rendering ladder (ART-001 §15)
Fidelity grows with the warp; the WarpComposer owns the switches.

| Stage | Enabled | Owner |
|---|---|---|
| T0 / Act 0 | flat colour through `Look.c()` (Neon Cabinet palette), CRT post | `features/cabinet` (built) |
| THE PRETENCE | `Look.t` 0 → 1: every cabinet colour morphs neon → Aether | `PretenceReveal` (built) |
| T1+ | **the Aether** (ART-001 §16): layered aether-fog shader fields with colour and currents, the crystal-sphere parallax, ambient aether-life particles; `PointLight2D` lantern (key light) + `LightOccluder2D` shadows; soft particles (`GPUParticles2D`, generated textures) | WarpComposer (planned); the reveal's first aether fog is built (`shaders/aether_fog.gdshader`) |
| T2+ | emitter lights (Shroud, glass, veins), 2D HDR glow/bloom, dense particle systems, Shroud field shader | WarpComposer (planned) |
| T3+ | volumetric fog and god-rays, distortion/lensing, normal-mapped generated bodies | WarpComposer (planned) |

Forward+ (§1.1) supports 2D lights, shadows and HDR 2D. Every rung has a cost line in §8.1; on min spec the composer drops the costliest rung first, never a readability rule (ART-001 §15.1).

---

## 6. Asset consumption

> **D-13 / D-14 (2026-11-18): the game loads no image or audio files.** Every visual comes from a generator (ART-001 §14) and every sound from synthesis (AUDIO-001 §11). §6.1–§6.4 below describe the retired raster pipeline and remain only as reference. The current rule is §6.5.

Producer side: ASSET-003. This section is what the engine does with the output.

### 6.1 Inputs
(Retired raster inputs, now local-only and Godot-ignored:) `assets/sprites/SPRITE_MANIFEST.csv` (schema: ASSET-003), PNGs under `assets/sprites/generated/<kit>/`, atlases under `assets/sprites/atlas/`, `assets/palettes/darkstar_palette.json`. The manifest CSV is imported with importer **`keep`** (ruling R-19): Godot otherwise treats any CSV as a translation table. Fixed 2026-11-17 in `SPRITE_MANIFEST.csv.import`.

### 6.2 Consumer-side lints (planned as tests in `tests/assets/`)
Naming (ART-002 §2 grammar), palette (every row's colours ⊆ its kit's `kit_locks`, ≤ 10 colours, GASLIGHT only on the three ruling R-06 parts), existence (every `generated` row has a file), size (module multiples of 64 or the row's declared w×h). A lint failure fails the test suite; it never silently substitutes art.

### 6.3 ManifestImporter and AtlasTable (retired, D-13)
`core/assets/manifest_importer.gd` (planned), run headless (`-s`) as the `manifest_import` build step (§1.4). It strips the UTF-8 BOM the generator writes, merges `assets/sprites/SPRITE_MANIFEST_HAND.csv` (hand-authored rows the generator must never overwrite, ASSET-003), and fails on a duplicate id. Atlas sidecar JSON format: ASSET-003 §6.2. It reads the manifest and atlas JSON and writes `generated/sprite_table.gd`: a `const` dictionary `id → {atlas, region, pivot, sockets, frames}` (`AtlasTable`). Runtime code addresses sprites by manifest id only. A missing id in a dev build draws a VOID-5/BONE-5 checkerboard module and logs an error; in a release build the lint above has already failed the build.

### 6.5 Generators (current)
- **Visuals (build time):** pxl renders from `art/src/*.px.js` in `assets/art/generated/` (PNG, sheets, `SpriteFrames` `.tres`), on the palette (D-13 amended, ART-001 §14.8). They load as ordinary textures and swap between tiers.
- **Visuals:** generator classes draw through `CanvasItem` or shaders, with colours from `Pal` (`core/ui/pal.gd`) and text from `PixelText`. A generator is deterministic from its parameters and seed; the WarpComposer (§5.1) feeds it `tier` and `horror`.
- **Sound:** `AudioService` plays the chirp render of each cue (`res://assets/audio/generated/sfx/<id>.wav`, built from `audio/src/*.cx.js`, D-14 amended) and falls back to streams built by `SfxSynth` at load; long stems and beds render on a worker thread; reactive textures use `AudioStreamGenerator` (AUDIO-001 §11.5).
- **Enforcement:** `tests/test_generated_assets_only.gd` fails if any scene, script or resource under `features/`, `scenes/`, `core/`, `autoload/` or `data/` references a font, an image outside `assets/art/generated/`, or an audio file outside `assets/audio/generated/`; if any render has no matching `.px.js`/`.cx.js` source; if a pxl source does not include a project palette; or if a source uses pxl `image()` or chirp `sample()`.

### 6.4 CompositeRig consumption
`CompositeRig` (§2.4) reads part descriptors (ART-002 §5.1) and instantiates the part generators they name (§6.5); runtime mutation (ART-002 §5.3, the warp's limb swaps) swaps atlas regions on existing `Sprite2D` nodes, never instantiates nodes per frame.

## 7. Save system

### 7.1 SaveEnvelope
`core/save/save_envelope.gd`. A JSON object: `format`, `schema_version`, `slot`, `game_version`, `written_unix`, `checksum` (SHA-256 of the canonical payload), `payload`. Load statuses: `OK`, `MISSING`, `CORRUPT`, `CHECKSUM_MISMATCH`, `NEWER_VERSION`, `WRONG_SLOT`.

### 7.2 Slots and cadence

| Slot | Persistence class (LOOP-001 §2) | Allowed save reasons | Status |
|---|---|---|---|
| `profile` | Anchored | `ruins_entry`, `tree_purchase`, `iteration_end`, `cabinet_score` (Act 0 high score / game over), `cabinet_tape` (coin-slot hazard tape removed; written in attract, never mid-run) | built: Act 0 writes `cabinet_hi_score`, `act0_complete`, `pretence_seen`, `cabinet_tape_peeled` |
| `iteration` | Iteration | `ruins_entry`, `iteration_end`, `new_iteration` | interface built |
| `run` | Run | `seam_boundary` only (never mid-run, SYS-001 §8) | interface built |

Profile flags for endings, Archivist variant and achievements are LOOP-001 §11.7 (invariant IDs). `act0_clean_hands` is evaluated **per Act 0 playthrough** (a replay from the Cabinet starts a fresh evaluation) and only ever sets the profile flag true.

`SaveService.save_slot(slot, payload, reason)` refuses any other reason with `save_failed(slot, &"not_allowed_now")`. Payloads hold invariant IDs and numbers only, never display text. No gameplay writes any slot yet.

### 7.3 Storage, recovery, migration
`FileSaveBackend` writes `user://saves/<slot>.json` via `.tmp` then rename, keeping the previous file as `.bak`. A corrupt or tampered main copy loads from `.bak` (`recovered = true`). A newer schema is refused and never overwritten. Migration: bump `SCHEMA_VERSION`, add one step in `SaveEnvelope.migrate`, never edit a shipped step. `MemorySaveBackend` is for tests. Steam Cloud is a future backend; not built.

Device settings live in `user://settings.cfg` (`SettingsService`), not in a save slot (ruling R-05, §11.1a).

**Demo → full game (MARKET-001 §6, PROD-001 M4):** the demo build writes the same slots with the same `SaveEnvelope` schema and an extra payload field `content_scope = "demo"`. The full game reads demo saves through the normal migration path, clears `content_scope`, and keeps every anchored unlock earned in the demo. A demo build refuses a save whose `content_scope` is absent (a full-game save) instead of overwriting it, and says so in plain words. Both builds use the same Steam app data folder only if the demo is a Steam playable-demo branch of the same app (TECH-001 §1.4); otherwise the full game offers a one-time import from the demo folder.

Player-facing failure text: `PlayerMessages.save_message(reason)` → `MSG_SAVE_*` keys. Codes and paths never reach the screen; details go to `push_warning` only.

Troubleshooting: delete `%APPDATA%\Godot\app_userdata\DARKSTAR\saves\` to reset; a `.bak` next to a slot is the previous good copy.

## 8. Budgets

**Nothing in this section has been measured.** Every number below is a target ✱ or a SYS-001 citation. Measurements go in §8.5 with a date, build and machine, or they do not exist.

### 8.1 FrameBudget
Target from GDD §15: median frame ≤ 8 ms at T2 and ≤ 14 ms at T5 on minimum spec (GDD §13: a 2016-class laptop iGPU for T0–T2; a GTX 1060-class GPU for T3–T5). The 8 ms T2 split ✱:

| Subsystem | Budget (ms) | Source |
|---|---|---|
| Gameplay GDScript (motors, director, Waking, economy) | 2.0 | ✱ |
| Choir AI decisions | 0.8 | ✱ (§4.7, 10 Hz decisions) |
| Shot sweeps + hit resolution | 0.8 | ✱ (§4.6, at SYS-001 §9's 180 shots) |
| Shard field (§4.3) | 0.3 | ✱ |
| Warp effects | 1.2 | **SYS-001 §9** 🔒 |
| Other rendering (sprites, MultiMesh, particles) | 1.9 | ✱ |
| HUD + Ledger Compass (§5.2, §5.4) | 0.5 | ✱ |
| Slack | 0.5 | ✱ |
| **Total** | **8.0** | GDD §15 |

At T5 the 14 ms allowance is spent on warp and post passes; gameplay lines keep their T2 budgets.

### 8.2 ContactBudget
The runtime counter for SYS-001 §9's caps (on-screen Choir units, entity modules, geodes, simultaneous hostile contacts, active shots, colliders per sector). Owned by `SpawnDirector` (§4.5). Over-cap behaviour: queue off-screen (spawns), stand down (contacts), refuse the Sigil shot multiplier past the shot cap (LOOP-001 §4.3 ceiling lint). Each cap gets a test that drives a bench scene to the cap and asserts the behaviour.

### 8.3 Measurement method
- Custom monitors: `Performance.add_custom_monitor("darkstar/<subsystem>_ms", …)` around each §8.1 row, visible in the editor debugger and dumped headless.
- Bench scenes: `tests/perf/bench_<subsystem>.tscn` drive each subsystem to its SYS-001 §9 cap for 60 s with a fixed seed and write p50/p95/p99 frame and subsystem times to `reports/perf/<date>_<build>.json`.
- Machines: a named minimum-spec machine per GDD §13 tier and a Steam Deck (GDD R-06, PROD-001 M3 gate). Results are only quoted with the machine named.
- A regression > 10 % ✱ on any p95 subsystem time against the last recorded run fails the perf job (CI, PROD-001).

### 8.4 GDScript hot spots and the escalation ladder
The two designed hot spots are the shard field (§4.3) and the Ledger Compass (§5.4); the third candidate is the shot layer (§4.6). The ladder for any miss, in order: fix the data structure (grids, packed arrays) → reduce frequency (decision ticks, cached layers) → batch rendering (MultiMesh) → move per-pixel work to a shader → GDExtension, only with a profile attached and a §11.2 decision.

### 8.5 Measurement log
| Date | Build | Machine | Bench | Result |
|---|---|---|---|---|
| — | — | — | — | no measurement has been taken yet |

## 9. Automated tests

Framework: **GdUnit4 v6.2.3** vendored in `addons/gdUnit4` (owner decision 2026-11-17). Tests live in `<area>/tests/test_*.gd` next to the code (`core/**/tests`, `features/<f>/tests`, `scenes/tests`) plus cross-cutting suites in `tests/`. Helpers: `tests/support/` (e.g. `FakeRouteHost`, which lets UI tests trigger routing without replacing the runner scene).

```
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a core -a features -a scenes -a tests --ignoreHeadlessMode -c
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 600 -- --smoke
```
The smoke run prints `BOOT_SMOKE: reached route 'sector'` and exits 0. GdUnit writes HTML/XML reports to `reports/` (generated, not source).

| Suite | Covers |
|---|---|
| `core/components/tests/test_health_component.gd` | damage, depletion, D-08 1 vs 2 HP, one-hit-per-window, invulnerability expiry, heal clamp |
| `core/components/tests/test_hitbox_component.gd` | closed windows, repeated overlap = one hit, acceptance reporting |
| `core/save/tests/test_save_service.gd` | round trip, cadence refusal, unknown slot, missing, corrupt→backup, tamper, newer schema, wrong slot, write failure, file atomicity, player text for every reason |
| `core/data/tests/test_tunable_registry.gd` | data lint (§3.3) |
| `core/i18n/tests/test_localization.gd` | missing/unused keys, placeholders, English fallback, plurals, English number format, glyph coverage |
| `core/ui/tests/test_theme_palette.gd` | theme and scene colours ⊆ palette, text-scale application |
| `features/vigil/tests/test_vigil_motor.gd` | speed cap, drag, brake, 30/60/144 Hz independence, full reversal 0.28 s, turn rate, ±π wrap |
| `features/arc_lance/tests/test_arc_lance.gd` | Arc-Lance stats, projectile, emitter (M1 slice 1) |
| `features/vigil/tests/test_vigil_hull.gd` | D-08 runtime hull switch (`set_hull_max_hp`), grace only at max_hp >= 2 |
| `features/vigil/tests/test_hull_mode.gd` | `HullMode` `--hull=1\|2` parsing, invalid/absent falls back to data value, `apply_hull_override` on Vigil (M1 slice 2A; passes (139 cases, 0 failures, 2026-11-18)) |
| `features/vigil/tests/test_vigil_collision.gd` | data-driven radius, wall stop, no tunnelling at 6000 px/s, overlap recovery, live hitbox one hit per window → breach → HUD |
| `scenes/tests/test_attract_mode.gd` | default focus, focus loop/wrap, settings modal + ui_cancel + focus restore, root ui_cancel no-op, repeated input, 200 % text safe area (menu + settings), no raw keys |
| `scenes/tests/test_attract_coin_slot.gd` | 16 tests: tape prompt delay, peel by hold / drag / pad A, press off the tape ignored, tape flag saved, coin → credit → New Vigil spends once, no New Vigil without a credit, tape stays off, no demo while credited, power-on start / skip / self-finish, route without `power_on`, page cycle, binding labels |
| `scenes/tests/test_sector_and_pause.gd` | spawn at anchor, HUD text, pause action, ui_cancel/pause resume, confirm defaults to the safe choice, abandon routes + unpauses, three-deep modal unwind |
| `tests/test_boot_flow.gd` | route table loads, unknown route fails safely, input-mode switching, accessibility defaults |
| `features/cabinet/tests/test_cabinet_rules.gd` | torus maths, extra Vigils, calm mining vs over-fire, glass → Charges with overflow, Charge homing + module knock-off + interception, Grub deposits → segments, Cold Sepulchre never wakes, Awakening silence → line → rampage, contact death, lance cannot bite the entity, 13 Charges unmake for 15,000, censer lag 0.25 s, **autopilot clears A0-1 end to end** |
| `tests/test_input_map.gd` | every GDD §4.1 key/mouse binding and GDD §4.3 pad binding (ruling R-12); no two gameplay actions share a key |

Result on 2026-11-18 (attract boot / coin slot): 118 test cases, 0 failures, 0 errors; boot smoke (`-- --smoke --no-save`, attract → cabinet) exit 0 with no `ERROR`/`WARNING` lines. Not verified: real gamepad hardware, real mouse-drag feel, audio by ear.

Not covered (honest list): native-resolution rendering after Act 0 (decided, not implemented, D-A), window sizes other than the 640×360 logical viewport, real integer scaling at 1080p/1440p, gamepad glyphs (none exist), shaders, audio, Steam, performance. Slopes, stairs, doors and moving platforms are N/A (§2.6).

## 10. Import conventions
**D-13:** no raster imports feed the game. The reference PNGs under `assets/sprites/` are local-only reference: kept on disk, **not in git** (`.gitignore`) and **ignored by Godot** (`assets/sprites/.gdignore`), so they are never imported, exported or pushed. Only `SPRITE_MANIFEST.csv` is tracked, as the inventory of parts to build (owner decision 2026-11-18). Exports must still exclude `tools/**` (set in the export preset when it is created). Historical, for the reference PNGs only: per ART-002 §7, canvas default filter Nearest (set in `project.godot`); pixel atlases import with `compress/mode = Lossless`, mipmaps off, `fix_alpha_border = true`. Every `.csv` under `assets/` imports as `keep` (ruling R-19), never as a translation; PNG import flags per ASSET-003. ART-002 §7 mentions a `godot/DarkStar/` path; the project root is the repo root (TASK-BOOT Q4), so that path is obsolete — §11 Q-T08. No import preset file is committed yet. `docs/`, `tools/`, `research/` and `Claude outputs/` carry `.gdignore`.

## 11. Open questions and decision log

### 11.1 Open questions

| # | Question | Found in | Proposed |
|---|---|---|---|
| Q-T15 | SYS-001 §1.4 `hits_needed = 13 - 3 + ceil(segments/7)` gives 10 at 0 segments, but its own note says "3 at 0 segments". The cabinet sidesteps it (the entity is only hittable once complete, 13 hits) | SYS-001 §1.4 | design rewrites the formula or its note |
| Q-T16 | SYS-001 §2 phase 3 says "Compass starts lying" at Quickening; WARP-001 W0-02 says the Act 0 HUD is always honest (T0 lie budget 0). The cabinet keeps the compass honest (WARP-001 owns HUD lies) | SYS-001 §2, WARP-001 §2.1 | SYS-001 scopes the lie to T ≥ 3 |
| Q-T17 | Cabinet ✱ values with no SYS-001 row: lives at start (3), respawn delay and shield (2 s each), lance range (0.9 s life; lance lifetime now also lives in `data/arc_lance/arc_lance.tres`, SYS-001 §1.3 row awaiting approval), Grub seek speed (160 px/s) and flee radius (110 px), Acolyte engagement range (300 px) and shot life (2.2 s), Charge life (6 s), entity costume radius/contact inset/turn rate | `data/cabinet/cabinet_tuning.tres`, `sepulchre_ritual.gd` | add an Act 0 table to SYS-001 |
| Q-T18 | `CabinetBootTuning` ✱ values (`ds_cabinet.boot.*`: warm-up, noise, scroll speed, self-test line/hold, card time, tape hint delay, tape hold, tape drag distance, tape fall, coin drop) have no SYS-001 rows (2026-11-18) | `data/cabinet/cabinet_boot_tuning.tres` | add presentation-timing rows to SYS-001 or keep as ✱ |
| Q-T19 | Godot's built-in `ui_accept` has **no gamepad binding** here (`InputMap.action_get_events(&"ui_accept")` lists only Enter, Kp Enter, Space). `CoinSlot` accepts `JOY_BUTTON_A` explicitly via `InputLabels.is_accept()`, but ordinary menu Buttons may not respond to pad A: D-01 gamepad parity gap. Not fixed (2026-11-18) | `tests/test_input_map.gd` owns the input map | owner decides whether to add a pad event to `ui_accept` |
| Q-T20 | The Act 0 bezel side panels and coin door are a placeholder mockup (owner: "a quick mockup is fine", 2026-11-18); detailed bezel design is still to be written | `features/cabinet/cabinet_bezel.gd` | ART-001 gets a bezel design section |
| Q-T21 | NARR-001's ending has the credits peel "HUD, bezel, scanlines, the Cabinet's marquee", but the bezel leaves the frame for good after the Act 0 zoom-in (D-B). GDD §9 ending 4 ("the retro arcade shell being peeled away") and the GDD §8.7 T4 row ("the arcade shell slips") lean on the same image | NARR-001 ending; GDD §9, §8.7 | bookend return to the cabinet, or rewrite the beats |
| Q-T22 | Are pxl raster renders used after Act 0? | ART-001 §14.8 | Act 0 only; Aether art stays runtime vector/shader |
| Q-T23 | `PixelText` scales by integers only; native resolutions are not integer multiples of 360 | ART-001 §11, R-02 | pixel faces for the cabinet; scalable rendering of the chalk faces after Act 0 |
| Q-T24 | SYS-001 §9 frame budget was never measured at native resolution; fog/post buffers likely need a fractional render scale and quality presets | SYS-001 §9 | measure at 1080p/1440p/4K before locking |
| Q-T25 | Post-Act 0 camera scale / visible world area is a design number not yet set | D-A | design to set; no value invented |
| Q-T29 | Detonation shard count conflict: GDD §8.2 (~line 208) says 3-5; SYS-001 §1.3 row 74 says 3-5 but row 76 says 4-6; the Cabinet code uses 4-6. Also no SYS-001 row for magnet pull speed (170 px/s) or shard drag (1.2/s), both currently ✱ in code (2026-11-18) | GDD §8.2; SYS-001 §1.3 | owner ruling on 3-5 vs 4-6; add rows or keep ✱ |

### 11.1a Resolved questions

Rows R-01…R-19 are the owner-delegated rulings of 2026-11-17; later rows carry their own date. The owner delegated every open ruling to the 2026-11-17 authoring pass. Each ruling is reversible by the owner; reversing one means editing the cited rows, not this table alone.

| # | Question | Ruling | Applied in |
|---|---|---|---|
| Q-T01 | 512×288 fallback still listed | **R-01:** 640×360 only. *Superseded for post-Act 0 by D-A (owner, 2026-11-18, §11.2): 640×360 binds the Act 0 screen only* | GDD §2, SYS-001 §9 |
| Q-T02 | No font spec; ART-001 §9 mis-cited | **R-02:** three bitmap faces (Ledger, Litany, Cabinet), 200 % = exact ×2, English coverage only (CJK plan dropped 2026-11-17) | ART-001 §11 |
| Q-T03 | SYS-001 has no `ds_` keys | **R-03:** §3.4 here is the key registry; SYS tables gain a `ds_` column as each is next touched | §3.4 |
| Q-T04 | 12 px hitbox: diameter or radius | **R-04:** diameter (6 px radius) — matches the code | SYS-001 §9 |
| Q-T05 | Where accessibility settings persist | **R-05:** device-level `settings.cfg`, loaded before any profile; "save-scoped" = never reset by a run or Iteration | LOOP-001 §2, §7.3 here |
| Q-T06 | GASLIGHT on three Choir parts | **R-06:** canon — salvaged Lampkeeper lanterns; GAS-5 never on Choir/entity | ART-001 §4, NARR-001 |
| Q-T07 | anchors cited as ZONES §1.6 | fixed: §1.7 | CLAUDE.md, §0.1 |
| Q-T08 | ART-002 §7 `godot/DarkStar/` path | **R-08:** repo root; presets here §10 | ART-002 §7 |
| Q-T09 | UI-state colours | **R-09:** focus GAS-3 (the cursor is the player's lamp), pressed GAS-2 keyline, errors BONE-5 + chalk-strike icon (never SIGNAL), reassurance PHOS-4 | ART-001 §12, `data/ui/darkstar_theme.tres`, UI-001 §5 |
| Q-T10 | entity 16 px inset vs §9 1 px inset | **R-10:** the entity is the one exception | SYS-001 §9 |
| Q-T11 | no post-hit invulnerability value | **R-11:** 0.75 s ✱, only matters at Hull HP ≥ 2 | SYS-001 §1.2, `data/vigil/vigil_hull.tres` |
| Q-T12 | ✱ gamepad bindings | **R-12:** GDD §4.3 exactly (A Surgelight, LSB brake, X lantern, B ward, Y unravel, LT charge, RT lance); full GDD §4.1 action set added | `project.godot`, `tests/test_input_map.gd` |
| Q-T13 | Seam vs sector | **R-13:** both canon (ZONES-001 §1.1–§1.2); GDD §19 adds *sector* | GDD §19 |
| Q-T14 | on-screen caps had no SYS-001 source | **R-14:** six ✱ cap rows added to SYS-001 §9 | SYS-001 §9, §1.5, §8.2 here |
| — | GDD §9.6 and WARP "GDD-001 §1.9" citations | **R-15:** → GDD §8.5 + AUDIO-001 §4.11; → GDD §10 | GDD §6.3, WARP-001 §5 |
| — | GDD §20 open questions | **R-16:** closed by WARP-001 §6.1; daily Hollow Vigil ships in the first free update, seed contract at 1.0 | GDD §20, §4.9 here |
| — | GDD §13 quadtree | **R-17:** Area2D/ShapeCast first | GDD §13, §4.6 here |
| — | Price and hull A/B | **R-18:** D-07 stays Proposed ($19.99), D-08 stays Open | GDD §18 |
| — | Manifest CSV imported as a translation | **R-19:** import as `keep` | §6.1, ASSET-003 |
| Q-T26 | `hash64` encoding, SeedCode byte/symbol order and `seam_index` type unspecified | SHA-256 over a tagged canonical encoding, first 8 bytes LE; SeedCode MSB-first symbols with the checksum last; `seam_index` int, 0 = run-wide, 1–5 = Seams (owner, 2026-11-18) | §4.9 |
| Q-T27 | 5-bit SeedCode checksum unspecified | CRC-5, poly `0x05`, init 0, over the 55 seed bits MSB first (owner, 2026-11-18) | §4.9 |
| Q-T28 | No `core/` subfolder for `RunSeed`/`SeedCode` | new `core/rng/` (owner, 2026-11-18) | §2, §4.9, CLAUDE.md §2 |

### 11.2 Decision log
| Date | Decision | By |
|---|---|---|
| 2026-11-17 | Adopt TASK-BOOT Q1–Q6 recommendations: Area2D/ShapeCast before a quadtree; Forward+; no `networking/` folder; `project.godot` at repo root; GdUnit4; data-switchable hull | owner |
| 2026-11-17 | The brief's `docs/ARCHITECTURE.md`, `SCENE_TREE_RULES.md`, `RESOURCES.md`, `SAVE_SYSTEM.md` are sections of this doc (§2, §3, §7); `AI_INSTRUCTIONS.md` is `CLAUDE.md` (TASK-BOOT §2) | owner |
| 2026-11-17 | GdUnit4 v6.2.3 vendored into `addons/gdUnit4` | owner |
| 2026-11-17 | Route scenes mount under Boot's `RouteHost` (not `change_scene_to_*`) so the curtain persists and UI tests can use a fake host | production |
| 2026-11-17 | §1.1 multiplayer citation corrected from D-11 to D-09 | production |
| 2026-11-17 | Doc review: fixed 13 mechanical citation/status errors across TECH-001, SYS-001, LOOP-001, ZONES-001, WARP-001, AUDIO-001, NARR-001, UI-001, EVT-001, TASK-BOOT; removed unsourced on-screen cap numbers from §0.3/§1.5/§2.6 (Q-T14). WARP-001 §6.1 decision IDs kept (its §9.2 freezes the `WARP-001 §6.1 D-nn` citation form); ambiguous bare uses now say §6.1 | production |
| 2026-11-17 | Owner-delegated authoring pass: rulings R-01…R-19 (§11.1a); §4–§6 and §8 designed; `RunSession` and `AudioService` autoloads approved as planned; full GDD §4.1/§4.3 input map | owner (delegated) |
| 2026-11-18 | M1 slice 1: `features/arc_lance` built with `Area2D` overlap hits (no ShapeCast); runtime D-08 hull switch `Vigil.set_hull_max_hp` / `HealthComponent.set_max_hp` (§3.4); SYS-001 §1.3 gets damage 1, lifetime 0.9 s, range 306 px as ✱ rows, approved by owner 2026-11-18 | owner (via session) |
| 2026-11-18 | M1 slice 2 part A: D-08 hull A/B is switchable at launch with `--hull=1\|2` (`HullMode`, §3.4); invalid/absent keeps the data value. Persisted setting deferred (needs `SettingsService` key + settings row). Part B (seeded RNG) blocked on Q-T26..Q-T28; shard-count conflict logged as Q-T29 | production (via session) |
| 2026-11-17 | **English only.** All non-English plans removed: per-locale number tables, the language setting and picker, pseudo-translation and right-to-left tests, the CJK font plan, translator workflow and vendor milestones. `tr()` keys and `en.po` stay so player text remains testable and a language can be added later (L10N-001 §7) | owner |
| 2026-11-18 | Act 0 built as the Cabinet feature (§2.10): own torus simulation without Godot physics bodies; vector costume art from `Pal`; 5×7 Cabinet face via `PixelText`; `AudioService` built with synthesised placeholder cues; profile save reason `cabinet_score`; `--no-save` switch; New Vigil now routes to `cabinet` | production |
| 2026-11-18 | Arcade boot-up and attract (§2.10): a first-attract-of-launch power-on self-test (`PowerOnTest`), four instruction cards (`AttractPages`), and a hazard-taped coin slot (`CoinSlot`) on the Act 0 bezel; New Vigil is greyed and out of the focus loop until one credit is in (one credit max, New Vigil spends it). Tape removal is saved forever (`cabinet_tape_peeled`, save reason `cabinet_tape`, `profile` slot). Bezel and coin-door art is a placeholder mockup. **GDD §10 "3 clicks max" still holds:** first launch = drag tape + click slot + New Vigil (3 actions); later launches = slot + New Vigil (2). The power-on test is skippable by any key/click and is not an action | owner (request in session) |
| 2026-11-18 | **D-A (resolution):** 640×360 pixel-perfect, integer-scaled, nearest-filtered applies only to the Act 0 arcade screen; the bezel and everything after Act 0 render at native resolution. ✱ proposed, not owner-approved: keep 640×360 as the logical space, switch to `canvas_items` stretch with snapping off after the zoom-in. Decided, not implemented; open items Q-T23..Q-T25 | owner |
| 2026-11-18 | **D-B (bezel):** the cabinet bezel is a real-world object at native resolution, full-colour printed cabinet art, not bound by the Neon Cabinet palette or screen role laws; generated in code (D-13); instruction text via `tr()`. At the end of Act 0 the camera zooms in to the screen and the bezel leaves the frame permanently (replaces the ART-001 §12.7 seam peel; reduced motion = 1-frame cut). Open: Q-T21 | owner |
| 2026-11-18 | **D-C (UI after Act 0):** modern game-UI structure and UX (hierarchy, primary/secondary actions, focus, input glyphs, Returnal-style list/preview/detail) with chalk-and-brass as the skin; ART-001 §12 stays valid as the skin | owner |
| 2026-11-18 | **D-B amended (the zoom):** the zoom-in carries the destruction: as the camera pushes in, the bezel peels, cracks, decays and warps out of frame. It is the game's main hook and must be a show-stopper; highest presentation bar (ART-001 §12.7, ART-004 §7.1). Decided, not implemented | owner |
| 2026-11-18 | **D-D (visual benchmarks):** AAA comparison set for visual-quality reviews: Returnal, Saros (Housemarque) and Ball x Pit (top-down camera/genre and density-readability benchmark, not a budget comparison) | owner |
| 2026-11-18 | **D-13 / D-14 (user directive): all graphics generated at runtime (vector or shader), all sound generated by code.** Raster pipeline (manifest import, atlases, sprite imports) retired; PNGs under `assets/sprites/` become reference only and are excluded from export; `tests/test_generated_assets_only.gd` enforces it; the reveal's PNG replaced by a generated body; `AudioService` cues are the design, not placeholders | user |
| 2026-11-18 | Reference sprites (`assets/sprites/`, 83 PNGs) untracked from git and Godot-ignored (`.gdignore`): kept locally as the look generators reproduce, never pushed, never imported or exported. Only `SPRITE_MANIFEST.csv` stays tracked | owner |
| 2026-11-18 | **D-14 amended (user directive):** chirp (uilianks/chirp, MIT) installed as a project Claude Code skill in `.claude/skills/chirp-game-audio/` (git-ignored); `audio/src/*.cx.js` → `assets/audio/generated/` WAV renders, committed; `AudioService` prefers renders, falls back to `SfxSynth`; asset test rewritten for the amended rule | user |
| 2026-11-18 | **D-13 amended (user directive):** pxl (uilianks/pxl, MIT) installed as a project Claude Code skill in `.claude/skills/pxl/` (git-ignored); `art/src/*.px.js` (with the shared palette include) → `assets/art/generated/`, committed; renders must stay on the 32-colour palette (test checks every pixel); `image()` forbidden; runtime generation stays for continuous morphs | user |
| 2026-11-18 | **Fidelity ladder (owner direction):** Act 0 renders in the Neon Cabinet palette (flat, unlit); THE PRETENCE morphs it into the base palette (`Look.t`); from T1 lighting, fog, bloom and complex particles are allowed and grow with the tier (ART-001 §15, §5.5 here). Per-pixel palette enforcement on pxl renders removed; role laws kept | owner |
| 2026-11-18 | **The Aether (owner direction):** space is retro-future Victorian, full of aether, fog, life, crystal spheres and colour, not a black vacuum; Act 0's black is the Pretence and the only true black is the entity (ART-001 §16). The reveal blooms into aether colour instead of desaturating; WARP-001 W0-08/W1-01 re-voiced; ART-001 law 4 amended | owner |
| 2026-11-18 | **Seeded RNG spec (Q-T26…Q-T28):** `hash64` = first 8 bytes (LE) of SHA-256 over a tagged canonical encoding with domain `darkstar.rng.v1`; `seam_index` int (0 run-wide, 1–5 Seams); SeedCode = `(seed << 5) \| crc5`, MSB-first Crockford symbols; checksum CRC-5 poly `0x05` over the 55 seed bits; code in new `core/rng/`. Engineering-only (✱); test vectors in §4.9. Unblocks M1 slice 2 part B | owner |
