extends GdUnitTestSuite
## Guards export_presets.cfg: release-class presets must exclude all automation and test code, the
## QA preset must ship the runner and scenarios, and the file must stay credential-free.

const PATH := "res://export_presets.cfg"
const REQUIRED_EXCLUDES: Array[String] = [
	"core/automation/*", "features/*/automation/*", "tests/*", "core/*/tests/*", "features/*/tests/*",
	"scenes/tests/*", "scenes/dev/*", "data/routes/dev_*", "addons/gdUnit4/*", "addons/godot_ai/*",
]
const QA_REQUIRED_EXCLUDES: Array[String] = [
	"core/automation/tests/*", "core/*/tests/*", "features/*/tests/*", "scenes/tests/*", "tests/test_*",
	"tests/support/*", "addons/gdUnit4/*", "addons/godot_ai/*",
]
const QA_REQUIRED_INCLUDES: Array[String] = ["tests/scenarios/*.json", "tests/fixtures/saves/*.json", "core/automation/step_catalog.json"]
const SECRET_WORDS: Array[String] = ["password", "secret", "token", "signtool", "steam", "certificate", "keystore", "apikey", "api_key"]

var _cfg := ConfigFile.new()


func before_test() -> void:
	assert_int(_cfg.load(PATH)).is_equal(OK)


func _presets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for sec in _cfg.get_sections():
		if sec.begins_with("preset.") and not sec.ends_with(".options"):
			var d := {"section": sec}
			for k in _cfg.get_section_keys(sec):
				d[k] = _cfg.get_value(sec, k)
			out.append(d)
	return out


func _is_automation(p: Dictionary) -> bool:
	var f := str(p.get("custom_features", ""))
	return f.contains("automation_qa") or f.contains("automation_dev")


func _filters(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	for part in text.split(","):
		out.append(part.strip_edges())
	return out


func test_release_class_presets_exclude_automation_and_tests() -> void:
	var seen := 0
	for p in _presets():
		if _is_automation(p):
			continue
		seen += 1
		var ex := _filters(str(p.get("exclude_filter", "")))
		for need in REQUIRED_EXCLUDES:
			assert_bool(ex.has(need)).override_failure_message("%s lacks exclude %s" % [p.name, need]).is_true()
		var inc := str(p.get("include_filter", ""))
		assert_bool(inc.contains("tests/") or inc.contains("automation")).override_failure_message(str(p.name) + " includes tests or automation").is_false()
	assert_int(seen).is_greater(0)


func test_only_qa_presets_carry_automation_features() -> void:
	var desktop := 0
	for p in _presets():
		var f := str(p.get("custom_features", ""))
		if f.contains("automation"):
			assert_bool(f.contains("automation_qa") and not f.contains("automation_dev")).override_failure_message(str(p.name)).is_true()
		if p.name == "Windows Desktop":
			desktop += 1
			assert_str(f).is_empty()
	assert_int(desktop).is_equal(1)


func test_qa_preset_ships_runner_and_scenarios_but_no_test_code() -> void:
	var qa := 0
	for p in _presets():
		if not str(p.get("custom_features", "")).contains("automation_qa"):
			continue
		qa += 1
		var inc := _filters(str(p.include_filter))
		for need in QA_REQUIRED_INCLUDES:
			assert_bool(inc.has(need)).override_failure_message("QA lacks include %s" % need).is_true()
		var ex := _filters(str(p.exclude_filter))
		for need in QA_REQUIRED_EXCLUDES:
			assert_bool(ex.has(need)).override_failure_message("QA lacks exclude %s" % need).is_true()
		for e in ex:
			assert_bool(e.contains("tests/scenarios") or e.contains("tests/fixtures") or e == "tests/*").override_failure_message("QA excludes %s" % e).is_false()
	assert_int(qa).is_equal(1)


func test_every_automation_folder_is_covered_in_release() -> void:
	var dirs: Array[String] = ["core/automation"]
	for f in DirAccess.get_directories_at("res://features"):
		if DirAccess.dir_exists_absolute("res://features/%s/automation" % f):
			dirs.append("features/%s/automation" % f)
	for p in _presets():
		if _is_automation(p):
			continue
		var ex := _filters(str(p.get("exclude_filter", "")))
		for d in dirs:
			var covered := false
			for g in ex:
				if ("res://" + d + "/x.gd").matchn("res://" + g):
					covered = true
			assert_bool(covered).override_failure_message("%s: %s is not excluded" % [p.name, d]).is_true()


func test_presets_hold_no_credentials() -> void:
	for sec in _cfg.get_sections():
		for k in _cfg.get_section_keys(sec):
			var v: Variant = _cfg.get_value(sec, k)
			if str(v).is_empty() or str(v) in ["false", "0", "[]"]:
				continue
			for w in SECRET_WORDS:
				assert_bool(k.to_lower().contains(w)).override_failure_message("%s/%s looks like a credential" % [sec, k]).is_false()
