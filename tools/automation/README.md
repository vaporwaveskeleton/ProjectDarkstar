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
`charges_thrown`, `glass_carried`). Fixtures: `{"profile": "<name>"}` loads
`tests/fixtures/saves/<name>.json` into the in-memory save.

The same runner runs inside GdUnit: `tests/test_scenarios.gd` plays every scenario that is valid for
the suite (`args == []`, `timeout_frames <= 1200`).
