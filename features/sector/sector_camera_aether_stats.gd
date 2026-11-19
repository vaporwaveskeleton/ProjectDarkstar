class_name SectorCameraAetherStats
extends TunableResource
## Aether camera velocity lead (SYS-001 §1.1a). Both values ✱ engineering. data/sector/sector_camera_aether.tres.

## Seconds of velocity the camera leads by.
@export var velocity_lead_s: float = 0.0
## Hard cap on the lead (px).
@export var velocity_lead_max_px: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["velocity_lead_s", "velocity_lead_max_px"])
