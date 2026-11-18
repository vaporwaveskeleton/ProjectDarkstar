# TASK — Bootstrap architecture (adapted to DARKSTAR)

**Status:** done 2026-11-17 — owner adopted every §1 recommendation and the §2 doc mapping; GdUnit4 v6.2.3 installed. Result recorded in TECH-001 §9 and §11.2. · **Date:** 2026-11-17

> Deviations from §4 as built: the boot smoke path is `-- --smoke` (boot → attract → sector → quit 0). The extra overlays (settings, pause, confirm) were added to meet the brief's UI test list. `core/physics_layers.gd` lives at `core/physics/physics_layers.gd`. `features/charges`, `entity_voice` and `interactions` folders exist alongside the §3.1 list.
**Source:** the generic "Create the initial architecture for a scalable Godot game" brief, correlated against the existing doc set. Where the brief and the docs disagree, the docs win unless §1 says otherwise.

---

## 1. Decisions the owner must make before running

| # | Question | Brief says | Docs say | Recommendation |
|---|---|---|---|---|
| Q1 | Bullet / projectile collision | — | GDD §13: `Node2D` + custom quadtree, no physics bodies for the bullet layer. TECH-001 §1.5: Godot 2D physics (~80 colliders) is enough, measure first | Godot `Area2D`/ShapeCast for the bootstrap; quadtree only if §8 profiling says so. Record in TECH-001 §11 |
| Q2 | Renderer | Forward+ | TECH-001 §1.1 says "2D renderer" (no backend named) | Forward+ is fine for Windows. Use Compatibility only if min-spec testing shows T2 warp shaders miss the 1.2 ms budget (SYS-001 §9) |
| Q3 | `networking/` folder | create it | D-09, TECH-001 §1.1: "no network scene" | **Do not create.** Multiplayer sections of the brief are N/A |
| Q4 | Project root | — | Docs cite `assets/sprites/...`, `data/`, `generated/` | `project.godot` at repo root; `.gdignore` in `docs/`, `tools/`, `research/` (stops Godot importing Aseprite's data PNGs) |
| Q5 | Test framework | "available tests" | not chosen | GdUnit4 (headless CLI). Check its release supports 4.7 before installing; GUT is the fallback |
| Q6 | Hull model for `HealthComponent` | generic health | D-08 **open**: one-hit hull vs more | Component supports `max_hp = 1` and N; value comes from a `ds_` key so the A/B is a data edit |

## 2. Where each requested doc goes (no second source of truth)

| Brief asks for | Goes to | Why |
|---|---|---|
| `README.md` | **new**, repo root | none exists; short, points at docs/ |
| `docs/ARCHITECTURE.md` | **TECH-001** §2 onward | TECH-001 owns architecture. §2–§11 written 2026-11-17 (several subsections still planned; see TECH-001 §0.3) |
| `docs/SCENE_TREE_RULES.md` | TECH-001 §2 (scene tree, `SectorHost`, `CompositeRig`, anchors) | §0.1 table assigns it there |
| `docs/SIGNALS_AND_EVENTS.md` | **new** `docs/04-production/SIGNALS_AND_EVENTS.md` (EVT-001) | not owned by any doc; add a row to TECH-001 §0.1 |
| `docs/RESOURCES.md` | TECH-001 §3 (`TunableRegistry`, `ds_` keys, data lint) | already assigned |
| `docs/SAVE_SYSTEM.md` | TECH-001 §7 (`SaveEnvelope`), citing SYS-001 §8 and LOOP-001 §2 | already assigned |
| `docs/ADDING_A_FEATURE.md` | **new** `docs/04-production/ADDING_A_FEATURE.md` | workflow doc, nothing owns it |
| `docs/AI_INSTRUCTIONS.md` | **`CLAUDE.md`** at repo root | Claude Code loads it automatically; a second copy would drift |
| Localization doc | **new** `docs/04-production/LOCALIZATION.md` (L10N-001) | GDD §2 lists locales; TECH-001 §1.4 has `localize_extract`; nothing owns the system |
| UI architecture | TECH-001 §5 (`DiegeticHud`, `SteadyLedger`) + new `docs/04-production/UI_ARCHITECTURE.md` for menus/Theme | HUD content stays in WARP-001 §4 |

## 3. The brief, mapped to DARKSTAR

### 3.1 Feature folders
| Brief | DARKSTAR feature folder | Notes |
|---|---|---|
| characters | `vigil`, `choir`, `sepulchre` (the entity) | units are `CompositeRig`s of 64×64 modules (ART-002 §5) |
| combat | `arc_lance`, `charges` (Mourning Glass, Null-Iron Charges) | |
| inventory | `run` (Run Sigils, Relics, Pacts) | no classic inventory/equipment screen |
| dialogue | `entity_voice` | big-type lines, AUDIO-001 §4; no branching dialogue |
| quests | — | N/A. Nearest: `lantern_tree`, `codex`, iteration state |
| interactions | `interactions` (shrines, Chalk Desk, Sepulchre deposit) | |
| (missing from brief) | `composure`, `warp`, `sector` (`SeamAssembler`), `hud` | core to the game |

Bootstrap scope builds only `vigil` + `core/components`. The rest get empty folders and a README line.

### 3.2 Movement and animation audit — keep, but scope to 2D
Applies: Vigil thrust/turn/Surgelight (SYS-001 §1.1), lance and charge VFX, Choir locomotion, modular rig mutation (ART-002 §5.3), camera follow/shake/zoom (SYS-001 §9), warp-driven motion (WARP-001 §2).
N/A, say so in the doc: skeletons/IK, blend spaces, lip-sync (lines are text), jumps/landings, vehicles, ragdoll, cloth, multiplayer authority.
Responsibility split to write into TECH-001: `CharacterBody2D` owns movement; `AnimationPlayer` owns frame swaps and method-track events; `Tween` owns UI and small juice; GPUParticles2D for VFX; canvas-item shaders via `WarpComposer` for per-pixel effects.

### 3.3 Collision audit — keep, with DARKSTAR facts
Inputs already fixed: player hitbox 12 px circle; enemy hitbox = sprite alpha ∩ 1 px inset (SYS-001 §9); geode/entity segments are `StaticBody2D` per module (TECH-001 §1.2); ≤ 24 contacts, ≤ 180 active shots (TECH-001 §1.5). Resolve Q1 first.
Applies: swept ShapeCast for the lance and fast shots, one-hit-per-window, layer/mask table, tunnelling at 30/60/144 FPS. N/A: slopes, stairs, doors, moving platforms, ragdolls.

### 3.4 UI — keep, but it is not a generic menu stack
- Boot → **Attract mode** (fake cabinet) → New Vigil → Sector 1. Three clicks max (GDD §10).
- HUD is diegetic and allowed to lie under warp; **Steady Ledger** forces it honest (WARP-001 §4.2, §4.4). Elements that never lie: WARP-001 §4.7.
- Theme from ART-001 §7 and the palette file; GASLIGHT amber is the player's colour only.
- 200 % text-scale safe-area rule (SYS-001 §9, `TEST-ACC-04`). Photosensitivity mode must not hide information (GDD §10, WARP-001 §4.5).
- Brief items with nothing to build yet: shop, equipment, skills screens. Lantern Tree screen comes later.

### 3.5 Localization — keep, scoped to the locales in GDD §2

> **Superseded 2026-11-17:** the game is English only (L10N-001 §1). The locale, RTL, pseudo-translation and CJK items below were removed from code, tests and docs. Kept here as history.
Launch: EN; then de/fr/es/pt-BR/zh-CN/ja. No RTL locale is planned, so RTL is "architecture must not block it" + one pseudo-RTL test, not a shipping requirement.
Godot has no ICU: use gettext `.po` with plural forms and `msgctxt`. CJK needs the bitmap-font pass (ART-001 §9) before those locales build. Warp effects that corrupt text must work on the translated string, not the key. Pseudolocale must pass under T0–T2 warp.

### 3.6 Player-readable output — keep as written
One clarification for the AI: authored HUD lies are content, not bugs. Raw errors, keys and debug values on screen are still bugs.

## 4. Bootstrap deliverables (DARKSTAR names)

| Brief | DARKSTAR |
|---|---|
| bootstrap scene | `scenes/boot/boot.tscn` (cabinet first frame, TECH-001 §1.2) |
| main menu | `scenes/attract/attract_mode.tscn` |
| minimal gameplay | `scenes/sector/sector_stub.tscn` (one empty sector, `SectorHost` stub) |
| reusable character | `features/vigil/vigil.tscn` (move + aim only, SYS-001 §1.1 values via `ds_` keys) |
| health component | `core/components/health_component.tscn` (Q6) |
| scene routing | `autoload/scene_router.gd` |
| save interface | `autoload/save_service.gd` + `core/save/save_envelope.gd` (versioned, cadence per SYS-001 §8) |
| (extra, needed) | `core/data/tunable_registry.gd` stub, `core/physics_layers.gd`, `locale/en.po`, project settings from TECH-001 §1.2 |

Done = boots into `boot.tscn`, reaches `sector_stub.tscn` with no log errors, all tests pass headless.

## 5. Execution plan with model tiers

| Phase | Work | Agent (model) |
|---|---|---|
| 0 | Owner answers §1 | — |
| 1 | Draft TECH-001 §2 (scene tree), §3 (resources), §5 (UI/HUD skeleton), §7 (save) from cited excerpts | `doc-scout` (haiku) feeds `architect` (opus) |
| 2 | Create folders, `project.godot` settings, `.gdignore`s, install GdUnit4 | `godot-builder` (sonnet) |
| 3 | Bootstrap scenes, components, autoloads, tests | `godot-builder` (sonnet), one feature per call |
| 4 | Run tests + boot smoke | `test-runner` (haiku), loop with phase 3 until green |
| 5 | EVT-001, L10N-001, UI_ARCHITECTURE, ADDING_A_FEATURE, README; update TECH-001 §0.1 and §11; trim CLAUDE.md | `doc-keeper` (sonnet) |
| 6 | Review against this brief and GDD §18 | `architect` (opus), one pass |

Opus is used twice (phase 1 and 6). Everything that reads large files or logs goes to haiku.

## 6. Known gaps found during the correlation
- ~~TECH-001 ends at §1.5~~ — resolved 2026-11-17: §2–§11 written. Still planned (cited but not yet subsections): §4.3, §4.4, §4.9, §5.1–§5.4, §6.3, §8.1–§8.4.
- `ASSET_PIPELINE.md` (ASSET-003), `PRODUCTION_PLAN_MILESTONES.md` and `STEAM_MARKET_PLAN.md` are referenced but not on disk.
- GDD §2 allows 512×288 as a fallback; TECH-001 §1.1 closes it to 640×360. SYS-001 §9 still lists the fallback. Ask the owner to strike it.
