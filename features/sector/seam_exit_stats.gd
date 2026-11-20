class_name SeamExitStats
extends TunableResource
## How a Seam ends in the sector (TECH-001 §2.9 `SeamExit`; Q-T275, Q-T278). Values in
## data/sector/seam_exit.tres (`ds_sector.exit.*`). Game numbers are SYS-001 §6 rows (proposed);
## ✱ = engineering placement or presentation, owned by TECH-001.

## SYS-001 §6 `Seam clear: Sepulchre segments knocked` (proposed, Q-T275): the Seam clears when the
## Sepulchre stands cold again (0 segments) after Charges have knocked at least this many off.
@export var knocks_required: int = 0
## ✱ Where the exit throat opens, torus px (PM-01 "the throat", ZONES-001 §3.1). Until kits carry an
## exit anchor (ZONES-001 §1.7) one point serves every Seam.
@export var throat_pos: Vector2 = Vector2.ZERO
## ✱ Radius (px) the Vigil must be inside to pass the open throat.
@export var throat_radius_px: float = 0.0
## ✱ Seconds the throat takes to open fully (presentation; it is passable from the first frame).
@export var throat_open_s: float = 0.0
## ✱ Seconds between a hull breach and the return to the Ruins (the breach plays first).
@export var return_hold_s: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"knocks_required", "throat_pos", "throat_radius_px", "throat_open_s", "return_hold_s",
	])
