# features/choir

The Hollow Choir units (CompositeRig, TECH-001 §2.4). Owner docs: GDD §8.5, SYS-001 §3–§4, ART-002 §5.

Status (M1 slice 3 PR 4): Oubliette Grubs only, no CompositeRig/Brain yet (runtime vector art).
- `oubliette_grub.gd` / `.tscn` (`OublietteGrub`, `GrubStats`): seek (ShardField hooks, one query per 6 ticks, offset by spawn index), steal (`ShardField.take`, cue `grub_steal`), carry along the procession route (join at the nearest waypoint) and deposit at the Sepulchre; flee the Vigil's lantern unless carrying (devotion beats fear, TECH-001 Q-T112). Plain state machine (seek, carry, flee, idle orbit); a Brain/CompositeRig comes later (TECH-001 §4.7). Biting HurtboxComponent on `choir_hurtbox` + HealthComponent (HP 4). Death plays `grub_die`; a carrying Grub also drops its shard back into the field and keens (`grub_keen`, only then). `grub_view.gd` (`GrubView`) draws it in Choir hue.
- `grub_procession.gd` (`GrubProcession`): spawns the Grubs under %Actors on a ring round the Sepulchre, counts kills (score 150), respawns at the Sepulchre after 6.0 s; registers each with the Ledger Compass (kind `grub`).
- Data: `data/choir/grub.tres` (`ds_choir.grub.*`). Tests in `tests/`; scenario `m1_grub_procession`.
