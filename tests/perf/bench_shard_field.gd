extends Node
## bench_shard_field (TECH-001 §8.3): drives ShardField at its worst case (the full 144-shard pool,
## Q-T58) for 60 s of 60 Hz ticks with a fixed seed, and writes p50/p95/p99 of the per-tick
## subsystem time to reports/perf/<date>_<build>.json. Budget: ≤ 0.3 ms per tick ✱ (§4.3, §8.1).
## Run: <godot> --headless --path . res://tests/perf/bench_shard_field.tscn
##
## Worst case modelled: every slot alive and drifting; the magnet always on (collected shards are
## respawned outside the timing so the pool stays full); the collector circles the torus so shards
## keep entering the magnet window; 24 Grub queries per 6 ticks (one per SYS-001 §9 geode cap, the
## number of glass carriers is not set yet ✱), spread 4 per tick. The render upload (MultiMesh) is
## timed separately because it belongs to the "Other rendering" row of §8.1.

const WORLD := Vector2(1920, 720)   ## Q-T57 M1 torus ✱
const TICKS := 3600                 ## 60 s at 60 Hz (§8.3)
const DT := 1.0 / 60.0
const SEED := 20261118
const GRUB_QUERIES := 24
const ORBIT_PX := 300.0
const ORBIT_RAD_S := 0.8

var results: Dictionary = {}


func _ready() -> void:
	results = run_bench(self, TICKS)
	print("BENCH shard_field: ", JSON.stringify(results))
	_write(results)
	get_tree().quit(0)


static func run_bench(host: Node, ticks: int) -> Dictionary:
	var root := Node2D.new()
	host.add_child(root)
	var mag := ChargeMagazine.new()
	mag.stats = ChargeMagazineStats.new()
	mag.stats.capacity = 1 << 30   # never full: the magnet stays on (worst case)
	var field: ShardField = (load("res://features/charges/shard_field.tscn") as PackedScene).instantiate()
	field.magazine = mag
	var collector := Node2D.new()
	root.add_child(mag)
	root.add_child(field)
	root.add_child(collector)
	var torus := Torus.new(WORLD)
	field.setup(torus)
	field.collector = collector
	field.collector_radius_px = 6.0
	var rng := RunSeed.new(SEED).stream(RunSeed.STREAM_VFX)
	var refill := func() -> void:
		while field.live_count() < field.pool_size():
			field.spawn(Vector2(rng.randf() * WORLD.x, rng.randf() * WORLD.y),
				Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 140.0))
	refill.call()
	var grubs := PackedVector2Array()
	for k in GRUB_QUERIES:
		grubs.append(Vector2(rng.randf() * WORLD.x, rng.randf() * WORLD.y))
	var step_us := PackedFloat64Array()
	var render_us := PackedFloat64Array()
	var mm_ok := field.get_node_or_null("%ShardMesh") != null
	for t in ticks:
		var ang := t * DT * ORBIT_RAD_S
		collector.position = torus.wrap(WORLD * 0.5 + Vector2(cos(ang) * ORBIT_PX * 2.0, sin(ang) * ORBIT_PX))
		var t0 := Time.get_ticks_usec()
		field.step(DT)
		for g in GRUB_QUERIES:
			if field.grub_query_due(t, g):
				field.nearest_free(grubs[g], field.stats.magnet_radius_px)
		var t1 := Time.get_ticks_usec()
		field.update_render()
		var t2 := Time.get_ticks_usec()
		step_us.append(float(t1 - t0))
		render_us.append(float(t2 - t1))
		refill.call()
	var out := {
		"bench": "shard_field",
		"ticks": ticks,
		"shards": field.pool_size(),
		"collected": field.collected_total,
		"latches": field.latch_count,
		"multimesh": mm_ok,
		"step_ms": _percentiles(step_us),
		"render_upload_ms": _percentiles(render_us),
		"budget_ms": 0.3,
		"engine": Engine.get_version_info().string,
		"cpu": OS.get_processor_name(),
		"debug_build": OS.is_debug_build(),
	}
	root.free()
	return out


static func _percentiles(samples: PackedFloat64Array) -> Dictionary:
	var s := Array(samples)
	s.sort()
	var pick := func(q: float) -> float:
		return float(s[clampi(int(ceil(q * s.size())) - 1, 0, s.size() - 1)]) / 1000.0
	var total := 0.0
	for v in s:
		total += float(v)
	return {"p50": pick.call(0.5), "p95": pick.call(0.95), "p99": pick.call(0.99),
		"max": float(s[s.size() - 1]) / 1000.0, "mean": total / s.size() / 1000.0}


func _write(r: Dictionary) -> void:
	var dir := ProjectSettings.globalize_path("res://reports/perf")
	DirAccess.make_dir_recursive_absolute(dir)
	var date := Time.get_date_string_from_system()
	var path := dir.path_join("%s_%s_shard_field.json" % [date, "local"])
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(r, "\t"))
		print("BENCH written: ", path)
