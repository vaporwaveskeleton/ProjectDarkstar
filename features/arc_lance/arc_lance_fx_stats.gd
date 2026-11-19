class_name ArcLanceFxStats
extends TunableResource
## Arc-Lance "bite" presentation tunables (M1): muzzle star, visual-only recoil, impact flecks,
## chalk tick and the lance_dull level. Values are the owner-approved Lance-bite values in
## SYS-001 §9 (TECH-001 Q-T50), copied into data/arc_lance/arc_lance_fx.tres under ds_arc_lance.fx.
## The Cabinet keeps its own copies under ds_cabinet.fx (Act 0 owns its own tuning).
## Never edit numbers here; edit the .tres (and SYS-001 first).

## px ⚙ SYS-001 §9: arm length of the muzzle plus
@export var muzzle_star_px: int = 0
## drawn frames ⚙ SYS-001 §9: how long the muzzle star shows
@export var muzzle_star_frames: int = 0
## px ⚙ SYS-001 §9: visual-only draw nudge opposite the aim (never moves position/velocity/facing)
@export var recoil_px: int = 0
## drawn frames ⚙ SYS-001 §9
@export var recoil_frames: int = 0
## px/s ⚙ SYS-001 §9: impact flecks leave perpendicular to the shot
@export var fleck_speed_px_s: float = 0.0
## s ⚙ SYS-001 §9
@export var fleck_life_s: float = 0.0
## px ⚙ SYS-001 §9: the chalk tick where the lance cannot bite
@export var tick_len_px: int = 0
## s ⚙ SYS-001 §9
@export var tick_life_s: float = 0.0
## dB ⚙ SYS-001 §9: lance_dull cue volume offset
@export var lance_dull_db: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["muzzle_star_px", "muzzle_star_frames", "recoil_px", "recoil_frames",
		"fleck_speed_px_s", "fleck_life_s", "tick_len_px", "tick_life_s", "lance_dull_db"])
