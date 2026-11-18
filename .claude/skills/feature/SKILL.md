---
name: feature
description: Build a DARKSTAR feature or code change end to end with the project agents - doc-scout fetches the numbers and names, godot-builder writes code and tests, test-runner verifies, doc-keeper updates docs, then the CLAUDE.md §6 report. Use when asked to add, build or change a gameplay feature, scene, component or Resource.
---

# /feature — the DARKSTAR build sequence

Subagents cannot start other agents, so the main session runs every step below itself. Keep the main session thin: it plans, delegates and reviews diffs; it never reads whole design docs or full test logs.

## 1. Scope (main session)
- Restate the task in one or two lines. Pick the feature folder from the glossary names in `CLAUDE.md` §2 (TECH-001 §2.9).
- Check `docs/04-production/ADDING_A_FEATURE.md` via `doc-scout` if the task adds a new feature folder, signal, autoload or tunable.
- If it needs a new boundary, autoload, or resolves a doc conflict: stop and use `architect` (pass it excerpts) before any code.

## 2. Fetch facts — `doc-scout` (haiku)
One call, listing everything the build needs:
- every number from SYS-001 (by section), every name from GDD §19,
- the owning TECH-001 section(s) (scene tree, data layout, `ds_` keys, signals in EVT-001, UI rules in UI-001),
- any WARP-001 / LOOP-001 / ZONES-001 / ART-001 / AUDIO-001 section the task cites.
If a number is missing, stop and ask the user. Never invent one.

## 3. Build — `godot-builder` (sonnet)
Pass in the prompt: the task, the feature folder, and **the doc-scout excerpts verbatim** (numbers and names exactly as returned). Ask it to report files changed, tests added, and what `doc-keeper` must update. For several independent features, one builder call per feature.

## 4. Verify — `test-runner` (haiku)
Run it after the builder returns. On failure, send the failing test lines back to `godot-builder` (same feature) and repeat 3–4 until green. For a player-visible change, also capture it with the Act 0 switches (`--autopilot ... --no-save`) and look at the frame before calling it done.

## 5. Docs — `doc-keeper` (sonnet)
Pass the changed-file list, any decisions (date, decision, who decided), and the builder's "docs to update" list.

## 6. Report (CLAUDE.md §6)
List every file created or changed, every doc updated, every command run with its result, and anything not verified. Never claim a test or number that did not run.
