class_name WarpTier
extends RefCounted
## Warp tier state (WARP-001 §1.3–§1.5): the world tier of one Seam, computed once at Seam entry from
## the four drives, plus the `Hollowed` forced rise. Pure: no nodes, no saves. The tier is never a flag
## on the save (WARP-001 §1.5); RunSessionCore supplies the drives and the composer asks this class.

const PRETENCE := 0
const FRAYED := 1
const BLEEDING := 2
const UNBOUND := 3
const INVERTED := 4
const UNMAKING := 5

## The world tier picked at Seam entry.
var world: int = 0
## +1 while the Hollowed band forces a rise this sector (SYS-001 §1.5); ends at sector end.
var forced: int = 0
## The drives that produced `world`, kept for tests and the dev overlay.
var act: int = 0
var entropy: int = 0
var hollow: bool = false
var composure_zero: bool = false


## WARP-001 §1.3: T_world = clamp(act_floor + hollow + entropy + composure, act_floor, act_ceiling).
static func compute(stats: WarpTierStats, p_act: int, p_entropy: int, p_hollow: bool,
		p_composure_zero: bool) -> WarpTier:
	var t := WarpTier.new()
	t.act = p_act
	t.entropy = p_entropy
	t.hollow = p_hollow
	t.composure_zero = p_composure_zero
	if stats == null or stats.act_floor.is_empty():
		return t
	var a := clampi(p_act, 0, stats.act_floor.size() - 1)
	var lo := stats.act_floor[a]
	var hi := stats.act_ceiling[mini(a, stats.act_ceiling.size() - 1)]
	var sum := lo + entropy_term(stats, p_entropy)
	if p_hollow:
		sum += stats.hollow_term
	if p_composure_zero:
		sum += stats.composure_term
	t.world = clampi(sum, lo, hi)
	return t


static func entropy_term(stats: WarpTierStats, e: int) -> int:
	if stats.entropy_step_2 > 0 and e >= stats.entropy_step_2:
		return 2
	if stats.entropy_step_1 > 0 and e >= stats.entropy_step_1:
		return 1
	return 0


## The tier in play: the world tier plus a Hollowed forced rise, never above the act ceiling
## (WARP-001 §1.4 "Any → T+1 forced": "at any tier below that act's ceiling").
func effective(stats: WarpTierStats) -> int:
	if stats == null or stats.act_ceiling.is_empty():
		return world
	var hi := stats.act_ceiling[clampi(act, 0, stats.act_ceiling.size() - 1)]
	return mini(world + forced, maxi(hi, world))


## Hollowed band reached (Composure 0): force +1 for the rest of the sector, below the ceiling only.
## Returns true when the effective tier rose.
func force_hollowed(stats: WarpTierStats) -> bool:
	if forced > 0:
		return false
	var before := effective(stats)
	forced = 1
	return effective(stats) > before
