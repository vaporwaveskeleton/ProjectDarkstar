class_name ProcessionSandboxStats
extends TunableResource
## The M1 sector sandbox's Sepulchre placement, procession route and Grub count (no kit assembly
## yet; SeamAssembler and the kit's `sepulchre_anchor` / `procession_routes` replace this later,
## ZONES-001 §6.1, §6.4). Values in data/sepulchre/procession_sandbox.tres. Deterministic: no RNG.

## Torus position of the Sepulchre ✱: off the spawn sightline (ZONES-001 §6.1 phase 0).
@export var sepulchre_pos: Vector2 = Vector2.ZERO
## The one procession route: waypoints in walking order, the last one nearest the Sepulchre ✱
## (ZONES-001 §6.1: 1–2 routes of 2–4 waypoints; this sandbox uses 1 route of 3).
@export var route: PackedVector2Array = PackedVector2Array()
## Grubs in the sandbox (PM, M1 slice 3 PR 4: 4).
@export var grub_count: int = 0
## Grubs start on a ring of this radius round the Sepulchre (px) ✱ (the Cabinet's 60).
@export var grub_spawn_ring_px: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["sepulchre_pos", "route", "grub_count", "grub_spawn_ring_px"])
