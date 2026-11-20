# features/warp

Warp Tiers T0–T5 and WarpComposer (TECH-001 §5.1, §5.1a). Owner docs: WARP-001.

Status: **slice T1 set built** (2026-11-19, Q-T100 set): `WarpComposer` (one per sector), `WarpSet` /
`WarpEffect` data (`data/warp/t1_frayed.tres`), `WarpTier` + `WarpTierStats` (WARP-001 §1.3,
`data/warp/warp_tier.tres`), `WarpSchedule` (seeded `warp` stream), `WarpTeeth` (W1-05),
`WarpChantSign` (W1-07/W1-08 visual chant indicators). Shaders in `shaders/warp/`. HUD deviations go
through `features/hud/hud_liar.gd` (Smear, Glyph; no Lie class yet).

Tests: `tests/test_warp_tier.gd`, `tests/test_warp_composer.gd`. Captures: scenario
`tests/scenarios/warp_t1_capture.scenario.json` (dev, `--warp-showcase`).

Not built: T2+ sets, the Passing, eaten rules, lies (M5), measured costs (Q-T204).
