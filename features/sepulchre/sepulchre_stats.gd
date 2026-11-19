class_name SepulchreStats
extends TunableResource
## The Sepulchre's build numbers, phases 0–1 (GDD §8.4, SYS-001 §2). Values in data/sepulchre/sepulchre.tres.

## SYS-001 §2 phase 1: a segment costs 3 shards ✱ (each deposited shard = 1 segment point).
@export var shards_per_segment: int = 1
## GDD §8.4 / SYS-001 §2: 20 segments complete the entity (🔒).
@export var segments_total: int = 1
## Segments one Charge hit knocks off in phases 0–1 (PM, M1 slice 3 PR 4: 1).
@export var segments_knocked_per_hit: int = 1
## SYS-001 §7.1 "Sepulchre module knocked off": 500 per segment.
@export var score_per_segment_knocked: int = 0
## A carrying Grub deposits inside this distance of the Sepulchre (px) ✱ (the Cabinet's 26).
@export var deposit_radius_px: float = 0.0
## Radius of the Sepulchre's hurtbox (Charges hit it; the lance leaves a chalk tick) (px) ✱ (Cabinet 26).
@export var hurt_radius_px: float = 0.0
## Seconds the deposit ring shows after a deposit ✱ (presentation).
@export var deposit_pulse_s: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["shards_per_segment", "segments_total", "segments_knocked_per_hit",
		"score_per_segment_knocked", "deposit_radius_px", "hurt_radius_px", "deposit_pulse_s"])
