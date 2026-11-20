class_name Neighbourhood
extends RefCounted
## The Vigil's neighbourhood (SYS-001 §1.7, TECH-001 §2.10): the field is 65,536 px square, but the
## free units live in a (2 × half)² box centred on the Vigil (half = CabinetTuning.field_neighbourhood_half_px).
## Once per sim tick, after the units have moved, every free object whose torus offset from the Vigil
## exceeds `half` on an axis re-enters on the opposite edge of the box (a local wrap round the Vigil:
## a shift of 2 × half on that axis). It is never placed inside the view: if it would land there it is
## pushed to just outside the view edge.
## Free = geodes, loose glass (not carried), Grubs not carrying, Acolytes that neither escort nor guard.
## Never moved: laden Grubs, their escorts, guard Acolytes, the Sepulchre and the awake entity.
## Owned by ArcadeWorld; holds no state of its own.

var world: ArcadeWorld


func _init(p_world: ArcadeWorld) -> void:
	world = p_world


func half() -> float:
	return world.tuning.field_neighbourhood_half_px


## Local wrap of one axis of an offset from the Vigil into [-half, half).
static func wrap_axis(d: float, half_px: float) -> float:
	return fposmod(d + half_px, 2.0 * half_px) - half_px


## `p` re-seated inside the box round the Vigil and outside the view (grown by `margin`). Returns `p`
## unchanged (same value) when it already lies inside the box. Pure: the callers apply the result.
func reseat(p: Vector2, margin: float) -> Vector2:
	var v := world.vigil.pos
	var d := world.torus.delta(v, p)
	var h := half()
	if absf(d.x) <= h and absf(d.y) <= h:
		return p
	var nd := Vector2(wrap_axis(d.x, h), wrap_axis(d.y, h))
	var vh := world.view_size * 0.5 + Vector2(margin, margin)
	if absf(nd.x) < vh.x and absf(nd.y) < vh.y:
		# would land in view: push out along the axis that is cheaper to leave by
		if vh.x - absf(nd.x) <= vh.y - absf(nd.y):
			nd.x = (1.0 if nd.x >= 0.0 else -1.0) * (vh.x + 1.0)
		else:
			nd.y = (1.0 if nd.y >= 0.0 else -1.0) * (vh.y + 1.0)
	return world.torus.wrap(v + nd)


## Is `p` outside the box round the Vigil?
func outside(p: Vector2) -> bool:
	var d := world.torus.delta(world.vigil.pos, p)
	var h := half()
	return absf(d.x) > h or absf(d.y) > h


## One pass over every free object. Run once per sim tick after the layers have ticked.
func step() -> void:
	var t := world.tuning
	for g in world.geodes.items:
		if g.alive and outside(g.pos):
			g.pos = reseat(g.pos, g.radius + GeodeField.DRAW_MARGIN)
	for s in world.glass.shards:
		if s.alive and not s.carried and outside(s.pos):
			s.pos = reseat(s.pos, t.size_shard_px)
			world.grubs.release_shard(s)
	for gr in world.grubs.items:
		if gr.alive and not gr.carrying and outside(gr.pos):
			gr.pos = reseat(gr.pos, t.size_grub_px)
			world.grubs.release_claim(gr)
	for a in world.acolytes.items:
		if a.alive and not a.guard and not a.escorting and outside(a.pos):
			a.pos = reseat(a.pos, t.size_acolyte_px)


## A random point inside the box round the Vigil and outside the view (spawns: initial geodes, Grubs and
## Acolytes, drift-in geodes, censer-bell reinforcements, Grub respawns). At least `clear` px from `avoid`.
## Uses world.rng. Falls back to the last candidate after a bounded number of tries.
func random_spot(margin: float, avoid: Vector2 = Vector2(-99999.0, -99999.0), clear: float = 0.0) -> Vector2:
	var h := half()
	var v := world.vigil.pos
	var vh := world.view_size * 0.5 + Vector2(margin, margin)
	var p := v
	for i in 30:
		var d := Vector2(world.rng.randf_range(-h, h), world.rng.randf_range(-h, h))
		p = world.torus.wrap(v + d)
		if (absf(d.x) >= vh.x or absf(d.y) >= vh.y) and world.torus.distance(p, avoid) >= clear:
			return p
	# bound hit: force the point out of view along x
	var d2 := Vector2(world.rng.randf_range(vh.x + 1.0, h), world.rng.randf_range(-h, h))
	return world.torus.wrap(v + d2)
