extends GdUnitTestSuite
## RunSeed streams and SeedCode (TECH-001 §4.9). Pinned hash values were computed by an
## independent BigInt reference (node), not by this implementation.

const MAX_SEED := 0x7FFFFFFFFFFFFF


func _draw(rng: RandomNumberGenerator, n: int) -> Array[int]:
	var out: Array[int] = []
	for i in n:
		out.append(rng.randi())
	return out


func test_hash64_pinned_values() -> void:
	assert_int(RunSeed.hash64(123456789, "map", 0)).is_equal(-7834688126535706054)
	assert_int(RunSeed.hash64(123456789, "kits", 3)).is_equal(-1513310087194196715)
	assert_int(RunSeed.hash64(MAX_SEED, "warp", -2)).is_equal(-2734986135168668244)


func test_same_seed_stream_seam_same_sequence() -> void:
	var a := RunSeed.new(42).stream(RunSeed.STREAM_MAP, 5)
	var b := RunSeed.new(42).stream(RunSeed.STREAM_MAP, 5)
	assert_array(_draw(a, 16)).is_equal(_draw(b, 16))


func test_different_streams_differ() -> void:
	var rs := RunSeed.new(42)
	var seen: Dictionary = {}
	for s in RunSeed.STREAMS:
		seen[_draw(rs.stream(s), 4)] = true
	assert_int(seen.size()).is_equal(RunSeed.STREAMS.size())


func test_different_seams_differ() -> void:
	var rs := RunSeed.new(42)
	assert_array(_draw(rs.stream(&"map", 0), 4)).is_not_equal(_draw(rs.stream(&"map", 1), 4))


func test_different_seeds_differ() -> void:
	assert_array(_draw(RunSeed.new(1).stream(&"ai"), 4)).is_not_equal(_draw(RunSeed.new(2).stream(&"ai"), 4))


func test_seed_masked_to_55_bits() -> void:
	assert_int(RunSeed.new(-1).seed_value).is_equal(MAX_SEED)


func _seed_samples() -> Array[int]:
	var seeds: Array[int] = [0, 1, MAX_SEED, MAX_SEED - 1, 1 << 54, 31, 32]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 500:
		seeds.append(((rng.randi() << 32) | rng.randi()) & MAX_SEED)
	return seeds


func test_round_trip() -> void:
	for s in _seed_samples():
		var code := SeedCode.encode(s)
		assert_int(code.length()).is_equal(12)
		assert_int(SeedCode.decode(code)).is_equal(s)
		assert_int(SeedCode.decode(SeedCode.encode(s, true))).is_equal(s)


func test_grouped_format() -> void:
	var code := SeedCode.encode(MAX_SEED, true)
	assert_int(code.length()).is_equal(14)
	assert_str(code[4]).is_equal("-")
	assert_str(code[9]).is_equal("-")


func test_zero_seed_code() -> void:
	assert_str(SeedCode.encode(0)).is_equal("000000000000")


func test_single_symbol_corruption_always_detected() -> void:
	for s in _seed_samples().slice(0, 60):
		var code := SeedCode.encode(s)
		for pos in 12:
			for sym in SeedCode.ALPHABET:
				if sym == code[pos]:
					continue
				var bad := code.substr(0, pos) + sym + code.substr(pos + 1)
				assert_int(SeedCode.decode(bad)).is_equal(SeedCode.INVALID)


func test_crc5_pinned_vectors() -> void:
	var vectors := {0: "0000-0000-0000", 1: "0000-0000-0015", 12345: "0000-0000-C1SK", MAX_SEED: "ZZZZ-ZZZZ-ZZZ4"}
	for s: int in vectors:
		var code: String = vectors[s]
		assert_str(SeedCode.encode(s, true)).is_equal(code)
		assert_int(SeedCode.decode(code)).is_equal(s)


func test_adjacent_swap_of_known_vector_rejected() -> void:
	assert_int(SeedCode.decode("0000-0000-1CSK")).is_equal(SeedCode.INVALID)


func test_adjacent_swap_stats() -> void:
	var total := 0
	var rejected := 0
	for s in _seed_samples().slice(0, 60):
		var code := SeedCode.encode(s)
		for pos in 11:
			if code[pos] == code[pos + 1]:
				continue
			var swapped := code.substr(0, pos) + code[pos + 1] + code[pos] + code.substr(pos + 2)
			total += 1
			if SeedCode.decode(swapped) == SeedCode.INVALID:
				rejected += 1
	print("SEEDCODE_SWAP_STATS rejected=%d total=%d" % [rejected, total])
	assert_int(total).is_greater(0)
	assert_int(rejected).is_greater(0)


func test_rejects_bad_length_and_symbols() -> void:
	assert_int(SeedCode.decode("")).is_equal(SeedCode.INVALID)
	assert_int(SeedCode.decode("00000000000")).is_equal(SeedCode.INVALID)
	assert_int(SeedCode.decode("0000000000000")).is_equal(SeedCode.INVALID)
	assert_int(SeedCode.decode("00000000000U")).is_equal(SeedCode.INVALID)
	assert_int(SeedCode.decode("00000000000!")).is_equal(SeedCode.INVALID)
	assert_bool(SeedCode.is_valid("000000000000")).is_true()


func test_lowercase_ambiguous_and_grouping_accepted() -> void:
	var s := 0x1234567
	var code := SeedCode.encode(s, true)
	assert_int(SeedCode.decode(code.to_lower())).is_equal(s)
	assert_int(SeedCode.decode(code.replace("-", " "))).is_equal(s)
	# I/L read as 1, O reads as 0.
	assert_int(SeedCode.decode("OOOOOOOOOOOO")).is_equal(0)
	var one_code := SeedCode.encode(1)
	assert_int(SeedCode.decode(one_code.replace("1", "I"))).is_equal(1)
	assert_int(SeedCode.decode(one_code.replace("1", "l"))).is_equal(1)
