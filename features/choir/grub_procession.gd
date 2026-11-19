class_name GrubProcession
extends Node
## Keeps a Sepulchre's Oubliette Grubs (SYS-001 §3): spawns them on a ring round the Sepulchre,
## counts and frees the dead (score per Grub, SYS-001 §7.1), and has the Sepulchre birth a
## replacement `respawn_s` after each death. Each Grub seeks, steals and walks the route on its
## own (no procession spacing). Grubs live under the sector's %Actors (SectorWrap re-images them)
## and join the Ledger Compass as kind `grub`. No signals: the sector reads the counters (probes).

const GRUB_SCENE := preload("res://features/choir/oubliette_grub.tscn")
const COMPASS_KIND := &"grub"
const COMPASS_RANK := 10   ## after the Sepulchre, before geodes

@export var stats: GrubStats
@export var shard_field: ShardField

var torus: Torus
var actors: Node
var lantern: Node2D
var sepulchre: Sepulchre
var route := PackedVector2Array()

var grubs: Array[OublietteGrub] = []
var respawn_timers: Array[float] = []
var kills: int = 0
var score: int = 0
var spawned: int = 0
## Cue sink handed to every Grub. Tests replace it.
var sfx: Callable = AudioService.play


## Spawns `count` Grubs evenly on a ring of `ring_px` round the Sepulchre.
func begin(p_torus: Torus, p_actors: Node, p_lantern: Node2D, p_sepulchre: Sepulchre,
		p_route: PackedVector2Array, count: int, ring_px: float) -> void:
	torus = p_torus
	actors = p_actors
	lantern = p_lantern
	sepulchre = p_sepulchre
	route = p_route
	for g in grubs:
		if is_instance_valid(g):
			g.queue_free()
	grubs.clear()
	respawn_timers.clear()
	for i in count:
		spawn(sepulchre.home + Vector2.from_angle(TAU * i / maxi(1, count)) * ring_px)


func spawn(at: Vector2) -> OublietteGrub:
	var g := GRUB_SCENE.instantiate() as OublietteGrub
	g.configure(stats, torus, shard_field, sepulchre, lantern, route, spawned, at)
	g.sfx = sfx
	spawned += 1
	(actors if actors != null else self).add_child(g)
	LedgerCompass.register(g, COMPASS_KIND, COMPASS_RANK)
	grubs.append(g)
	return g


func _physics_process(delta: float) -> void:
	tick(delta)


## Counts and frees dead Grubs, runs the respawn timers. Deterministic.
func tick(delta: float) -> void:
	var keep: Array[OublietteGrub] = []
	for g in grubs:
		if not is_instance_valid(g):
			continue
		if g.dead:
			kills += 1
			score += stats.score
			respawn_timers.append(stats.respawn_s)
			g.queue_free()
		else:
			keep.append(g)
	grubs = keep
	for i in range(respawn_timers.size() - 1, -1, -1):
		respawn_timers[i] -= delta
		if respawn_timers[i] <= 0.0001:
			respawn_timers.remove_at(i)
			if sepulchre != null and is_instance_valid(sepulchre):
				spawn(sepulchre.home)


func alive_count() -> int:
	var n := 0
	for g in grubs:
		if is_instance_valid(g) and not g.dead:
			n += 1
	return n


func carrying_count() -> int:
	var n := 0
	for g in grubs:
		if is_instance_valid(g) and not g.dead and g.carrying:
			n += 1
	return n
