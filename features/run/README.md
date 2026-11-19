# features/run

Run, Iteration and profile Ember state behind the `RunSession` autoload. Owner docs: LOOP-001 §2; contract TECH-001 §4.2a.

Status: built (M2 PR 1): `RunSessionCore` (all rules, injected stats + saver), `RunState`, `IterationState`, `ProfileState`, `SeamReport`, `RunPayload` (typed payload reads), `RunSessionStats` (`data/run/run_session.tres`, `ds_run.session.*`). Run Sigils, Relics and Pacts are fields only; no content yet.
