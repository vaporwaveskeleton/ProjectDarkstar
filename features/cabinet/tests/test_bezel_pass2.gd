extends GdUnitTestSuite
## PR C pass 2: the real tube (rounded mask, a very faint glass layer with a readability bound and an off
## switch), the screen lighting the cabinet (read-only sampling), the cabinet's edge (T-molding, bolts,
## room) never covering the opening at the five target sizes, and the marquee.

const SCREEN := Rect2(192, 28, 256, 304)
const SIZES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3440, 1440), Vector2i(1280, 800), Vector2i(1366, 768)]
const READABLE := 0.15        ## the glass must never move a screen channel (0..1) by more than this

var _saved_photo := false
var _saved_persist := true


func before_test() -> void:
	_saved_persist = SettingsService.persist
	SettingsService.persist = false          # never write the player's settings.cfg
	_saved_photo = SettingsService.get_value(&"photosensitivity")
	SettingsService.set_value(&"photosensitivity", false)


func after_test() -> void:
	SettingsService.set_value(&"photosensitivity", _saved_photo)
	SettingsService.persist = _saved_persist


func _surface() -> CabinetSurface:
	return load("res://data/cabinet/cabinet_surface.tres") as CabinetSurface


# --- the tube glass ---------------------------------------------------------------------------------

## Computed analytically: an alpha blend moves a channel by at most its alpha, and the shader clamps the glass's
## alpha to max_alpha, the sum of its own ✱ amounts bounded by tube_max_shift. So no screen channel moves by more.
func test_tube_glass_cannot_shift_any_screen_channel_beyond_the_bound() -> void:
	var s := _surface()
	var sum := (s.tube_reflection + s.tube_dust + s.tube_bloom + s.tube_edge_shadow) * s.tube_glass
	var bound := ScreenTube.max_alpha(s, true)
	assert_float(bound).is_equal(minf(sum, s.tube_max_shift))
	assert_float(bound).is_greater(0.0)
	assert_float(bound).is_less_equal(READABLE)
	assert_float(s.tube_max_shift).is_less_equal(READABLE)
	for v in [s.tube_reflection, s.tube_dust, s.tube_bloom, s.tube_edge_shadow]:
		assert_float(v).is_between(0.0, 0.1)         # each layer on its own is faint
	# the node pushes exactly that bound into the shader
	var tube := ScreenTube.new()
	add_child(tube)
	auto_free(tube)
	assert_float(float(tube.tube_material().get_shader_parameter(&"max_alpha"))).is_equal(bound)
	assert_float(float(tube.tube_material().get_shader_parameter(&"glass"))).is_equal(s.tube_glass)


func test_tube_glass_has_an_off_switch_tied_to_photosensitivity() -> void:
	var s := _surface()
	assert_bool(ScreenTube.glass_enabled(s, false)).is_true()
	assert_bool(ScreenTube.glass_enabled(s, true)).is_false()
	assert_float(ScreenTube.max_alpha(s, false)).is_equal(0.0)
	var tube := ScreenTube.new()
	add_child(tube)
	auto_free(tube)
	assert_bool(tube.glass_on()).is_true()
	SettingsService.set_value(&"photosensitivity", true)
	assert_bool(tube.glass_on()).is_false()
	assert_float(float(tube.tube_material().get_shader_parameter(&"glass"))).is_equal(0.0)
	assert_float(float(tube.tube_material().get_shader_parameter(&"max_alpha"))).is_equal(0.0)
	SettingsService.set_value(&"photosensitivity", false)
	assert_float(float(tube.tube_material().get_shader_parameter(&"max_alpha"))).is_greater(0.0)
	var off := _surface().duplicate() as CabinetSurface
	off.tube_glass = 0.0
	assert_bool(ScreenTube.glass_enabled(off, false)).is_false()


func test_tube_mask_replaces_only_a_few_corner_texels() -> void:
	var s := _surface()
	assert_float(s.tube_corner_radius).is_between(2.0, 8.0)
	var n := ScreenTube.mask_pixels(s)
	assert_int(n).is_greater(3)
	assert_int(n).is_less_equal(40)            # of 77,824 screen texels


## The glass is a separate overlay, after the screen: its shader reads nothing of the screen and has no
## part in the CRT or the register quantize.
func test_tube_is_a_separate_overlay_that_reads_nothing_of_the_screen() -> void:
	var code := (load("res://shaders/cabinet/screen_tube.gdshader") as Shader).code
	assert_bool(code.contains("SCREEN_TEXTURE")).is_false()
	assert_bool(code.contains("hint_screen_texture")).is_false()
	var tube := ScreenTube.new()
	add_child(tube)
	auto_free(tube)
	assert_object(tube.get_rect()).is_equal(CabinetBezel.hole())
	var state := (load("res://features/cabinet/cabinet_game.tscn") as PackedScene).get_state()
	for i in state.get_node_count():
		assert_bool(String(state.get_node_name(i)) == "ScreenTube").is_false()   # built by the Hud, outside the ArcadeScreen


# --- the screen lights the cabinet ----------------------------------------------------------------

func test_screen_average_only_reads_and_gives_the_mean_colour() -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	img.fill(Color(0.2, 0.4, 0.6))
	var before := img.get_data()
	var avg := ScreenLight.average(img)
	assert_bool(img.get_data() == before).override_failure_message("sampling wrote into the image").is_true()
	assert_float(avg.r).is_equal_approx(0.2, 0.01)
	assert_float(avg.g).is_equal_approx(0.4, 0.01)
	assert_float(avg.b).is_equal_approx(0.6, 0.01)
	# a region and a stride read a part of it
	img.fill_rect(Rect2i(0, 0, 8, 16), Color(1, 0, 0))
	var left := ScreenLight.average(img, Rect2i(0, 0, 8, 16), 2)
	assert_float(left.r).is_equal_approx(1.0, 0.01)
	assert_float(left.g).is_equal_approx(0.0, 0.01)
	assert_bool(ScreenLight.average(null).is_equal_approx(Color(0, 0, 0, 1))).is_true()


func test_screen_average_becomes_a_light_by_colour_and_luminance() -> void:
	var s := _surface()
	var dark := ScreenLight.to_light(Color(0.02, 0.02, 0.04), s)
	var bright := ScreenLight.to_light(Color(0.5, 0.2, 0.1), s)
	assert_float(bright.a).is_greater(dark.a)
	assert_float(bright.r).is_equal_approx(1.0, 0.001)         # the colour is stretched to full strength
	assert_float(bright.b).is_less(bright.r)
	assert_float(bright.a).is_between(0.0, 1.0)
	assert_float(ScreenLight.to_light(Color(0, 0, 0), s).a).is_equal(0.0)


func test_screen_light_never_writes_into_the_screen_and_holds_steady_with_photosensitivity() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 304)
	add_child(vp)
	auto_free(vp)
	var light := ScreenLight.new()
	light.source = vp
	add_child(light)
	auto_free(light)
	assert_int(vp.get_child_count()).is_equal(0)               # it added nothing to the screen
	assert_int(vp.size.x).is_equal(256)
	light._sample()                                             # headless: no read-back, and never a write
	assert_int(vp.get_child_count()).is_equal(0)
	SettingsService.set_value(&"photosensitivity", true)
	light._process(1.0)
	assert_bool(light.light.is_equal_approx(ScreenLight.steady(_surface()))).is_true()
	SettingsService.set_value(&"photosensitivity", false)
	light._target = Color(1, 0, 0, 1)
	light._process(0.01)
	assert_float(light.light.a).is_less(1.0)                    # eased, not snapped (the cabinet breathes)
	assert_float(light.light.r).is_greater(0.0)


func test_the_live_light_is_one_global_every_cabinet_shader_reads() -> void:
	CabinetLighting.set_screen_light(Color(0.1, 0.2, 0.3, 0.4))
	var got: Variant = RenderingServer.global_shader_parameter_get(CabinetLighting.GLOBAL)
	assert_bool(got != null or DisplayServer.get_name() == "headless").is_true()   # the dummy renderer keeps no globals
	if got is Color:
		assert_bool((got as Color).is_equal_approx(Color(0.1, 0.2, 0.3, 0.4))).is_true()
	for path in ["coin_door", "bezel_print", "bezel_glass", "bezel_marquee", "bezel_frame", "screen_tube", "bezel_sticker", "cabinet_trim", "cabinet_room"]:
		var code := FileAccess.get_file_as_string("res://shaders/cabinet/%s.gdshader" % path)
		assert_bool(code.contains("cabinet_material.gdshaderinc")).override_failure_message(path).is_true()
	assert_bool(FileAccess.get_file_as_string("res://shaders/cabinet/cabinet_material.gdshaderinc").contains("global uniform vec4 cab_screen_light")).is_true()


# --- the cabinet's edge never reaches the opening ---------------------------------------------------

func test_trim_room_marquee_and_frame_never_cover_the_opening_at_the_five_sizes() -> void:
	var spec := load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	var s := _surface()
	for win in SIZES:
		var area := ScreenFit.bezel_rect(win, spec.grid)
		for r in CabinetTrim.strip_rects(area, s.tmold_width):
			assert_bool(r.intersects(SCREEN)).override_failure_message("T-molding %s at %s" % [r, win]).is_false()
			assert_bool(r.size.y >= area.size.y - 0.01).is_true()          # runs to the window's top and bottom
		for r in CabinetRoom.room_rects(area, s.tmold_width):
			assert_bool(r.intersects(SCREEN)).override_failure_message("room %s at %s" % [r, win]).is_false()
		for c in CabinetTrim.bolt_centres():
			assert_bool(Rect2(c - Vector2(5, 5), Vector2(10, 10)).intersects(SCREEN)).override_failure_message("bolt %s" % c).is_false()
		assert_bool(CabinetBezel.marquee().intersects(SCREEN)).is_false()
		# glass rects (existing) plus the sheet: the room starts exactly where the sheet's molding ends
		for r in BezelField.glass_rects(area, 0.0):
			assert_bool(r.intersects(SCREEN)).is_false()
		var sx := CabinetBezel.sheet_x()
		var rooms := CabinetRoom.room_rects(area, s.tmold_width)
		assert_float(rooms[0].end.x).is_equal_approx(sx.x - s.tmold_width, 0.001)
		assert_float(rooms[1].position.x).is_equal_approx(sx.y + s.tmold_width, 0.001)
	assert_bool(BezelFrame.rect().encloses(SCREEN)).is_true()    # the shader paints nothing inside the opening
	var wide := ScreenFit.bezel_rect(Vector2i(3440, 1440), spec.grid)
	var rooms_wide := CabinetRoom.room_rects(wide, s.tmold_width)
	assert_float(rooms_wide[0].size.x).is_greater(100.0)         # ultrawide: real dark room, not stretched print
	assert_float(rooms_wide[1].size.x).is_greater(100.0)


func test_trim_bolts_are_seeded_and_not_all_alike() -> void:
	var trim := CabinetTrim.new()
	add_child(trim)
	auto_free(trim)
	assert_int(trim.strips().size()).is_equal(2)
	assert_int(trim.bolts().size()).is_equal(CabinetTrim.BOLT_Y.size() * 2)
	var angles := {}
	for b in trim.bolts():
		angles[snappedf(float((b.material as ShaderMaterial).get_shader_parameter(&"slot_angle")), 0.001)] = true
	assert_int(angles.size()).is_greater(2)


# --- the marquee ----------------------------------------------------------------------------------

func test_marquee_is_a_thin_sign_in_the_top_28_units_with_vector_lettering() -> void:
	var m := CabinetBezel.marquee()
	assert_float(m.position.y).is_greater_equal(0.0)
	assert_float(m.end.y).is_less_equal(28.0)
	var sign := BezelMarquee.new()
	add_child(sign)
	auto_free(sign)
	assert_object(sign.get_rect()).is_equal(m)
	var s := _surface()
	assert_float(s.marquee_lettering).is_between(14.0, 22.0)        # about 20 units of lettering
	var painted := sign.lettering_size()
	assert_float(painted.y).is_less_equal(m.size.y)
	assert_float(painted.x).is_less_equal(m.size.x - 8.0)
	assert_str(BezelMarquee.KEY).is_equal("GAME_TITLE")
	assert_str(tr(BezelMarquee.KEY)).is_equal("DARKSTAR")


# --- the print ------------------------------------------------------------------------------------

func test_halftone_pitch_is_about_one_to_one_and_a_half_units_and_plates_are_screened() -> void:
	var s := _surface()
	assert_float(s.print_halftone_cell).is_between(1.0, 1.5)
	assert_float(s.print_dot_gain).is_between(0.05, 0.4)
	var code := (load("res://shaders/cabinet/bezel_print.gdshader") as Shader).code
	assert_bool(code.contains("plate_tone")).is_true()
	assert_bool(code.contains("plate_angle")).is_true()
	assert_bool(code.contains("flake_color")).is_true()          # sharp flakes show the black backing
	var m := CabinetLighting.print_material(s, Vector2.ZERO, true)
	assert_float(float(m.get_shader_parameter(&"halftone_cell"))).is_equal(s.print_halftone_cell)
	assert_float(float(m.get_shader_parameter(&"dot_gain"))).is_equal(s.print_dot_gain)


func test_tone_ramps_run_linear_and_radial() -> void:
	var p := BezelPiece.new()
	p.tone_mode = BezelPiece.TONE_LINEAR
	p.tone_a = Vector2(0, 0)
	p.tone_b = Vector2(10, 0)
	p.tone0 = 1.0
	p.tone1 = 0.0
	assert_float(p.tone_at(Vector2(0, 5))).is_equal_approx(1.0, 0.001)
	assert_float(p.tone_at(Vector2(5, 5))).is_equal_approx(0.5, 0.001)
	assert_float(p.tone_at(Vector2(20, 0))).is_equal_approx(0.0, 0.001)
	p.tone_mode = BezelPiece.TONE_RADIAL
	p.tone_a = Vector2(10, 10)
	p.tone_b = Vector2(2, 12)
	p.tone0 = 0.0
	p.tone1 = 1.0
	assert_float(p.tone_at(Vector2(10, 10))).is_equal_approx(0.0, 0.001)
	assert_float(p.tone_at(Vector2(10, 17))).is_equal_approx(0.5, 0.001)
	assert_float(p.tone_at(Vector2(30, 10))).is_equal_approx(1.0, 0.001)


## The door stays black: its warm key is neutralised for the paint's diffuse light (warmth only in the highlights).
func test_door_paint_is_black_and_lit_neutrally() -> void:
	var s := _surface()
	assert_bool(s.paint_color.get_luminance() < 0.08).is_true()
	var code := (load("res://shaders/cabinet/coin_door.gdshader") as Shader).code
	assert_bool(code.contains("keyd")).is_true()
	assert_bool(code.contains("0.78, 0.66, 0.42")).override_failure_message("the brown nicotine tint is back").is_false()
