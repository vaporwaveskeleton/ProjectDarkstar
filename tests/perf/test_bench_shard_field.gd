extends GdUnitTestSuite
## Keeps the bench harness runnable: a short run reports a full pool, the magnet working and the
## MultiMesh render path. Asserts no timing (that is the bench's job, TECH-001 §8.3).

const Bench := preload("res://tests/perf/bench_shard_field.gd")


func test_short_bench_run_reports_a_full_pool() -> void:
	SettingsService.persist = false
	var host: Node = auto_free(Node.new())
	add_child(host)
	var r: Dictionary = Bench.run_bench(host, 120)
	assert_int(int(r.ticks)).is_equal(120)
	assert_int(int(r.shards)).is_equal(144)
	assert_bool(bool(r.multimesh)).is_true()
	assert_int(int(r.latches)).is_greater(0)
	assert_bool((r.step_ms as Dictionary).has("p95")).is_true()
	SettingsService.persist = true
