class_name OublietteGrub
extends Node2D
## One Oubliette Grub (GDD §8.5, SYS-001 §3): a harmless larva of the Hollow Choir. It never
## attacks. It seeks the nearest free Mourning Glass (ShardField hooks, one query per
## `grub_query_interval_ticks`, offset by its index), claims it, steals it (cue grub_steal; the shard
## leaves the field), walks the procession route to the Sepulchre and deposits it there.
## It flees the Vigil's lantern inside the flee radius unless it is carrying (devotion beats fear,
## as in the Cabinet). Killed by the Arc-Lance (biting HurtboxComponent on `choir_hurtbox` +
## HealthComponent): a carried shard drops back into the field and the Choir keens (grub_keen,
## SYS-001 §3 "keening when a deposit dies"); a claim is released; cue grub_die.
## A dead Grub stays in the tree (hidden, inert) until its GrubProcession counts and frees it.
## Movement is torus-aware (Torus.delta); the node lives under the sector's %Actors, so SectorWrap
## keeps it on the image nearest the Vigil. No RNG: identical inputs give identical paths.

enum State { SEEK, CARRY, FLEE, IDLE }

var stats: GrubStats
var torus: Torus
var field: ShardField
var sepulchre: Sepulchre
## The Vigil (its lantern). Null or breached = nothing to fear.
var lantern: Node2D
## Procession route, torus positions in walking order (the last one nearest the Sepulchre).
var route := PackedVector2Array()
## Spawn order: the query tick offset and the idle orbit phase.
var index: int = 0

var state: State = State.IDLE
var velocity: Vector2 = Vector2.ZERO
var shard: int = ShardField.NONE   ## claimed shard (SEEK)
var carrying: bool = false
var route_at: int = -1             ## next waypoint while carrying; route.size() = to the Sepulchre
var dead: bool = false
var deposits: int = 0
var ticks: int = 0
var time_s: float = 0.0
## Cue sink (id, volume_db). Tests replace it.
var sfx: Callable = AudioService.play

@onready var health: HealthComponent = %HealthComponent
@onready var hurtbox: HurtboxComponent = %Hurtbox
@onready var view: GrubView = %GrubView
@onready var _hurt_shape: CollisionShape2D = %HurtShape


## Configure before adding to the tree.
func configure(p_stats: GrubStats, p_torus: Torus, p_field: ShardField, p_sepulchre: Sepulchre,
		p_lantern: Node2D, p_route: PackedVector2Array, p_index: int, at: Vector2) -> void:
	stats = p_stats
	torus = p_torus
	field = p_field
	sepulchre = p_sepulchre
	lantern = p_lantern
	route = p_route
	index = p_index
	position = torus.wrap(at)


func _ready() -> void:
	hurtbox.collision_layer = PhysicsLayers.bit(PhysicsLayers.CHOIR_HURTBOX)
	hurtbox.collision_mask = 0
	(_hurt_shape.shape as CircleShape2D).radius = stats.radius_px
	health.set_max_hp(stats.hp)
	health.health_depleted.connect(die)
	health.damaged.connect(func(_a: int, _r: int) -> void: view.flash())


func _physics_process(delta: float) -> void:
	step(delta)


## Torus position of this Grub.
func home() -> Vector2:
	return torus.wrap(global_position)


## One deterministic tick: decide, steer, move, then steal / pass waypoints / deposit.
func step(delta: float) -> void:
	if dead:
		return
	ticks += 1
	time_s += delta
	var pos := home()
	var to_lantern := Vector2.ZERO
	var scared := false
	if _lantern_lit():
		to_lantern = torus.delta(pos, lantern.global_position)
		scared = not carrying and to_lantern.length() < stats.flee_radius_px
	if scared:
		state = State.FLEE
	elif carrying:
		state = State.CARRY
	else:
		if not _holds_claim():
			shard = ShardField.NONE
		if shard == ShardField.NONE and field.grub_query_due(ticks, index):
			_claim(pos)
		state = State.SEEK if shard != ShardField.NONE else State.IDLE
	var goal := pos
	var speed := 0.0
	match state:
		State.FLEE:
			goal = pos - to_lantern.normalized() * stats.flee_step_px
			speed = stats.flee_speed_px_s
		State.CARRY:
			goal = carry_goal()
			speed = stats.carry_speed_px_s
		State.SEEK:
			goal = field.positions[shard]
			speed = stats.seek_speed_px_s
		State.IDLE:
			goal = sepulchre.home + Vector2.from_angle(time_s * stats.idle_orbit_rate + index) * stats.idle_orbit_px
			speed = stats.idle_speed_px_s
	velocity = steer_velocity(velocity, torus.delta(pos, goal), speed, stats.arrive_px, clampf(delta * stats.steer_per_s, 0.0, 1.0))
	global_position += velocity * delta
	pos = home()
	if state == State.SEEK and _holds_claim() \
			and torus.distance(pos, field.positions[shard]) < stats.radius_px + stats.pickup_margin_px:
		_steal(pos)
	elif state == State.CARRY:
		_walk_route(pos)


## Velocity toward `to_goal` at `speed` (zero inside `arrive`), eased by `steer` (0..1).
static func steer_velocity(v: Vector2, to_goal: Vector2, speed: float, arrive: float, steer: float) -> Vector2:
	var want := to_goal.normalized() * speed if to_goal.length() > arrive else Vector2.ZERO
	return v.lerp(want, steer)


## Where a carrier is heading: the next route waypoint, then the Sepulchre.
func carry_goal() -> Vector2:
	if route_at >= 0 and route_at < route.size():
		return route[route_at]
	return sepulchre.home


## Index of the route waypoint nearest `p` (torus): a carrier joins the route there.
static func nearest_waypoint(p_torus: Torus, p_route: PackedVector2Array, p: Vector2) -> int:
	var best := 0
	var best_d := INF
	for i in p_route.size():
		var d := p_torus.distance_sq(p, p_route[i])
		if d < best_d:
			best_d = d
			best = i
	return best


func _claim(pos: Vector2) -> void:
	var i := field.nearest_free(pos, _whole_field_radius())
	if i != ShardField.NONE and field.claim(i):
		shard = i


func _steal(pos: Vector2) -> void:
	if not field.take(shard):
		shard = ShardField.NONE
		return
	shard = ShardField.NONE
	carrying = true
	route_at = nearest_waypoint(torus, route, pos) if not route.is_empty() else 0
	_play(&"grub_steal")


func _walk_route(pos: Vector2) -> void:
	while route_at >= 0 and route_at < route.size() and torus.distance(pos, route[route_at]) <= stats.waypoint_reach_px:
		route_at += 1
	if route_at >= route.size() and sepulchre.in_deposit_reach(pos):
		carrying = false
		route_at = -1
		deposits += 1
		sepulchre.deposit()


## Killed (HealthComponent depleted). Drops a carried shard back into the field and keens.
func die() -> void:
	if dead:
		return
	dead = true
	if carrying:
		carrying = false
		field.spawn(home(), velocity * stats.drop_speed_frac)
		_play(&"grub_keen")
	elif shard != ShardField.NONE:
		field.release_claim(shard)
	shard = ShardField.NONE
	_play(&"grub_die")
	hurtbox.set_deferred("monitorable", false)
	visible = false


## A claim this Grub still holds: the shard is live and flagged claimed. The Vigil may have
## collected it (the slot then reads dead, or reused without the claim flag).
func _holds_claim() -> bool:
	return shard != ShardField.NONE and field.is_claimed(shard)


func _lantern_lit() -> bool:
	if not is_instance_valid(lantern):
		return false
	var v := lantern as Vigil
	return v == null or not v.health.is_depleted


## A search radius that covers the whole torus: Grubs seek the nearest free shard anywhere (the
## Cabinet rule; SYS-001 gives no detection radius).
func _whole_field_radius() -> float:
	return torus.size.length()


func _play(id: StringName) -> void:
	if sfx.is_valid():
		sfx.call(id, 0.0)


## Starts laden (a kit's `start_carriers`): standing at route waypoint `at_waypoint`, carrying a shard
## toward the next one. Call before the first step.
func start_laden(at_waypoint: int) -> void:
	if route.is_empty():
		return
	var i := clampi(at_waypoint, 0, route.size() - 1)
	position = torus.wrap(route[i])
	carrying = true
	route_at = i + 1
	state = State.CARRY
