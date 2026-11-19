# features/choir

The Hollow Choir units (CompositeRig, TECH-001 §2.4). Owner docs: GDD §8.5, SYS-001 §3–§4, ART-002 §5.

Status (M1 slice 3 PR 4): Oubliette Grubs only, no CompositeRig/Brain yet (runtime vector art).
- `oubliette_grub.gd` / `.tscn` (`OublietteGrub`, `GrubStats`): seek (ShardField hooks, one query per 6 ticks, offset by spawn index), steal (`ShardField.take`, cue `grub_steal`), carry along the procession route (join at the nearest waypoint) and deposit at the Sepulchre; flee the Vigil's lantern unless carrying. Biting HurtboxComponent on `choir_hurtbox` + HealthComponent (HP 4). Death drops a carried shard and keens (`grub_keen`), `grub_die`. `grub_view.gd` (`GrubView`) draws it in Choir hue.
- `grub_procession.gd` (`GrubProcession`): spawns the Grubs under %Actors on a ring round the Sepulchre, counts kills (score 150), respawns at the Sepulchre after 6.0 s; registers each with the Ledger Compass (kind `grub`).
- Data: `data/choir/grub.tres` (`ds_choir.grub.*`). Tests in `tests/`; scenario `m1_grub_procession`.
