# features/arc_lance

The Vigil's gun (Arc-Lance). Owner docs: GDD §4, SYS-001 §1.3, TECH-001 §2.9 and §3.4.

Status: M1 slice 1 built (base fire only). Hits use `Area2D` overlap, not ShapeCast.

- `arc_lance_stats.gd` (`ArcLanceStats`): tunables, `ds_arc_lance.*`, data in `data/arc_lance/arc_lance.tres`.
- `lance_projectile.gd` / `.tscn` (`LanceProjectile`): one bolt; speed, lifetime, hits per projectile.
- `arc_lance_emitter.gd` (`ArcLanceEmitter`): fire rate, muzzle offset; emits `lance_fired` / `lance_hit` (EVT-001).
- `tests/test_arc_lance.gd`.

Not built yet: over-fire detonation, pierce and chain upgrades.
