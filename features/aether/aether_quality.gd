class_name AetherQuality
extends TunableResource
## One rung of the Aether quality ladder (PM ruling CH-7; engineering ✱, not a game number).
## AetherBackdrop.apply_quality() reads it. Every rung keeps the sphere curve, the entity's exact
## black and the play-band fog cap; lower rungs drop noise octaves, render fog bands offscreen at a
## lower resolution, thin the particles and freeze the shafts. Switches are 0/1 ints so every
## field is a numeric ds_ key. Files: data/aether/quality/quality_<level>.tres.

## Rung name: high, medium or low.
@export var level: String = "high"
## ✱ octaves removed from every fog band (the far band keeps at least 3, nearer bands 2).
@export var fog_octave_drop: int = 0
## ✱ octaves of the fog's domain warp (2–3).
@export var warp_octaves: int = 3
## ✱ 1 = two advected samples blended across the flow cycle (no pop); 0 = one sample.
@export var two_sample_advection: int = 1
## ✱ 1 = the silver lining on the sphere side of each billow (one more fbm per pixel).
@export var silver_lining: int = 1
## ✱ fog bands render offscreen at this fraction of the window's pixel size; 1 = in place.
@export var fog_resolution_scale: float = 1.0
## ✱ the two MID fog bands render offscreen at this fraction (pass 3: mid fog is the CH-7 lever,
## quarter-res at low); never above fog_resolution_scale.
@export var mid_fog_resolution_scale: float = 1.0
## ✱ most fog bands drawn (the look may ask for fewer).
@export var max_fog_bands: int = 5
## ✱ multiplier on every particle count.
@export var particle_scale: float = 1.0
## ✱ 1 = god-rays move; 0 = static shafts (frozen time, fewer octaves, offscreen).
@export var animated_shafts: int = 1
## ✱ god-ray resolution scale (offscreen when < 1).
@export var shaft_resolution_scale: float = 1.0
## ✱ 1 = the sphere bends the fog behind it (reads the screen texture).
@export var sphere_refraction: int = 1
## ✱ nested sphere shells drawn behind the hero seam (0–2).
@export var nested_shells: int = 2
## ✱ fbm scales on the entity's torn edge (2–4); the black itself never changes.
@export var entity_edge_octaves: int = 4
## ✱ 1 = far set pieces (orrery rings, lattice, dome) drawn.
@export var set_pieces: int = 1
## ✱ 1 = gallery bloom on.
@export var glow: int = 1


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"fog_octave_drop", "warp_octaves", "two_sample_advection", "silver_lining", "fog_resolution_scale", "mid_fog_resolution_scale",
		"max_fog_bands", "particle_scale", "animated_shafts", "shaft_resolution_scale", "sphere_refraction",
		"nested_shells", "entity_edge_octaves", "set_pieces", "glow",
	])


## The rung file for a level name ("high" when unknown).
static func path_for(level_name: String) -> String:
	var n := level_name if level_name in LEVELS else "high"
	return "res://data/aether/quality/quality_%s.tres" % n


const LEVELS: Array[String] = ["high", "medium", "low"]
