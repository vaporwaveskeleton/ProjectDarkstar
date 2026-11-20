class_name GeodeField
extends ArcadeLayer
## Geodes: drifting rock full of Mourning Glass (GDD §8.2, SYS-001 §1.3).
## Calm mining: every `face_hits` lance hits shatters one face and frees one shard; the last face
## frees the rest (calm total = shards_calm, +1 because it was mined). Over-fire: `overfire_hits`
## hits inside `overfire_window` detonates the geode and scatters 4–6 shards far — the Grubs win
## that race. That is the skill expression: calm fire vs confetti for the Choir.

class Geode:
	var pos: Vector2
	var vel: Vector2
	var rot: float
	var spin: float
	var radius: float
	var faces: int
	var faces_left: int
	var hits_on_face: int = 0
	var recent: Array[float] = []      ## times of recent hits (over-fire window)
	var shape: PackedVector2Array
	var glints: PackedVector2Array
	var flash: float = 0.0
	var shards_freed: int = 0
	var alive: bool = true

const DRAW_MARGIN := 4.0                              ## px a geode's glow reaches past its radius (_draw cull)
const DRIFT_TRIES := 30                               ## placement attempts per drift-in tick (search bound, like random_point's)

var items: Array[Geode] = []
var _drift_clock := 0.0               ## P2 drift-in: sim s spent below the floor since the last arrival


func reset() -> void:
	items.clear()
	_drift_clock = 0.0
	for i in world.stage.geodes:
		var size_class := world.rng.randi_range(0, 2)
		add_geode(world.neighbourhood.random_spot(size_radius(size_class) + DRAW_MARGIN), size_class)


## Radius in px of size class 0..2 (CabinetTuning.size_geode_radii, SYS-001 §1.7).
func size_radius(size_class: int) -> float:
	return world.tuning.size_geode_radii[clampi(size_class, 0, world.tuning.size_geode_radii.size() - 1)]


func add_geode(at: Vector2, size_class: int) -> Geode:
	var g := Geode.new()
	g.pos = at
	var a := world.rng.randf() * TAU
	g.vel = Vector2.from_angle(a) * world.rng.randf_range(4.0, 14.0)
	g.rot = world.rng.randf() * TAU
	g.spin = world.rng.randf_range(-0.4, 0.4)
	g.faces = size_class + 1
	g.faces_left = g.faces
	g.radius = size_radius(size_class)
	var n := 8 + size_class * 2
	for k in n:
		var ang := TAU * k / n
		g.shape.append(Vector2.from_angle(ang) * g.radius * world.rng.randf_range(0.72, 1.0))
	for k in 2 + size_class * 2:
		g.glints.append(Vector2.from_angle(world.rng.randf() * TAU) * g.radius * world.rng.randf_range(0.1, 0.55))
	items.append(g)
	return g


func tick(delta: float) -> void:
	for g in items:
		g.pos = world.torus.wrap(g.pos + g.vel * delta)
		g.rot += g.spin * delta
		g.flash = maxf(0.0, g.flash - delta * 4.0)
	items.assign(items.filter(func(g: Geode) -> bool: return g.alive))
	_tick_drift(delta)


## P2 drift-in (CabinetStage.geode_drift_s; 0 = off): once fewer than floor(geodes × geode_drift_floor)
## remain, one new geode drifts in off-view every geode_drift_s of sim time. Never above stage.geodes.
func _tick_drift(delta: float) -> void:
	var st := world.stage
	if st.geode_drift_s <= 0.0:
		return
	if items.size() >= mini(st.geodes, floori(st.geodes * world.tuning.geode_drift_floor)):
		_drift_clock = 0.0
		return
	_drift_clock += delta
	if _drift_clock >= st.geode_drift_s and drift_in() != null:
		_drift_clock = 0.0


## One geode placed like the stage's own (random point, random size class, world.rng), at least
## geode_drift_clear_px from the Vigil and wholly outside the view. Null if no spot was found this
## time (the caller tries again next tick).
func drift_in() -> Geode:
	var size_class := world.rng.randi_range(0, 2)
	var margin := size_radius(size_class) + DRAW_MARGIN
	for i in DRIFT_TRIES:
		var p := world.neighbourhood.random_spot(margin, world.vigil.pos, world.tuning.geode_drift_clear_px)
		if world.torus.distance(p, world.vigil.pos) >= world.tuning.geode_drift_clear_px and not world.on_screen(p, margin):
			return add_geode(p, size_class)
	return null


## The first live geode overlapping a circle, or null.
func hit_test(p: Vector2, r: float) -> Geode:
	for g in items:
		if g.alive and world.torus.distance_sq(p, g.pos) <= (g.radius + r) * (g.radius + r):
			return g
	return null


## A lance bolt struck `g`. Returns true when the geode is gone.
func lance_hit(g: Geode, by_player: bool = true) -> bool:
	var t := world.tuning
	if by_player:
		world.award(t.score_face, g.pos)
	if by_player or world.on_screen(g.pos, 0.0):
		world.sfx(&"geode_hit", -6.0)
	g.flash = 1.0
	g.recent.append(world.time)
	g.recent.assign(g.recent.filter(func(x: float) -> bool: return world.time - x <= t.overfire_window))
	if g.recent.size() >= t.overfire_hits:
		detonate(g, by_player)
		return true
	g.hits_on_face += 1
	if g.hits_on_face >= t.face_hits:
		g.hits_on_face = 0
		g.faces_left -= 1
		if g.faces_left <= 0:
			# calm kill: free what is left of the calm total, +1 for mining it (SYS-001 §1.3)
			var remaining := maxi(1, t.shards_calm + 1 - g.shards_freed)
			_free_shards(g, remaining, g.radius + 10.0, 40.0, by_player)
			_break(g, false)
			return true
		_free_shards(g, 1, g.radius + 6.0, 30.0, by_player)
		world.sfx(&"geode_hit", 0.0)
	return false


func detonate(g: Geode, by_player: bool = true) -> void:
	var t := world.tuning
	# 4–6 is the geode's total (SYS-001 §1.3): glass already freed by mining counts toward it
	var n := world.rng.randi_range(t.shards_detonated_min, t.shards_detonated_max) - g.shards_freed
	_free_shards(g, maxi(1, n), t.detonation_scatter * 0.35, t.detonation_scatter, by_player)
	_break(g, true)


## The entity eats a geode (SYS-001 §2.1). No shards: it takes the glass for itself.
func devour(g: Geode) -> void:
	g.alive = false
	world.fx.burst(g.pos, Look.c(Pal.BONE_2), world.fx_tuning.geode_devour_burst_count, world.fx_tuning.geode_devour_burst_speed)


## `by_player`: only the player's mining counts in the service record (an Acolyte's does not).
func _free_shards(g: Geode, n: int, dist: float, speed: float, by_player: bool = true) -> void:
	if by_player and world.record != null:
		world.record.glass_mined += n
	for k in n:
		var dir := Vector2.from_angle(world.rng.randf() * TAU)
		world.glass.spawn_shard(world.torus.wrap(g.pos + dir * world.rng.randf_range(4.0, dist * 0.3)),
			g.vel + dir * world.rng.randf_range(speed * 0.4, speed))
		g.shards_freed += 1


func _break(g: Geode, violent: bool) -> void:
	g.alive = false
	world.sfx(&"geode_break", 0.0 if violent else -4.0)
	world.fx.burst(g.pos, Look.c(Pal.BONE_3), world.fx_tuning.geode_violent_burst_count if violent else world.fx_tuning.geode_break_burst_count,
			world.fx_tuning.geode_violent_burst_speed if violent else world.fx_tuning.geode_break_burst_speed)
	world.fx.ring(g.pos, Look.c(Pal.PHOS_4) if violent else Look.c(Pal.BONE_2), g.radius * (world.fx_tuning.geode_violent_ring_scale if violent else world.fx_tuning.geode_break_ring_scale))
	if violent:
		world.shake(world.fx_tuning.geode_violent_shake_amp, world.fx_tuning.geode_violent_shake_dur)


func _draw() -> void:
	if world == null:
		return
	for g in items:
		if not visible_at(g.pos, g.radius + 4.0):
			continue
		var c := world.to_screen(g.pos)
		var pts := PackedVector2Array()
		for v in g.shape:
			pts.append((c + v.rotated(g.rot)).round())
		var heat := clampf(float(g.recent.size()) / world.tuning.overfire_hits, 0.0, 1.0)
		var bright := Look.c(Pal.BONE_3)
		if heat > 0.6:
			bright = Look.c(Pal.PHOS_5)
		elif heat > 0.3:
			bright = Look.c(Pal.BONE_5)
		if g.flash > 0.5:
			bright = Look.c(Pal.BONE_5)
		Pal.glow_polyline(self, pts, bright, Look.c(Pal.BONE_0))
		# cracks: one chalk line per broken face
		for f in g.faces - g.faces_left:
			var a := g.rot + f * 2.1
			draw_line(c, (c + Vector2.from_angle(a) * g.radius * 0.9).round(), Look.c(Pal.BONE_1))
		for gl in g.glints:
			var q := (c + gl.rotated(g.rot)).round()
			draw_rect(Rect2(q - Vector2(1, 1), Vector2(2, 2)), Look.c(Pal.PHOS_3))
			draw_rect(Rect2(q, Vector2.ONE), Look.c(Pal.PHOS_5) if heat > 0.0 else Look.c(Pal.PHOS_4))
