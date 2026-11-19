class_name ShardField
extends Node2D
## Mourning Glass shards and the Vigil's magnet (TECH-001 §4.3, SYS-001 §1.4).
## No node and no physics body per shard: positions, velocities and flags live in packed arrays
## (struct of arrays), indexed by a fixed pool. A uniform grid of `grid_cell_px` cells answers
## circle queries (the magnet, Grubs). All shard positions are torus positions: stored wrapped,
## compared with `Torus.delta` (the shortest way round). The sector injects the Torus.
## One MultiMeshInstance2D draws every shard (one draw call).
##
## Pool exhaustion: shards never despawn (SYS-001 §1.4), so when every slot holds a live shard a new
## spawn is refused (`spawn` returns -1, `spawns_refused` counts it). Nothing crashes, nothing is
## recycled. Pool size is PM ruling Q-T58 (144).

const FLAG_ALIVE := 1
const FLAG_CLAIMED := 2   ## a Grub has claimed it (Grub hook; no Grubs in M1 yet)
const NONE := -1
## Diamond width / height ratio of the drawn shard (presentation, mirrors the Cabinet).
const DIAMOND_WIDTH_RATIO := 0.6
const CORE_RATIO := 0.35

@export var stats: ShardFieldStats
## Collected shards go here (one shard = one Charge). With the magazine full, the magnet is off and
## overflow glass stays in the world (SYS-001 §1.4).
@export var magazine: ChargeMagazine

## Injected by the sector (TECH-001 §4.3; one world size, Q-T57).
var torus: Torus
## The magnet's centre (the Vigil). Null = no magnet.
var collector: Node2D
## Collector body radius (px); pickup distance = this + shard radius + margin.
var collector_radius_px: float = 0.0

var score: int = 0
var collected_total: int = 0
var spawns_refused: int = 0
var latch_count: int = 0
var tick_count: int = 0

var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var flags := PackedInt32Array()

var _latch_tick := PackedInt32Array()   ## tick a shard was last inside the magnet radius
var _cell := PackedInt32Array()          ## grid cell per shard, NONE when dead
var _next := PackedInt32Array()          ## intrusive doubly linked list per cell
var _prev := PackedInt32Array()
var _cell_head := PackedInt32Array()
var _cols: int = 0
var _rows: int = 0
var _free_slots := PackedInt32Array()   ## stack of unused pool slots
var _live := PackedInt32Array()          ## dense list of live shard indices
var _live_at := PackedInt32Array()       ## index into _live per shard, NONE when dead
var _multimesh: MultiMesh

@onready var _mesh_instance: MultiMeshInstance2D = get_node_or_null("%ShardMesh")


func _ready() -> void:
	process_physics_priority = 30   # Economy stage (TECH-001 §4.1)
	if torus != null and positions.is_empty():
		setup(torus)


## Allocates the pool and grid for `p_torus`. Call once the world size is known.
func setup(p_torus: Torus) -> void:
	torus = p_torus
	var n := stats.pool_size
	positions.resize(n)
	velocities.resize(n)
	flags.resize(n)
	_latch_tick.resize(n)
	_cell.resize(n)
	_next.resize(n)
	_prev.resize(n)
	_live_at.resize(n)
	_free_slots.resize(n)
	_live = PackedInt32Array()
	for i in n:
		positions[i] = Vector2.ZERO
		velocities[i] = Vector2.ZERO
		flags[i] = 0
		_latch_tick[i] = NONE
		_cell[i] = NONE
		_next[i] = NONE
		_prev[i] = NONE
		_live_at[i] = NONE
		_free_slots[i] = n - 1 - i   # pop() hands out slot 0 first
	_cols = cell_count(torus.size.x, stats.grid_cell_px)
	_rows = cell_count(torus.size.y, stats.grid_cell_px)
	_cell_head = PackedInt32Array()
	_cell_head.resize(_cols * _rows)
	_cell_head.fill(NONE)
	score = 0
	collected_total = 0
	spawns_refused = 0
	latch_count = 0
	tick_count = 0
	_setup_render()


func pool_size() -> int:
	return positions.size()


func live_count() -> int:
	return _live.size()


## Live shards no Grub has claimed.
func free_count() -> int:
	var n := 0
	for i in _live:
		if flags[i] & FLAG_CLAIMED == 0:
			n += 1
	return n


func is_alive(i: int) -> bool:
	return i >= 0 and i < flags.size() and flags[i] & FLAG_ALIVE != 0


func live_indices() -> PackedInt32Array:
	return _live.duplicate()


## Adds a shard; returns its index, or -1 when the pool is full (counted in `spawns_refused`).
func spawn(at: Vector2, vel: Vector2) -> int:
	if _free_slots.is_empty():
		spawns_refused += 1
		return NONE
	var i := _free_slots[_free_slots.size() - 1]
	_free_slots.resize(_free_slots.size() - 1)
	positions[i] = torus.wrap(at)
	velocities[i] = vel
	flags[i] = FLAG_ALIVE
	_latch_tick[i] = NONE
	_live_at[i] = _live.size()
	_live.append(i)
	_link(i, cell_of(positions[i]))
	return i


func _physics_process(delta: float) -> void:
	if torus != null and not positions.is_empty():
		step(delta)


func _process(_delta: float) -> void:
	update_render()


## One economy tick: magnet window, pickup, drag, drift. Deterministic for a given input.
func step(delta: float) -> void:
	tick_count += 1
	var damp := exp(-stats.drag_per_s * delta)
	var steer := clampf(delta * stats.magnet_steer_per_s, 0.0, 1.0)
	var pull := stats.magnet_pull_px_s * (-1.0 if stats.magnet_inverted else 1.0)
	var target := Vector2.ZERO
	if magnet_active():
		target = torus.wrap(collector.global_position)
		var pickup := collector_radius_px + stats.shard_radius_px + stats.collect_margin_px
		for i in query_circle(target, stats.magnet_radius_px):
			if _latch_tick[i] != tick_count - 1:
				latch_count += 1
				AudioService.play(&"magnet_latch")
			_latch_tick[i] = tick_count
			if torus.distance(positions[i], target) < pickup:
				_collect(i)
				if not magnet_active():
					break   # the magazine just filled: the rest stays in the world
	var k := 0
	while k < _live.size():
		var i := _live[k]
		var inside := _latch_tick[i] == tick_count
		var to_target := torus.delta(positions[i], target) if inside else Vector2.ZERO
		var v := step_velocity(velocities[i], to_target, inside, damp, steer, pull)
		velocities[i] = v
		var p := torus.wrap(positions[i] + v * delta)
		positions[i] = p
		var c := cell_of(p)
		if c != _cell[i]:
			_unlink(i)
			_link(i, c)
		k += 1


## Magnet is on while there is a collector and room in the magazine.
func magnet_active() -> bool:
	return collector != null and is_instance_valid(collector) and magazine != null and not magazine.is_full()


## Pure velocity step. Outside the magnet: exponential drift drag. Inside: steer toward the pull
## with no drag, so the shard settles at exactly the pull speed (SYS-001 §1.4 "170 px/s"; PM
## 2026-11-18; the Cabinet's glass_field.gd does the same).
## `damp` = exp(-drag * dt); `steer` = clamp(dt * steer_rate, 0, 1); `pull` is signed (H4).
static func step_velocity(v: Vector2, to_target: Vector2, inside: bool, damp: float, steer: float, pull: float) -> Vector2:
	if inside and to_target != Vector2.ZERO:
		return v.lerp(to_target.normalized() * pull, steer)
	return v * damp


func _collect(i: int) -> void:
	_remove(i)
	collected_total += 1
	score += stats.score_per_shard
	AudioService.play(&"shard_chime")
	if magazine != null:
		magazine.try_add(1)


func _remove(i: int) -> void:
	_unlink(i)
	flags[i] = 0
	var k := _live_at[i]
	var last := _live[_live.size() - 1]
	_live[k] = last
	_live_at[last] = k
	_live.resize(_live.size() - 1)
	_live_at[i] = NONE
	_free_slots.append(i)


# --- Grub hook (TECH-001 §4.3) --------------------------------------------------------------------

## True on the ticks a Grub may ask the grid for glass (once per `grub_query_interval_ticks`).
func grub_query_due(tick: int, offset: int = 0) -> bool:
	var every := maxi(1, stats.grub_query_interval_ticks)
	return posmod(tick + offset, every) == 0


## Nearest live, unclaimed shard within `radius` of `at` (torus distance), or -1.
func nearest_free(at: Vector2, radius: float) -> int:
	var best := NONE
	var best_d := INF
	for i in query_circle(at, radius):
		if flags[i] & FLAG_CLAIMED != 0:
			continue
		var d := torus.distance_sq(at, positions[i])
		if d < best_d:
			best_d = d
			best = i
	return best


func claim(i: int) -> bool:
	if not is_alive(i) or flags[i] & FLAG_CLAIMED != 0:
		return false
	flags[i] |= FLAG_CLAIMED
	return true


func release_claim(i: int) -> void:
	if is_alive(i):
		flags[i] &= ~FLAG_CLAIMED


# --- grid -----------------------------------------------------------------------------------------

## Cells needed to cover `world` px with `cell` px cells (the last one may be partial: 720/64 = 12).
static func cell_count(world: float, cell: float) -> int:
	return maxi(1, ceili(world / cell))


## Grid cell of a wrapped position.
func cell_of(p: Vector2) -> int:
	var cx := clampi(int(p.x / stats.grid_cell_px), 0, _cols - 1)
	var cy := clampi(int(p.y / stats.grid_cell_px), 0, _rows - 1)
	return cy * _cols + cx


## Cell indices along one axis covering [lo, hi] on a wrapping axis of length `world`.
## Handles the partial last cell (world not a multiple of cell) and spans that cross the seam.
static func cell_span(lo: float, hi: float, world: float, cell: float, count: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if hi - lo >= world:
		for c in count:
			out.append(c)
		return out
	var a := fposmod(lo, world)
	var b := a + (hi - lo)
	var first := mini(int(a / cell), count - 1)
	if b < world:
		for c in range(first, mini(int(b / cell), count - 1) + 1):
			out.append(c)
		return out
	for c in range(first, count):
		out.append(c)
	for c in range(0, mini(int((b - world) / cell), count - 1) + 1):
		if c >= first:
			break   # already listed
		out.append(c)
	return out


## Live shards within `radius` of `at` (torus distance, inclusive).
func query_circle(at: Vector2, radius: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var cell := stats.grid_cell_px
	var xs := cell_span(at.x - radius, at.x + radius, torus.size.x, cell, _cols)
	var ys := cell_span(at.y - radius, at.y + radius, torus.size.y, cell, _rows)
	var r2 := radius * radius
	for cy in ys:
		var row := cy * _cols
		for cx in xs:
			var i := _cell_head[row + cx]
			while i != NONE:
				if torus.distance_sq(at, positions[i]) <= r2:
					out.append(i)
				i = _next[i]
	return out


## Count of shards in one cell (tests).
func cell_population(c: int) -> int:
	var n := 0
	var i := _cell_head[c]
	while i != NONE:
		n += 1
		i = _next[i]
	return n


func grid_size() -> Vector2i:
	return Vector2i(_cols, _rows)


func _link(i: int, c: int) -> void:
	_cell[i] = c
	_prev[i] = NONE
	_next[i] = _cell_head[c]
	if _cell_head[c] != NONE:
		_prev[_cell_head[c]] = i
	_cell_head[c] = i


func _unlink(i: int) -> void:
	var c := _cell[i]
	if c == NONE:
		return
	if _prev[i] != NONE:
		_next[_prev[i]] = _next[i]
	else:
		_cell_head[c] = _next[i]
	if _next[i] != NONE:
		_prev[_next[i]] = _prev[i]
	_cell[i] = NONE
	_next[i] = NONE
	_prev[i] = NONE


# --- render ---------------------------------------------------------------------------------------

func _setup_render() -> void:
	if _mesh_instance == null:
		return
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.mesh = _build_mesh(stats.shard_radius_px)
	_multimesh.instance_count = pool_size()
	_multimesh.visible_instance_count = 0
	_mesh_instance.multimesh = _multimesh


## Writes one transform per live shard, at the image nearest the collector (torus-aware drawing).
func update_render() -> void:
	if _multimesh == null:
		return
	var use_ref := collector != null and is_instance_valid(collector)
	var ref := collector.global_position if use_ref else Vector2.ZERO
	for k in _live.size():
		var p := positions[_live[k]]
		var at := ref + torus.delta(ref, p) if use_ref else p
		_multimesh.set_instance_transform_2d(k, Transform2D(0.0, at.round()))
	_multimesh.visible_instance_count = _live.size()


## Diamond of Mourning Glass: phosphor body, bright core (phosphor = truth, ART-001 role law).
static func _build_mesh(radius: float) -> ArrayMesh:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var w := radius * DIAMOND_WIDTH_RATIO
	var core := radius * CORE_RATIO
	for d: Array in [[radius, w, Pal.PHOS_3], [core, core, Pal.PHOS_5]]:
		var h: float = d[0]
		var hw: float = d[1]
		var c: Color = d[2]
		var top := Vector2(0, -h)
		var right := Vector2(hw, 0)
		var bottom := Vector2(0, h)
		var left := Vector2(-hw, 0)
		verts.append_array(PackedVector2Array([top, right, bottom, top, bottom, left]))
		for _k in 6:
			cols.append(c)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
