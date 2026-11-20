# DARKSTAR

2D arcade roguelike. Godot **4.7.2**, GDScript only, 640×360 pixel-perfect, Windows + Steam, single-player.

Current state: **Act 0 is playable.** The game boots into the cabinet's attract screen; **New Vigil** starts *The Last Normal Day*, the 1983-style arcade shell (GDD §6.1):

1. **First Vigil** — mine geodes for Mourning Glass, turn it into Charges, and break a Cold Sepulchre before the Grubs rebuild it.
2. **The Last Normal Day** — Grubs race you for the same glass to build the Dark Star; Acolytes guard it; at 20 segments the chant stops, *IT WAKES*, and it hunts you. Unmake it with 13 Charges.
3. **The Pretence** — then the cabinet stops pretending. (Play it.)

After that you land in the Ruins of the Ninth Sky (a stub for now). Act 1 onward is designed in `docs/` but not built.

## Run

```
tools\godot\Godot_v4.7.2-stable_win64.exe --path .                       # play (or open in the editor)
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a core -a features -a scenes -a tests --ignoreHeadlessMode -c
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 600 -- --smoke
```
Controls: **WASD** move · **mouse** aim · **left click** Arc-Lance (mine and shoot) · **right click** throw a Null-Iron Charge (homes on the Sepulchre / the Dark Star) · **Shift** Surgelight · **Space** brake · **Esc** pause. Gamepad: left stick move, right stick aim, RT lance, LT Charge, A Surgelight, left-stick click brake, Start pause.

Tips: fire in calm bursts — over-firing a geode (7 hits in 1.2 s) shatters it and scatters the glass where the Grubs can steal it. Shoot Grubs that are carrying glass. Acolytes' censers lag a quarter-second behind you: keep moving.

## Art tool (pxl)

Build-time pixel art is code too (GDD D-13). Sources live in `art/src/*.px.js` (each starts with `include("darkstar_palette.px.js")`) and are rendered by [pxl](https://github.com/uilianks/pxl) into `assets/art/generated/` (committed). To edit art, install pxl once per machine (Node ≥ 22.18, no dependencies):

```
git clone https://github.com/uilianks/pxl .claude/skills/pxl
```
Then `node .claude/skills/pxl/bin/pxl.js serve art/src/reference.px.js` for the live viewer (http://127.0.0.1:4321), `... lint art/src/<file>.px.js` before calling art done, and `... build art/src/<file>.px.js --out assets/art/generated` to re-render. Only palette colours; never `image()`. Details: ART-001 §14.8.

## Texture tool (loom)

Seamless textures are code too (ART-001 §14.8a). Sources live in `art/src/*.tx.js` (each starts with `include("darkstar_palette.tx.js")` and names colours by Pal role only) and are rendered by [loom](https://github.com/uilianks/loom) into `assets/art/generated/textures/` (albedo, normal, ORM, emissive: committed). To edit textures, install loom once per machine at the pinned commit (Node ≥ 22.18; one runtime dependency, `@resvg/resvg-js`, used only for the preview sheets; no install scripts):

```
git clone https://github.com/uilianks/loom .claude/skills/loom
git -C .claude/skills/loom checkout bc0159965033b5a7e3483c13787036eec516b210
cd .claude/skills/loom && npm ci --omit=dev --ignore-scripts
```

Then `node .claude/skills/loom/bin/loom.js build art/src/<file>.tx.js --out assets/art/generated/textures` to re-render (read `assets/art/generated/textures/_preview/<name>.png`, then `--import`), and `... serve art/src/<file>.tx.js` for the live viewer (http://127.0.0.1:4350). Never use loom's `image()`. The tool, its `node_modules`, the previews and the unused maps (height, roughness, metallic, AO) are git-ignored.

## Sound tools (chirp)

Every sound is code (GDD D-14). Authored sounds live in `audio/src/*.cx.js` and are rendered by [chirp](https://github.com/uilianks/chirp) into `assets/audio/generated/` (committed, so playing the game needs nothing extra). To edit sounds you need Node ≥ 22.18 and chirp, installed once per machine as a project Claude Code skill:

```
git clone https://github.com/uilianks/chirp .claude/skills/chirp-game-audio
cd .claude/skills/chirp-game-audio && npm install
```
Then, from the repo root: `node .claude/skills/chirp-game-audio/bin/chirp.js serve audio/src/cabinet.cx.js` to listen live (http://127.0.0.1:4330), and `... build audio/src/cabinet.cx.js --out assets/audio/generated` to re-render. Never use chirp's `sample()` (recordings are not allowed). Details: AUDIO-001 §11.7.

## Layout

| Folder | Holds |
|---|---|
| `autoload/` | the three global services (`SettingsService`, `SaveService`, `SceneRouter`) — TECH-001 §2.8 |
| `core/` | shared components, data registry, save, routing, UI base, i18n, physics layers |
| `features/<glossary_name>/` | one folder per game feature (`vigil` is the only built one) |
| `scenes/` | boot, attract, settings, sector stub, shared overlays |
| `data/` | loose `.tres` tunables, theme, route table, audio buses |
| `locale/` | `en.po`, the English text for every on-screen key (English only) |
| `shaders/`, `generated/` | empty for now |
| `tests/` | cross-cutting test suites and helpers |
| `addons/gdUnit4` | test framework (v6.2.3) |
| `docs/` | design and production docs (ignored by Godot) |

There is deliberately no `networking/` folder: the game is single-player (GDD D-09).

## Where the rules live

| You want | Read |
|---|---|
| AI / contributor rules (short) | [`CLAUDE.md`](CLAUDE.md) |
| Architecture, scene tree, resources, save system, tests | [`docs/04-production/TECH_ARCHITECTURE.md`](docs/04-production/TECH_ARCHITECTURE.md) (TECH-001) |
| Signals and events | [`docs/04-production/SIGNALS_AND_EVENTS.md`](docs/04-production/SIGNALS_AND_EVENTS.md) (EVT-001) |
| Menus, buttons, focus, Theme | [`docs/04-production/UI_ARCHITECTURE.md`](docs/04-production/UI_ARCHITECTURE.md) (UI-001) |
| Player text keys (English only) | [`docs/04-production/LOCALIZATION.md`](docs/04-production/LOCALIZATION.md) (L10N-001) |
| Adding a feature | [`docs/04-production/ADDING_A_FEATURE.md`](docs/04-production/ADDING_A_FEATURE.md) |
| Every game number | [`docs/01-design/SYSTEMS_BIBLE_STATS.md`](docs/01-design/SYSTEMS_BIBLE_STATS.md) (SYS-001) |
| What the game is | [`docs/01-design/GDD_DARKSTAR_v0.2.md`](docs/01-design/GDD_DARKSTAR_v0.2.md) |
| Lore, cast, endings, Codex prose | [`docs/01-design/NARRATIVE_LORE_BIBLE.md`](docs/01-design/NARRATIVE_LORE_BIBLE.md) (NARR-001) |
| Run loop, economy, unlocks, endings triggers, achievements | [`docs/01-design/ROGUELIKE_LOOP_AND_LANTERN_TREE.md`](docs/01-design/ROGUELIKE_LOOP_AND_LANTERN_TREE.md) (LOOP-001) |
| Asset pipeline | [`docs/02-art/ASSET_PIPELINE.md`](docs/02-art/ASSET_PIPELINE.md) (ASSET-003) |
| Milestones and schedule | [`docs/04-production/PRODUCTION_PLAN_MILESTONES.md`](docs/04-production/PRODUCTION_PLAN_MILESTONES.md) (PROD-001) |
| Steam launch plan | [`docs/04-production/STEAM_MARKET_PLAN.md`](docs/04-production/STEAM_MARKET_PLAN.md) (MARKET-001) |

The generic bootstrap brief asked for `docs/ARCHITECTURE.md`, `SCENE_TREE_RULES.md`, `RESOURCES.md`, `SAVE_SYSTEM.md` and `AI_INSTRUCTIONS.md`. Those topics are TECH-001 §2, §2.1, §3 and §7, and `CLAUDE.md`. Each has one owner (see `docs/04-production/TASK_BOOTSTRAP_ARCHITECTURE.md` §2).
