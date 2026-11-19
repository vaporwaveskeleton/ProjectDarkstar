# features/hud

DiegeticHud and Steady Ledger pinning (TECH-001 §5.2–§5.3), and the Ledger Compass (TECH-001 §5.4). Owner docs: WARP-001 §4.

Status: Ledger Compass stub built (M1 slice 3 PR 1): `ledger_compass.gd` (`LedgerCompass`, always honest, no lie logic) and `ledger_compass_stats.gd` (`LedgerCompassStats`, data in `data/hud/ledger_compass.tres`, `ds_hud.compass.*`). Tests in `tests/`. `HudModel`, `HudLiar`, `HudView` are not built. Follow docs/04-production/ADDING_A_FEATURE.md before adding code.
