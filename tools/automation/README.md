# DARKSTAR scenario runner (automation phase 1)

In-process, no sockets (D-09). The game is launched with a scenario id; the runner inside the game
plays `tests/scenarios/<id>.scenario.json` with real input events, frame-counted waits and
assertions, writes `result.json` (+ screenshots) and quits with an exit code.
Dev/QA only: Boot starts it only in editor builds or builds with the `automation_dev` /
`automation_qa` feature tag. Release builds may exclude `core/automation/`.

## Commands

```
node tools/automation/darkstar_auto.js validate <file|id>
node tools/automation/darkstar_auto.js run <id> [--windowed] [--keep] [--godot=<exe>] [--timeout=<s>] [--out=<dir>]
```

- `run` validates, then spawns
  `godot --path <repo> [--headless] --fixed-fps 60 -- --scenario=<id> --no-save --out=<dir>`.
  Headless by default (screenshots are skipped there; use `--windowed` for PNGs).
- Output goes to `reports/automation/<id>-<timestamp>/` (`result.json`, `console.log`, PNGs). A clean
  pass with no screenshots is deleted unless `--keep` is given or `--out` is explicit. The game only
  accepts `--out` under `user://` or the project `reports/` folder.
- Godot exe: `--godot=`, then env `DARKSTAR_GODOT`, then `tools/godot/Godot_v4.7.2-stable_win64_console.exe`
  (a worktree falls back to the main checkout's copy).
- `--timeout` is the real-time watchdog (default 120 s).

## Dev launch switch `--route=<id>`

`godot --path . -- --route=sector [--hull=1|2] [--no-save]` starts the game on that route instead of
the attract/Cabinet (e.g. the M1 sector). Same gate as the runner (`editor`, `automation_dev`,
`automation_qa`); a release build, an unknown id or an empty value starts normally. `--smoke` ignores
it. Code: `core/routing/launch_route.gd` (`LaunchRoute`); TECH-001 §9.1.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | pass |
| 1 | a step failed, or `timeout_frames` ran out |
| 2 | scenario invalid (or CLI usage error) |
| 3 | refused (saves not in memory, or `--out` outside the allowed roots) |
| 4 | watchdog: the game was killed after `--timeout` seconds |
| 5 | no `result.json` was produced (crash) |

## Scenario files

`{format:"darkstar.scenario", version:1, id, args?, fixtures?, timeout_frames, steps:[{do:"<step>", ...}]}`.
Step names and argument types live in `core/automation/step_catalog.json` (read by both the GDScript
validator and this CLI). Comparators on `wait_until` / `assert`: exactly one of `eq ne lt lte gt gte in`.
Ids: `<route>/ui/<UniqueName>` for controls, plus `cabinet/game` (`state`, `stage_index`, `demo`),
`cabinet/score` (`score`, `lives`), `cabinet/record` (`grubs_destroyed`, `glass_mined`,
`charges_thrown`, `glass_carried`), `sector/vigil` (`vigil_x`, `vigil_y`, `vigil_speed`, `hull_max_hp`,
`camera_x`, `compass_markers`, `camera_gap`; scenario `m1_sector_feel`). Fixtures: `{"profile": "<name>"}` loads
`tests/fixtures/saves/<name>.json` into the in-memory save.

The same runner runs inside GdUnit: `tests/test_scenarios.gd` plays every scenario that is valid for
the suite (`args == []`, `timeout_frames <= 1200`).

## Phase 2: probes, snapshots, events, dev ops

```
node tools/automation/darkstar_auto.js caps [--windowed]          # launch with --automation-caps, print steps/profile/probes
node tools/automation/darkstar_auto.js run-all [--only=<substr>]  # every scenario in turn, summary table, exit 1 if any failed
```

- **Probes.** Game state ids come from one probe per route (`features/<f>/automation/<f>_probe.gd`, no
  `class_name`, loaded by path only if present; release builds exclude the folder). The contract is the
  comment block at the top of `core/automation/scenario_runner.gd`. The cabinet probe exposes
  `cabinet/game|score|record|vigil|world` and `cabinet/acolyte/<id>`, `cabinet/grub/<id>`,
  `cabinet/geode/<index>` (see `caps` for the allow-listed props; `cabinet/vigil` includes `killer_kind`, `killer_dx/dy`,
  `killer_on_screen`, `death_marks`; `cabinet/world` includes `death_marks`, `entity_awake`, `entity_dx/dy`). `assert {id, exists:false}` works for gone entities.
- **New steps.** `snapshot{name}` writes `<out>/snapshots/<name>.json` (max 50 per run); `wait_event{event, within, count?}`
  waits for a probe event (the failure names the events seen); `perf_sample{}` appends to `result.perf` (max 200).
  Cabinet dev steps (dev profile only, refused in QA before frame 0): `set_stage`, `set_lives`, `teleport`, `spawn`
  (acolyte|geode|shard at Vigil + dx,dy), `shoot_vigil` (a hostile censer shot from Vigil + dx,dy aimed at the Vigil),
  `kill_all` (Acolytes, Grubs, hostile shots), `place_entity` (dx,dy, |v| ≤ 4000; entity must be awake), `wake_entity`
  (needs a non-Cold Sepulchre, so `set_stage 1` first; awake after about 4.2 s: wait on `cabinet/world entity_awake`), `pause_sim`, `step_sim` (needs paused_sim; steps ArcadeWorld only, not
  the CabinetGame state machine, so the death timer and respawn do not advance).
- **Errors.** Every run captures engine errors and warnings into `result.errors[]`, `error_count`, `warning_count`.
  Scenario field `"fail_on_errors": true` fails the run on any error-type entry, except messages containing a
  string from `"allow_errors": [...]`.
- **result.json** also holds `snapshots[]`, `events[]` (last 256 `{frame,id,args}`) and `perf[]`.
- **Caps.** `-- --automation-caps --no-save --out=<dir>` writes `caps.json` (`format darkstar.caps`, steps with `dev`,
  comparators, screenshot targets, probe ids/events/dev ops, approved fixtures, build) and exits 0.
