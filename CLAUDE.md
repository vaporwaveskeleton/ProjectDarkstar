# DARKSTAR — Claude Code instructions

Godot **4.7.2**, **GDScript only**, 2D, 640×360 pixel-perfect, Windows + Steam, single-player (no networking).
This file is loaded every turn: keep it short. Detail lives in `docs/`; cite it, do not copy it.

## 1. Sources of truth (read the owner, never guess)

| Question | Owner doc | Rule |
|---|---|---|
| Any number (speeds, HP, budgets, timings) | `docs/01-design/SYSTEMS_BIBLE_STATS.md` (SYS-001) | Never invent a game number. Missing → stop and ask. Engineering-only params get `✱` and go in TECH-001 |
| Scene tree, node ownership, data layout, `ds_` keys, save layout, shaders, budgets, tests | `docs/04-production/TECH_ARCHITECTURE.md` (TECH-001) | The architecture doc. Update it; do not create a competing `ARCHITECTURE.md` |
| Names of things (code, UI, files) | GDD §19 glossary | Use glossary words exactly: Vigil, Arc-Lance, Surgelight, Composure, Choir… |
| Locked decisions | GDD §18 (D-01…D-14) | Code may assert, never vary. D-08 (one-hit hull) is **open**: keep it data-switchable |
| Warp tiers, HUD lie law, Steady Ledger | `docs/01-design/REALITY_WARP_ESCALATION.md` (WARP-001) §4 | |
| Run structure, saves classes, Lantern Tree | `docs/01-design/ROGUELIKE_LOOP_AND_LANTERN_TREE.md` (LOOP-001) §2–3 | |
| Kits, anchors, seam assembly | `docs/01-design/ZONES_AND_ENCOUNTERS.md` (ZONES-001) §1.7 (kit tree + anchor names), §4 | |
| Sprite naming, sockets, import flags | `docs/02-art/SPRITE_MODULARITY_SPEC.md` (ART-002) §2, §7 | |
| Palette, UI/VFX art rules | `docs/02-art/ART_BIBLE.md` (ART-001) §4, §7 | Palette violations are bugs (palette test enforces UI) |
| Audio buses, cues, ducking | `docs/03-audio/AUDIO_DESIGN.md` (AUDIO-001) §6–7 | |
| Signals register, no event bus | `docs/04-production/SIGNALS_AND_EVENTS.md` (EVT-001) | Add a row before adding a signal |
| Menus, `Screen`/`ScreenStack`, Theme, focus, control states | `docs/04-production/UI_ARCHITECTURE.md` (UI-001) | |
| Player text keys (English only), formatting | `docs/04-production/LOCALIZATION.md` (L10N-001) | English only for now; no other languages, no language setting. Still use `tr()` keys |
| New feature checklist | `docs/04-production/ADDING_A_FEATURE.md` | |

Design docs are 15–140 KB. **Do not read them whole.** Use the `doc-scout` agent to fetch the cited section.
When docs disagree, record it in TECH-001 §11.1 (open questions) and ask; do not silently pick one.
Architectural decisions go in the TECH-001 §11.2 decision log (date, decision, who decided), plus the section they change.
Owner rulings R-01…R-19 (2026-11-17) are in TECH-001 §11.1a; treat them as decided. Input actions follow GDD §4.1/§4.3 exactly (`tests/test_input_map.gd`).

## 2. Project layout

```
project.godot            (repo root, so res://assets matches the docs)
addons/  autoload/  core/  features/<feature>/  scenes/  shaders/  data/  generated/  tests/  locale/
assets/  docs/           (docs/, tools/, research/ carry a .gdignore)
```
- `features/<feature>/` holds that feature's scenes, scripts, resource classes and `tests/`. Feature names come from the glossary (`vigil`, `arc_lance`, `charges`, `choir`, `sepulchre`, `composure`, `warp`, `sector`, `lantern_tree`, `run`, `hud`, `codex`, `entity_voice`, `interactions`); map in TECH-001 §2.9.
- `core/` = feature-agnostic code (`components`, `data`, `save`, `routing`, `ui`, `i18n`, `physics`). `scenes/` = boot, attract, settings, sector stub, shared overlays.
- `data/<feature>/*.tres` = loose tunables (TECH-001 §3). `generated/` = build output (`sprite_table.gd`); never hand-edit.
- Tests sit next to code in `tests/` subfolders (`core/**/tests`, `features/<f>/tests`, `scenes/tests`); cross-cutting suites and helpers in root `tests/`.
- No `networking/` folder (D-09, TECH-001 §1.1).

## 3. Code rules

- snake_case files and folders; PascalCase `class_name`; signals past-tense (`hull_breached`); `ds_` keys for every tunable.
- Composition: small components (`HealthComponent`, `HurtboxComponent`…) as child scenes. No god scripts for player, game manager or level.
- Data in `Resource` subclasses (`.tres`), never in code constants. Tunables extend `TunableResource` with a `ds_namespace` (TECH-001 §3.4). New **scene** when it needs nodes/transform/collision/lifetime; new **Resource** when it is shared or tuned data.
- Signals when the sender must not know the receiver; direct calls parent→child. No `get_node("../../x")`; use `@export` refs, `%UniqueName` inside a scene, groups, or a resource. Routes by id (`SceneRouter.go_to(&"sector")`), never by scene path.
- Autoloads only for global-lifetime services. Built: `SettingsService`, `SaveService`, `SceneRouter`, `AudioService`; approved, not built: `RunSession` (TECH-001 §2.8). Adding one needs a §2.8 row first. No UI manager, game manager or event bus autoloads.
- UI: screens extend `Screen`, overlays go on the scene's `ScreenStack`, rows inside `FitScrollContainer`; one default focus, explicit focus neighbours, `ui_cancel` works (UI-001).
- Saves: `SaveService.save_slot(slot, payload, reason)` with an allowed reason; never mid-run; payloads hold ids and numbers only (TECH-001 §7).
- Warnings are errors here: give a variable an explicit type when its value comes from a `Dictionary`/`Array`/`Variant`.
- **Generated assets only (D-13, D-14):** never add or reference image, texture, font or audio files in game code, scenes or data. Visuals = vector draw calls or shaders with `Pal` colours (ART-001 §14); text = `PixelText`; sound = `SfxSynth`/`AudioService` synthesis (AUDIO-001 §11). PNGs under `assets/sprites/` are local-only reference: not in git, Godot-ignored, never shipped — never re-add them. `tests/test_generated_assets_only.gd` enforces this.
- Gameplay collision is separate from sprites and animation; animation fires events, it never owns hit truth.
- Every player-visible string goes through `tr()` with a stable key. No raw errors, IDs, enum names or paths on screen. (Diegetic HUD "lies" are authored content per WARP-001 §4.2, not debug output; Steady Ledger must always be honest.)

## 4. Commands

```
GODOT=tools\godot\Godot_v4.7.2-stable_win64_console.exe
%GODOT% --headless --path . --import                        # first run / after asset changes
%GODOT% --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a core -a features -a scenes -a tests --ignoreHeadlessMode -c   # all tests (GdUnit4 v6.2.3)
%GODOT% --headless --path . --quit-after 600 -- --smoke     # boot smoke: must print "BOOT_SMOKE: reached route 'cabinet'", exit 0, no ERROR lines
```
Expected `ERROR`/`WARNING` lines in the test log come only from negative-path tests (corrupt save, unknown route); the smoke log must have none.
Act 0 (the Cabinet, TECH-001 §2.10) takes capture switches after `--`: `--autopilot --stage=N --segments=N --hits=N --smoke-frames=N --no-save`. Always pass `--no-save` when capturing, so the player's saves are never written.
Prefer the `godot-ai` MCP (`test_run`, `logs_read`, `project_run`, `scene_*`) when the editor is open. Fall back to the console exe.

## 5. Model delegation (token budget)

| Work | Agent | Model |
|---|---|---|
| Find a doc section, list files, grep for a key | `doc-scout` | haiku |
| Run tests / boot, summarise failures | `test-runner` | haiku |
| Write scenes, scripts, resources, tests | `godot-builder` | sonnet |
| Update docs after a change | `doc-keeper` | sonnet |
| Resolve a cross-doc conflict, design a new boundary, review a TECH-001 section | `architect` | opus |

The main session plans, delegates, and reviews diffs. It does not read large docs or test logs itself.

## 6. Definition of done (every task)

1. Tests pass headless; boot smoke test reaches the gameplay scene with no errors in the log.
2. The docs that own the change are updated (TECH-001 section, `data/` table, AI rules in this file if a boundary moved). No second source of truth.
3. Final report lists every file created or changed, every doc updated, every command run and its result, and anything not verified.
4. Never claim a number, measurement or test coverage that was not actually run.
