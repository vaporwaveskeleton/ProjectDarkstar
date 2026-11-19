# features/arc_lance

The Vigil's gun (Arc-Lance). Owner docs: GDD §4, SYS-001 §1.3, TECH-001 §2.9 and §3.4.

Status: M1 slice 1 (base fire) and slice 3 PR 2 (Lance bite) built. Hits use `Area2D` overlap, not ShapeCast.

- `arc_lance_stats.gd` (`ArcLanceStats`): tunables, `ds_arc_lance.*`, data in `data/arc_lance/arc_lance.tres`.
- `lance_projectile.gd` / `.tscn` (`LanceProjectile`): one bolt; speed, lifetime, hits per projectile; `can_bite(target)` skips damage on a hurtbox with `bites = false` (the shot is still used up).
- `arc_lance_emitter.gd` (`ArcLanceEmitter`): fire rate, muzzle offset; sets `last_shot`, then emits `lance_fired` / `lance_hit` (EVT-001).
- `arc_lance_fx_stats.gd` (`ArcLanceFxStats`): the nine Lance-bite tunables, `ds_arc_lance.fx.*`, data in `data/arc_lance/arc_lance_fx.tres` (values: SYS-001 §9 Lance-bite rows).
- `arc_lance_fx.gd` (`ArcLanceFx`): top-level world-space effects on the Vigil (`%ArcLanceFx`): muzzle star on `lance_fired`; flecks on a bite, or a chalk tick + `lance_dull` on a non-biting hurtbox. Deterministic, no RNG.
- `lance_recoil.gd` (`LanceRecoil`): visual-only nudge of `Facing/Visual` (`%LanceRecoil`); never moves body, velocity or Facing; off under reduced_motion.
- `tests/test_arc_lance.gd`.
- `tests/test_lance_bite.gd` (12 cases; not the Cabinet suite of the same file name).

Not built yet: over-fire detonation, pierce and chain upgrades.
