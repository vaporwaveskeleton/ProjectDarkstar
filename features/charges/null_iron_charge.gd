class_name NullIronCharge
extends Area2D
## One fired Null-Iron Charge (GDD §8.3, SYS-001 §1.4). Fire-and-forget: it homes on its target's
## hurtbox at `speed_px_s`, turning at most PI / turn_authority_s rad/s, and ends in one of:
##  - HIT: it touched its target's hurtbox and delivered `target_hits` there (kind KIND; the
##    target decides what that does; the hurtbox's `bites` flag is ignored, PM ruling A2);
##  - LOST: an interceptor (a Grub hurtbox on `choir_hurtbox`, a geode hurtbox on `world`) took its
##    HP to 0. Cue charge_lost (AUDIO-001 B06, used for this only);
##  - GUTTERED: it reached `life_s`. Cue charge_gutter (B12).
## A spent Charge stops moving and colliding but stays in the tree: its ChargeLauncher counts the
## outcome and frees it. Torus-aware: steering uses Torus.delta; the node lives under the sector's
## %Actors, so SectorWrap keeps it on the image nearest the Vigil.

enum Outcome { FLYING, HIT, LOST, GUTTERED }

const KIND := &"null_iron_charge"

var stats: ChargeStats
var torus: Torus
## What the Charge homes on and can hit (the Sepulchre's hurtbox in phases 0–1). Null = flies straight.
var target: HurtboxComponent
var direction: Vector2 = Vector2.RIGHT
var age_s: float = 0.0
var hp: int = 1
var outcome: Outcome = Outcome.FLYING
var source_id: int = 0
## Recent torus positions, newest last (drawing only).
var trail := PackedVector2Array()
## Cue sink (id, volume_db). Tests replace it.
var sfx: Callable = AudioService.play

@onready var _shape: CollisionShape2D = %ChargeShape


func _ready() -> void:
	collision_layer = PhysicsLayers.bit(PhysicsLayers.VIGIL_SHOTS)
	collision_mask = PhysicsLayers.mask([PhysicsLayers.WORLD, PhysicsLayers.CHOIR_HURTBOX])
	monitorable = false
	area_entered.connect(resolve_contact)
	_apply_shape()


## Configure before or right after adding to the tree. `dir` need not be normalised.
func launch(p_stats: ChargeStats, p_torus: Torus, at: Vector2, dir: Vector2, p_target: HurtboxComponent, p_source_id: int = 0) -> void:
	stats = p_stats
	torus = p_torus
	target = p_target
	global_position = at
	direction = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	rotation = 0.0
	hp = stats.hp
	source_id = p_source_id
	age_s = 0.0
	outcome = Outcome.FLYING
	trail = PackedVector2Array()
	if is_node_ready():
		_apply_shape()


func is_flying() -> bool:
	return outcome == Outcome.FLYING


func _physics_process(delta: float) -> void:
	advance(delta)


## One deterministic step: steer, move, age, gutter. Returns false once the Charge is spent.
func advance(delta: float) -> bool:
	if not is_flying() or stats == null:
		return false
	age_s += delta
	direction = steer(direction, _to_target(), stats.turn_rate() * delta)
	global_position += direction * stats.speed_px_s * delta
	trail.append(_wrap(global_position))
	while trail.size() > maxi(0, stats.trail_points):
		trail.remove_at(0)
	queue_redraw()
	if age_s >= stats.life_s - 0.0001:
		_end(Outcome.GUTTERED, &"charge_gutter")
		return false
	return true


## Turns `dir` toward `to_target` by at most `max_turn` radians. Zero `to_target` keeps `dir`.
static func steer(dir: Vector2, to_target: Vector2, max_turn: float) -> Vector2:
	if to_target == Vector2.ZERO:
		return dir
	var ang := dir.angle_to(to_target)
	return dir.rotated(clampf(ang, -max_turn, max_turn))


## Resolves touching `area`. Public so tests drive it without a physics frame.
func resolve_contact(area: Area2D) -> void:
	if not is_flying() or not (area is HurtboxComponent):
		return
	var hb := area as HurtboxComponent
	if is_instance_valid(target) and hb == target:
		hb.receive_hit(HitInfo.make(stats.target_hits, source_id, get_instance_id(), KIND))
		_end(Outcome.HIT, &"charge_hit")
		return
	var from_choir := hb.collision_layer & PhysicsLayers.bit(PhysicsLayers.CHOIR_HURTBOX) != 0
	hp -= stats.grub_contact_damage if from_choir else stats.geode_contact_damage
	if hp <= 0:
		_end(Outcome.LOST, &"charge_lost")


func _to_target() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO
	if torus != null:
		return torus.delta(global_position, target.global_position)
	return target.global_position - global_position


func _wrap(p: Vector2) -> Vector2:
	return torus.wrap(p) if torus != null else p


func _end(o: Outcome, cue: StringName) -> void:
	outcome = o
	set_deferred("monitoring", false)
	visible = false
	if sfx.is_valid():
		sfx.call(cue, 0.0)


func _apply_shape() -> void:
	if stats and _shape and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius = stats.radius_px


## Runtime vector (ART-001 §14): a bone-white core in a dim phosphor shell, a phosphor trail.
func _draw() -> void:
	if not is_flying():
		return
	var here := _wrap(global_position)
	var prev := Vector2.INF
	for i in trail.size():
		var q := torus.delta(here, trail[i]) if torus != null else trail[i] - here
		if prev != Vector2.INF:
			draw_line(prev, q, Pal.PHOS_2 if i < trail.size() - 4 else Pal.PHOS_4, 1.0)
		prev = q
	draw_rect(Rect2(Vector2(-2, -2), Vector2(5, 5)), Pal.PHOS_1)
	draw_rect(Rect2(Vector2(-1, -1), Vector2(3, 3)), Pal.BONE_5)
