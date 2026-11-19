class_name LaunchRoute
extends RefCounted
## Dev launch switch `-- --route=<id>`: start on a routed scene other than the table's initial
## route (e.g. `--route=sector` for the M1 sandbox). Combines with `--hull=1|2` and `--no-save`.
## Gated exactly like the automation runner (Boot._make_automation_runner): only builds with
## feature `editor`, `automation_dev` or `automation_qa` honour it; a release export ignores it.
## An unknown id, an empty value or a non-dev build quietly falls back to the normal first route.

const ROUTE_KEY := "route"
const DEV_FEATURES: Array[String] = ["editor", "automation_dev", "automation_qa"]


## Value of `--key=value` in the user args, or "" when absent. First match wins.
static func arg_value(args: PackedStringArray, key: String) -> String:
	var prefix := "--%s=" % key
	for a in args:
		if a.begins_with(prefix):
			return a.trim_prefix(prefix)
	return ""


## True in builds that may honour dev switches (same tags as the automation gate).
static func is_dev_build() -> bool:
	for f in DEV_FEATURES:
		if OS.has_feature(f):
			return true
	return false


## The first route of this launch. Pure: the caller passes args, table and the build gate.
static func resolve(args: PackedStringArray, table: RouteTable, dev_build: bool) -> StringName:
	if table == null:
		return &""
	if not dev_build:
		return table.initial_route
	var wanted := arg_value(args, ROUTE_KEY)
	if wanted.is_empty() or not table.has_route(StringName(wanted)):
		return table.initial_route
	return StringName(wanted)
