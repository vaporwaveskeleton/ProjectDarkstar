class_name GeodeSandboxStats
extends TunableResource
## The M1 sector sandbox's geode layout (no kit assembly yet). Values in data/charges/geode_sandbox.tres.

## Geodes placed in the M1 sandbox (PM, M1 slice 3 PR 3).
@export var geode_count: int = 0
## Run seed for the sandbox (masked to 55 bits by RunSeed). Positions and size classes use the
## `map` stream, detonations the `loot` stream, shapes the `vfx` stream (TECH-001 §4.9) ✱.
@export var run_seed: int = 0
## No geode is placed closer than this to the Vigil spawn (px) ✱ (mirrors the Cabinet's 160).
@export var spawn_clear_radius_px: float = 0.0
## Tries to find a clear point before accepting the last one drawn ✱ (engineering).
@export var placement_attempts: int = 1


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["geode_count", "run_seed", "spawn_clear_radius_px", "placement_attempts"])
