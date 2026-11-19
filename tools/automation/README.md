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
`camera_x`, `compass_markers`, `camera_gap`, `facing_deg`, `aim_x`, `aim_y`; scenario `m1_sector_feel`),
`sector/field` (`geodes_alive`, `geodes_detonated`, `shards_free`, `charges`, `score`; scenarios
`m1_geode_mine` (feathered fire, calm mining), `m1_magnet_collect` (mine, then fly in and collect
glass), `m1_overfire` (held fire detonates a 3-face geode; it lines up with `move_up` and aims
with `mouse_move`), `m1_mouse_aim` (`mouse_move`, then asserts `facing_deg`, `aim_x`, `aim_y`; TECH-001 §9.1 "Mouse aim
and injected input")). `mouse_move` coordinates are logical 640×360 (the catalog wording "window coordinates" is a known
follow-up). Fixtures: `{"profile": "<name>"}` loads
`tests/fixtures/saves/<name>.json` into the in-memory save.

The same runner runs inside GdUnit: `tests/test_scenarios.gd` plays every scenario that is valid for
the suite (`args == []`, `timeout_frames <= 1200`).
