class_name BezelInks
extends TunableResource
## The printed inks of the Cabinet bezel (owner decision D-B, TECH-001 §1.3). The bezel is a real
## object, the 1983 marketing art for the fake arcade game (the Pretence): it is NOT a CRT image and
## NOT a phosphor, so these colours sit outside the 32-colour Neon Cabinet palette and never go
## through Look.c. Lit things behind the glass (readout text, lamps, the coin slit glow) still do.
## Every value is ✱ presentation data owned by the cabinet feature.

@export var key_black: Color = Color8(0x14, 0x10, 0x18)
@export var navy: Color = Color8(0x1E, 0x23, 0x50)
@export var process_blue: Color = Color8(0x2E, 0x5B, 0xB8)
@export var cyan: Color = Color8(0x29, 0xB6, 0xD6)
@export var magenta: Color = Color8(0xC7, 0x30, 0x7A)
@export var warm_red: Color = Color8(0xD9, 0x44, 0x2B)
@export var yellow: Color = Color8(0xF2, 0xC2, 0x30)
@export var orange: Color = Color8(0xE8, 0x79, 0x2B)
@export var cream: Color = Color8(0xF1, 0xE6, 0xC8)
@export var brass: Color = Color8(0xB0, 0x8A, 0x3E)
@export var chrome_light: Color = Color8(0xD8, 0xDC, 0xE6)
@export var chrome_dark: Color = Color8(0x5A, 0x60, 0x70)
@export var smoked_glass: Color = Color8(0x10, 0x12, 0x24)     ## key black tinted slightly navy: the smoked glass (unused since the readouts moved onto the screen strip)
@export var plexi_glare: Color = Color(1.0, 1.0, 1.0, 0.06)    ## the diagonal reflection band over the print

const _DEFAULT_PATH := "res://data/cabinet/bezel_inks.tres"


## The shared default inks (data/cabinet/bezel_inks.tres); callers cast with `as BezelInks`.
## Returns Resource on purpose: naming BezelInks inside its own static func leaks the script at
## exit (Godot 4.7, seen in the boot smoke).
static func default() -> Resource:
	return load(_DEFAULT_PATH)


func tunable_properties() -> PackedStringArray:
	var out := PackedStringArray()
	for p in get_property_list():
		if (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and (p.usage & PROPERTY_USAGE_EDITOR) and p.name != "ds_namespace" and p.name != "source_section":
			out.append(p.name)
	return out


## Ink ids as StringNames, in declaration order.
func ink_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for n in tunable_properties():
		out.append(StringName(n))
	return out


func has_ink(id: StringName) -> bool:
	return tunable_properties().has(String(id))


func ink(id: StringName) -> Color:
	var v: Variant = get(id)
	return v if v is Color else Color.MAGENTA
