# features/charges

Null-Iron Charges and Mourning Glass handling. Owner docs: GDD §8.2–8.3, SYS-001 §1.3–1.4, TECH-001 §2.6, §4.1, §4.3.

Status (M1 slice 3 PR 3): geodes, over-fire detonation, Mourning Glass shards and the Vigil's magnet. All mounted in `scenes/sector/sector_stub.tscn`, which injects the sector `Torus`.
- `sector_geode.gd` / `.tscn` (`SectorGeode`, `GeodeStats`): a HurtboxComponent on the `world` layer (biting) + HealthComponent; calm mining and over-fire. No `StaticBody2D`, so the Vigil flies through geodes (TECH-001 §2.6, Q-T76). Named `SectorGeode` because the Cabinet already has an inner class `GeodeField.Geode`.
- `geode_sandbox.gd` (`GeodeSandbox`, `GeodeSandboxStats`): the M1 sandbox layout, seeded (`map` / `loot` / `vfx` streams); registers geodes with the `LedgerCompass`; each tick moves geodes to the image nearest the Vigil (physics priority 1, after `SectorWrap`).
- `shard_field.gd` / `.tscn` (`ShardField`, `ShardFieldStats`): struct-of-arrays shard pool (no node per shard), 64 px torus grid, magnet (no drag inside the radius; off when the magazine is full), H4 flag `magnet_inverted`, Grub query hooks, one MultiMesh, physics priority 30. A full pool refuses spawns (`spawns_refused`), never recycles.
- `charge_magazine.gd` (`ChargeMagazine`, `ChargeMagazineStats`): Charge pips to the cap; cues `charge_armed` per gain, `magazine_full` on reaching the cap. Firing Charges is not built (PR 4).
- Data: `data/charges/{geode,geode_sandbox,shard_field,charge_magazine}.tres` (`ds_charges.{geode,sandbox,shards,magazine}.*`, TECH-001 §3.4). Values come from SYS-001; never edit numbers in the scripts.
- Tests in `tests/`; benchmark `tests/perf/bench_shard_field.tscn` (TECH-001 §8.3, §8.5). Automation probe `sector/field` and scenarios `m1_geode_mine`, `m1_magnet_collect`, `m1_overfire` (TECH-001 §9.1).
