# features/hud

DiegeticHud and Steady Ledger pinning (TECH-001 §5.2–§5.3), and the Ledger Compass (TECH-001 §5.4). Owner docs: WARP-001 §4.

Status: Ledger Compass stub built (M1 slice 3 PR 1): `ledger_compass.gd` (`LedgerCompass`, always honest, no lie logic) and `ledger_compass_stats.gd` (`LedgerCompassStats`, data in `data/hud/ledger_compass.tres`, `ds_hud.compass.*`). Tests in `tests/`. Composure wick built (M1, Q-T119): `composure_wick.gd` (`ComposureWick`, 64 × 16, bottom-right of the sector `Hud`, always honest; the flame height steps by Composure band only, four heights) and `composure_wick_stats.gd` (`ComposureWickStats`, `data/hud/composure_wick.tres`, `ds_hud.wick.*`). `HudModel`, `HudLiar`, `HudView` are not built. Follow docs/04-production/ADDING_A_FEATURE.md before adding code.
