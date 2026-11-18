class_name TunableResource
extends Resource
## Base class for every loose tunable `.tres` in res://data (TECH-001 §3).
## Each tunable property is addressable by a `ds_` key: "<ds_namespace>.<property>".
## Subclasses list their tunable properties in `tunable_properties()`.

## Dotted namespace starting with "ds_", e.g. "ds_vigil.move". One per .tres file.
@export var ds_namespace: String = ""
## SYS-001 section the values were copied from, e.g. "SYS-001 §1.1". Documentation only.
@export var source_section: String = ""


## Names of the @export properties that are game tunables. Override in subclasses.
func tunable_properties() -> PackedStringArray:
	return PackedStringArray()


## Map of full ds_ key -> property name.
func ds_keys() -> Dictionary:
	var out := {}
	for p in tunable_properties():
		out["%s.%s" % [ds_namespace, p]] = p
	return out
