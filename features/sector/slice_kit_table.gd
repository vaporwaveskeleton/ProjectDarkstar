class_name SliceKitTable
extends TunableResource
## The slice run's Seam kits in order (`ds_sector.slice.*`, data/sector/slice_kits.tres): Seam 1 PM-01,
## Seam 2 PM-02. The sector host asks for the kit of the run's current Seam; a Seam past the last entry
## replays the last kit.

const ARG_KIT := "kit"
## Dev switch (captures, scenarios that cross the Acolyte's ground unarmed): the kit builds no Acolytes.
const ARG_ACOLYTE_OFF := "--acolyte-off"

@export var seam_kits: Array[SectorKit] = []


## The kit of 1-based `seam_index`: index seam − 1, clamped to the table. Null when the table is empty.
func kit_for_seam(seam_index: int) -> SectorKit:
	if seam_kits.is_empty():
		return null
	return seam_kits[clampi(seam_index - 1, 0, seam_kits.size() - 1)]


## The kit with `id`, or null.
func kit_by_id(id: StringName) -> SectorKit:
	for k in seam_kits:
		if k != null and k.kit_id == id:
			return k
	return null


## The kit a launch uses for `seam_index`: in a dev build a `--kit=<id>` switch forces that kit
## (an unknown id is ignored); otherwise the Seam's own.
func kit_for_launch(args: PackedStringArray, dev_build: bool, seam_index: int) -> SectorKit:
	if dev_build:
		var forced := LaunchRoute.arg_value(args, ARG_KIT)
		if forced != "" and kit_by_id(StringName(forced)) != null:
			return kit_by_id(StringName(forced))
	return kit_for_seam(seam_index)


## True when `--acolyte-off` is given in a dev build.
static func acolytes_off(args: PackedStringArray, dev_build: bool) -> bool:
	return dev_build and args.has(ARG_ACOLYTE_OFF)
