extends GdUnitTestSuite
## Race edge markers (Q-T357): one brass chevron per off-screen race part, on the inner band that clears
## the HUD plates, pointing at the part; on-screen parts get none; Charges first under the cap; palette
## colours only; no lie seam.

const STATS := preload("res://data/hud/race_edge_markers.tres")
const SCREEN := Vector2(640, 360)


func _markers() -> RaceEdgeMarkers:
	var m: RaceEdgeMarkers = auto_free(RaceEdgeMarkers.new())
	m.stats = STATS
	add_child(m)
	return m


func test_edge_point_sits_on_the_band_along_the_ray() -> void:
	var m := _markers()
	var band := m.inner_band(SCREEN)
	assert_vector(band.position).is_equal(Vector2(STATS.inset_side_px, STATS.inset_top_px))
	assert_vector(band.end).is_equal(SCREEN - Vector2(STATS.inset_side_px, STATS.inset_bottom_px))
	var half := SCREEN * 0.5
	# Straight right: on the right edge of the band, at the centre's height.
	assert_vector(RaceEdgeMarkers.edge_point(Vector2(900, 0), half, band)).is_equal(Vector2(band.end.x, half.y))
	# Straight up: on the band's top (below the top plates).
	assert_vector(RaceEdgeMarkers.edge_point(Vector2(0, -500), half, band)).is_equal(Vector2(half.x, band.position.y))
	# A diagonal stays on the ray and inside the band.
	var d := Vector2(800, 600)
	var p := RaceEdgeMarkers.edge_point(d, half, band)
	assert_bool(band.grow(0.01).has_point(p)).is_true()
	assert_float((p - half).normalized().dot(d.normalized())).is_greater(0.999)


func test_only_offscreen_parts_get_markers() -> void:
	var m := _markers()
	var offs := PackedVector2Array([Vector2(100, 20), Vector2(700, 0), Vector2(-50, -400)])
	var kinds: Array[StringName] = [RaceEdgeMarkers.KIND_CHARGE, RaceEdgeMarkers.KIND_SEPULCHRE, RaceEdgeMarkers.KIND_GRUB]
	m.show_race(offs, kinds, SCREEN)
	assert_int(m.count()).is_equal(2)
	assert_array(m.kinds).is_equal([RaceEdgeMarkers.KIND_SEPULCHRE, RaceEdgeMarkers.KIND_GRUB])
	assert_float(m.dirs[0].dot(Vector2.RIGHT)).is_greater(0.99)
	m.show_race(PackedVector2Array(), [] as Array[StringName], SCREEN)
	assert_int(m.count()).is_equal(0)


func test_charges_come_first_under_the_cap() -> void:
	var m := _markers()
	var offs := PackedVector2Array()
	var kinds: Array[StringName] = []
	for i in STATS.max_markers + 3:
		offs.append(Vector2(-800 - i * 10, 0))
		kinds.append(RaceEdgeMarkers.KIND_GRUB)
	offs.append(Vector2(0, 900))
	kinds.append(RaceEdgeMarkers.KIND_CHARGE)
	m.show_race(offs, kinds, SCREEN)
	assert_int(m.count()).is_equal(STATS.max_markers)
	assert_str(String(m.kinds[0])).is_equal(String(RaceEdgeMarkers.KIND_CHARGE))


func test_colours_are_palette_entries_and_there_is_no_lie_seam() -> void:
	var allowed: Array = Pal.ALL.values()
	for k: StringName in [RaceEdgeMarkers.KIND_CHARGE, RaceEdgeMarkers.KIND_GRUB, RaceEdgeMarkers.KIND_SEPULCHRE, &"other"]:
		assert_bool(allowed.has(RaceEdgeMarkers.color_for(k))).is_true()
	assert_bool(RaceEdgeMarkers.HONEST).is_true()
	var probe: RaceEdgeMarkers = auto_free(RaceEdgeMarkers.new())
	assert_bool("liar" in probe).is_false()


func test_it_draws() -> void:
	var m := _markers()
	var kinds: Array[StringName] = [RaceEdgeMarkers.KIND_SEPULCHRE]
	m.show_race(PackedVector2Array([Vector2(900, 300)]), kinds, SCREEN)
	await await_idle_frame()
	assert_int(m.draw_count).is_greater(0)
