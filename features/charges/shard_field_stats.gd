class_name ShardFieldStats
extends TunableResource
## Mourning Glass shard field tunables (TECH-001 §4.3). Values live in data/charges/shard_field.tres.
## Never edit numbers here; edit the .tres (and SYS-001 first).

## Shard pool size (PM ruling Q-T58, 2026-11-18: 144 = 24 geodes × 6 detonated shards) ✱.
## Shards never despawn (SYS-001 §1.4); a spawn past the pool is refused and counted, never a crash.
@export var pool_size: int = 0
## Spatial grid cell (px). TECH-001 §4.3: 64 px, one module (ART-002 §1) ✱.
@export var grid_cell_px: float = 0.0
## SYS-001 §1.4 Shard magnet radius (px).
@export var magnet_radius_px: float = 0.0
## SYS-001 §1.4 magnet pull speed inside the radius (px/s).
@export var magnet_pull_px_s: float = 0.0
## How fast a shard's velocity turns toward the pull, per second ✱ (mirrors the Cabinet's
## glass_field.gd literal `delta * 6.0`).
@export var magnet_steer_per_s: float = 0.0
## SYS-001 §1.4 shard drift drag (1/s, exponential).
@export var drag_per_s: float = 0.0
## Shard pickup radius (px) ✱ (mirrors the Cabinet's SHARD_RADIUS).
@export var shard_radius_px: float = 0.0
## Extra pickup slack beyond collector + shard radius (px) ✱ (mirrors the Cabinet's `+ 2.0`).
@export var collect_margin_px: float = 0.0
## WARP-001 §3.2 H4: true pushes shards away instead of pulling (one flag, no second code path).
@export var magnet_inverted: bool = false
## Grubs query the grid for glass once every this many physics ticks (TECH-001 §4.3) ✱.
@export var grub_query_interval_ticks: int = 1
## GDD §8.3 / SYS-001: score per collected shard.
@export var score_per_shard: int = 0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["pool_size", "grid_cell_px", "magnet_radius_px", "magnet_pull_px_s",
		"magnet_steer_per_s", "drag_per_s", "shard_radius_px", "collect_margin_px", "magnet_inverted",
		"grub_query_interval_ticks", "score_per_shard"])
