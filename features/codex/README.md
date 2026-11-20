# features/codex

Codex (lore/knowledge system). Owner docs: LOOP-001 §8 (mechanics), §3.7 (gating map and backstops); NARR-001 §8 (prose).

Status: minimal knowledge record built (2026-11-19 overnight; TECH-001 §2.9, Q-T350..Q-T353). `codex_record.gd` (`CodexRecord`) holds the pure rules: stamp once (`cx_` ids only, never undone), read only stamped entries, the tier-1 gating ids from the Lantern Tree data, the tier-1 backstop check. The record itself lives in the profile (`ProfileState.codex_known`, `codex_read`, `runs_ended`); `RunSessionCore` stamps and reads, and the profile reaches disk only at its allowed reasons. Not built: discovery sources, the per-death backstop, the tier-t floor, the run summary and the Codex screen (Q-T351). Tests: `tests/test_codex_record.gd`.
