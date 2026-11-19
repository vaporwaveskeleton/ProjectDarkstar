class_name GeodeStats
extends TunableResource
## Geode mining tunables (SYS-001 §1.3). Values live in data/charges/geode.tres.
## Size classes are indices 0..2 into the *_by_class arrays.

## SYS-001 §1.3: lance hits to shatter one face (0.9 s at 6/s, damage 1) 🔒.
@export var face_hits: int = 0
## SYS-001 §1.3 over-fire: this many hits inside the window detonates the geode ✱.
@export var overfire_hits: int = 0
## SYS-001 §1.3 over-fire window (s) ✱.
@export var overfire_window_s: float = 0.0
## Hits inside the window that sound the over-fire warning once (AUDIO-001 cue overfire_warn) ✱.
@export var overfire_warn_hits: int = 0
## SYS-001 §1.3 calm kill shards.
@export var shards_calm: int = 0
## SYS-001 §1.3: +1 shard for a mined (calm) kill.
@export var shards_mined_bonus: int = 0
## SYS-001 §1.3 detonated shards, total for the geode (already-freed glass counts toward it).
@export var shards_detonated_min: int = 0
@export var shards_detonated_max: int = 0
## SYS-001 §1.3 detonation scatter (px): a detonated shard comes to rest within this of the centre.
@export var detonation_scatter_px: float = 0.0
## SYS-001 §1.3 faces per size class (1/2/3).
@export var faces_by_class: PackedInt32Array = PackedInt32Array()
## SYS-001 §1.3 radius per size class (px; 10/15/21). Hurtbox and drawing both use it.
@export var radius_by_class: PackedFloat32Array = PackedFloat32Array()

@export_group("Shard release (mirrors the Cabinet's geode_field.gd literals) ✱")
## Release ring for a shattered face: radius + this (px) ✱.
@export var face_release_px: float = 0.0
## Release speed for a shattered face (px/s) ✱.
@export var face_release_speed: float = 0.0
## Release ring for the calm kill: radius + this (px) ✱.
@export var calm_release_px: float = 0.0
## Release speed for the calm kill (px/s) ✱.
@export var calm_release_speed: float = 0.0
## Shards appear at least this far from the centre (px) ✱.
@export var release_offset_min_px: float = 0.0
## Shards appear at most release distance × this ✱.
@export var release_offset_frac: float = 0.0
## Slowest release speed as a fraction of the release speed ✱.
@export var release_speed_min_frac: float = 0.0
## Detonation release distance = scatter × this; its speed is the scatter, capped so the drift
## stops inside detonation_scatter_px ✱.
@export var detonation_inner_frac: float = 0.0

@export_group("Shape (presentation, mirrors the Cabinet) ✱")
@export var shape_vertices_base: int = 0
@export var shape_vertices_per_class: int = 0
@export var shape_jitter_min: float = 0.0
@export var glints_base: int = 0
@export var glints_per_class: int = 0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["face_hits", "overfire_hits", "overfire_window_s", "overfire_warn_hits",
		"shards_calm", "shards_mined_bonus", "shards_detonated_min", "shards_detonated_max",
		"detonation_scatter_px", "faces_by_class", "radius_by_class", "face_release_px",
		"face_release_speed", "calm_release_px", "calm_release_speed", "release_offset_min_px",
		"release_offset_frac", "release_speed_min_frac", "detonation_inner_frac",
		"shape_vertices_base", "shape_vertices_per_class", "shape_jitter_min", "glints_base",
		"glints_per_class"])


func class_count() -> int:
	return mini(faces_by_class.size(), radius_by_class.size())


func faces_for(size_class: int) -> int:
	return faces_by_class[clampi(size_class, 0, class_count() - 1)]


func radius_for(size_class: int) -> float:
	return radius_by_class[clampi(size_class, 0, class_count() - 1)]
