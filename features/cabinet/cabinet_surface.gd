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
@export var lip_color: Color = Color8(0xB4, 0xB6, 0xBA)           ## the coin slot's lip, polished by coins: bright metal, one step under the lit plate
@export var bare_steel_color: Color = Color8(0x6E, 0x6A, 0x64)    ## steel showing through chipped paint
@export var brass_color: Color = Color8(0xB4, 0x8E, 0x45)         ## cylinder lock face
@export var lens_color: Color = Color8(0xE0, 0x3A, 0x12)          ## translucent red-orange lamp plate (the reject / price plate)
@export var sticker_paper_color: Color = Color8(0xDC, 0xD8, 0xCC) ## faded off-white paper remnant of a peeled label

# --- Wear (0 new … 1 wrecked; PR D destroys, this only ages) ---
@export_range(0.0, 1.0) var wear: float = 0.8                     ## chipped paint, scratches
@export_range(0.0, 1.0) var grime: float = 0.95                   ## dirt packed into recesses, nicotine film
@export_range(0.0, 1.0) var smudge: float = 0.8                   ## greasy fingerprints and palm smears
@export_range(0.0, 1.0) var dust: float = 0.7                     ## dust settled on the top edges of the recesses
@export_range(0.0, 1.0) var finger_halo: float = 0.85             ## greasy grey and bare-steel wear round the coin slot
@export_range(0.0, 1.0) var thumb_wear: float = 0.85              ## the dulled, greyed thumb patch on the lit plate
@export_range(0.0, 1.0) var micro_texture: float = 0.55           ## painted-steel orange-peel grain
@export var lamp_idle: float = 0.22                               ## lamp light at glow 0 (dim but visible)
@export var lamp_spill: float = 0.2                               ## red-orange light the lit plate throws on its neighbours
@export var lamp_spill_radius: float = 10.0                       ## how far it reaches, rig units

# --- Determinism and light ---
@export var noise_seed: float = 7.0                               ## fixed: the same wear every run
@export var light_direction: Vector3 = Vector3(-0.55, -0.65, 0.55) ## strength (xy) and elevation (z) of the key; its heading comes from the screen hole
@export var warm_color: Color = Color(1.0, 0.78, 0.52)            ## the screen glow
@export var fill_color: Color = Color(0.5, 0.58, 0.78)            ## the cool dim room fill
@export var warm_gain: float = 0.5                                ## the steady glow of the tube next to the hole (the live spill adds the rest)
@export var warm_radius: float = 170.0                            ## rig units over which the screen glow falls to 1/e
@export var fill_gain: float = 0.78                               ## room fill strength
@export var top_gain: float = 1.0                                 ## fill at the top of the cabinet
@export var bottom_gain: float = 0.62                             ## fill at the bottom (in shadow)
@export_range(0.0, 1.0) var contact_shadow: float = 0.7           ## darkness of the shadow a raised part throws on the bezel
@export var contact_blur: float = 5.0                             ## its softness, rig units

# --- Printed glass (reverse screen print under the glass) ---
@export var print_misregister: float = 0.4                        ## plate misregistration, rig units
@export_range(0.0, 1.0) var print_fade: float = 0.28              ## ink faded by years of light
@export_range(0.0, 1.0) var print_mottle: float = 0.4             ## ink-density unevenness (slow blotches only)
@export_range(0.0, 1.0) var print_halftone: float = 1.0           ## screened tones on (1) or flat (0)
@export var print_halftone_cell: float = 1.25                     ## halftone dot pitch, rig units (about 1 to 1.5)
@export_range(0.0, 1.0) var print_scuff: float = 0.5              ## rub fade along the worn edges
@export_range(0.0, 1.0) var print_flake: float = 0.95            ## sharp-edged flakes of ink lost to the black backing (causal)
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


# --- PR C pass 2: the screen lights the cabinet, the real tube, trim, marquee, bezel lettering (all ✱) ---
@export var spill_gain: float = 2.2                               ## strength of the screen's average colour on the bezel and door
@export var spill_radius: float = 150.0                           ## rig units over which that spill falls to 1/e
@export var spill_boost: float = 12.0                              ## screen average luminance to spill intensity: (luminance * boost) ^ curve
@export var spill_curve: float = 0.6                              ## below 1 so a mostly dark screen still lights the cabinet a little
@export var spill_interval: float = 0.2                           ## s between samples of the screen
@export var spill_smooth: float = 0.25                            ## s: how slowly the cabinet follows the screen (breathes, never strobes)
@export var spill_steady_color: Color = Color(0.5, 0.6, 0.85)     ## the fixed spill colour while photosensitivity is on
@export var spill_steady_amount: float = 0.22                     ## its fixed intensity
@export var recess_shadow: float = 0.7                            ## darkness of the tube's recess wall beside the opening
@export var recess_width: float = 7.0                             ## its reach, rig units
@export var tube_corner_radius: float = 5.0                       ## rounded corners of the tube mask, rig units (the only screen pixels it ever replaces)
@export_range(0.0, 1.0) var tube_glass: float = 1.0               ## master amount of the glass layer over the screen (0 = off)
@export var tube_reflection: float = 0.035                        ## faint convex reflection, max alpha
@export var tube_dust: float = 0.02                               ## light dust on the tube glass, max alpha
@export var tube_bloom: float = 0.04                              ## phosphor bloom bleed at the edges, max alpha
@export var tube_edge_shadow: float = 0.07                        ## soft inner shadow where the tube sits recessed, max alpha
@export var tube_max_shift: float = 0.12                          ## readability bound: the glass may move no screen channel by more than this (0..1)
@export var tmold_width: float = 3.2                              ## black T-molding on the bezel's outer edges, rig units
@export var bolt_radius: float = 2.3                              ## zinc bezel bolt heads
@export var marquee_lettering: float = 17.0                       ## cap height of the marquee's title, rig units
@export var marquee_stroke: float = 2.6                           ## its stroke
@export var marquee_tracking: float = 5.0
@export_range(0.0, 1.0) var marquee_unevenness: float = 0.55      ## uneven backlight
@export var print_dot_gain: float = 0.22                          ## ink spread: a 50 % tone prints as about 61 %
@export var price_cap: float = 4.6                                ## cap height of the price plate's lettering
@export var price_stroke: float = 1.0
@export var price_tracking: float = 0.8
@export_range(0.0, 1.0) var glass_band: float = 0.6               ## broad soft diagonal specular band on the bezel glass
@export_range(0.0, 1.0) var glass_screen_reflection: float = 0.5  ## the screen's glow reflected in the glass

# --- PR C pass 2 polish: glass reads through light, visible wear, UV fade, backlit marquee, room glow (all ✱) ---
@export var glass_band_lift: float = 0.42                         ## peak alpha of the glass specular band (a pale veil: lowers contrast and saturation)
@export var glass_smear_haze: float = 1.0                         ## peak alpha of the thumb-smear when the screen is bright
@export_range(0.0, 1.0) var glass_smear_idle: float = 0.0         ## its share of that when the screen is dark
@export_range(0.0, 1.0) var print_uv_fade: float = 0.8           ## reds and magentas fade toward pink / salmon where light fell (upper, outer art)
@export var print_uv_edge: float = 9.0                            ## width of the unfaded band the T-molding shaded, rig units
@export_range(0.0, 1.0) var print_grime: float = 0.6             ## dirt dulling the ink in the causal wear zones
@export var marquee_hot: float = 1.0                              ## brightness of the hot band under each tube
@export var marquee_shadow_depth: float = 0.6                     ## how much the shadow across the backlight darkens the lens and its lettering
@export var marquee_spill: float = 0.55                           ## warm light the marquee throws on the bezel round it
@export var room_glow: float = 0.6                                ## strength of the screen-coloured spill on the room round the cabinet


# --- PR C pass 2c: the angled control panel, panel captions, the power rocker, real hazard tape (all ✱) ---
@export_range(0.0, 1.0) var panel_lip: float = 0.85               ## brightness of the bevelled top lip where the panel meets the bezel under the tube
@export var panel_lip_width: float = 1.6                          ## that lip's width, rig units
@export_range(0.0, 1.0) var panel_front_shadow: float = 0.7       ## darkness of the shadow under the panel's front (lower) edge
@export var panel_front_width: float = 5.5                        ## its reach, rig units
@export_range(0.0, 1.0) var panel_contact: float = 0.8            ## darkness of the contact shadow under each button's bezel
@export_range(0.0, 1.0) var panel_palm_polish: float = 0.8        ## palm-polish where hands rest beside START (smoother, glossier laminate)
@export_range(0.0, 1.0) var panel_grain: float = 0.5              ## the laminate's fine grain (its own material, not the print's speckle)
@export var panel_color: Color = Color8(0x1E, 0x21, 0x2C)         ## dark blue-grey laminate
@export_range(0.0, 1.0) var start_decal_rub: float = 0.34         ## share of the START decal's ink rubbed off by thumbs (the left half goes first)
@export_range(0.0, 1.0) var decal_rub: float = 0.12               ## the other decals' light wear
@export var caption_cap: float = 4.4                              ## cap height of the panel captions (Settings, Quit game), rig units
@export var caption_stroke: float = 0.95
@export var caption_tracking: float = 0.8
@export var caption_pad: Vector2 = Vector2(3.0, 2.0)              ## the caption plate's margin round its lettering
@export var tape_sheen: float = 0.7                               ## gloss of the hazard tape's vinyl
@export var tape_misregister: float = 0.4                         ## black plate's offset against the yellow, rig units
@export_range(0.0, 1.0) var tape_lift: float = 0.8                ## how far the tape's long edges stand off the bezel (a shadow under them)
@export_range(0.0, 1.0) var tape_dirt: float = 0.8                ## dirt caught on the adhesive edge
@export_range(0.0, 1.0) var tape_crease: float = 0.8              ## the stress crease where the tape bends
@export var tape_yellow: Color = Color8(0xE2, 0xB0, 0x14)         ## the tape's yellow vinyl
@export var tape_black: Color = Color8(0x16, 0x14, 0x14)          ## its black ink
@export var rocker_lamp_color: Color = Color8(0xFF, 0x4A, 0x1C)   ## the lit half of the POWER rocker

# --- loom textures (owner direction 2026-11-19; ART-001 §14.8a; CabinetTextures, art/src/cabinet_textures.tx.js) ---
@export_range(0.0, 1.0) var texture_detail: float = 1.0           ## strength of every loom detail texture (0 = the untextured look)
@export var laminate_tile: float = 40.0                           ## control-panel laminate: rig units per texture repeat
@export var side_tile: float = 48.0                               ## the side panel's chipped paint over plywood: rig units per repeat
@export var steel_tile: float = 30.0                              ## the coin door's painted steel: rig units per repeat

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
