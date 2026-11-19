class_name CabinetSurface
extends TunableResource
## The physical materials of the Cabinet's bezel hardware and printed glass (owner direction 2026-11-18: a
## real old arcade cabinet, a grimy surface you could reach out and touch). Read by CoinDoorFace, the
## printed field and columns, the glass, the vents and the sticker (through CabinetLighting). Like the
## printed inks these are real objects, outside the Neon Cabinet palette, so they never go through
## Look.c. Every value is engineering presentation data (✱), not a game number.

# --- Door materials (the coin door is satin-painted and zinc-plated steel; only the coin lip is bright) ---
@export var paint_color: Color = Color8(0x0E, 0x0E, 0x10)         ## satin black-painted steel
@export var zinc_color: Color = Color8(0x8A, 0x8C, 0x8E)          ## dull zinc-plated steel (entry plate, lock collar, screws, flap)
@export var lip_color: Color = Color8(0xE6, 0xE8, 0xEC)           ## the coin slot's lip, polished by coins: the one bright metal
@export var bare_steel_color: Color = Color8(0x6E, 0x6A, 0x64)    ## steel showing through chipped paint
@export var brass_color: Color = Color8(0xB4, 0x8E, 0x45)         ## cylinder lock face
@export var lens_color: Color = Color8(0xE0, 0x3A, 0x12)          ## translucent red-orange lamp plate (the reject / price plate)
@export var sticker_paper_color: Color = Color8(0xD2, 0xC7, 0xA3) ## pale paper remnant of a peeled sticker

# --- Wear (0 new … 1 wrecked; PR D destroys, this only ages) ---
@export_range(0.0, 1.0) var wear: float = 0.8                     ## chipped paint, scratches
@export_range(0.0, 1.0) var grime: float = 0.95                   ## dirt packed into recesses, nicotine film
@export_range(0.0, 1.0) var smudge: float = 0.8                   ## greasy fingerprints and palm smears
@export_range(0.0, 1.0) var dust: float = 0.7                     ## dust settled on the top edges of the recesses
@export_range(0.0, 1.0) var finger_halo: float = 0.85             ## greasy grey and bare-steel wear round the coin slot
@export_range(0.0, 1.0) var thumb_wear: float = 0.85              ## the dulled, greyed thumb patch on the lit plate
@export_range(0.0, 1.0) var micro_texture: float = 0.55           ## painted-steel orange-peel grain
@export var lamp_idle: float = 0.22                               ## lamp light at glow 0 (dim but visible)
@export var lamp_spill: float = 0.32                              ## red-orange light the lit plate throws on its neighbours
@export var lamp_spill_radius: float = 10.0                       ## how far it reaches, rig units

# --- Determinism and light ---
@export var noise_seed: float = 7.0                               ## fixed: the same wear every run
@export var light_direction: Vector3 = Vector3(-0.55, -0.65, 0.55) ## strength (xy) and elevation (z) of the key; its heading comes from the screen hole
@export var warm_color: Color = Color(1.0, 0.78, 0.52)            ## the screen glow
@export var fill_color: Color = Color(0.5, 0.58, 0.78)            ## the cool dim room fill
@export var warm_gain: float = 1.25                               ## key strength next to the hole
@export var warm_radius: float = 170.0                            ## rig units over which the screen glow falls to 1/e
@export var fill_gain: float = 0.78                               ## room fill strength
@export var top_gain: float = 1.0                                 ## fill at the top of the cabinet
@export var bottom_gain: float = 0.62                             ## fill at the bottom (in shadow)
@export_range(0.0, 1.0) var contact_shadow: float = 0.7           ## darkness of the shadow a raised part throws on the bezel
@export var contact_blur: float = 5.0                             ## its softness, rig units

# --- Printed glass (reverse screen print under the glass) ---
@export var print_misregister: float = 0.4                        ## plate misregistration, rig units
@export_range(0.0, 1.0) var print_fade: float = 0.28              ## ink faded by years of light
@export_range(0.0, 1.0) var print_mottle: float = 0.55            ## ink-density unevenness
@export_range(0.0, 1.0) var print_halftone: float = 0.4           ## visible halftone where the tone changes
@export var print_halftone_cell: float = 2.6                      ## halftone dot pitch, rig units (about 45 lpi on a real bezel)
@export_range(0.0, 1.0) var print_scuff: float = 0.55             ## fine scuffs through to the white backer
@export_range(0.0, 1.0) var print_flake: float = 0.45             ## ink flaked off in specks
@export var backer_color: Color = Color8(0xE4, 0xDF, 0xD2)        ## the white backer ink behind the colours
@export_range(0.0, 1.0) var glass_reflection: float = 0.55        ## broad soft reflection on the glass
@export_range(0.0, 1.0) var glass_edge_tint: float = 0.6          ## green-blue tint of the glass edge
@export var glass_edge_color: Color = Color8(0x3C, 0xB0, 0x9A)    ## the glass edge's tint
@export_range(0.0, 1.0) var glass_dust: float = 0.5               ## dust on the glass
@export_range(0.0, 1.0) var glass_smudge: float = 0.5             ## fingerprints and wipe marks on the glass
@export_range(0.0, 1.0) var glass_scratch: float = 0.5            ## fine scratches in the glass
@export_range(0.0, 1.0) var sticker_fade: float = 0.18            ## the "new" sticker's faded vinyl inks
@export var sticker_curl: float = 13.0                            ## how far the lifted corner reaches, rig units
@export_range(0.0, 1.0) var vent_dust: float = 0.6                ## dust in the speaker-grille holes

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
