# features/charges

Null-Iron Charges and Mourning Glass handling. Owner docs: GDD §8.2–8.3, SYS-001 §1.3–1.4, TECH-001 §4.3.

Status (M1 slice 3 PR 3): geodes, over-fire detonation, Mourning Glass shards and the Vigil's magnet.
- `sector_geode.gd` / `.tscn` (`SectorGeode`): HurtboxComponent (`world` layer) + HealthComponent; calm mining and over-fire. Named `SectorGeode` because the Cabinet already has an inner class `GeodeField.Geode`.
- `geode_sandbox.gd` (`GeodeSandbox`): the M1 sandbox layout, seeded (`map` / `loot` / `vfx` streams).
- `shard_field.gd` / `.tscn` (`ShardField`): struct-of-arrays shard pool, 64 px torus grid, magnet, Grub query hook, one MultiMesh.
- `charge_magazine.gd` (`ChargeMagazine`): Charge pips to the cap. Firing Charges is not built (PR 4).
- Data: `data/charges/{geode,geode_sandbox,shard_field,charge_magazine}.tres` (`ds_charges.*`).
- Tests in `tests/`; benchmark `tests/perf/bench_shard_field.tscn`.
