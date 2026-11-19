# features/composure

Composure, the sanity resource (GDD §8.6). Owner docs: SYS-001 §1.5 (every number), WARP-001 §4.1–§4.2 (cockpit flame, L10), TECH-001 §2.9, §3.4.

Status: built for M1 (Q-T118, Q-T119; PM under owner autonomy grant 2026-11-19).

| File | What |
|---|---|
| `composure.gd` | `Composure` node: 0–10, starts at 10 (Clear), clamped, no passive regen. The full SYS-001 §1.5 event API (gaze cone, gaze drain T3+, chant radius, warp passive × T, Charge lost / spent, death at run start with 60 s recovery, Surgelight from T2 capped at 2/s, Shrine, Matron, procession let pass, darkness after 5 s capped at +2, Codex full restore, Clear Eyed). Bands via `band_for` (Clear ≥ 7, Frayed ≥ 4, Unmoored > 0, Hollowed = 0). Requests E01/E02/E03 on entering a worse band and E04 on recovery (cue ids `wick_frayed`, `wick_unmoored`, `wick_hollowed`, `wick_recovery`; not in `data/audio/cue_ids.tres` yet, so silent no-ops) |
| `composure_stats.gd` | `ComposureStats` (`ds_composure.*`, `data/composure/composure.tres`) |
| `cockpit_flame.gd` | `CockpitFlame` on the Vigil (`%CockpitFlame` under `Facing/Visual`): band by shape only (steady, flickering, guttering, hollow), one PHOS-4 colour, deterministic time phase ≤ 3 Hz, frozen under reduced motion |
| `cockpit_flame_stats.gd` | `CockpitFlameStats` (`ds_composure.flame.*`, `data/composure/cockpit_flame.tres`, all ✱) |

The HUD wick lives in `features/hud/composure_wick.gd` (Q-T119).

**Scope.** Sector-scoped for M1: one `%Composure` node in `SectorStub`; it moves to `RunSession` (TECH-001 §2.8) when that is built. Wired sources today: a Charge lost to an interceptor (−0.5, from `ChargeLauncher.prune`) and a Charge on target (Δ 0). Every other row is API only and inert in the sandbox (no entity, chant, Warp Tier, Surgelight, Shrine, Matron, Codex or death-at-run-start source yet). Band effects (false cues, phantom Grubs, axis inversion, +1 tier) are not built: the bands are display only. Readers poll `value` / `band`; there are no signals.

Tests: `tests/test_composure.gd`, `tests/test_cockpit_flame.gd`.
