extends RefCounted
## Command-line entry for the scenario runner: argument parsing, output-path confinement, runner
## creation. Boot reaches this only after its own feature check. The runner never mutates OS args.
## No class_name: release builds may exclude core/automation.

const Runner := preload("res://core/automation/scenario_runner.gd")
const Schema := preload("res://core/automation/scenario_schema.gd")
const SCENARIO_DIR := "res://tests/scenarios/"
const DEFAULT_OUT := "user://automation/"
const REPORTS_DIR := "res://reports"


## Value of `--key=value`, or "" when absent. `has_key` reports presence.
static func arg_value(args: PackedStringArray, key: String) -> String:
	var prefix := "--%s=" % key
	for a in args:
		if a.begins_with(prefix):
			return a.trim_prefix(prefix)
	return ""


static func has_scenario_arg(args: PackedStringArray) -> bool:
	return not arg_value(args, "scenario").is_empty()


## Returns the normalised, allowed output directory, or "" when `path` is not allowed.
static func confine_out(path: String) -> String:
	var p := path.replace("\\", "/")
	if p.split("/").has(".."):
		return ""
	p = p.simplify_path()
	if p.begins_with("user://"):
		return p
	var root := ProjectSettings.globalize_path(REPORTS_DIR).replace("\\", "/").simplify_path().trim_suffix("/")
	var norm := ProjectSettings.globalize_path(p).replace("\\", "/").simplify_path() if p.begins_with("res://") else p
	var a := norm
	var b := root
	if OS.has_feature("windows"):
		a = a.to_lower()
		b = b.to_lower()
	return norm if a == b or a.begins_with(b + "/") else ""


static func create_runner(args: PackedStringArray) -> Node:
	var runner: Node = Runner.new()
	var id := arg_value(args, "scenario")
	var opts := {"out_dir": "", "quit_on_finish": true, "source": "cli"}
	if not Schema.is_name(id):
		runner.preset_failure(&"invalid", 2, "invalid scenario id '%s'" % id, opts)
		return runner
	var out := arg_value(args, "out")
	out = DEFAULT_OUT + id if out == "" else confine_out(out)
	if out == "":
		runner.preset_failure(&"refused", 3, "--out must be under user:// or the project reports/ folder", opts)
		return runner
	opts.out_dir = out
	var path := SCENARIO_DIR + id + ".scenario.json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if typeof(parsed) != TYPE_DICTIONARY:
		runner.preset_failure(&"invalid", 2, "scenario file '%s' is missing or not valid JSON" % path, opts)
		return runner
	var scenario: Dictionary = parsed
	if str(scenario.get("id", "")) != id:
		runner.preset_failure(&"invalid", 2, "scenario id does not match its file name", opts)
		return runner
	runner.setup(scenario, opts)
	return runner
