class_name GeodeSandbox
extends Node2D
## Places the M1 sector sandbox's geodes (no kit assembly yet; SeamAssembler replaces this later).
## Deterministic: positions and size classes from the RunSeed `map` stream, detonations from the
## `loot` stream, shapes from `vfx` (TECH-001 §4.9). All positions are torus positions (the sector
## injects the Torus); each tick a geode node is moved to the image of its home nearest the
## reference (the Vigil), so it draws and collides on the Vigil's side of the wrap seam.
## Geodes are NOT under the sector's %Actors, so SectorWrap never moves them: this re-imaging is the
## one mechanism. The sector gives this node process_physics_priority 1, so it runs after SectorWrap
## has wrapped the Vigil in the same tick.

const GEODE_SCENE := preload("res://features/charges/sector_geode.tscn")
const COMPASS_KIND := &"geode"

@export var stats: GeodeSandboxStats
@export var geode_stats: GeodeStats
@export var shard_field: ShardField

var torus: Torus
var reference: Node2D
var geodes: Array[SectorGeode] = []
var loot_rng: RandomNumberGenerator
var _detonated_freed: int = 0   ## detonated geodes whose nodes have already left the tree


## Spawns the layout. `avoid` is the Vigil spawn (kept clear); `p_reference` is the Vigil.
func populate(p_torus: Torus, avoid: Vector2, p_reference: Node2D = null) -> void:
	torus = p_torus
	reference = p_reference
	for g in geodes:
		if is_instance_valid(g):
			g.queue_free()
	geodes.clear()
	_detonated_freed = 0
	var run_seed := RunSeed.new(stats.run_seed)
	loot_rng = run_seed.stream(RunSeed.STREAM_LOOT)
	var vfx_rng := run_seed.stream(RunSeed.STREAM_VFX)
	for entry in layout(run_seed, stats, geode_stats.class_count(), torus, avoid):
		var g := GEODE_SCENE.instantiate() as SectorGeode
		g.configure(geode_stats, int(entry.size_class), entry.pos as Vector2, torus, shard_field, loot_rng, vfx_rng)
		add_child(g)
		g.tree_exiting.connect(_on_geode_exiting.bind(g))
		LedgerCompass.register(g, COMPASS_KIND)
		geodes.append(g)
	place_images()


## Pure layout: per geode, size class then position, both from the `map` stream (seam 0).
## Returns [{size_class: int, pos: Vector2}] with every pos wrapped into the torus.
static func layout(run_seed: RunSeed, p_stats: GeodeSandboxStats, class_count: int, p_torus: Torus, avoid: Vector2) -> Array[Dictionary]:
	var rng := run_seed.stream(RunSeed.STREAM_MAP)
	var out: Array[Dictionary] = []
	for _i in p_stats.geode_count:
		var size_class := rng.randi_range(0, class_count - 1)
		var p := Vector2.ZERO
		for _t in maxi(1, p_stats.placement_attempts):
			p = Vector2(rng.randf() * p_torus.size.x, rng.randf() * p_torus.size.y)
			if p_torus.distance(p, avoid) >= p_stats.spawn_clear_radius_px:
				break
		out.append({"size_class": size_class, "pos": p_torus.wrap(p)})
	return out


func alive_count() -> int:
	var n := 0
	for g in geodes:
		if is_instance_valid(g) and g.alive:
			n += 1
	return n


## Geodes destroyed by over-fire (not calm mining). Dev/QA read via the `sector/field` probe.
func detonated_count() -> int:
	var n := _detonated_freed
	for g in geodes:
		if is_instance_valid(g) and g.detonated and g.is_inside_tree():
			n += 1
	return n


func _on_geode_exiting(g: SectorGeode) -> void:
	if g.detonated and geodes.has(g):
		_detonated_freed += 1


func _physics_process(_delta: float) -> void:
	place_images()


## Moves each live geode to the image of its home nearest the reference.
func place_images() -> void:
	if torus == null:
		return
	var has_ref := reference != null and is_instance_valid(reference)
	var ref := reference.global_position if has_ref else Vector2.ZERO
	for g in geodes:
		if not is_instance_valid(g) or not g.alive:
			continue
		var at := (ref + torus.delta(ref, g.home)) if has_ref else g.home
		if g.position != at:
			g.position = at
