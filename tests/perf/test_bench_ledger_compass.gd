extends GdUnitTestSuite
## Keeps the compass bench runnable: a short run fills the 8-marker cap from 16 targets, draws the
## markers every frame and the static layer at most 10 Hz. Asserts no timing (TECH-001 §8.3).

const Bench := preload("res://tests/perf/bench_ledger_compass.gd")


func test_short_bench_run_reports_the_cap_and_layers() -> void:
	var host: Node = auto_free(Node.new())
	add_child(host)
	var r: Dictionary = await Bench.run_bench(host, 60)
	assert_int(int(r.frames)).is_equal(60)
	assert_int(int(r.targets)).is_equal(16)
	assert_int(int(r.markers)).is_equal(8)
	assert_int(int(r.marker_draws)).is_greater_equal(60)
	assert_int(int(r.static_draws)).is_less_equal(11)
	assert_bool((r.frame_ms as Dictionary).has("p95")).is_true()
