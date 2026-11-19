# Adding a Feature to DARKSTAR

**Owner:** production · **Date:** 2026-11-17 · Checklist only. Every rule links to its owner doc.

## 0. Before code
- [ ] Name it with the GDD §19 glossary word. The folder is `features/<snake_name>/` (TECH-001 §2.9 lists the existing folders).
- [ ] Find every number it needs in SYS-001. A missing number means stop and ask, never invent one (CLAUDE.md §1).
- [ ] If it needs a new boundary (autoload, new layer, new route, new save slot), write the TECH-001 section or row first.

## 1. Folder
```
features/<feature>/
  <feature>.tscn            root scene (thin root script that wires components)
  <feature>.gd
  <thing>_component.gd      one responsibility per script
  <feature>_stats.gd        TunableResource subclass (if it has tunables)
  tests/test_<thing>.gd     GdUnit4 suites
data/<feature>/<name>.tres  the tunable values (TECH-001 §3)
```

## 2. Scenes and scripts
- [ ] Composition: reuse `core/components` (`HealthComponent`, `HurtboxComponent`, `HitboxComponent`) before writing new ones.
- [ ] No hard-coded node paths: `%UniqueName` inside the scene, `@export` across scenes, groups for "all of a kind". No `get_node("../..")`.
- [ ] Collision: primitive shapes on `PhysicsLayers` layers (TECH-001 §2.6), sized from data. Animation never owns hit truth.
- [ ] Movement and hit logic run in `_physics_process`. Keep the maths in a static pure function so it can be unit-tested (see `VigilMotor.step_velocity`).

## 3. Data
- [ ] Subclass `TunableResource`; list the properties in `tunable_properties()`.
- [ ] In the `.tres`, set `ds_namespace = "ds_<feature>.<group>"` and `source_section = "SYS-001 §x"`. Comment each property with its SYS-001 row and 🔒/⚙/✱.
- [ ] Add the keys to TECH-001 §3.4 and to `REQUIRED_KEYS` in `core/data/tests/test_tunable_registry.gd` if code depends on them.

## 4. Signals
- [ ] Past tense, typed payload, ids not text. Add a row to EVT-001 §2.

## 5. UI and text
- [ ] Every visible string is a key in `locale/en.po` with a context note when the meaning is not obvious (L10N-001 §3).
- [ ] New screens follow UI-001 §8.
- [ ] UI control or entity worth testing: unique `%Name` / automation id (TECH-001 §9.1). New feature with state worth testing: a probe in `features/<f>/automation/` (TECH-001 §9.1).
- [ ] Colours come from the palette (ART-001 §4); the palette test must stay green.

## 6. Saves
- [ ] Persisted state goes through `SaveService` with an allowed reason (TECH-001 §7.2). Never save mid-run. Ids only.

## 7. Tests and done
- [ ] Unit tests for the rules, plus a scene test if it has input or UI.
- [ ] Run the commands in TECH-001 §9: all tests pass, and the boot smoke prints `BOOT_SMOKE` with no `ERROR` lines.
- [ ] Update the docs that own the change (TECH-001 row status, EVT-001, L10N-001, UI-001). Update `CLAUDE.md` if a rule or command changed.
- [ ] The final report lists every file and doc touched, every command run with its result, and what was not verified.

## Troubleshooting
| Symptom | Likely cause |
|---|---|
| `Parse Error: … inferred from a Variant value` | `:=` on a `Dictionary`/`Array` element. Give the variable an explicit type |
| New `class_name` not found in tests | run `--import` once so the class cache is rebuilt |
| UI test replaces the test runner | install `FakeRouteHost` (see `scenes/tests/test_attract_mode.gd`) before triggering `SceneRouter` |
| Tree stays paused after a test | clear `get_tree().paused` in `after_test` |
