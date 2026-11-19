class_name Sepulchre
extends Node2D
## The Sepulchre, phases 0–1 (GDD §8.4, SYS-001 §2): the altar the Choir builds the entity on.
##  - Phase 0 Seed / Cold Sepulchre at sector start (0 segments).
##  - Phase 1 Procession: Grubs deposit shards; every `shards_per_segment` deposits add 1 of
##    `segments_total` segments. At the total the Sepulchre is complete (`is_complete()`); no
##    Awakening or win flow yet (phases ≥ 2 out of scope).
## Its HurtboxComponent sits on `world` with `bites = false`: the Arc-Lance does no damage and
## leaves a chalk tick + lance_dull (ArcLanceFx). A Null-Iron Charge hit (HitInfo kind
## NullIronCharge.KIND) knocks `segments_knocked_per_hit` segments off. The hurtbox has no
## HealthComponent: this script reads `hit_received` itself.
## `home` is the torus position; the node lives under the sector's %Actors, so SectorWrap keeps it
## on the image nearest the Vigil.

enum Phase { SEED, PROCESSION }

@export var stats: SepulchreStats

var torus: Torus
var home: Vector2 = Vector2.ZERO
var phase: Phase = Phase.SEED
var segments: int = 0
var shard_points: int = 0       ## deposits toward the next segment
var deposited_shards: int = 0   ## every shard deposited, ever
var charge_hits: int = 0
var segments_knocked: int = 0
var score: int = 0
var pulse_left: float = 0.0     ## deposit ring, presentation
## Cue sink (id, volume_db). Tests replace it.
var sfx: Callable = AudioService.play

@onready var hurtbox: HurtboxComponent = %Hurtbox
@onready var _hurt_shape: CollisionShape2D = %HurtShape


func configure(p_stats: SepulchreStats, p_torus: Torus, p_home: Vector2) -> void:
	stats = p_stats
	torus = p_torus
	home = torus.wrap(p_home) if torus else p_home
	position = home


func _ready() -> void:
	hurtbox.bites = false
	hurtbox.collision_layer = PhysicsLayers.bit(PhysicsLayers.WORLD)
	hurtbox.collision_mask = 0
	(_hurt_shape.shape as CircleShape2D).radius = stats.hurt_radius_px
	hurtbox.hit_received.connect(_on_hit_received)


func _physics_process(delta: float) -> void:
	if pulse_left > 0.0:
		pulse_left = maxf(0.0, pulse_left - delta)


func is_complete() -> bool:
	return segments >= stats.segments_total


## True when a carrier at torus position `p` is close enough to deposit.
func in_deposit_reach(p: Vector2) -> bool:
	var d := torus.distance(p, home) if torus else p.distance_to(home)
	return d <= stats.deposit_radius_px


## A Grub delivered one shard (SYS-001 §2 phase 1: one segment point). Cue segment_deposit.
func deposit() -> void:
	deposited_shards += 1
	pulse_left = stats.deposit_pulse_s
	_play(&"segment_deposit")
	if is_complete():
		return
	shard_points += 1
	if shard_points >= stats.shards_per_segment:
		shard_points -= stats.shards_per_segment
		segments += 1
	phase = phase_for(segments)


## A Null-Iron Charge landed: knock segments off (none to knock in phase 0). Cue segment_knocked
## when one came off (the Charge itself plays charge_hit).
func take_charge_hit() -> int:
	charge_hits += 1
	var n := mini(segments, stats.segments_knocked_per_hit)
	if n > 0:
		segments -= n
		segments_knocked += n
		score += n * stats.score_per_segment_knocked
		_play(&"segment_knocked")
	phase = phase_for(segments)
	return n


static func phase_for(n: int) -> Phase:
	return Phase.SEED if n <= 0 else Phase.PROCESSION


func _on_hit_received(hit: HitInfo, _accepted: bool) -> void:
	if hit.kind == NullIronCharge.KIND:
		for _k in maxi(1, hit.amount):
			take_charge_hit()


func _play(id: StringName) -> void:
	if sfx.is_valid():
		sfx.call(id, 0.0)
