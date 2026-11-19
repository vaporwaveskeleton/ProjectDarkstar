# features/hud

DiegeticHud and Steady Ledger pinning (TECH-001 §5.2–§5.3), and the Ledger Compass (TECH-001 §5.4). Owner docs: WARP-001 §4.

Status: Ledger Compass built beyond the stub (2026-11-19; TECH-001 §5.4):
- `ledger_compass.gd` (`LedgerCompass`): the 64 × 64 module (ART-001 §12.5, Q-T120), top-centre. Samples the world into a `HudModel` every frame and draws only `HudModel.presented()`. `HONEST` stays true; no lie logic here.
- `ledger_compass_static.gd` (`LedgerCompassStatic`): brass bezel, VOID-1 face, chalk ticks, the sector cell with its map grid, the sector list, the empty entity marker frame. Redraws only when invalidated, at most `redraw_hz` (10 ✱); otherwise the canvas replays its recorded commands.
- `ledger_compass_markers.gd` (`LedgerCompassMarkers`): one dot per marker, redrawn every frame.
- `ledger_compass_layout.gd` (`LedgerCompassLayout`): pure geometry on the 4 px sub-grid.
- `hud_model.gd` (`HudModel`): the compass slice of the HUD model; the honesty seam (`presented()`, `lie_hook()`), honest under Steady Ledger and, since `HudLiar` is not built, always.
- `ledger_compass_stats.gd` (`LedgerCompassStats`): data in `data/hud/ledger_compass.tres`, `ds_hud.compass.*`.
- `composure_wick.gd` (`ComposureWick`): the Composure wick, 64 × 16, bottom-right of the sector `Hud`, always honest; the flame height steps by Composure band only, four heights (Q-T119). Data `composure_wick_stats.gd` (`ComposureWickStats`), `data/hud/composure_wick.tres`, `ds_hud.wick.*`.

Stubs and gaps: the sector list is a **one-cell stub** (no doc specifies its fields yet). The entity marker frame is drawn and empty (no entity in M1). `HudLiar`, `HudView`, the corruption layer and H16 are not built.

Tests in `tests/`; bench `tests/perf/bench_ledger_compass.tscn`. Follow docs/04-production/ADDING_A_FEATURE.md before adding code.
