extends GdUnitTestSuite
## PM ruling 2026-11-19 (a): the tube mask rounds the screen's four corners (ScreenTube, radius ✱ in CabinetSurface),
## replacing the few corner texels outside the corner circle. No HUD readout and no fixed message margin may sit
## in those texels. The masked cells here use ScreenTube's own rule (and are checked against mask_pixels()).

const SPEC := "res://data/cabinet/cabinet_screen.tres"


func _surface() -> CabinetSurface:
	return CabinetSurface.default() as CabinetSurface


## Every masked texel of a grid of `grid` texels, as unit cells in grid coordinates: the cells whose centre lies
## outside the corner circle, mirrored into all four corners (the same rule as ScreenTube.mask_pixels()).
func _masked_cells(grid: Vector2i) -> Array[Rect2]:
	var r := _surface().tube_corner_radius
	var out: Array[Rect2] = []
	for i in int(ceil(r)):
		for j in int(ceil(r)):
			if Vector2(i + 0.5, j + 0.5).distance_to(Vector2(r, r)) > r:
				for fx in [false, true]:
					for fy in [false, true]:
						var x := float(grid.x - 1 - i) if fx else float(i)
						var y := float(grid.y - 1 - j) if fy else float(j)
						out.append(Rect2(x, y, 1.0, 1.0))
	return out


func _hits(box: Rect2, grid: Vector2i) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for c in _masked_cells(grid):
		if box.intersects(c):
			out.append(c)
	return out


func test_masked_cells_match_the_tubes_own_count() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	assert_int(_masked_cells(spec.grid).size()).is_equal(ScreenTube.mask_pixels(_surface()))


func test_no_hud_readout_sits_in_a_masked_corner() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	# worst cases: the widest score and high score the strip can show, every lamp and every spare Vigil, both sepulchre readouts
	var cases: Array[Array] = [["0", "0", "0/9"], ["9,999,999", "9,999,999", "9/9"], ["12,345", "99,999", ""]]
	for c in cases:
		for b in CabinetScreenHud.readout_boxes(c[0], c[1], c[2], 9, CabinetScreenHud.MAX_LAMPS):
			var hit := _hits(b.box, spec.grid)
			assert_int(hit.size()).override_failure_message("HUD readout '%s' %s covers masked texels %s" % [b.name, b.box, hit]).is_equal(0)
	for text in ["CREDIT 0", "CREDIT 1", "CREDITS 99"]:
		var cb := CabinetScreenHud.credit_box(text, Vector2(spec.grid))
		assert_int(_hits(cb, spec.grid).size()).override_failure_message("credit line %s covers masked texels" % cb).is_equal(0)


func test_hud_strip_and_message_margin_clear_the_corner_extent() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	var cells := _masked_cells(spec.grid)
	var reach := 0.0     # the farthest a masked texel is from its own corner, along either axis
	for c in cells:
		var dx := minf(c.position.x, float(spec.grid.x) - 1.0 - c.position.x)
		var dy := minf(c.position.y, float(spec.grid.y) - 1.0 - c.position.y)
		reach = maxf(reach, maxf(dx, dy) + 1.0)
	assert_float(CabinetMessages.MARGIN).override_failure_message("message margin %s inside the masked corner reach %s" % [CabinetMessages.MARGIN, reach]).is_greater_equal(reach)
	assert_float(CabinetScreenHud.LEFT_X).is_greater_equal(reach)
	assert_float(float(spec.grid.x) - CabinetScreenHud.RIGHT_EDGE).is_greater_equal(reach)
	assert_float(float(spec.grid.x) - CabinetScreenHud.LAMP_END_X).is_greater_equal(reach)
