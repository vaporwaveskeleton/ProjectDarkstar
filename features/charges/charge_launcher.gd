class_name ChargeLauncher
extends Node
## Fires Null-Iron Charges from the Vigil (GDD §8.3; input `deploy_charge`, RMB / LT, D-01) and
## keeps the books on the ones in flight. One Charge per press, spent from the ChargeMagazine;
## an empty magazine plays dry_fire (AUDIO-001 A09) and fires nothing.
## Spent Charges (hit, lost, guttered) are counted here and freed here (NullIronCharge leaves itself
## in the tree so its outcome can be read). No signals: the sector reads the counters (probes).
## Composure loss on a lost Charge (SYS-001 §1.5) is NOT applied: Composure is not built yet.

const CHARGE_SCENE := preload("res://features/charges/null_iron_charge.tscn")

@export var stats: ChargeStats
@export var magazine: ChargeMagazine

## Injected by the sector.
var torus: Torus
var vigil: Vigil
## The hurtbox Charges home on (the Sepulchre's in phases 0–1).
var target: HurtboxComponent
## Where Charges live (the sector's %Actors, so SectorWrap re-images them). Null = this node.
var projectile_parent: Node

var flying: Array[NullIronCharge] = []
var fired: int = 0
var dry_fires: int = 0
## Counts of Charges already freed, per outcome.
var _done := {NullIronCharge.Outcome.HIT: 0, NullIronCharge.Outcome.LOST: 0, NullIronCharge.Outcome.GUTTERED: 0}
## Cue sink (id, volume_db). Tests replace it; each Charge gets the same sink.
var sfx: Callable = AudioService.play


func _physics_process(_delta: float) -> void:
	prune()
	if is_instance_valid(vigil) and vigil.input.consume_deploy() and not vigil.health.is_depleted:
		fire_from_vigil()


## Fires toward the Vigil's aim (stick or mouse), else along its facing.
func fire_from_vigil() -> NullIronCharge:
	var dir := vigil.input.aim_dir(vigil.global_position)
	if dir == Vector2.ZERO:
		dir = vigil.get_aim_dir()
	return fire(vigil.global_position, dir)


## Spends one Charge and launches it from `at` along `dir`. Null (and dry_fire) when empty.
func fire(at: Vector2, dir: Vector2) -> NullIronCharge:
	if magazine == null or not magazine.try_spend(1):
		dry_fires += 1
		_play(&"dry_fire")
		return null
	var c := CHARGE_SCENE.instantiate() as NullIronCharge
	var src := vigil.get_instance_id() if is_instance_valid(vigil) else get_instance_id()
	c.launch(stats, torus, at, dir, target, src)
	c.sfx = sfx
	(projectile_parent if projectile_parent != null else self).add_child(c)
	flying.append(c)
	fired += 1
	_play(&"charge_fire")
	return c


## Counts and frees spent Charges.
func prune() -> void:
	var keep: Array[NullIronCharge] = []
	for c in flying:
		if not is_instance_valid(c):
			continue
		if c.is_flying():
			keep.append(c)
			continue
		_done[c.outcome] = int(_done[c.outcome]) + 1
		c.queue_free()
	flying = keep


func in_flight() -> int:
	var n := 0
	for c in flying:
		if is_instance_valid(c) and c.is_flying():
			n += 1
	return n


## Charges that ended with `o`, freed or not yet pruned.
func count(o: NullIronCharge.Outcome) -> int:
	var n: int = int(_done.get(o, 0))
	for c in flying:
		if is_instance_valid(c) and c.outcome == o:
			n += 1
	return n


func hits() -> int:
	return count(NullIronCharge.Outcome.HIT)


## Charges destroyed by an interceptor (not guttered ones).
func lost() -> int:
	return count(NullIronCharge.Outcome.LOST)


func guttered() -> int:
	return count(NullIronCharge.Outcome.GUTTERED)


func _play(id: StringName) -> void:
	if sfx.is_valid():
		sfx.call(id, 0.0)
