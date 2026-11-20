extends GdUnitTestSuite
## Scenario validator: every rule rejects with a clear message; the catalog and validator agree.

const Schema := preload("res://core/automation/scenario_schema.gd")

const MINIMAL := {
	"wait_frames": {"frames": 1},
	"wait_route": {"route": "attract", "within": 1},
	"wait_until": {"id": "a/ui/b", "prop": "visible", "within": 1, "eq": true},
	"assert": {"id": "a/ui/b", "exists": true},
	"checkpoint": {"name": "c"},
	"quit": {},
	"screenshot": {"name": "s", "target": "arcade"},
	"coin": {},
	"activate": {"id": "a/ui/b"},
	"focus": {"id": "a/ui/b"},
	"cancel": {},
	"goto": {"route": "cabinet"},
	"autopilot": {"on": true},
	"press": {"action": "move_right"},
	"release": {"action": "move_right"},
	"hold": {"action": "move_right", "frames": 2},
	"key": {"keycode": "SHIFT", "frames": 2},
	"mouse_move": {"x": 1.5, "y": 2},
	"mouse_button": {"button": "left", "pressed": true},
	"reset": {},
	"set_setting": {"key": "reduced_motion", "value": true},
	"snapshot": {"name": "snap_one"},
	"wait_event": {"event": "vigil_destroyed", "within": 5},
	"perf_sample": {},
	"perf_begin": {"name": "w_one"}, "perf_end": {"name": "w_one"},
	"luma_begin": {"name": "l_one"}, "luma_end": {"name": "l_one"},
	"set_stage": {"index": 1},
	"set_lives": {"lives": 3},
	"teleport": {"x": 10.5, "y": -20},
	"spawn": {"kind": "acolyte", "dx": 0, "dy": -110},
	"shoot_vigil": {"dx": 0, "dy": -450}, "kill_acolyte": {"acolyte_id": "last"},
	"kill_all": {},
	"pause_sim": {"on": true},
	"step_sim": {"frames": 30}, "wake_entity": {}, "place_entity": {"dx": 0, "dy": -20},
}


func _sc(steps: Array = [{"do": "wait_frames", "frames": 3}]) -> Dictionary:
	return {"format": "darkstar.scenario", "version": 1, "id": "ok_one", "timeout_frames": 100, "steps": steps}


func _step(name: String, extra: Dictionary = {}) -> Dictionary:
	var d: Dictionary = (MINIMAL[name] as Dictionary).duplicate()
	d["do"] = name
	d.merge(extra, true)
	return d


func _expect(sc: Dictionary, text: String, suite := false) -> void:
	var errs := Schema.validate(sc, suite)
	assert_bool(errs.is_empty()).is_false()
	assert_str("\n".join(errs)).contains(text)


func test_valid_scenario_passes() -> void:
	assert_array(Schema.validate(_sc(), false)).is_empty()
	assert_array(Schema.validate(_sc(), true)).is_empty()


func test_top_level_rules() -> void:
	var a := _sc()
	a["format"] = "nope"
	_expect(a, "format")
	var b := _sc()
	b["version"] = 2
	_expect(b, "version")
	var c := _sc()
	c["id"] = "Bad-Id"
	_expect(c, "id must match")
	var d := _sc()
	d["surprise"] = 1
	_expect(d, "unknown top-level key 'surprise'")
	var e := _sc()
	e["timeout_frames"] = 999999
	_expect(e, "timeout_frames")
	var f := _sc()
	f["fixtures"] = {"profile": "Bad Name"}
	_expect(f, "fixtures")
	var g := _sc()
	g["fixtures"] = {"nowhere": "ok_name"}
	_expect(g, "unknown slot")


func test_step_rules() -> void:
	_expect(_sc([{"do": "teleport_home"}]), "unknown step 'teleport_home'")
	_expect(_sc([{"do": "wait_frames"}]), "missing arg 'frames'")
	_expect(_sc([_step("wait_frames", {"extra": 1})]), "unknown arg 'extra'")
	_expect(_sc([_step("wait_frames", {"frames": "ten"})]), "must be int")
	_expect(_sc([_step("wait_until", {"ne": 1})]), "exactly one comparator")
	var none := _step("wait_until")
	none.erase("eq")
	_expect(_sc([none]), "exactly one comparator")
	_expect(_sc([{"do": "assert", "id": "a/ui/b", "prop": "visible"}]), "assert")
	_expect(_sc([_step("assert", {"prop": "visible"})]), "cannot combine")
	_expect(_sc([_step("press", {"action": "no_such_action"})]), "unknown action")
	_expect(_sc([_step("key", {"keycode": "NOT_A_KEY"})]), "unknown keycode")
	_expect(_sc([_step("screenshot", {"name": "Bad Name"})]), "name must match")
	_expect(_sc([_step("screenshot", {"target": "moon"})]), "target")
	_expect(_sc([_step("mouse_move", {"x": "left"})]), "must be number")
	_expect(_sc([_step("mouse_button", {"button": "side"})]), "button")


func test_size_limits() -> void:
	var many: Array = []
	for i in Schema.MAX_STEPS + 1:
		many.append({"do": "wait_frames", "frames": 1})
	_expect(_sc(many), "too many steps")
	var shots: Array = []
	for i in Schema.MAX_SCREENSHOTS + 1:
		shots.append(_step("screenshot"))
	_expect(_sc(shots), "too many screenshots")


func test_suite_extra_rules() -> void:
	var a := _sc()
	a["args"] = ["--autopilot"]
	assert_array(Schema.validate(a, false)).is_empty()
	_expect(a, "args == []", true)
	var b := _sc()
	b["timeout_frames"] = Schema.SUITE_TIMEOUT_FRAMES + 1
	assert_array(Schema.validate(b, false)).is_empty()
	_expect(b, "timeout_frames <=", true)


func test_catalog_and_validator_agree() -> void:
	var steps: Dictionary = Schema.catalog().steps
	assert_int(steps.size()).is_equal(MINIMAL.size())
	for name: String in steps.keys():
		assert_bool(MINIMAL.has(name)).override_failure_message("no minimal form for " + name).is_true()
		var errs := Schema.validate(_sc([_step(name)]), false)
		assert_array(errs).override_failure_message("%s: %s" % [name, errs]).is_empty()


## Long end-to-end scenarios run only from the CLI (tests/test_scenarios.gd skips them): they must
## still be valid scenarios, just not suite-eligible. Each entry is named here on purpose.
## a1_golden_path: coin → Act 0 → reveal → the 94 s Unmaking → Ruins → PM-01 (~20600 frames, Act 0
## capture switches as args; TECH-001 §9.1). perf_golden_path and a11y_flash_pass: the same path with
## frame-time windows / flash-rule windows (TECH-001 §8.5, §9.1). warp_t1_capture: the T1 warp stills
## (dev `--warp-showcase` arg, ~1000 frames + margin; TECH-001 §5.1a). a0_reveal_decay_capture: a0_5 by
## autopilot with `--clean-hands`, then ending 5's ten screens, the line and the Decay (~3400 frames; ART-001 §12.7b). perf_ruins: the Ruins frame-time
## window alone (~760 frames; Q-T248); kept out of the suite, whose scenario test is near its 5 min limit.
## a1_run_loop: Ruins → PM-01 → clear → Ruins → buy → relaunch (~1900 frames, dev args `--clear-knocks=1
## --sepulchre-start=1`; TECH-001 §9.1, Q-T281). ui_menus_capture: the restyled overlay menus capture
## (timeout_frames 1500, over the suite's 1200; listed here when merging main into the run-loop branch).
## a0_cursed_cabinet_capture: the a0_3 after-image (dev `--haunt=after_image`), then a0_5 by autopilot and the
## cursed turn, one still every 0.5 s, with a luma window (~3100 frames). a0_haunt_attract_capture: every attract
## Haunting once (dev `--haunt-showcase`, fixture profile_act0_done, ~950 frames). TECH-001 Q-T268, §9.1.
## a0_rework_capture: stage cards, the new scale and one a0_3 Unmaking by autopilot (~5000 frames; Q-T365..Q-T380).
const LONG_SCENARIOS: Array[String] = ["a1_golden_path.scenario.json", "ruins_onboarding_first_visit.scenario.json", "perf_golden_path.scenario.json", "a11y_flash_pass.scenario.json",
	"warp_t1_capture.scenario.json", "a0_reveal_decay_capture.scenario.json", "perf_ruins.scenario.json", "a1_run_loop.scenario.json",
	"ui_menus_capture.scenario.json", "a0_cursed_cabinet_capture.scenario.json", "a0_haunt_attract_capture.scenario.json",
	"a0_rework_capture.scenario.json"]


func test_shipped_scenarios_are_valid_for_the_suite() -> void:
	for f in DirAccess.get_files_at("res://tests/scenarios"):
		if f.ends_with(".scenario.json"):
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/scenarios/" + f))
			var errs := Schema.validate(d, not LONG_SCENARIOS.has(f))
			assert_array(errs).override_failure_message("%s: %s" % [f, errs]).is_empty()


func test_no_class_name_under_core_automation() -> void:
	for f in DirAccess.get_files_at("res://core/automation"):
		if f.ends_with(".gd"):
			var text := FileAccess.get_file_as_string("res://core/automation/" + f)
			assert_bool(RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text) == null) \
				.override_failure_message(f + " declares class_name").is_true()


func test_dev_marker_comes_from_the_catalog() -> void:
	assert_bool(Schema.is_dev_step("set_setting")).is_true()
	assert_bool(Schema.is_dev_step("reset")).is_false()
	assert_bool(Schema.is_dev_step("quit")).is_false()
	assert_array(Schema.dev_steps_used(_sc([_step("set_setting"), _step("reset"), _step("set_setting")]))).contains_exactly(["set_setting"])
	assert_array(Schema.validate(_sc([_step("set_setting"), _step("reset")]), true)).is_empty()
	_expect(_sc([_step("set_setting", {"value": [1]})]), "must be scalar")


func test_profile_field_values() -> void:
	for p in ["qa", "dev"]:
		var a := _sc()
		a["profile"] = p
		assert_array(Schema.validate(a, false)).is_empty()
	var b := _sc()
	b["profile"] = "prod"
	_expect(b, "profile must be")


func test_phase2_steps_validate_and_reject_bad_args() -> void:
	for n in ["snapshot", "wait_event", "perf_sample", "set_stage", "set_lives", "teleport", "spawn", "shoot_vigil", "kill_acolyte", "kill_all", "pause_sim", "step_sim", "wake_entity", "place_entity"]:
		assert_array(Schema.validate(_sc([_step(n)]), false)).override_failure_message(n).is_empty()
	_expect(_sc([_step("snapshot", {"name": "Bad Name"})]), "name must match")
	_expect(_sc([_step("wait_event", {"count": 0})]), "count")
	_expect(_sc([_step("set_lives", {"lives": 10})]), "lives")
	_expect(_sc([_step("set_lives", {"lives": -1})]), "lives")
	_expect(_sc([_step("set_stage", {"index": -1})]), "index")
	_expect(_sc([_step("teleport", {"x": 5000})]), "<= 4000")
	_expect(_sc([_step("spawn", {"kind": "dragon"})]), "kind must be one of")
	_expect(_sc([_step("spawn", {"dy": -4001})]), "<= 4000")
	_expect(_sc([_step("shoot_vigil", {"dx": 0, "dy": 0})]), "cannot both be 0")
	_expect(_sc([_step("place_entity", {"dx": 4001})]), "<= 4000")
	_expect(_sc([_step("shoot_vigil", {"dx": 0, "dy": -9, "acolyte_id": -1})]), "acolyte_id")
	_expect(_sc([_step("shoot_vigil", {"dx": 0, "dy": -9, "acolyte_id": "first"})]), "acolyte_id")
	_expect(_sc([_step("shoot_vigil", {"dx": 0, "dy": -9, "acolyte_id": 1.5})]), "acolyte_id")
	_expect(_sc([_step("kill_acolyte", {"acolyte_id": -2})]), "acolyte_id")
	_expect(_sc([_step("step_sim", {"frames": 3601})]), "step_sim")
	_expect(_sc([_step("step_sim", {"frames": 0})]), "frames")


func test_cabinet_dev_steps_are_dev_only_and_probe_ops() -> void:
	var defs: Dictionary = Schema.catalog().steps
	for n in ["set_stage", "set_lives", "teleport", "spawn", "shoot_vigil", "kill_acolyte", "kill_all", "pause_sim", "step_sim", "wake_entity", "place_entity"]:
		assert_bool(Schema.is_dev_step(n)).override_failure_message(n).is_true()
		assert_bool(bool(defs[n].get("probe_op", false))).is_true()
		assert_str(str(defs[n].route)).is_equal("cabinet")
	for n in ["snapshot", "wait_event", "perf_sample"]:
		assert_bool(Schema.is_dev_step(n)).override_failure_message(n).is_false()


func test_fail_on_errors_and_allow_errors_types() -> void:
	var a := _sc()
	a["fail_on_errors"] = true
	a["allow_errors"] = ["known noise"]
	assert_array(Schema.validate(a, false)).is_empty()
	a["fail_on_errors"] = "yes"
	_expect(a, "fail_on_errors must be a bool")
	var b := _sc()
	b["allow_errors"] = [1]
	_expect(b, "allow_errors must be an array of strings")


## The golden-path variants must leave the Ruins exactly as a1_golden_path does: the steps from the
## Ruins onboarding wait to the sector route are copied, and this test makes a1_golden_path the one
## place a Ruins change is made (the variants then fail here, naming the scenario to update).
const GOLDEN_VARIANTS: Array[String] = ["perf_golden_path", "a11y_flash_pass"]


static func _ruins_block(steps: Array) -> Array:
	var start := -1
	for i in steps.size():
		var s: Dictionary = steps[i]
		if start < 0 and str(s.get("id", "")).begins_with("ruins/"):
			start = i
		if start >= 0 and s.get("do") == "wait_route" and s.get("route") == "sector":
			return steps.slice(start, i + 1)
	return []


func test_golden_path_variants_share_the_ruins_steps() -> void:
	var golden: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/scenarios/a1_golden_path.scenario.json"))
	var want := _ruins_block(golden.steps as Array).filter(func(s: Dictionary) -> bool: return s.get("do") != "assert")
	assert_bool(want.is_empty()).is_false()
	for id in GOLDEN_VARIANTS:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/scenarios/%s.scenario.json" % id))
		var got := _ruins_block(d.steps as Array).filter(func(s: Dictionary) -> bool: return s.get("do") != "assert")
		assert_str(JSON.stringify(got)).override_failure_message("%s: copy a1_golden_path's Ruins steps" % id).is_equal(JSON.stringify(want))
