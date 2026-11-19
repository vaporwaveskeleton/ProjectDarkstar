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
	_expect(_sc([{"do": "teleport"}]), "unknown step 'teleport'")
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


func test_shipped_scenarios_are_valid_for_the_suite() -> void:
	for f in DirAccess.get_files_at("res://tests/scenarios"):
		if f.ends_with(".scenario.json"):
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/scenarios/" + f))
			var errs := Schema.validate(d, true)
			assert_array(errs).override_failure_message("%s: %s" % [f, errs]).is_empty()


func test_no_class_name_under_core_automation() -> void:
	for f in DirAccess.get_files_at("res://core/automation"):
		if f.ends_with(".gd"):
			var text := FileAccess.get_file_as_string("res://core/automation/" + f)
			assert_bool(RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text) == null) \
				.override_failure_message(f + " declares class_name").is_true()
