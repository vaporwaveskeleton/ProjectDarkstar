class_name GrubStats
extends TunableResource
## Oubliette Grub tunables (GDD §8.5, SYS-001 §3). Values live in data/choir/grub.tres.

## SYS-001 §3: HP 2 (hits at base lance; owner F-11, 2026-11-20, was 4).
@export var hp: int = 1
## SYS-001 §3: 130 px/s while carrying.
@export var carry_speed_px_s: float = 0.0
## SYS-001 §3: 190 px/s while fleeing.
@export var flee_speed_px_s: float = 0.0
## SYS-001 §3 Grub seek speed: 160 px/s ✱ toward a free shard.
@export var seek_speed_px_s: float = 0.0
## SYS-001 §3 Grub flee radius: 110 px ✱ from the Vigil's lantern.
@export var flee_radius_px: float = 0.0
## SYS-001 §3 Grub respawn: 6.0 s ✱ until a killed Grub is replaced (at the Sepulchre).
@export var respawn_s: float = 0.0
## SYS-001 §7.1: score per Grub killed (150).
@export var score: int = 0
## Body / hurtbox radius (px) ✱ (the Cabinet's 6).
@export var radius_px: float = 6.0
## A seeking Grub takes its shard within radius + this (px) ✱ (the Cabinet's 4).
@export var pickup_margin_px: float = 4.0
## Velocity steer rate toward the wanted velocity (1/s) ✱ (the Cabinet's 5).
@export var steer_per_s: float = 5.0
## Closer than this to its goal a Grub wants no velocity (px) ✱ (the Cabinet's 2).
@export var arrive_px: float = 2.0
## A fleeing Grub aims this far straight away from the lantern (px) ✱ (the Cabinet's 80).
@export var flee_step_px: float = 80.0
## Idle (no free glass): orbit the Sepulchre at this radius (px) ✱ (the Cabinet's 90) …
@export var idle_orbit_px: float = 90.0
## … at this speed (px/s) ✱ (the Cabinet's 70) …
@export var idle_speed_px_s: float = 70.0
## … with the orbit point turning at this rate (rad/s) ✱ (the Cabinet's 0.3).
@export var idle_orbit_rate: float = 0.3
## A carrier counts a route waypoint as passed inside this distance (px) ✱.
@export var waypoint_reach_px: float = 12.0
## A dying carrier drops its shard with this fraction of its velocity ✱ (the Cabinet's 0.3).
@export var drop_speed_frac: float = 0.3


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["hp", "carry_speed_px_s", "flee_speed_px_s", "seek_speed_px_s",
		"flee_radius_px", "respawn_s", "score", "radius_px", "pickup_margin_px", "steer_per_s",
		"arrive_px", "flee_step_px", "idle_orbit_px", "idle_speed_px_s", "idle_orbit_rate",
		"waypoint_reach_px", "drop_speed_frac"])
