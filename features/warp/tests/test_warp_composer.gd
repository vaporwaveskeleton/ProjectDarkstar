extends GdUnitTestSuite
## WarpComposer in the PM-01 sector (TECH-001 §5.1; WARP-001 §1.4, §2.2, §4.4, §4.5, §5.1): the T1
## standing set comes up after the entry quiet, Frayed brings W1-06/W1-07, Steady Ledger pins
## W1-09/W1-10 off, teeth and breathing never touch a hitbox, and the Warp Tier passive drains Composure.

const SCENE := "res://scenes/sector/sector_stub.tscn"
const STANDING: Array[StringName] = [&"W1-01", &"W1-02", &"W1-03", &"W1-05", &"W1-08"]

var _was: Dictionary = {}
var _was_persist := true


func before_test() -> void:
	_was_persist = SettingsService.persist
	SettingsService.persist = false
	for k: StringName in [&"steady_ledger", &"photosensitivity", &"reduced_motion"]:
		_was[k] = SettingsService.get_value(k)


func after_test() -> void:
	for k: StringName in _was.keys():
		SettingsService.set_value(k, _was[k])
	SettingsService.persist = _was_persist
	get_tree().paused = false


func _sector() -> Node:
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	var w: WarpComposer = sector.get_node("%WarpComposer")
	w.set_physics_process(false)
	return sector


func _warp(sector: Node) -> WarpComposer:
	return sector.get_node("%WarpComposer") as WarpComposer


func _run(w: WarpComposer, seconds: float) -> void:
	var steps := int(seconds * 60.0)
	for i in steps:
		w.step(1.0 / 60.0)


func test_sector_runs_at_t1_and_nothing_fires_in_the_entry_quiet() -> void:
	var w := _warp(_sector())
	assert_int(w.current_tier()).is_equal(1)
	assert_bool(w.runs_set()).is_true()
	_run(w, 1.9)
	assert_int(w.live_count()).is_equal(0)
	_run(w, 0.2)
	for id in STANDING:
		assert_bool(w.is_live(id)).override_failure_message(str(id)).is_true()
	assert_float(w.live_cost_ms()).is_less_equal(w.warp_set.budget_ms)


func test_pm01_far_look_represents_w1_01_and_w1_03() -> void:
	var w := _warp(_sector())
	for e in w.warp_set.effects:
		if e.represented_by == &"aether_look":
			assert_bool(w.far.look.warp_effects.has(String(e.id))).override_failure_message(str(e.id)).is_true()


func test_teeth_ring_every_geode_without_touching_its_hurtbox() -> void:
	var sector := _sector()
	var w := _warp(sector)
	var radii: Dictionary = {}
	for n in sector.get_tree().get_nodes_in_group(LedgerCompass.GROUP):
		if LedgerCompass.kind_of(n) == &"geode":
			radii[n] = ((n.get_node("%HurtShape") as CollisionShape2D).shape as CircleShape2D).radius
	assert_int(radii.size()).is_greater(0)
	_run(w, 6.0)
	for n: Node in radii.keys():
		assert_bool(n.has_node(^"WarpTeeth")).is_true()
		var shape := (n.get_node("%HurtShape") as CollisionShape2D).shape as CircleShape2D
		assert_float(shape.radius).is_equal(float(radii[n]))
		assert_vector((n as Node2D).scale).is_equal(Vector2.ONE)


func test_breathing_scales_views_only() -> void:
	var sector := _sector()
	var w := _warp(sector)
	_run(w, 5.0)
	var saw_breath := false
	for n in sector.get_tree().get_nodes_in_group(LedgerCompass.GROUP):
		var kind := LedgerCompass.kind_of(n)
		if kind != &"grub" and kind != &"sepulchre":
			continue
		assert_vector((n as Node2D).scale).is_equal(Vector2.ONE)   # the body (and its hitbox) never scales
		for c in n.get_children():
			if c is GrubView or c is SepulchreView:
				var s := (c as Node2D).scale.x
				assert_float(absf(s - 1.0)).is_less_equal(w.warp_set.breath_px / 8.0 + 0.0001)
				if not is_equal_approx(s, 1.0):
					saw_breath = true
	assert_bool(saw_breath).is_true()


func test_warp_tier_passive_drains_composure() -> void:
	var sector := _sector()
	var w := _warp(sector)
	var before: float = sector.composure
	_run(w, 10.0)
	# SYS-001 §1.5 `Warp Tier passive` −0.1/s × T at T1 (Composure also ticks on its own physics).
	assert_float(sector.composure).is_less(before - 0.7)   # 8 s after the 2 s entry quiet


func test_frayed_brings_the_chromatic_edge_and_false_chant() -> void:
	SettingsService.set_value(&"photosensitivity", false)
	var sector := _sector()
	var w := _warp(sector)
	_run(w, 3.0)
	w.composure.change(6.9 - w.composure.value)
	assert_int(w.composure.band).is_equal(Composure.Band.FRAYED)
	_run(w, 0.1)
	assert_bool(w.is_live(&"W1-06")).is_true()
	assert_bool(w.far.backdrop.chromatic_edge).is_true()
	_run(w, w.warp_set.false_chant_period_s * WarpComposer.FIRST_FALSE_CHANT + 0.1)
	assert_bool(w.is_live(&"W1-07")).is_true()
	assert_int(w.schedule.novel_used).is_equal(1)
	_run(w, w.warp_set.false_chant_s + 0.1)
	assert_bool(w.is_live(&"W1-07")).is_false()
	w.composure.change(8.0 - w.composure.value)
	_run(w, 0.1)
	assert_bool(w.is_live(&"W1-06")).is_false()


func test_photosensitivity_never_draws_the_edge_split() -> void:
	SettingsService.set_value(&"photosensitivity", true)
	var sector := _sector()
	var w := _warp(sector)
	_run(w, 3.0)
	w.composure.change(5.5 - w.composure.value)
	_run(w, 0.2)
	assert_bool(w.is_live(&"W1-06")).is_true()
	assert_bool((w.get_node("WarpEdge/ChromaticEdge") as CanvasItem).visible).is_false()


func test_steady_ledger_pins_smear_and_glyph_off() -> void:
	SettingsService.set_value(&"steady_ledger", true)
	var w := _warp(_sector())
	_run(w, w.warp_set.transient_latest_s + w.warp_set.blip_smear_s + 1.0)
	assert_bool(w.is_live(&"W1-09")).is_false()
	assert_bool(w.is_live(&"W1-10")).is_false()
	assert_int(w.liar.deviations_used).is_equal(0)


func test_steady_ledger_off_lets_the_t1_smear_and_glyph_run_once() -> void:
	SettingsService.set_value(&"steady_ledger", false)
	var w := _warp(_sector())
	var saw: Dictionary = {}
	var t := 0.0
	var until := w.warp_set.transient_latest_s + maxf(w.warp_set.blip_smear_s, w.warp_set.glyph_s) + 1.0
	while t < until:
		w.step(0.25)
		t += 0.25
		for id: StringName in [&"W1-09", &"W1-10"]:
			if w.is_live(id):
				saw[id] = true
	assert_bool(saw.has(&"W1-09")).is_true()
	assert_bool(saw.has(&"W1-10")).is_true()
	assert_int(w.liar.deviations_used).is_equal(2)
	assert_bool(w.is_live(&"W1-09") or w.is_live(&"W1-10")).is_false()
