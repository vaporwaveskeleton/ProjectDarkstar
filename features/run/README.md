# features/run

Run, Iteration and profile Ember state behind the `RunSession` autoload. Owner docs: LOOP-001 §2; contract TECH-001 §4.2a.

Status: built (M2 PR 1, 2026-11-19): `RunSessionCore` (all rules, injected stats + saver), `RunState`, `IterationState`, `ProfileState`, `SeamReport`, `RunPayload` (typed payload reads), `RunSessionStats` (`data/run/run_session.tres`, `ds_run.session.*`). Run Sigils, Relics and Pacts are fields only; no content yet.

As built (full list: TECH-001 §4.2a):
- `RunState.seed_value` (payload key `seed`) avoids shadowing the built-in `seed()`.
- `arrive_at_ruins` reloads the profile and merges: Cabinet/attract keys from disk, `ember_banked` and `act0_banked` from memory.
- `ProfileState` keeps other writers' plain values in `extra`; an unreadable profile on disk is never overwritten.
- Act 0 bank is `max(floor(VI / 200), 40)` (Q-T146). Abandon banks in-run Ember like a death (Q-T152 (a), ruled yes 2026-11-19 overnight).
- `RunState.composure < 0` = not set; a new run keeps the sector's `ComposureStats` start.
- The clock ticks on unscaled delta; it pauses on `SceneRouter.is_busy`, the pause menu and `SceneTree.paused`, and is off on `clock_free_routes` (attract, cabinet).
- Callers (2026-11-19, golden path): the Ruins' `launch()` (`scenes/ruins/ruins.gd`, called when the pilot lamp walks into the lit hangar mouth; LOOP-001 §10.5) calls `start_run` (if no run is active), then `enter_seam`, then routes to `&"sector"`; the sector stub's throwaway core stays the dev path.
- A ninth sky ends the run and Iteration and banks nothing (`TODO(Q-T143)`).
- Back door (2026-11-19 overnight, Q-T276, Q-T277): `at_frontier()` / `return_from_frontier(report)` end the run `returned` at the slice frontier (`slice_last_seam`, proposed 1; one `run_end` write set); `abandon_from_seam()` is the sector pause's mid-Seam Abandon Run at the death price. Every run end routes to the Ruins (the sector's job, TECH-001 §2.1).
