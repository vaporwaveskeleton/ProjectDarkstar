class_name PhysicsLayers
extends RefCounted
## Collision layer numbers (1-based, as shown in the editor) and bit helpers.
## The table and its rules live in TECH-001 §2.6. project.godot [layer_names] must match.

const WORLD := 1          ## StaticBody2D walls, geodes, entity segments (per module)
const VIGIL := 2          ## the Vigil's movement body
const CHOIR := 3          ## Choir unit movement bodies
const VIGIL_SHOTS := 4    ## Arc-Lance hitboxes and shots
const CHOIR_SHOTS := 5    ## Choir projectile hitboxes
const PICKUPS := 6        ## Mourning Glass and other collectables
const INTERACTABLES := 7  ## shrines, Sepulchre deposit, Chalk Desk
const SHROUD := 8         ## grown hazard terrain
const VIGIL_HURTBOX := 9  ## the Vigil's hurtbox Area2D
const CHOIR_HURTBOX := 10 ## Choir hurtbox Area2Ds

const NAMES := {
	WORLD: "world", VIGIL: "vigil", CHOIR: "choir", VIGIL_SHOTS: "vigil_shots",
	CHOIR_SHOTS: "choir_shots", PICKUPS: "pickups", INTERACTABLES: "interactables",
	SHROUD: "shroud", VIGIL_HURTBOX: "vigil_hurtbox", CHOIR_HURTBOX: "choir_hurtbox",
}


## Bit value for one 1-based layer number.
static func bit(layer: int) -> int:
	assert(layer >= 1 and layer <= 32, "physics layer out of range")
	return 1 << (layer - 1)


## Combined bit mask for several 1-based layer numbers.
static func mask(layers: Array[int]) -> int:
	var m := 0
	for l in layers:
		m |= bit(l)
	return m
