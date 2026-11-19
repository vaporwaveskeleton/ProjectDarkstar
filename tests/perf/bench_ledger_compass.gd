extends Node
## bench_ledger_compass (TECH-001 §5.4, §8.3): drives the Ledger Compass at its marker cap (8 ✱) on
## the M1 torus (1920 × 720, Q-T58) for 60 s of frames with a fixed seed, and writes p50/p95/p99/max
## of the per-frame compass time to reports/perf/<date>_local_ledger_compass.json.
## Budget: ≤ 0.2 ms per frame ✱ (§5.4, §8.1).
## Run: <godot> --headless --path . res://tests/perf/bench_ledger_compass.tscn
##
## Worst case modelled: 16 registered targets (the Vigil, a Sepulchre, 4 Grubs, 10 geodes, as the
## sector sandbox), all moving every frame, so the rank sort and the cap run on a full group; the
## static layer is invalidated every frame, so it redraws at its 10 Hz ✱ ceiling. Per frame we time
## `LedgerCompass.tick` (sample, model, mapping, queue) plus the two `_draw` passes that frame
## (markers every frame; the static layer when it redrew), read from the layers' own timers.

const WORLD := Vector2(1920, 720)   ## Q-T58 M1 torus ✱
const FRAMES := 3600                ## 60 s at 60 Hz (§8.3)
const DT := 1.0 / 60.0
const SEED := 20261119
const GEODES := 10
const GRUBS := 4
const STATS := preload("res://data/hud/ledger_compass.tres")

var results: Dictionary = {}


func _ready() -> void:
	results = await run_bench(self, FRAMES)
	print("BENCH ledger_compass: ", JSON.stringify(results))
	_write(results)
	get_tree().quit(0)


static func run_bench(host: Node, frames: int) -> Dictionary:
	var world := Node2D.new()
	host.add_child(world)
	var hud := CanvasLayer.new()
	host.add_child(hud)
	var torus := Torus.new(WORLD)
	var rng := RunSeed.new(SEED).stream(RunSeed.STREAM_VFX)
	var movers: Array[Node2D] = []
	var vel: Array[Vector2] = []
	var add := func(kind: StringName, rank: int, vigil: bool) -> void:
		var n := Node2D.new()
		world.add_child(n)
		n.position = Vector2(rng.randf() * WORLD.x, rng.randf() * WORLD.y)
		if vigil:
			n.add_to_group(LedgerCompass.VIGIL_GROUP)
		else:
			LedgerCompass.register(n, kind, rank)
		movers.append(n)
		vel.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(40.0, 260.0))
	add.call(LedgerCompass.KIND_VIGIL, 0, true)
	add.call(LedgerCompass.KIND_SEPULCHRE, 0, false)
	for i in GRUBS:
		add.call(LedgerCompass.KIND_GRUB, 10, false)
	for i in GEODES:
		add.call(&"geode", LedgerCompass.RANK_DEFAULT, false)
	var compass := LedgerCompass.new()
	compass.stats = STATS
	hud.add_child(compass)
	compass.set_process(false)
	compass.world_rect = Rect2(Vector2.ZERO, WORLD)
	compass.torus = torus
	var markers: LedgerCompassMarkers = compass.get_node(^"Markers")
	var static_layer: LedgerCompassStatic = compass.get_node(^"Static")
	var frame_us := PackedFloat64Array()
	var tick_us := PackedFloat64Array()
	var static_draws := 0
	for f in frames + 1:
		for i in movers.size():
			movers[i].position = torus.wrap(movers[i].position + vel[i] * DT)
		compass.invalidate_static()
		var mk_before := markers.draw_count
		var st_before := static_layer.draw_count
		var t0 := Time.get_ticks_usec()
		compass.tick(DT)
		var t1 := Time.get_ticks_usec()
		await host.get_tree().process_frame   # the deferred `_draw` passes run here
		if f == 0:
			continue   # warm-up frame (first static draw, script caches)
		var us := float(t1 - t0)
		tick_us.append(us)
		if markers.draw_count > mk_before:
			us += float(markers.last_draw_usec)
		if static_layer.draw_count > st_before:
			us += float(static_layer.last_draw_usec)
			static_draws += 1
		frame_us.append(us)
	var out := {
		"bench": "ledger_compass",
		"frames": frames,
		"targets": movers.size(),
		"markers": compass.marker_points.size(),
		"marker_draws": markers.draw_count,
		"static_draws": static_draws,
		"frame_ms": _percentiles(frame_us),
		"tick_ms": _percentiles(tick_us),
		"budget_ms": 0.2,
		"engine": Engine.get_version_info().string,
		"cpu": OS.get_processor_name(),
		"debug_build": OS.is_debug_build(),
	}
	hud.free()
	world.free()
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
	var path := dir.path_join("%s_%s_ledger_compass.json" % [date, "local"])
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(r, "\t"))
		print("BENCH written: ", path)
