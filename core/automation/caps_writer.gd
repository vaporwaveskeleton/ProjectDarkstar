extends Node
## `-- --automation-caps --no-save --out=<dir>`: writes <out>/caps.json and quits 0.
## Describes this build's automation surface (steps, profile, comparators, probes, fixtures).
## No class_name: release builds may exclude core/automation.

const Runner := preload("res://core/automation/scenario_runner.gd")
const Schema := preload("res://core/automation/scenario_schema.gd")

var out_dir := ""
var quit_on_finish := true
var written_path := ""


func _ready() -> void:
	write()
	if quit_on_finish and is_inside_tree():
		get_tree().quit.call_deferred(0)


## Writes caps.json when out_dir is set; returns the capabilities either way.
func write() -> Dictionary:
	var caps := build()
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
		written_path = out_dir.path_join("caps.json")
		var f := FileAccess.open(written_path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(caps, "\t"))
			f.close()
	return caps


static func build() -> Dictionary:
	var steps: Array = []
	var defs: Dictionary = Schema.catalog().get("steps", {})
	for n: Variant in defs.keys():
		steps.append({"name": str(n), "dev": bool((defs[n] as Dictionary).get("dev", false))})
	var probes := {}
	for route: Variant in Runner.PROBES.keys():
		var path := str(Runner.PROBES[route])
		if ResourceLoader.exists(path):
			var script := load(path) as GDScript
			if script != null:
				probes[str(route)] = (script.new() as RefCounted).call("describe")
	var fixtures: Array = []
	if FileAccess.file_exists(Runner.APPROVED_FIXTURES):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Runner.APPROVED_FIXTURES))
		if typeof(parsed) == TYPE_ARRAY:
			fixtures = parsed
	return {
		"format": "darkstar.caps", "version": 1, "protocol": 1,
		"profile": Runner.build_profile(),
		"steps": steps,
		"comparators": Schema.COMPARATORS,
		"screenshot_targets": Schema.TARGETS,
		"probes": probes,
		"fixtures": fixtures,
		"build": {"godot": Engine.get_version_info().string,
			"game_version": str(ProjectSettings.get_setting("application/config/version", ""))},
	}
