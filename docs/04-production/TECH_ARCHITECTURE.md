# DARKSTAR — Tech Architecture

**Doc ID:** TECH-001 · **Version:** 1.1 · **Date:** 2026-11-17 · **Owner:** production · **Status:** complete-draft
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
| Zones & encounters | `docs/01-design/ZONES_AND_ENCOUNTERS.md` | Biomes, the 32 Encounter Kits, kit `.tres` parameters, the seam assembler's rules, the **anchor-node names** (§1.6) and the geometry contracts each anchor carries | The node classes that implement those anchors; budgets |
| Roguelike loop & Lantern Tree | `docs/01-design/ROGUELIKE_LOOP_AND_LANTERN_TREE.md` | Iterations, Run Sigils, Pacts, Relics, the ~90 Lantern Tree nodes, the five endings | Save schema, unlock persistence mechanics |
| Reality-warp escalation | `docs/01-design/REALITY_WARP_ESCALATION.md` | Warp Tiers T0–T5 as authored content; eaten-rule list; the UI-eating and Compass-lying content | The shader that implements a tier, the tier state machine |
| Art bible | `docs/02-art/ART_BIBLE.md` | Palette roles, silhouette grammar, lighting law | File formats, atlas packing, import flags |
| Sprite modularity spec | `docs/02-art/SPRITE_MODULARITY_SPEC.md` | Module grid, kit ids, part ids, sockets, naming grammar, atlas geometry, Godot import settings | How a composite is instantiated, pooled or mutated in a scene |
| Asset pipeline & manifest | `docs/02-art/ASSET_PIPELINE.md` (**ASSET-003 — pending, not on disk**), `assets/sprites/SPRITE_MANIFEST.csv` | How art is produced; the generator and its scripts; per-row asset status | Anything the engine does with the output — that is §6 here |
| Production plan | `docs/04-production/PRODUCTION_PLAN_MILESTONES.md` (**pending**) | Milestones, vertical-slice definition, kit build order, schedule risk | What is technically possible, or what a milestone costs in frames |
| Audio design | `docs/03-audio/AUDIO_DESIGN.md` (AUDIO-001) | The chant as a positional system, Silence budget, music escalation | Bus layout, voice-count ceilings |
| Source research | `docs/00-research/REFERENCE_SINISTAR_SOURCE_MATERIAL.md` (RES-001) | What the 1983 original did; the IP guardrail | Any shipped name or asset |
| Signals and events | `docs/04-production/SIGNALS_AND_EVENTS.md` (EVT-001) | Every cross-node signal, its sender, payload, listeners; when to use a signal vs a call | Scene tree (here §2) |
| UI architecture | `docs/04-production/UI_ARCHITECTURE.md` (UI-001) | Menu/overlay stack, `Screen` contract, Theme, control states, focus and input rules, UI tests | HUD lie content (WARP-001 §4); palette (ART-001 §4) |
| Localization | `docs/04-production/LOCALIZATION.md` (L10N-001) | Keys, `.po` files, locales, fallback, formatting, pseudoloc, validation commands | Copy tone (GDD §10), fonts (ART-001, pending) |
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
| `ManifestImporter` | Build-time step that turns `SPRITE_MANIFEST.csv` into a generated GDScript table | §6.3 |
| `AtlasTable` | The generated lookup from part id to atlas region | §6.3 |
| `WarpComposer` | The per-frame owner of which canvas-item shaders are active at the current Warp Tier | §5.1 |
| `DiegeticHud` | The HUD layer built from in-world objects so it can lie, be eaten, and be drawn by the same code as honest data | §5.2 |
| `SteadyLedger` | The accessibility option that forces the HUD honest | §5.3 |
| `RunSeed`, `SeedCode`, `ReplayVerifier` | Deterministic run identity, the 12-character shareable form, and the hash-comparison test | §4.9 |
| `SaveEnvelope` | The versioned wrapper around every persisted block | §7.1 |
| `ContactBudget` | The runtime counter enforcing SYS-001 §9's on-screen contact ceiling | §8.2 |
| `FrameBudget` | The per-system split of the 16.7 ms frame | §8.1 |

---

## 1. Engine and build

### 1.1 Locked by the GDD

| Item | Value | Source |
|---|---|---|
| Engine | Godot **4.7.2 stable**, 2D renderer | GDD §2, §12; D-06 |
| Language | **GDScript only** for gameplay | D-06 |
| Internal resolution | **640 × 360** pixel-perfect | SYS-001 §0; ART-001 §1; GDD §2 |
| Filtering | nearest-neighbour, never anti-aliased, never mipmapped | ART-002 §1 |
| Scaling | integer multiples only (`window/stretch/mode = viewport`, aspect `keep`, integer snap) | §1.3 |
| Target frame rate | 60 FPS; 60 Hz fixed logic tick | SYS-001 §0, §9 |
| Platform at 1.0 | **Windows + Steam** | GDD §2, §12 |
| Platforms after 1.0 | Linux, then Mac | GDD §2 |
| Data-driven | every table in SYS-001 maps to a `.tres`/JSON resource | D-06, SYS-001 header |
| Mono / C# | not used | D-06 |
| Multiplayer | none in the build; no `MultiplayerAPI`, no network scene, no `networking/` folder | D-09 (coop out of scope for 1.0), GDD R-07 |
| Rendering method | **Forward+** (`rendering/renderer/rendering_method = forward_plus`) | owner decision 2026-11-17 (TASK-BOOT Q2); revisit only if min-spec shows T2 warp shaders over SYS-001 §9's 1.2 ms |

The GDD §2 row offering "512×288 **or** 640×360" is closed here: **640×360**. It is the resolution SYS-001's px values are written against and the one ART-002's module grid composes against (360 px = 5.625 modules of height; the entity composite at 512×256 therefore cannot fit the frame, which is ART-001 §2's scale-dread rule working by arithmetic rather than by staging).

### 1.2 Project settings we set and never revisit

| Setting | Value | Why |
|---|---|---|
| `display/window/size/viewport_width` | 640 | §1.1 |
| `display/window/size/viewport_height` | 360 | §1.1 |
| `display/window/stretch/mode` | `viewport` | pixel-perfect at any window size |
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
| `manifest_import` | pre-build, CI and local | `generated/sprite_table.gd` from `SPRITE_MANIFEST.csv` (§6.3) |
| `data_lint` | pre-build, CI | every SYS-001 §10 row ↔ exactly one `ds_` key; class check (§3.3) |
| `palette_lint` | pre-build, consumer-side only | every manifest row's used colours ⊆ its kit's `palette_lock`; ≤ 10 colours (ART-002 §1) |
| `localize_extract` | nightly | string table; CJK needs the ART-001 §9 font pass before those locales build |
| `export_presets` | release | `Windows Desktop` preset, PCK packed, no encryption at 1.0 |

Modders: we ship the `.tres` files loose in the PCK's `data/` folder so a player can edit a tunable in a text editor, and we ship no mod API, no loader hooks and no Steam Workshop at 1.0. Editing a `.tres` is supported as a supported-as-is affordance and is deliberately not a feature; §3.3 rejects a save that carries an out-of-class edit.

### 1.5 GDScript versus native — the honest boundary

| Work | Where it runs | Why |
|---|---|---|
| Movement, lance, charges, Composure, Warp Tier state, Hourglass Clock, spawn budgets, Choir AI state machines, Lantern Tree, save, telemetry, HUD, menus, dialogue, Codex, sector assembly | **GDScript** | all of it is state machines over small numbers, bounded by SYS-001 §3 spawn budgets and §9 contact ceilings — not by arithmetic volume |
| Per-pixel work (light masks, Shroud, warp distortion) | **canvas-item shaders**, GLSL-like Godot shader language | GPU-side; no GDScript pixel loops ever |
| Composite atlas lookups, part pooling | **GDScript**, table-driven | lookups are dictionary hits, not per-pixel work |
| Anything measured over 10,000 objects per frame | would need GDExtension/Rust or C++ | **the ceiling is never reached**: SYS-001 §3.1 caps Choir on-screen at 32 entities + 20 entity modules + 24 geodes, and §9 caps contacts at 24 and active shots at 180 |
| A native collision or spatial-hash rewrite | refused for v1 | Godot's 2D physics at ~80 colliders per sector is far inside budget; §8.3 measures before we decide |
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
   │   └─ AttractMode | SectorStub (SectorHost) | later: Ruins, LanternTree…
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
Assembles a unit from 64×64 modules (ART-002 §5). One `StaticBody2D`/`Area2D` shape per module (§1.2), so a knocked-off segment loses collision on the same frame. Not built.

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

Bullet-layer decision (TASK-BOOT Q1, owner 2026-11-17): Godot `Area2D`/`ShapeCast2D` first. GDD §13's custom quadtree is built only if §8 profiling shows the 180-shot ceiling missing budget.

### 2.7 Audio buses
`data/audio/default_bus_layout.tres`: `Master` (= AUDIO-001's `BUS-MST`; Godot requires bus 0 to be the master), `BUS-MUS`, `BUS-CHO`, `BUS-ENT`, `BUS-UI`, `BUS-FLY`, `BUS-AMB`, all sending to `Master`. Ducking sidechains (AUDIO-001 §7.2) and the never-ducked rules (§7.3) are **not wired yet**. No `AudioService` autoload exists; one needs a §2.8 row first.

### 2.8 Autoload register

An autoload exists only when the service genuinely needs a global lifetime. Adding one: add a row here first, then `project.godot`.

| Autoload | File | Why global | Must not | Status |
|---|---|---|---|---|
| `SettingsService` | `autoload/settings_service.gd` | locale, text scale and accessibility apply before the first frame and across scenes | hold game state; read saves | built |
| `SaveService` | `autoload/save_service.gd` | slots outlive scenes; one place enforces SYS-001 §8 cadence | decide *when* to save (callers do); store display text | built |
| `SceneRouter` | `autoload/scene_router.gd` | one top-level scene at a time; any screen may request a change | own overlays/modals or UI state | built |

Refused as autoloads: a UI manager (menus use a per-scene `ScreenStack`), a game manager (state lives in features), a networking service (D-09), a global event bus (EVT-001 §3).

### 2.9 Feature folders

| Brief term | DARKSTAR folder(s) | Status |
|---|---|---|
| characters | `features/vigil`, `features/choir`, `features/sepulchre` | vigil built (move + aim + hull) |
| combat | `features/arc_lance`, `features/charges` | empty |
| inventory | `features/run` (Run Sigils, Relics, Pacts) — no classic inventory/equipment | empty |
| dialogue | `features/entity_voice` (big-type lines; no branching dialogue) | empty |
| quests | **N/A**; nearest: `features/lantern_tree`, `features/codex` | empty |
| interactions | `features/interactions` (shrines, Chalk Desk, Sepulchre deposit) | empty |
| (game-specific) | `features/composure`, `features/warp`, `features/sector`, `features/hud` | empty |

Each empty folder has a `README.md` naming its owner doc. Shared, feature-agnostic code lives in `core/` (`components`, `data`, `save`, `routing`, `ui`, `i18n`, `physics`). Menus and the bootstrap sector live in `scenes/`.

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

---

## 4. Gameplay runtime — planned
Composure, the Warp Tier state machine, Hourglass Clock, spawn budgets, Choir AI, Lantern Tree and `RunSeed` / `SeedCode` / `ReplayVerifier` (§4.9) are not designed in this revision. Each gets a subsection here before code. Constraint already fixed: warp state is derivable from the seed alone (SYS-001 §10).

## 5. UI and HUD

| Part | Where | Status |
|---|---|---|
| Menus, overlays, Theme, focus and input rules | UI-001 | built (attract, settings, pause, confirm) |
| §5.1 `WarpComposer` | per-frame shader owner by Warp Tier | planned |
| §5.2 `DiegeticHud` | in-world HUD that may lie per WARP-001 §4.2 | planned; the bootstrap HUD is one honest hull label |
| §5.3 `SteadyLedger` | `SettingsService` key `steady_ledger`, default **on** (WARP-001 §4.4); the `pause` action always opens the real pause screen | setting + pause built; HUD pinning planned |

## 6. Asset consumption
`ManifestImporter` / `AtlasTable` (§6.3) — planned. Import flags: §10.

## 7. Save system

### 7.1 SaveEnvelope
`core/save/save_envelope.gd`. A JSON object: `format`, `schema_version`, `slot`, `game_version`, `written_unix`, `checksum` (SHA-256 of the canonical payload), `payload`. Load statuses: `OK`, `MISSING`, `CORRUPT`, `CHECKSUM_MISMATCH`, `NEWER_VERSION`, `WRONG_SLOT`.

### 7.2 Slots and cadence

| Slot | Persistence class (LOOP-001 §2) | Allowed save reasons | Status |
|---|---|---|---|
| `profile` | Anchored | `ruins_entry`, `tree_purchase`, `iteration_end` | interface built |
| `iteration` | Iteration | `ruins_entry`, `iteration_end`, `new_iteration` | interface built |
| `run` | Run | `seam_boundary` only (never mid-run, SYS-001 §8) | interface built |

`SaveService.save_slot(slot, payload, reason)` refuses any other reason with `save_failed(slot, &"not_allowed_now")`. Payloads hold invariant IDs and numbers only, never translated text. No gameplay writes any slot yet.

### 7.3 Storage, recovery, migration
`FileSaveBackend` writes `user://saves/<slot>.json` via `.tmp` then rename, keeping the previous file as `.bak`. A corrupt or tampered main copy loads from `.bak` (`recovered = true`). A newer schema is refused and never overwritten. Migration: bump `SCHEMA_VERSION`, add one step in `SaveEnvelope.migrate`, never edit a shipped step. `MemorySaveBackend` is for tests. Steam Cloud is a future backend; not built.

Device settings live in `user://settings.cfg` (`SettingsService`), not in a save slot — see §11 Q-T05.

Player-facing failure text: `PlayerMessages.save_message(reason)` → `MSG_SAVE_*` keys. Codes and paths never reach the screen; details go to `push_warning` only.

Troubleshooting: delete `%APPDATA%\Godot\app_userdata\DARKSTAR\saves\` to reset; a `.bak` next to a slot is the previous good copy.

## 8. Budgets
§8.1 `FrameBudget`, §8.2 `ContactBudget`, §8.3 measurement method — **nothing measured yet.** No profile has been taken; this revision makes no performance claim.

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
| `core/i18n/tests/test_localization.gd` | missing/unused keys, placeholders, fallback, plurals, number formats, pseudoloc expansion, glyph coverage |
| `core/ui/tests/test_theme_palette.gd` | theme and scene colours ⊆ palette, text-scale application |
| `features/vigil/tests/test_vigil_motor.gd` | speed cap, drag, brake, 30/60/144 Hz independence, full reversal 0.28 s, turn rate, ±π wrap |
| `features/vigil/tests/test_vigil_collision.gd` | data-driven radius, wall stop, no tunnelling at 6000 px/s, overlap recovery, live hitbox one hit per window → breach → HUD |
| `scenes/tests/test_attract_mode.gd` | default focus, focus loop/wrap, settings modal + ui_cancel + focus restore, root ui_cancel no-op, repeated input, 200 % text safe area (menu + settings), RTL layout, pseudoloc fit, no raw keys |
| `scenes/tests/test_sector_and_pause.gd` | spawn at anchor, HUD text, pause action, ui_cancel/pause resume, confirm defaults to the safe choice, abandon routes + unpauses, three-deep modal unwind |
| `tests/test_boot_flow.gd` | route table loads, unknown route fails safely, input-mode switching, accessibility defaults |

Result on 2026-11-17: 72 test cases, 0 failures, 0 errors; boot smoke exit 0 with no `ERROR`/`WARNING` lines.

Not covered (honest list): window sizes other than the 640×360 logical viewport, real integer scaling at 1080p/1440p, gamepad glyphs (none exist), shaders, audio, Steam, per-locale screenshots (no second locale exists), performance. Slopes, stairs, doors and moving platforms are N/A (§2.6).

## 10. Import conventions
Per ART-002 §7: canvas default filter Nearest (set in `project.godot`); pixel atlases import with `compress/mode = Lossless`, mipmaps off, `fix_alpha_border = true`. ART-002 §7 mentions a `godot/DarkStar/` path; the project root is the repo root (TASK-BOOT Q4), so that path is obsolete — §11 Q-T08. No import preset file is committed yet. `docs/`, `tools/`, `research/` and `Claude outputs/` carry `.gdignore`.

## 11. Open questions and decision log

### 11.1 Open questions
| # | Question | Found in | Proposed |
|---|---|---|---|
| Q-T01 | GDD §2 and SYS-001 §9 still list 512×288 as a fallback; §1.1 closes it | GDD §2, SYS-001 §9 | owner strikes the fallback |
| Q-T02 | ART-001 §9 is cited for the bitmap/CJK font by GDD §2, TECH-001 §1.4 and TASK-BOOT, but ART-001 §9 is "Reference library" — no font spec exists | ART-001 | art owner writes the font section; until then the UI uses Godot's fallback font at ✱ 14 px |
| Q-T03 | SYS-001 defines no `ds_` keys; the §3.4 keys were coined here | SYS-001 §10 | add a key column to SYS-001 tables |
| Q-T04 | "player hitbox 12 px circle" — diameter or radius? Code reads **diameter** (radius 6) | SYS-001 §9 | design confirms |
| Q-T05 | Accessibility settings: LOOP-001 §2 says profile slot; WARP-001 §4.4 says "save-scoped"; code stores them device-level in `settings.cfg` | LOOP-001 §2, WARP-001 §4.4 | owner picks one; mirror into profile if needed |
| Q-T06 | ART-001 §4 law 1 (no GASLIGHT on Choir/entity) vs `darkstar_palette.json` v1.1 `faction_exceptions` (three parts) | ART-001, palette JSON | art owner updates ART-001 |
| Q-T07 | CLAUDE.md cited ZONES-001 §1.6 for anchors; the anchor tree is §1.7 | CLAUDE.md | fixed in CLAUDE.md 2026-11-17 |
| Q-T08 | ART-002 §7 refers to `godot/DarkStar/.import`; the project root is the repo root | ART-002 §7 | art owner updates |
| Q-T09 | ART-001 has no focus/hover/disabled/error colours; the UI uses a GAS-3 focus outline (GASLIGHT = "player only") and SIGNAL for error text (SIGNAL = "danger tell only") | ART-001 §4, §7 | art owner rules; see UI-001 §9 |
| Q-T10 | SYS-001 §2.1 entity contact hitbox "16 px inset" vs §9 "enemy hitbox = alpha ∩ 1 px inset" | SYS-001 | design clarifies (entity vs other enemies) |
| Q-T11 | No invulnerability-after-hit value exists; `invulnerable_after_hit_s = 0` ✱ | SYS-001 §1.2 | design adds a row if D-08 lands on > 1 HP |
| Q-T12 | Gamepad bindings for Surgelight (RB), brake (LB), pause (Start) and fire (RT) are ✱; the GDD gives keyboard/mouse only | GDD §4.1, D-01 | design confirms |
| Q-T13 | GDD §19 says "Seam (a run level)"; this doc and the code use "sector" for the playfield (`SectorHost`, `sector_stub`) | GDD §19, TECH-001 §0.3 | owner confirms both words, or rename |

### 11.2 Decision log
| Date | Decision | By |
|---|---|---|
| 2026-11-17 | Adopt TASK-BOOT Q1–Q6 recommendations: Area2D/ShapeCast before a quadtree; Forward+; no `networking/` folder; `project.godot` at repo root; GdUnit4; data-switchable hull | owner |
| 2026-11-17 | The brief's `docs/ARCHITECTURE.md`, `SCENE_TREE_RULES.md`, `RESOURCES.md`, `SAVE_SYSTEM.md` are sections of this doc (§2, §3, §7); `AI_INSTRUCTIONS.md` is `CLAUDE.md` (TASK-BOOT §2) | owner |
| 2026-11-17 | GdUnit4 v6.2.3 vendored into `addons/gdUnit4` | owner |
| 2026-11-17 | Route scenes mount under Boot's `RouteHost` (not `change_scene_to_*`) so the curtain persists and UI tests can use a fake host | production |
| 2026-11-17 | §1.1 multiplayer citation corrected from D-11 to D-09 | production |
