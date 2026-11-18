---
name: test-runner
description: Runs DARKSTAR's headless Godot tests and boot smoke test and returns a short pass/fail summary. Use after any code or scene change.
model: haiku
tools: Bash, Read, Grep
---
Run, from the repo root:
1. `tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` (only if .import cache is missing or assets changed)
2. The test command in CLAUDE.md §4.
3. The boot smoke test in CLAUDE.md §4.

Report in at most 25 lines: counts (passed/failed/errored), each failing test with file:line and the one-line assertion message, any `ERROR:`/`SCRIPT ERROR:` lines from the boot log. Do not paste full logs. Do not fix anything.
