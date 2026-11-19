extends GdUnitTestSuite
## Q-T127 option B long flights: AetherFarLayer.set_field resets the anchors; a continuous camera far
## from the origin never puts a raw world offset into a uniform (fog bands get their parallax offset
## wrapped into ±period / 2, the wrap hidden by wrap_mix); the landmarks (Presence, leviathan, set
## pieces, sky + smudge, entity layer, sphere drift) stay leashed: never past the cap, never more than
## max_step_px in one frame, and they ease back once the flight stops.

const FAR_LAYER := "res://features/aether/aether_far_layer.tscn"
const PM01 := "res://data/aether/pm01_pale_marches_t1.tres"
const DT := 1.0 / 60.0
## Test-local flight (backdrop px/s): deliberately faster than any cruise; not a game number.
const FLIGHT_V := Vector2(520.0, -190.0)
const FLIGHT_S := 360.0
const RETURN_S := 150.0
const CHANNELS: Array[StringName] = [&"sky", &"presence", &"set_pieces_back", &"set_pieces", &"leviathan", &"entity", &"drift"]


func _far() -> AetherFarLayer:
	var f := (load(FAR_LAYER) as PackedScene).instantiate() as AetherFarLayer
	f.look = load(PM01) as AetherLook
	add_child(f)
	f.set_process(false)
	f.backdrop.set_process(false)
	return auto_free(f)


func _bands(b: AetherBackdrop) -> Array[AetherFogBand]:
	var out: Array[AetherFogBand] = []
	for n in ["FarFog", "MidFogA", "MidFogB", "NearFog", "VeilFog"]:
		out.append(b.find_child(n, true, false) as AetherFogBand)
	return out


func _finite(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)


func test_set_field_resets_anchors() -> void:
	var f := _far()
	var b := f.backdrop
	await get_tree().process_frame
	for i in 240:
		f.set_camera(AetherFarLayer.HOME + FLIGHT_V * DT * float(i + 1), 1.0)
		b.step_travel(DT)
	assert_float(b.travel().length()).is_greater(100.0)
	assert_float(b.landmark_offset(&"leviathan").length()).is_greater(1.0)
	f.set_field(Vector2(8192.0, 8192.0))
	assert_vector(f.field_size).is_equal(Vector2(8192.0, 8192.0))
	assert_vector(b.travel()).is_equal(Vector2.ZERO)
	for ch in CHANNELS:
		assert_vector(b.landmark_offset(ch)).override_failure_message("%s not reset" % ch).is_equal(Vector2.ZERO)
	# the next set_camera is the new origin: every layer as if the camera were home
	var o := Vector2(98765.5, -43210.25)
	f.set_camera(o, 1.0)
	assert_vector(f.origin).is_equal(o)
	assert_vector(b.travel()).is_equal(Vector2.ZERO)
	b.step_travel(DT)
	b.refresh()
	var layers := b.landmark_layers()
	for ch: StringName in layers:
		assert_vector((layers[ch] as Parallax2D).scroll_offset).is_equal(Vector2.ZERO)
	for band in _bands(b):
		assert_vector(band.get_param(&"scroll_px") as Vector2).is_equal(Vector2.ZERO)
		assert_float(float(band.get_param(&"wrap_mix"))).is_equal(0.0)
	# the Camera2D never left home; later frames move relative to the new origin
	assert_vector((f.find_child("Camera", true, false) as Camera2D).position).is_equal(AetherFarLayer.HOME)
	f.set_camera(o + Vector2(10.0, 0.0), 1.0)
	assert_vector(b.travel()).is_equal(Vector2(10.0, 0.0))


func test_six_minute_flight_keeps_landmarks_leashed_then_they_return() -> void:
	var f := _far()
	var b := f.backdrop
	await get_tree().process_frame
	f.set_field(Vector2(16384.0, 16384.0))
	var start := Vector2(1234.0, 567.0)
	f.set_camera(start, 1.0)
	var cap := b.leash.cap_px
	var step_max := b.leash.max_step_px
	var half := b.leash.band_period_px * 0.5
	var prev := {}
	var worst_cap := 0.0
	var worst_step := 0.0
	var worst_band := 0.0
	var n := int(FLIGHT_S / DT)
	for i in n:
		f.set_camera(start + FLIGHT_V * (float(i + 1) * DT), 1.0)
		b.step_travel(DT)
		for ch in CHANNELS:
			var d := b.landmark_offset(ch)
			var p: Vector2 = prev.get(ch, Vector2.ZERO)
			worst_cap = maxf(worst_cap, d.length())
			worst_step = maxf(worst_step, (d - p).length())
			prev[ch] = d
		if i % 30 == 0:
			for k in 5:
				var o := b.band_offset(k)
				assert_bool(_finite(o)).is_true()
				worst_band = maxf(worst_band, maxf(absf(o.x), absf(o.y)))
	# the camera really went far (beyond 1e5 px), yet nothing left its leash or jumped
	assert_float(b.travel().length()).is_greater(150000.0)
	assert_float(worst_cap).override_failure_message("landmark past the cap: %.3f" % worst_cap).is_less_equal(cap + 0.001)
	assert_float(worst_step).override_failure_message("landmark jump: %.3f px/frame" % worst_step).is_less_equal(step_max + 0.001)
	assert_float(worst_band).is_less_equal(half)
	assert_float(worst_band).is_less(b.leash.band_period_px)
	# the cap engaged: the landmarks drifted off toward it, not further
	assert_float(b.landmark_offset(&"leviathan").length()).is_greater(cap * 0.9)
	assert_float(b.landmark_offset(&"sky").length()).is_greater(cap * 0.9)
	# the flight stops: every landmark eases back, monotonically and without a jump
	var at_stop := {}
	for ch in CHANNELS:
		at_stop[ch] = b.landmark_offset(ch).length()
	var still := f.camera_centre
	for i in int(RETURN_S / DT):
		f.set_camera(still, 1.0)
		b.step_travel(DT)
		for ch in CHANNELS:
			var d := b.landmark_offset(ch)
			var p: Vector2 = prev[ch]
			assert_float((d - p).length()).is_less_equal(step_max + 0.001)
			assert_float(d.length()).override_failure_message("%s moved away while returning" % ch).is_less_equal(p.length() + 0.001)
			prev[ch] = d
	for ch in CHANNELS:
		var back := b.landmark_offset(ch).length()
		assert_float(back).override_failure_message("%s did not ease back: %.2f" % [ch, back]).is_less(cap * 0.1)
		assert_float(back).is_less(float(at_stop[ch]))


func test_band_wrap_is_hidden_and_bounded() -> void:
	var leash := load("res://data/aether/leash/far_leash.tres") as AetherFarLeash
	var period := leash.band_period_px
	var window := leash.wrap_window_px
	for factor: float in [0.04, 0.35, 0.7, 1.1]:
		var prev := AetherFarTravel.band_offset(Vector2.ZERO, factor, period)
		var prev_mix := AetherFarTravel.wrap_mix(prev, period, window)
		var x := 0.0
		var jumps := 0
		# sweep the camera through one full band period (and a bit) along a diagonal
		var stride := 7.0 / factor
		while x * factor < period * 1.2:
			x += stride
			var d := Vector2(x, -0.5 * x)
			var o := AetherFarTravel.band_offset(d, factor, period)
			var m := AetherFarTravel.wrap_mix(o, period, window)
			assert_float(maxf(absf(o.x), absf(o.y))).is_less_equal(period * 0.5)
			assert_float(m).is_between(0.0, 1.0)
			if (o - prev).length() > 50.0:
				# a wrap: hidden on both sides of the jump
				jumps += 1
				assert_float(prev_mix).override_failure_message("wrap visible (before) f=%.2f" % factor).is_greater(0.99)
				assert_float(m).override_failure_message("wrap visible (after) f=%.2f" % factor).is_greater(0.99)
				# the second sample is half a period away from its own wrap there
				var ob := AetherFarTravel.band_offset(d, factor, period, period * 0.5)
				if absf(o.x - prev.x) > 50.0:
					assert_float(absf(ob.x)).is_less(period * 0.25)
				if absf(o.y - prev.y) > 50.0:
					assert_float(absf(ob.y)).is_less(period * 0.25)
			prev = o
			prev_mix = m
		assert_int(jumps).is_greater(0)
	# away from a wrap the band is untouched
	assert_float(AetherFarTravel.wrap_mix(Vector2(100.0, -300.0), period, window)).is_equal(0.0)


func test_camera_at_1_2e5_px_is_precise_and_bounded() -> void:
	var f := _far()
	var b := f.backdrop
	await get_tree().process_frame
	var period := b.leash.band_period_px
	var small := Vector2(37.25, -12.5)
	var far_centre := AetherFarLayer.HOME + Vector2(120000.0, -120000.0) + small
	f.set_camera(far_centre, 1.0)
	b.step_travel(DT)
	b.refresh()
	var travel := b.travel()
	assert_float(travel.x).is_equal_approx(120037.25, 0.01)
	var bands := _bands(b)
	var layers: Array[Parallax2D] = []
	for n in ["FarLayer", "MidLayerA", "MidLayerB", "NearLayer", "VeilLayer"]:
		layers.append(b.find_child(n, true, false) as Parallax2D)
	for k in 5:
		var factor := layers[k].scroll_scale.x
		for key: StringName in [&"scroll_px", &"scroll_px_b"]:
			var u := bands[k].get_param(key) as Vector2
			assert_bool(_finite(u)).is_true()
			assert_float(maxf(absf(u.x), absf(u.y))).override_failure_message("%s band %d = %s" % [key, k, u]).is_less_equal(period * 0.5)
		# exactly the float64 wrap of the travel (precision held), and it is the band_offset API's value
		var u := bands[k].get_param(&"scroll_px") as Vector2
		var ex := fposmod(float(travel.x) * factor + period * 0.5, period) - period * 0.5
		assert_float(u.x).is_equal_approx(ex, 0.01)
		assert_vector(u).is_equal_approx(b.band_offset(k), Vector2(0.001, 0.001))
		assert_float(float(bands[k].get_param(&"wrap_mix"))).is_between(0.0, 1.0)
		# same picture structure as a small camera, modulo the wrap: a whole number of band periods of
		# camera travel later the band gets the same offset (to well under a pixel)
		var m := roundf(120000.0 * factor / period)
		if m >= 1.0:
			var big := small + Vector2(m, -m) * (period / factor)
			var a := AetherFarTravel.band_offset(small, factor, period)
			var c := AetherFarTravel.band_offset(big, factor, period)
			assert_vector(c).is_equal_approx(a, Vector2(0.05, 0.05))
	# landmarks and the sphere's drift stay small and finite (a jump to 1.2e5 slides, never pops)
	var lay := b.landmark_layers()
	for ch: StringName in lay:
		var s := (lay[ch] as Parallax2D).scroll_offset
		assert_bool(_finite(s)).is_true()
		assert_float(s.length()).is_less_equal(b.leash.max_step_px + 0.001)
	var sphere := b.find_child("Sphere", true, false) as AetherShaderRect
	var cam_off := sphere.get_param(&"camera_offset") as Vector2
	assert_bool(_finite(cam_off)).is_true()
	# the Camera2D's own (home) offset plus at most one leash step: nothing near the 1e5 travel
	var home_off := AetherFarLayer.HOME - b.get_viewport_rect().size * 0.5
	assert_float((cam_off - home_off).length()).is_less_equal(b.leash.max_step_px + 0.001)
	# near life gets a velocity, never a position
	b.step_travel(DT)
	f.set_camera(far_centre + Vector2(6.0, 0.0), 1.0)
	b.step_travel(DT)
	b.refresh()
	var motes := b.find_child("Motes", true, false) as AetherLife
	var v := motes.motion_mat.get_shader_parameter(&"scroll_velocity") as Vector2
	var s_life := (b.find_child("LifeLayer", true, false) as Parallax2D).scroll_scale.x
	assert_float(v.x).is_equal_approx(6.0 * s_life / DT, 0.5)
