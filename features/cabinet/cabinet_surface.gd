class_name CabinetSurface
extends TunableResource
## The physical materials of the Cabinet's bezel hardware (owner direction 2026-11-18: a real old
## arcade cabinet, a grimy surface you could reach out and touch). Read by CoinDoorFace and, later,
## every other real part (buttons, T-molding, screws, glass). Like the printed inks these are real
## objects, outside the Neon Cabinet palette, so they never go through Look.c. Every value is
## engineering presentation data (✱), not a game number.

# --- Materials ---
@export var paint_color: Color = Color8(0x0E, 0x0E, 0x10)         ## satin black-painted steel
@export var chrome_color: Color = Color8(0xC9, 0xCD, 0xD4)        ## chrome-plated trim
@export var bare_steel_color: Color = Color8(0x6E, 0x6A, 0x64)    ## steel showing through chipped paint
@export var brass_color: Color = Color8(0xB4, 0x8E, 0x45)         ## cylinder lock face
@export var lens_color: Color = Color8(0xE0, 0x3A, 0x12)          ## translucent red-orange lamp lens
@export var rust_color: Color = Color8(0x8A, 0x45, 0x1E)          ## rust bloom round a screw
@export var label_paper_color: Color = Color8(0xD2, 0xC7, 0xA3)   ## aged, yellowed paper of the printed price label

# --- Wear (0 new … 1 wrecked; PR D destroys, this only ages) ---
@export_range(0.0, 1.0) var wear: float = 0.45                    ## chipped paint, scratches
@export_range(0.0, 1.0) var grime: float = 0.55                   ## dirt packed into recesses, nicotine film
@export_range(0.0, 1.0) var smudge: float = 0.6                   ## greasy fingerprints and palm smears
@export var lamp_idle: float = 0.22                               ## lamp light at glow 0 (dim but visible)

# --- Determinism and light ---
@export var noise_seed: float = 7.0                               ## fixed: the same wear every run
@export var light_direction: Vector3 = Vector3(-0.55, -0.65, 0.55) ## surface → key light: upper left, toward the viewer

const _DEFAULT_PATH := "res://data/cabinet/cabinet_surface.tres"


## The shared default surface (data/cabinet/cabinet_surface.tres); callers cast with `as CabinetSurface`.
## Returns Resource on purpose: naming CabinetSurface inside its own static func leaks the script at
## exit (Godot 4.7, seen in the boot smoke).
static func default() -> Resource:
	return load(_DEFAULT_PATH)


func tunable_properties() -> PackedStringArray:
	var out := PackedStringArray()
	for p in get_property_list():
		if (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and (p.usage & PROPERTY_USAGE_EDITOR) and p.name != "ds_namespace" and p.name != "source_section":
			out.append(p.name)
	return out
