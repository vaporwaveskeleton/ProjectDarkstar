class_name AetherAcolyte
extends Node2D
## The Aether Acolyte (PM-02 Dark Throat): a Choir censer-knight on watch at a post. It detects the
## Vigil inside `detect_radius_px` scaled by the lantern (up = a beacon, down = running dark), keeps
## tracking `acquisition_loss_s` after losing it, aims its censer at the Vigil with `turret_lag_s` of lag
## (so a mover is led past), and fires only while the Vigil is detected AND within `range_px`: a
## `tell_s` telegraph, then one ember shot (AcolyteShot) every `cycle_s`. It drifts toward the Vigil
## but never farther than `post_leash_px` from its post.
## Killed by the Arc-Lance like a Grub (HurtboxComponent on `choir_hurtbox` + HealthComponent); a
## Null-Iron Charge touching that hurtbox is intercepted exactly as by a Grub (NullIronCharge).
## A dead Acolyte stays in the tree (hidden, inert) so the sector can count it for score.
## Movement is torus-aware; the node lives under the sector's %Actors. No RNG, no signals.

var stats: AcolyteStats
var torus: Torus
## The torus position it stands guard at.
var post := Vector2.ZERO
var vigil: Node2D
var lantern: VigilLantern
## Where shots live (the sector's %Actors). Null = this node.
var shot_parent: Node
var index := 0
## Cue sink (id, volume_db). Tests replace it.
var sfx: Callable = AudioService.play

var dead := false
## The Vigil is inside the (lantern-scaled) detection radius this tick.
var detecting := false
## Detected now or within `acquisition_loss_s` of it.
var tracking := false
var lost_left := 0.0
## The censer's (lagged) aim, a unit vector.
var aim := Vector2.DOWN
## Seconds left of the telegraph (< 0 = not telling) and until the next telegraph may start.
var tell_left := -1.0
var cycle_left := 0.0
var shots_fired := 0
var time_s := 0.0
var die_s := -1.0

@onready var health: HealthComponent = %HealthComponent
@onready var hurtbox: HurtboxComponent = %Hurtbox
@onready var view: AcolyteView = %AcolyteView
@onready var _hurt_shape: CollisionShape2D = %HurtShape


## Configure before adding to the tree.
func configure(p_stats: AcolyteStats, p_torus: Torus, p_post: Vector2, p_vigil: Node2D,
		p_lantern: VigilLantern, p_index: int = 0) -> void:
	stats = p_stats
	torus = p_torus
	post = torus.wrap(p_post)
	vigil = p_vigil
	lantern = p_lantern
	index = p_index
	position = post


func _ready() -> void:
	hurtbox.collision_layer = PhysicsLayers.bit(PhysicsLayers.CHOIR_HURTBOX)
	hurtbox.collision_mask = 0
	(_hurt_shape.shape as CircleShape2D).radius = stats.radius_px
	health.set_max_hp(stats.hp)
	health.health_depleted.connect(die)
	health.damaged.connect(func(_a: int, _r: int) -> void: view.flash())


func _physics_process(delta: float) -> void:
	step(delta)


func home() -> Vector2:
	return torus.wrap(global_position)


## The Vigil's lantern is up (no lantern known = up).
func lantern_up() -> bool:
	return lantern == null or lantern.is_up


## Detection radius now: the base radius times the lantern multiplier.
func detect_radius() -> float:
	return stats.detect_radius_px * (stats.lantern_up_mult if lantern_up() else stats.lantern_down_mult)


func _vigil_alive() -> bool:
	if not is_instance_valid(vigil):
		return false
	var v := vigil as Vigil
	return v == null or not v.health.is_depleted


## One deterministic tick: detect, aim, drift inside the leash, telegraph and fire.
func step(delta: float) -> void:
	if dead:
		if die_s >= 0.0:
			die_s += delta
		return
	time_s += delta
	var pos := home()
	var alive := _vigil_alive()
	var to_vigil := torus.delta(pos, vigil.global_position) if alive else Vector2.ZERO
	var dist := to_vigil.length()
	detecting = alive and dist <= detect_radius()
	if detecting:
		lost_left = stats.acquisition_loss_s
	else:
		lost_left = maxf(0.0, lost_left - delta)
	tracking = alive and (detecting or lost_left > 0.0)
	if tracking and dist > 0.001:
		aim = lag_aim(aim, to_vigil / dist, delta, stats.turret_lag_s)
	_drift(pos, delta, alive)
	var can_fire := detecting and dist <= stats.range_px
	cycle_left = maxf(0.0, cycle_left - delta)
	if tell_left >= 0.0:
		if not can_fire:
			tell_left = -1.0
		else:
			tell_left -= delta
			if tell_left <= 0.0001:
				tell_left = -1.0
				fire()
	elif can_fire and cycle_left <= 0.0001:
		tell_left = stats.tell_s
		cycle_left = stats.cycle_s
		_play(&"acolyte_tell")


## The aim `current` eased toward `wanted` with time constant `lag_s` (both unit vectors).
static func lag_aim(current: Vector2, wanted: Vector2, delta: float, lag_s: float) -> Vector2:
	if lag_s <= 0.0:
		return wanted
	var k := 1.0 - exp(-delta / lag_s)
	var out := current.lerp(wanted, k)
	return out.normalized() if out.length() > 0.001 else wanted


## Toward the Vigil inside the leash while tracking, else back to the post.
func _drift(pos: Vector2, delta: float, alive: bool) -> void:
	var goal := post
	if tracking and alive:
		goal = post + torus.delta(post, vigil.global_position).limit_length(stats.post_leash_px)
	global_position += torus.delta(pos, goal).limit_length(stats.move_speed_px_s * delta)
	# never beyond the leash (the shortest torus distance to the post)
	var off := torus.delta(post, home())
	if off.length() > stats.post_leash_px:
		global_position = post + off.limit_length(stats.post_leash_px)


## One censer shot along the (lagged) aim.
func fire() -> AcolyteShot:
	var s := AcolyteShot.new()
	s.launch(global_position, aim, stats, torus, get_instance_id())
	(shot_parent if shot_parent != null else self).add_child(s)
	shots_fired += 1
	_play(&"acolyte_fire")
	return s


## Killed (HealthComponent depleted): the ember gutters (view), the knight goes inert.
func die() -> void:
	if dead:
		return
	dead = true
	die_s = 0.0
	tell_left = -1.0
	tracking = false
	detecting = false
	hurtbox.set_deferred("monitorable", false)
	_play(&"acolyte_die")


## 0..1 progress of the telegraph (0 = none).
func tell_frac() -> float:
	return 0.0 if tell_left < 0.0 else clampf(1.0 - tell_left / maxf(0.001, stats.tell_s), 0.0, 1.0)


func _play(id: StringName) -> void:
	if sfx.is_valid():
		sfx.call(id, 0.0)
