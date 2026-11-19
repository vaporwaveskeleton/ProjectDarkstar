extends GdUnitTestSuite
## Frame-time windows (frame_stats.gd), the flash-rule watch (luma_watch.gd) and the runner steps
## perf_begin / perf_end / luma_begin / luma_end, under a minimal fake Boot with in-memory saves.

const Runner := preload("res://core/automation/scenario_runner.gd")
const FrameStats := preload("res://core/automation/frame_stats.gd")
const LumaWatch := preload("res://core/automation/luma_watch.gd")
const OUT := "user://automation_test_perf/"

var _boot: Node
var _prev_backend: SaveBackend
var _prev_persist: bool


func before_test() -> void:
	_prev_backend = SaveService.backend
	_prev_persist = SettingsService.persist
	SaveService.set_backend(MemorySaveBackend.new())
	_boot = Node.new()
	var host := Node.new()
	host.name = "RouteHost"
	_boot.add_child(host)
	host.unique_name_in_owner = true
	host.owner = _boot
	add_child(_boot)


func after_test() -> void:
	_boot.free()
	SaveService.set_backend(_prev_backend)
	SettingsService.persist = _prev_persist


func _run(steps: Array) -> Node:
	var r: Node = Runner.new()
	r.setup({"format": "darkstar.scenario", "version": 1, "id": "t_perf", "timeout_frames": 300, "steps": steps},
		{"out_dir": OUT + "t_perf", "quit_on_finish": false, "source": "cli"})
	_boot.add_child(r)
	if not r.done:
		await await_signal_on(r, "scenario_finished", [], 20000)
	return r


## Feeds `n` frames of a uniform field whose luminance is f(frame). full >= 0 pins the whole-field
## mean (so a test can look at the per-cell flicker rule alone).
func _feed(w: LumaWatch, n: int, f: Callable, full := -1.0) -> void:
	for i in n:
		var l: float = f.call(i)
		var cells := PackedFloat64Array()
		cells.resize(LumaWatch.GRID.x * LumaWatch.GRID.y)
		cells.fill(l)
		w.add_cells(i, cells, l if full < 0.0 else full)


# --- frame_stats -------------------------------------------------------------------------------

func test_percentiles_are_nearest_rank() -> void:
	var s := PackedFloat64Array()
	for i in 100:
		s.append(float(i + 1))   # 1..100 ms
	var r := FrameStats.summarise(s)
	assert_int(int(r.frames)).is_equal(100)
	assert_float(float(r.p50_ms)).is_equal(50.0)
	assert_float(float(r.p95_ms)).is_equal(95.0)
	assert_float(float(r.p99_ms)).is_equal(99.0)
	assert_float(float(r.max_ms)).is_equal(100.0)
	assert_float(float(r.mean_ms)).is_equal(50.5)


func test_empty_window_is_all_zero() -> void:
	var r := FrameStats.summarise(PackedFloat64Array())
	assert_int(int(r.frames)).is_equal(0)
	assert_float(float(r.p99_ms)).is_equal(0.0)


# --- luma_watch --------------------------------------------------------------------------------

func test_steady_and_slow_ramps_pass() -> void:
	var w := LumaWatch.new()
	_feed(w, 240, func(i: int) -> float: return 0.1 + 0.002 * i)   # 0.12 per second, monotonic
	var r := w.report()
	assert_bool(bool(r.ok)).is_true()
	assert_int(int(r.soft_steps)).is_equal(0)


func test_four_hz_flicker_is_flagged() -> void:
	var w := LumaWatch.new()
	_feed(w, 120, func(i: int) -> float: return 0.6 if (i / 8) % 2 == 1 else 0.1)   # ~3.75 cycles/s
	var r := w.report()
	assert_bool(bool(r.ok)).is_false()
	assert_int((r.violations as Array).filter(func(v: Dictionary) -> bool: return v.kind == "flicker").size()).is_greater(0)
	assert_float(float(r.max_cycles_per_s)).is_greater(3.0)


func test_two_hz_flicker_is_within_the_rule() -> void:
	var w := LumaWatch.new()
	_feed(w, 180, func(i: int) -> float: return 0.3 if (i / 15) % 2 == 1 else 0.1)   # 2 cycles/s, small steps
	var r := w.report()
	assert_float(float(r.max_cycles_per_s)).is_less_equal(3.0)
	assert_int((r.violations as Array).filter(func(v: Dictionary) -> bool: return v.kind == "flicker").size()).is_equal(0)


func test_bright_only_swings_are_not_flashes() -> void:
	var w := LumaWatch.new()
	_feed(w, 120, func(i: int) -> float: return 0.98 if i % 4 < 2 else 0.84, 0.9)   # darker side above 0.80
	var r := w.report()
	assert_bool(bool(r.ok)).is_true()


func test_full_field_step_is_flagged_once_per_frame() -> void:
	var w := LumaWatch.new()
	_feed(w, 30, func(i: int) -> float: return 0.05 if i < 15 else 0.4)
	var r := w.report()
	assert_bool(bool(r.ok)).is_false()
	assert_int(int(r.violation_count)).is_equal(1)
	assert_str(str((r.violations as Array)[0].kind)).is_equal("full_field_step")
	assert_int(int(r.max_full_step_frame)).is_equal(15)


func test_add_image_reads_a_solid_frame() -> void:
	var w := LumaWatch.new()
	var img := Image.create(160, 90, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1))
	w.add_image(0, img)
	img.fill(Color(0, 0, 0))
	w.add_image(1, img)
	var r := w.report()
	assert_int(int(r.frames)).is_equal(2)
	assert_float(float(r.max_full_step)).is_equal_approx(1.0, 0.01)


# --- runner steps ------------------------------------------------------------------------------

func test_perf_window_records_percentiles_and_budget() -> void:
	var r := await _run([{"do": "perf_begin", "name": "w"}, {"do": "wait_frames", "frames": 20},
		{"do": "perf_end", "name": "w", "budget_ms": 1000.0}, {"do": "quit"}])
	assert_str(r.result.outcome).is_equal("pass")
	assert_int(r.result.perf_windows.size()).is_equal(1)
	var w: Dictionary = r.result.perf_windows[0]
	assert_str(str(w.name)).is_equal("w")
	assert_int(int(w.frames)).is_greater(0)
	for k in ["p50_ms", "p95_ms", "p99_ms", "max_ms", "mean_ms", "headless"]:
		assert_bool(w.has(k)).override_failure_message(k).is_true()
	assert_bool(bool(w.p50_within_budget)).is_true()


func test_perf_end_without_begin_fails() -> void:
	var r := await _run([{"do": "perf_end", "name": "nope"}, {"do": "quit"}])
	assert_str(r.result.outcome).is_equal("fail")
	assert_str(r.result.steps[0].detail).contains("not open")


func test_open_windows_close_at_finish() -> void:
	var r := await _run([{"do": "perf_begin", "name": "a"}, {"do": "luma_begin", "name": "b"},
		{"do": "wait_frames", "frames": 3}, {"do": "quit"}])
	assert_str(r.result.outcome).is_equal("pass")
	assert_bool(bool(r.result.perf_windows[0].open_at_finish)).is_true()
	assert_bool(bool(r.result.luma_windows[0].open_at_finish)).is_true()


func test_luma_window_is_skipped_headless() -> void:
	if DisplayServer.get_name() != "headless":
		return
	var r := await _run([{"do": "luma_begin", "name": "l"}, {"do": "wait_frames", "frames": 5},
		{"do": "luma_end", "name": "l"}, {"do": "quit"}])
	assert_str(r.result.outcome).is_equal("pass")
	assert_str(str(r.result.luma_windows[0].skipped)).is_equal("headless")


func test_bad_window_name_and_target_fail() -> void:
	var r := await _run([{"do": "perf_begin", "name": "Bad Name"}, {"do": "quit"}])
	assert_str(r.result.outcome).is_equal("fail")
	var r2 := await _run([{"do": "luma_begin", "name": "l", "target": "elsewhere"}, {"do": "quit"}])
	assert_str(r2.result.outcome).is_equal("fail")
