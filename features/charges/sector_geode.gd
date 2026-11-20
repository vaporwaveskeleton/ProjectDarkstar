class_name SectorGeode
extends Node2D
## A rock full of Mourning Glass (GDD §8.2, SYS-001 §1.3). Composition: a HurtboxComponent (Area2D on
## the `world` layer, biting by default, so the Arc-Lance hits it) forwards to a HealthComponent
## (one hit per attack window); this script turns accepted hits into mining:
##  - calm mining: every `face_hits` hits shatters a face and frees one shard; the last face frees
##    the rest of the calm total (shards_calm + 1 for mining it, minus what already came out);
##  - over-fire: `overfire_hits` hits inside `overfire_window_s` detonates it and scatters the
##    detonated total (4–6, minus what already came out) within `detonation_scatter_px`.
## Shard counts and directions come from an injected seeded RNG (the `loot` stream), never randi.
## `home` is the geode's torus position; the node itself sits at the image of `home` nearest the
## Vigil (set by GeodeSandbox), so drawing and lance overlap work across the wrap seam.

enum Outcome { NONE, HIT, FACE_SHATTERED, CALM_KILL, DETONATED }

@export var stats: GeodeStats

var size_class: int = 0
var faces: int = 1
var faces_left: int = 1
var hits_on_face: int = 0
var shards_freed: int = 0
var alive: bool = true
var detonated: bool = false
var overfire_warnings: int = 0
var home: Vector2 = Vector2.ZERO
var radius: float = 0.0

var torus: Torus
var shard_field: ShardField
var loot_rng: RandomNumberGenerator

var _time_s: float = 0.0
var _recent := PackedFloat64Array()   ## times of recent accepted hits (over-fire window)
var _shape := PackedVector2Array()
var _glints := PackedVector2Array()
## 0 = lantern up … 1 = lantern down (pass 8 c): the body dims to DARK_KEEP with a thin facet glint.
var dark: float = 0.0

@onready var health: HealthComponent = %HealthComponent
@onready var hurtbox: HurtboxComponent = %Hurtbox
@onready var _hurt_shape: CollisionShape2D = %HurtShape


## Configure before adding to the tree. `vfx_rng` only shapes the drawing.
func configure(p_stats: GeodeStats, p_size_class: int, p_home: Vector2, p_torus: Torus,
		p_field: ShardField, p_loot_rng: RandomNumberGenerator, vfx_rng: RandomNumberGenerator = null) -> void:
	stats = p_stats
	torus = p_torus
	shard_field = p_field
	loot_rng = p_loot_rng
	size_class = clampi(p_size_class, 0, stats.class_count() - 1)
	faces = stats.faces_for(size_class)
	faces_left = faces
	radius = stats.radius_for(size_class)
	home = torus.wrap(p_home) if torus else p_home
	position = home
	_build_shape(vfx_rng)


func _ready() -> void:
	hurtbox.collision_layer = PhysicsLayers.bit(PhysicsLayers.WORLD)
	hurtbox.collision_mask = 0
	(_hurt_shape.shape as CircleShape2D).radius = radius
	health.set_max_hp(faces * stats.face_hits)
	hurtbox.hit_received.connect(_on_hit_received)


func _physics_process(delta: float) -> void:
	advance(delta)


## Advances the geode's clock (the over-fire window). Deterministic; tests call it directly.
func advance(delta: float) -> void:
	_time_s += delta
	var before := _recent.size()
	_prune()
	if _recent.size() != before or not bool(SettingsService.get_value(&"reduced_motion")):
		queue_redraw()


## Pass 8 c (Q-T325): how dark the sector is (the far layer's reveal ramp, 0..1). Drawing only.
func set_dark(level: float) -> void:
	var d := clampf(level, 0.0, 1.0)
	if not is_equal_approx(d, dark):
		dark = d
		queue_redraw()


func recent_hits() -> int:
	return _recent.size()


func _on_hit_received(_hit: HitInfo, accepted: bool) -> void:
	if accepted:
		register_lance_hit()


## One accepted lance hit. Returns what it did.
func register_lance_hit() -> Outcome:
	if not alive:
		return Outcome.NONE
	AudioService.play(&"geode_hit")
	_recent.append(_time_s)
	_prune()
	queue_redraw()
	if _recent.size() >= stats.overfire_hits:
		detonate()
		return Outcome.DETONATED
	if _recent.size() == stats.overfire_warn_hits:
		overfire_warnings += 1
		AudioService.play(&"overfire_warn")
	hits_on_face += 1
	if hits_on_face < stats.face_hits:
		return Outcome.HIT
	hits_on_face = 0
	faces_left -= 1
	if faces_left <= 0:
		var remaining := maxi(1, stats.shards_calm + stats.shards_mined_bonus - shards_freed)
		_release(remaining, radius + stats.calm_release_px, stats.calm_release_speed, INF)
		AudioService.play(&"geode_break")
		_break()
		return Outcome.CALM_KILL
	_release(1, radius + stats.face_release_px, stats.face_release_speed, INF)
	AudioService.play(&"geode_crack")
	return Outcome.FACE_SHATTERED


## Over-fire: scatter the detonated total (minus glass already freed, at least 1).
func detonate() -> void:
	if not alive:
		return
	var total := loot_rng.randi_range(stats.shards_detonated_min, stats.shards_detonated_max)
	var scatter := stats.detonation_scatter_px
	_release(maxi(1, total - shards_freed), scatter * stats.detonation_inner_frac, scatter, scatter)
	detonated = true
	AudioService.play(&"overfire_burst")
	_break()


## Frees `n` shards around `home`. Offset in [min, dist × frac]; speed in [speed × min_frac, speed].
## With a finite `rest_within`, the speed is capped so the drift (offset + v / drag) stops inside it.
func _release(n: int, dist: float, speed: float, rest_within: float) -> void:
	var drag := shard_field.stats.drag_per_s if shard_field else 0.0
	for _k in n:
		var dir := Vector2.from_angle(loot_rng.randf() * TAU)
		var off_max := maxf(stats.release_offset_min_px, dist * stats.release_offset_frac)
		var off := loot_rng.randf_range(stats.release_offset_min_px, off_max)
		var v := loot_rng.randf_range(speed * stats.release_speed_min_frac, speed)
		if rest_within < INF and drag > 0.0:
			v = minf(v, maxf(0.0, rest_within - off) * drag)
		if shard_field:
			shard_field.spawn(home + dir * off, dir * v)
		shards_freed += 1


func _break() -> void:
	alive = false
	hurtbox.set_deferred("monitorable", false)
	queue_free()


func _prune() -> void:
	var keep := PackedFloat64Array()
	for t in _recent:
		if _time_s - t <= stats.overfire_window_s + 1e-6:
			keep.append(t)
	_recent = keep


func _build_shape(rng: RandomNumberGenerator) -> void:
	_shape = PackedVector2Array()
	_glints = PackedVector2Array()
	var n := stats.shape_vertices_base + size_class * stats.shape_vertices_per_class
	for k in n:
		var j := rng.randf_range(stats.shape_jitter_min, 1.0) if rng else 1.0
		_shape.append(Vector2.from_angle(TAU * k / n) * radius * j)
	if rng:
		for k in stats.glints_base + size_class * stats.glints_per_class:
			_glints.append(Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.1, 0.55))


const FILL_ALPHA := 0.7           ## ✱ drawing: body fill opacity (pass 8 from 0.55)
const BACKING_SCALE := 1.35       ## ✱ drawing, pass 8: dark fog pocket radius as a multiple of the body's
const BACKING_ALPHA := 0.35       ## ✱ drawing, pass 8: dark fog pocket opacity
const DARK_KEEP := 0.3            ## ✱ drawing, pass 8 c: share of the body's light kept with the lantern down
const DARK_GLINT_ALPHA := 0.8     ## ✱ drawing, pass 8 c: the thin facet glint on the lit edge in the dark
const SHIMMER_RATE := 1.7         ## rad/s ✱ drawing: facet glint shimmer
const RIM_SHARE := 0.4            ## ✱ drawing: fraction of the outline that takes the rim light
const RIM_DIR := Vector2(-0.6, -0.8)   ## ✱ drawing: light comes from upper left


## Runtime vector, Aether tier (ART-001 §15): translucent crystal body (AETHER ramp) with lighter
## facet edges, a rim light on the lit side and slowly shimmering inner facets; heats toward phosphor
## as the over-fire window fills; one chalk crack per shattered face. Reads only.
func _draw() -> void:
	if stats == null or _shape.size() < 3:
		return
	var heat := clampf(float(_recent.size()) / stats.overfire_hits, 0.0, 1.0)
	var edge := Pal.AETHER_3
	if heat > 0.6:
		edge = Pal.PHOS_5
	elif heat > 0.3:
		edge = Pal.AETHER_4
	var pts := PackedVector2Array()
	for v in _shape:
		pts.append(v.round())
	var n := pts.size()
	var still := bool(SettingsService.get_value(&"reduced_motion"))
	var fill := Pal.AETHER_1 if heat <= 0.3 else Pal.PHOS_1
	# pass 8 (Q-T304): a pocket of dark fog behind it, so it reads above the far layer
	for r in 3:   # soft-edged: stacked discs, darkest at the core
		draw_circle(Vector2.ZERO, radius * BACKING_SCALE * (1.0 - 0.15 * r), Color(Pal.VOID_1, BACKING_ALPHA * 0.45))
	draw_colored_polygon(pts, Color(fill, FILL_ALPHA))
	var hub := (RIM_DIR * radius * 0.2).round()
	for k in range(0, n, 2):
		draw_line(hub, pts[k], Color(Pal.AETHER_2, 0.6), 1.0)
	var inner := PackedVector2Array()
	for p in pts:
		inner.append((p * 0.6 + hub * 0.4).round())
	draw_colored_polygon(inner, Color(Pal.AETHER_2, 0.25))
	inner.append(inner[0])
	draw_polyline(inner, Color(Pal.AETHER_3, 0.35), 1.0)
	pts.append(pts[0])
	draw_polyline(pts, edge, 1.0)
	for k in n:
		var a := pts[k]
		var b := pts[k + 1]
		if ((a + b) * 0.5).normalized().dot(RIM_DIR) > 1.0 - 2.0 * RIM_SHARE:
			draw_line(a, b, Pal.AETHER_4, 2.0)
	for f in mini(2, n):
		var tri := PackedVector2Array([hub, pts[(f * 3 + 1) % n], pts[(f * 3 + 2) % n]])
		var phase := 0.5 if still else 0.5 + 0.5 * sin(_time_s * SHIMMER_RATE + f * 2.4)
		draw_colored_polygon(tri, Color(Pal.AETHER_4, 0.08 + 0.22 * phase))
	for f in faces - faces_left:
		draw_line(Vector2.ZERO, (Vector2.from_angle(f * 2.1) * radius * 0.9).round(), Pal.BONE_4, 1.0)
		draw_line(Vector2.ZERO, (Vector2.from_angle(f * 2.1 + 0.15) * radius * 0.5).round(), Pal.AETHER_0, 1.0)
	for g in _glints:
		var q := g.round()
		draw_rect(Rect2(q - Vector2(1, 1), Vector2(2, 2)), Pal.PHOS_3)
		draw_rect(Rect2(q, Vector2.ONE), Pal.PHOS_5 if heat > 0.0 else Pal.PHOS_4)
	# pass 8 c (Q-T325): lantern down, the rock sinks to about DARK_KEEP of its light (a VOID veil, never
	# black) and only a thin facet glint on its lit edge still catches the far light
	if dark > 0.001:
		var body := PackedVector2Array()
		for v in _shape:
			body.append(v.round())
		draw_colored_polygon(body, Color(Pal.VOID_1, (1.0 - DARK_KEEP) * dark))
		for k in n:
			var a := pts[k]
			var b := pts[k + 1]
			if ((a + b) * 0.5).normalized().dot(RIM_DIR) > 1.0 - 2.0 * RIM_SHARE * 0.5:
				draw_line(a, b, Color(Pal.AETHER_4, DARK_GLINT_ALPHA * dark), 1.0)
