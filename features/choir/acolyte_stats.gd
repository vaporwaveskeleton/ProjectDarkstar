class_name AcolyteStats
extends TunableResource
## Aether Acolyte tunables (a Choir censer-knight on watch at a post; PM-02 Dark Throat). Values in
## data/choir/acolyte.tres (`ds_choir.acolyte.*`). Numbers are the PM-02 ruling; ✱ = engineering.

## Hits (Arc-Lance damage units) to kill it.
@export var hp: int = 1
## Base detection radius (px); the Vigil's lantern scales it.
@export var detect_radius_px: float = 0.0
## Detection multiplier with the lantern up (it is a beacon) and down (running dark).
@export var lantern_up_mult: float = 1.0
@export var lantern_down_mult: float = 1.0
## Seconds it keeps tracking after the Vigil leaves its detection.
@export var acquisition_loss_s: float = 0.0
## Max distance from its post (px).
@export var post_leash_px: float = 0.0
## Lag of the censer's aim behind the Vigil (s, exponential time constant).
@export var turret_lag_s: float = 0.0
## It fires only while the Vigil is within this torus distance (px).
@export var range_px: float = 0.0
## Telegraph before a shot (s; 21 frames) and the whole shot cycle (s).
@export var tell_s: float = 0.0
@export var cycle_s: float = 0.0
## Censer-shot speed (px/s) and damage to the Vigil's hull.
@export var shot_speed_px_s: float = 0.0
@export var shot_damage: int = 1
## Score on death.
@export var score: int = 0
## ✱ Hurtbox radius (px) of the knight.
@export var radius_px: float = 8.0
## ✱ Speed (px/s) it drifts toward the Vigil inside its leash, and back to the post.
@export var move_speed_px_s: float = 40.0
## ✱ Shot life (s) and contact radius (px).
@export var shot_life_s: float = 1.5
@export var shot_radius_px: float = 3.0
## ✱ Death: the ember gutters over this many seconds.
@export var die_s: float = 0.4


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["hp", "detect_radius_px", "lantern_up_mult", "lantern_down_mult",
		"acquisition_loss_s", "post_leash_px", "turret_lag_s", "range_px", "tell_s", "cycle_s",
		"shot_speed_px_s", "shot_damage", "score", "radius_px", "move_speed_px_s", "shot_life_s",
		"shot_radius_px", "die_s"])
