extends GdUnitTestSuite
## Pal.AETHER (post-Pretence ramp; palette v2 pending, ART-001 §4): kept apart from the Choir and
## from SIGNAL in Oklab, and never part of Pal.ALL (not a neon role, not in Look).

## ✱ Oklab distance every AETHER entry keeps from every CHOIR entry and SIGNAL.
const MIN_DE := 0.075
## ✱ hue separation from every CHOIR hue when both colours carry chroma.
const MIN_HUE_DEG := 30.0
const MIN_CHROMA := 0.05
## Pairs allowed to break the hue rule. Empty: AETHER-3 moved to #968ED2 (hue 289°, 33° from CHOIR-0)
## so the rule holds for every pair (art director, 2026-11-18).
const KNOWN_HUE_CONFLICTS: Array[String] = []


static func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)


static func oklab(c: Color) -> Vector3:
	var r := _lin(c.r)
	var g := _lin(c.g)
	var b := _lin(c.b)
	var l := pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1.0 / 3.0)
	var m := pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1.0 / 3.0)
	var s := pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1.0 / 3.0)
	return Vector3(0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


static func chroma(lab: Vector3) -> float:
	return Vector2(lab.y, lab.z).length()


static func hue_gap_deg(a: Vector3, b: Vector3) -> float:
	var d := absf(rad_to_deg(atan2(a.z, a.y) - atan2(b.z, b.y)))
	d = fmod(d, 360.0)
	return 360.0 - d if d > 180.0 else d


func _choir() -> Dictionary:
	var out := {}
	for k: Variant in Pal.ALL.keys():
		if str(k).begins_with("CHOIR-"):
			out[str(k)] = Pal.ALL[k]
	return out


func test_aether_has_six_entries_outside_pal_all() -> void:
	assert_int(Pal.AETHER.size()).is_equal(6)
	for k: Variant in Pal.AETHER.keys():
		assert_bool(Pal.ALL.has(k)).override_failure_message("%s must not be in Pal.ALL" % k).is_false()
		var c: Color = Pal.AETHER[k]
		for v: Variant in Pal.ALL.values():
			assert_bool((v as Color).is_equal_approx(c)).override_failure_message("%s duplicates a Pal.ALL entry" % k).is_false()


func test_aether_keeps_its_distance_from_choir_and_signal() -> void:
	var others := _choir()
	others["SIGNAL"] = Pal.SIGNAL
	for k: Variant in Pal.AETHER.keys():
		var a := oklab(Pal.AETHER[k] as Color)
		for o: Variant in others.keys():
			var de := a.distance_to(oklab(others[o] as Color))
			assert_float(de).override_failure_message("%s vs %s: Oklab ΔE %.3f < %.3f" % [k, o, de, MIN_DE]).is_greater_equal(MIN_DE)


func test_aether_hue_stays_off_the_choir() -> void:
	var found: Array[String] = []
	var choir := _choir()
	for k: Variant in Pal.AETHER.keys():
		var a := oklab(Pal.AETHER[k] as Color)
		for o: Variant in choir.keys():
			var b := oklab(choir[o] as Color)
			if chroma(a) >= MIN_CHROMA and chroma(b) >= MIN_CHROMA and hue_gap_deg(a, b) < MIN_HUE_DEG:
				found.append("%s/%s" % [k, o])
	assert_array(found).override_failure_message("hue conflicts changed: %s (known: %s)" % [found, KNOWN_HUE_CONFLICTS]).is_equal(KNOWN_HUE_CONFLICTS)
