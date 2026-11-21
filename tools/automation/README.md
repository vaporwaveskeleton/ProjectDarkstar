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
- CI (`.github/workflows/ci.yml`) runs the scenarios (with the suite and smoke) only at milestone gates: a pushed tag `milestone/<id>` or a manual `workflow_dispatch`, not per PR (TECH-001 §9.2). Before a PR, run the scenarios you touched and the suite locally.
- Extra game args: everything after a bare `--` goes to the game after the scenario's own `args`, e.g.
  `node tools/automation/darkstar_auto.js run aether_unmaking_capture --windowed -- --aether-cine-scale=8`.
  Only `--name` / `--name=value` tokens; the runner's own (`--scenario`, `--record`, `--out`, `--no-save`,
  `--path`, `--headless`, `--fixed-fps`) are refused (exit 2). Dev builds read their dev args; a release
  build ignores them. Test: `node --test tools/automation/darkstar_auto.test.js`.
- `--exe=<exe>` (on `run` and `run-all`) runs an exported build instead: the exe is spawned directly, cwd =
  its folder, no `--path`. The exported game takes `--out` only as `res://reports/...` (= `<exe dir>/reports`);
  an absolute path is refused (exit 3). A QA build refuses dev-step scenarios (exit 3); the CLI prints
  "refused (QA profile)" and does not count it as a failure. Headless only. A release exe has no automation.

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
`camera_x`, `compass_markers`, `camera_gap`, `facing_deg`, `aim_x`, `aim_y`, `composure`,
`composure_band`; scenario `m1_sector_feel`),
`sector/field` (`geodes_alive`, `geodes_detonated`, `shards_free`, `charges`, `score`; M1 slice 3
PR 4 adds `shards_live`, `charges_in_flight`, `charges_lost`, `charges_hit`, `charges_guttered`,
`dry_fires`), `sector/choir` (PR 4: `grubs_alive`, `grubs_carrying`, `segments`, `deposited_shards`,
`sepulchre_complete`), `sector/run` (`seam_index`, `run_session`, `far_look`, `kit_id`; scenarios `a1_golden_path`, `a1_two_seams`), `sector/acolyte` (`acolyte_alive`, `acolyte_detecting`, `acolyte_shots_fired`); scenarios
`m1_geode_mine` (feathered fire, calm mining; waits on `shards_live`, because Grubs may steal free
glass), `m1_charge_fire` (dry fire at 0, mine and collect, fly down, fire a Charge: it hits the
Sepulchre), `m1_charge_intercept` (collect, fire a Charge without flying down first, so
it is intercepted on the way (Grub or geode contact): `charges_lost` 1, no hit, no gutter; Composure 10 → 9.5, still `clear`), `m1_grub_procession` (mine glass, a Grub steals it and deposits
it at the Sepulchre; 4 Grubs alive), `m1_magnet_collect` (mine, then fly in and collect
glass), `m1_overfire` (held fire detonates a 3-face geode; it lines up with `move_up` and aims
with `mouse_move`), `m1_mouse_aim` (`mouse_move`, then asserts `facing_deg`, `aim_x`, `aim_y`; TECH-001 §9.1 "Mouse aim
and injected input")). `mouse_move` coordinates are logical 640×360 (the catalog wording "window coordinates" is a known
follow-up). Fixtures: `{"profile": "<name>"}` loads
`tests/fixtures/saves/<name>.json` into the in-memory save.

`a1_golden_path` is long (`timeout_frames` 150000, so outside the suite), profile `dev` (dev build only), `fail_on_errors`,
args `--segments=20 --hits=1` and `set_lives 9` per stage so the demo autopilot can finish Act 0 (it cannot
win a0_3 or a0_5 unaided): coin, Act 0, reveal, Unmaking, Ruins, sector. About 20600 frames. Listed in `LONG_SCENARIOS` in
`core/automation/tests/test_scenario_schema.gd` (every other shipped scenario must be suite-valid). Run it with `run a1_golden_path`
(`--windowed` for the seven stills).

The same runner runs inside GdUnit: `tests/test_scenarios.gd` plays every scenario that is valid for
the suite (`args == []`, `timeout_frames <= 1200`).

## Frame time, flash rule, settings coverage, the run-all report

```
node tools/automation/darkstar_auto.js run perf_golden_path --windowed --timeout=1500   # frame-time windows over the golden path
node tools/automation/darkstar_auto.js run a11y_flash_pass --windowed --timeout=2400    # flash rule with reduced motion + photosensitivity on
node tools/automation/darkstar_auto.js run ui_settings_capture --windowed               # every settings screen, captured
node tools/automation/darkstar_auto.js run-all --windowed --only=<substr> --report=<dir> # + <dir>/latest.md (Markdown summary)
```

- **Frame time.** `perf_begin{name}` / `perf_end{name, budget_ms?}` open and close a window; each process
  frame's wall-clock time goes in, and `result.perf_windows[]` gets frames, mean, p50, p95, p99, max (ms). Under
  `--fixed-fps 60` the engine does not sleep, so this is the frame's real cost (CPU and, windowed, GPU wait).
  `budget_ms` adds `p50_within_budget` (TECH-001 §8.1: median ≤ 8 ms at T2 on minimum spec); it is report
  only, because this machine is not minimum spec. Headless windows are CPU only.
- **Flash rule.** `luma_begin{name, target?}` / `luma_end{name, report_only?}` read back every drawn frame
  (`window` default, or `arcade`) and run `core/automation/luma_watch.gd`: an 8×6 grid of relative-luminance
  cells; a cell swing ≥ 0.10 with the darker side < 0.80 is a transition, two opposite transitions one cycle;
  more than 3 cycles in any 60 frames, or a whole-field mean step ≥ 0.10 in one frame, is a violation
  (WARP-001 L-11, ART-001 §7; thresholds ✱). `luma_end` fails on a violation unless `report_only`. Headless:
  skipped. The readback costs frame time, so do not trust a perf window that overlaps a luma window
  (`luma_active` marks it).
- **Robust to visual changes.** These scenarios wait on routes and probe states (`cabinet/game.state`,
  `sector/run.seam_index`), never on pixels or frame counts of an animation, so new looks for warp T1, the
  sector, the reveal or the ship do not break them. Only the flash rule looks at pixels, and that is the point.
- **Report.** `run-all --report=<dir>` writes `<dir>/automation_report-<stamp>.md` and `<dir>/latest.md`: one table
  of scenarios (outcome, exit, frames, wall time, ERROR/WARNING lines, screenshots, first failure), one of
  perf windows against their budget, one of flash-rule windows, and where the screenshots are.

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
  `killer_on_screen`, `shooter_id` (-1 none), `shooter_alive`, `shooter_on_screen`, `death_marks`, `death_outline`, `death_arrow` (0..1 chalk progress); `cabinet/world` includes `last_spawned_acolyte_id` (-1 none), `death_marks`, `entity_awake`, `entity_dx/dy`). `assert {id, exists:false}` works for gone entities.
- **New steps.** `snapshot{name}` writes `<out>/snapshots/<name>.json` (max 50 per run); `wait_event{event, within, count?}`
  waits for a probe event (the failure names the events seen); `perf_sample{}` appends to `result.perf` (max 200).
  Cabinet dev steps (dev profile only, refused in QA before frame 0): `set_stage`, `set_lives`, `teleport`, `spawn`
  (acolyte|geode|shard at Vigil + dx,dy), `shoot_vigil` (a hostile censer shot from Vigil + dx,dy aimed at the Vigil; optional `acolyte_id`, int ≥ 0 or "last" = the Acolyte last made by `spawn acolyte`, becomes the shot's shooter; omitted = no shooter; a dead or missing id is accepted, which stages "shooter gone"),
  `kill_all` (Acolytes, Grubs, hostile shots), `kill_acolyte{acolyte_id}` (int or "last"; kills just that Acolyte, leaves shots alone; fails if no live Acolyte has that id), `place_entity` (dx,dy, |v| ≤ 4000; entity must be awake), `wake_entity`
  (needs a non-Cold Sepulchre: every stage of the three-stage shift wakes (F-14); awake after about 4.2 s: wait on `cabinet/world entity_awake`), `pause_sim`, `step_sim` (needs paused_sim; steps ArcadeWorld only, not
  the CabinetGame state machine, so the death timer and respawn do not advance).
- **Stage scenarios.** `cabinet/game` has prop `stage_id` (`a0_3`..`a0_5` in the shift, `""` out of range). The scenarios keep their old stage numbers in the name (F-14: `a0_stage_0_first_vigil` and `a0_stage_1_drift` were removed with the retired stages):
  `a0_stage_2_censer_watch`, `a0_stage_3_shoal`, `a0_stage_4_stillwater` each go coin, New Vigil, play,
  `set_stage N`, still during READY, play, then assert `stage_index`, `stage_id` and the start-of-play geode / Grub /
  Acolyte counts (entity cold); stages 2-4 also `wake_entity`, wait `entity_awake`, still. Stills `stage_N_ready`,
  `stage_N_play`, `stage_N_window` (+ `stage_N_awake`), snapshot `stage_N`. 522 frames (stages 0-1), 779 (2-4). Acolyte
  `eq` asserts may need loosening when the P2 pressure switches land; the awake phase is not asserted.
- **Death scenarios.** `a0_death_marks_clear` (marks held through DEAD, cleared on respawn, `killer_kind` "none")
  and `a0_death_reduced_motion` (uses `set_setting`; chalk completes at once with Reduced Motion). Dev steps, so
  not run in QA exes.
- **Shooter scenarios.** `a0_acolyte_shot_death` (on-screen shooter), `a0_offview_killer` (shooter spawned off view; staged,
  since Acolytes never fire off-screen) and `a0_shooter_gone` (shooter killed with `kill_acolyte` after the shot is in
  flight). The spawned Acolyte wanders, so `shooter_on_screen` is asserted right after the Vigil dies.
- **Errors.** Every run captures engine errors and warnings into `result.errors[]`, `error_count`, `warning_count`.
  Scenario field `"fail_on_errors": true` fails the run on any error-type entry, except messages containing a
  string from `"allow_errors": [...]`.
- **result.json** also holds `snapshots[]`, `events[]` (last 256 `{frame,id,args}`) and `perf[]`.
- **Caps.** `-- --automation-caps --no-save --out=<dir>` writes `caps.json` (`format darkstar.caps`, steps with `dev`,
  comparators, screenshot targets, probe ids/events/dev ops, approved fixtures, build) and exits 0.
