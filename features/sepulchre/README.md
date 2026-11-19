# features/sepulchre

The Sepulchre build altar and the entity's segments. Owner docs: GDD §8.4, SYS-001 §2, ZONES-001 §6.

Status (M1 slice 3 PR 4): phases 0 (Seed) and 1 (Procession) only; no ward, Litany Ring, Awakening or entity.
- `sepulchre.gd` / `.tscn` (`Sepulchre`, `SepulchreStats`): deposits → segment points (3 shards = 1 segment, 20 total, `is_complete()`), cue `segment_deposit` once per completed segment (every 3rd shard, as the Cabinet; TECH-001 Q-T113), not per deposit. HurtboxComponent on `world` with `bites = false` and no HealthComponent: a Null-Iron Charge hit knocks 1 segment off (cue `segment_knocked`, score 500); the lance leaves a chalk tick. `sepulchre_view.gd` (`SepulchreView`) draws it.
- `procession_sandbox.gd` (`ProcessionSandbox`, `ProcessionSandboxStats`): M1 sandbox layout (Sepulchre position, one route of 3 waypoints, 4 Grubs); places the Sepulchre under %Actors, registers it with the Ledger Compass (kind `sepulchre`, rank 0) and starts the `GrubProcession`.
- Data: `data/sepulchre/{sepulchre,procession_sandbox}.tres` (`ds_sepulchre.{sepulchre,sandbox}.*`). Tests in `tests/`.
