class_name RunSeed
extends RefCounted
## Deterministic run identity (TECH-001 §4.9). A 55-bit seed; every random draw goes through a
## named stream so adding a roll to one stream never shifts another.
##
## Gap defaults chosen for Q-T26 (owner told us to pick; record in TECH-001 when docs are updated):
##  - stream_seed = hash64(run_seed, stream_name, seam_index); seam_index is an int, 0 for streams with no seam.
##  - hash64: h = FNV-1a 64 over the UTF-8 bytes of stream_name; x = run_seed ^ h ^ (seam_index * 0x9E3779B97F4A7C15);
##    then the SplitMix64 finalizer. GDScript ints are signed 64-bit and wrap on multiply; there is no
##    logical shift, so every >> is followed by a mask of the vacated high bits.
## Not built here: ReplayVerifier (needs a deterministic simulation that does not exist yet).

const SEED_BITS := 55
const SEED_MASK := 0x7FFFFFFFFFFFFF

const STREAM_MAP := &"map"
const STREAM_KITS := &"kits"
const STREAM_SLOTS := &"slots"
const STREAM_WARP := &"warp"
const STREAM_LOOT := &"loot"
const STREAM_AI := &"ai"
const STREAM_VFX := &"vfx"  ## seeded but excluded from verification (§4.9)

const STREAMS: Array[StringName] = [
	STREAM_MAP, STREAM_KITS, STREAM_SLOTS, STREAM_WARP, STREAM_LOOT, STREAM_AI, STREAM_VFX,
]

# 64-bit constants built from 32-bit halves: GDScript hex literals above int64 max are not portable.
const _FNV_OFFSET := (0xcbf29ce4 << 32) | 0x84222325
const _FNV_PRIME := 0x100000001b3
const _GOLDEN := (0x9E3779B9 << 32) | 0x7F4A7C15
const _MIX1 := (0xBF58476D << 32) | 0x1CE4E5B9
const _MIX2 := (0x94D049BB << 32) | 0x133111EB

var seed_value: int = 0


func _init(value: int = 0) -> void:
	seed_value = value & SEED_MASK


## Seeded generator for one named stream. Same (seed, stream, seam_index) always gives the same sequence.
func stream(stream_name: StringName, seam_index: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash64(seed_value, String(stream_name), seam_index)
	return rng


static func hash64(run_seed: int, stream_name: String, seam_index: int) -> int:
	var h: int = _FNV_OFFSET
	for byte in stream_name.to_utf8_buffer():
		h = (h ^ int(byte)) * _FNV_PRIME
	var x: int = run_seed ^ h ^ (seam_index * _GOLDEN)
	var z: int = x ^ ((x >> 30) & 0x3FFFFFFFF)
	z = z * _MIX1
	z = z ^ ((z >> 27) & 0x1FFFFFFFFF)
	z = z * _MIX2
	return z ^ ((z >> 31) & 0x1FFFFFFFF)
