class_name SectorKit
extends TunableResource
## One Seam's authored layout (TECH-001 §2.9 `SectorKit`; ZONES-001 §1.7 stand-in until SeamAssembler):
## where the Vigil starts, the geodes, the Sepulchre and its procession, the Acolyte posts, the exit
## anchor and the dark look. The sector host reads one and builds the Seam from it; it never branches on
## `kit_id`. Values live in data/sector/kits/*.tres (`ds_sector.kit_<id>.*`). All positions are torus
## positions in the Cabinet-sized field. ✱ = engineering placement or presentation, owned by TECH-001.

## Stable id (`pm_01`, `pm_02`): the `--kit=` dev switch and the `sector/run` probe name it.
@export var kit_id: StringName = &""
## ✱ Where the Vigil starts.
@export var vigil_spawn: Vector2 = Vector2.ZERO
## ✱ Geode positions. Empty = the sandbox's seeded layout (GeodeSandboxStats), kept as PM-01 has it.
@export var geodes: PackedVector2Array = PackedVector2Array()
## ✱ Sepulchre placement, route and Grub count (the procession's own tunables).
@export var procession: ProcessionSandboxStats
## ✱ Segments the Sepulchre starts with (0 = cold, phase 0; > 0 = Active from the first second).
@export var sepulchre_start_segments: int = 0
## ✱ Route Grubs that spawn already carrying a shard (laid out along the route), so deposits start at once.
@export var start_carriers: int = 0
## ✱ One Acolyte per post.
@export var acolyte_posts: PackedVector2Array = PackedVector2Array()
## ✱ True = the exit throat opens at `exit_anchor`; false = at `ds_sector.exit.throat_pos`.
@export var has_exit_anchor: bool = false
@export var exit_anchor: Vector2 = Vector2.ZERO
## ✱ The dark kit look (PM-02): a multiply veil over the play layer, never black.
@export var dark_default: bool = false
## ✱ The veil colour away from every light (multiplies the play layer; VOID-tinted, never 0).
@export var dark_ambient: Color = Color(1, 1, 1, 1)
## ✱ Multiplier on a Grub's halo outside the light pocket (1 = unchanged).
@export var dark_halo: float = 1.0
## ✱ Extra dimming inside the unlit corridor (1 = none).
@export var corridor_dim: float = 1.0
## ✱ The light pocket: a cold pool of light at this point and radius (px).
@export var light_pocket_pos: Vector2 = Vector2.ZERO
@export var light_pocket_radius_px: float = 0.0
## ✱ The unlit corridor (torus px); Rect2() = none.
@export var unlit_corridor: Rect2 = Rect2()
## ✱ Extra Grubs that spawn at `satellite_spawn` and join the same procession.
@export var satellite_grubs: int = 0
@export var satellite_spawn: Vector2 = Vector2.ZERO
## The far layer's look for this Seam (null = keep the scene's).
@export var far_look: AetherLook


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"vigil_spawn", "geodes", "sepulchre_start_segments", "start_carriers", "acolyte_posts", "has_exit_anchor",
		"exit_anchor", "dark_default", "dark_ambient", "dark_halo", "corridor_dim", "light_pocket_pos",
		"light_pocket_radius_px", "unlit_corridor", "satellite_grubs", "satellite_spawn",
	])
