class_name SeedCode
extends RefCounted
## 12-character Crockford base32 form of a RunSeed (TECH-001 §4.9): 60 bits = (seed << 5) | checksum,
## most-significant symbol first. §4.9 says it is displayed as XXXX-XXXX-XXXX, so decode accepts
## hyphens and spaces and ignores them.
##
## Gap defaults chosen for Q-T26/Q-T27:
##  - checksum = CRC-5 (polynomial x^5+x^2+1 = 0x05, init 0, no reflection, no final XOR) over the
##    55 seed bits fed most-significant first. Detects every single-symbol error and, unlike a plain
##    XOR, is order-sensitive; it does not guarantee detection of every adjacent swap.
##  - decode is case-insensitive, reads I/L as 1 and O as 0; U and other symbols are rejected.
## decode() returns INVALID (-1, never a legal seed) on any failure; callers show a tr("MSG_...") line,
## never a raw error.

const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const LENGTH := 12
const INVALID := -1


static func checksum(run_seed: int) -> int:
	var crc: int = 0
	for i in range(54, -1, -1):
		var feedback: int = ((crc >> 4) & 1) ^ ((run_seed >> i) & 1)
		crc = (crc << 1) & 31
		if feedback == 1:
			crc ^= 0x05
	return crc


static func encode(run_seed: int, grouped: bool = false) -> String:
	var seed_value: int = run_seed & RunSeed.SEED_MASK
	var packed: int = (seed_value << 5) | checksum(seed_value)
	var out := ""
	for i in LENGTH:
		out += ALPHABET[(packed >> (5 * (LENGTH - 1 - i))) & 31]
	if grouped:
		return "%s-%s-%s" % [out.substr(0, 4), out.substr(4, 4), out.substr(8, 4)]
	return out


static func is_valid(code: String) -> bool:
	return decode(code) != INVALID


## Returns the seed, or INVALID when the length, a symbol or the checksum is wrong.
static func decode(code: String) -> int:
	var cleaned: String = code.strip_edges().to_upper().replace("-", "").replace(" ", "")
	cleaned = cleaned.replace("I", "1").replace("L", "1").replace("O", "0")
	if cleaned.length() != LENGTH:
		return INVALID
	var packed: int = 0
	for i in LENGTH:
		var idx: int = ALPHABET.find(cleaned[i])
		if idx < 0:
			return INVALID
		packed = (packed << 5) | idx
	var run_seed: int = packed >> 5
	if (packed & 31) != checksum(run_seed):
		return INVALID
	return run_seed
