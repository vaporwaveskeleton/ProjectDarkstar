extends GdUnitTestSuite
## The coin door's physical face (owner direction 2026-11-18): the CabinetSurface resource, the
## CoinDoorFace shader node, and the slit staying inside the drawn slot. Headless cannot render, so
## these check wiring, not pixels.

const SURFACE := "res://data/cabinet/cabinet_surface.tres"
const KEYS := [
	"paint_color", "zinc_color", "lip_color", "bare_steel_color", "brass_color", "lens_color", "sticker_paper_color",
	"wear", "grime", "smudge", "dust", "finger_halo", "thumb_wear", "micro_texture", "lamp_idle", "lamp_spill", "lamp_spill_radius",
	"noise_seed", "light_direction", "warm_color", "fill_color", "warm_gain", "warm_radius", "fill_gain", "top_gain", "bottom_gain",
	"contact_shadow", "contact_blur",
	"print_misregister", "print_fade", "print_mottle", "print_halftone", "print_halftone_cell", "print_scuff", "print_flake", "backer_color",
	"glass_reflection", "glass_edge_tint", "glass_edge_color", "glass_dust", "glass_smudge", "glass_scratch",
	"sticker_fade", "sticker_curl", "vent_dust",
	"spill_gain", "spill_radius", "spill_boost", "spill_curve", "spill_interval", "spill_smooth", "spill_steady_color", "spill_steady_amount", "recess_shadow",
	"recess_width", "tube_corner_radius", "tube_glass", "tube_reflection", "tube_dust", "tube_bloom", "tube_edge_shadow", "tube_max_shift",
	"tmold_width", "bolt_radius", "marquee_lettering", "marquee_stroke", "marquee_tracking", "marquee_unevenness", "print_dot_gain",
	"price_cap", "price_stroke", "price_tracking", "glass_band", "glass_screen_reflection",
	"glass_band_lift", "glass_smear_haze", "glass_smear_idle", "print_uv_fade", "print_uv_edge", "print_grime", "marquee_hot", "marquee_shadow_depth", "marquee_spill", "room_glow",
	"panel_lip", "panel_lip_width", "panel_front_shadow", "panel_front_width", "panel_contact", "panel_palm_polish", "panel_grain", "panel_color", "start_decal_rub", "decal_rub",
	"caption_cap", "caption_stroke", "caption_tracking", "caption_pad", "tape_sheen", "tape_misregister", "tape_lift", "tape_dirt", "tape_crease", "tape_yellow", "tape_black", "rocker_lamp_color",
	"backdrop_exposure", "backdrop_blur", "backdrop_grain", "backdrop_grain_fps", "backdrop_desaturate", "backdrop_cabinet_shadow", "backdrop_haze",
	"backdrop_wall_color", "backdrop_carpet_color", "backdrop_tungsten_color", "backdrop_neon",
]


func test_surface_loads_with_namespace_and_every_key() -> void:
	var s := load(SURFACE) as CabinetSurface
	assert_object(s).is_not_null()
	assert_str(s.ds_namespace).is_equal("ds_cabinet.surface")
	assert_str(s.source_section).contains("✱")
	var props := s.tunable_properties()
	for k in KEYS:
		assert_bool(props.has(k)).is_true()
	assert_int(props.size()).is_equal(KEYS.size())
	var reg := TunableRegistry.new().scan()
	assert_array(Array(reg.errors)).is_empty()
	for k in KEYS:
		assert_bool(reg.has_key("ds_cabinet.surface.%s" % k)).is_true()


func test_surface_values_are_sane() -> void:
	var s := load(SURFACE) as CabinetSurface
	for v in [s.wear, s.grime, s.smudge, s.lamp_idle, s.dust, s.print_fade, s.contact_shadow]:
		assert_float(v).is_between(0.0, 1.0)
	assert_float(s.light_direction.x).is_less(0.0)   # from the left
	assert_float(s.light_direction.y).is_less(0.0)   # from above (y down)
	assert_float(s.light_direction.z).is_greater(0.0)


func test_face_covers_exactly_the_coin_plate_and_pushes_glow() -> void:
	var host := auto_free(Control.new()) as Control
	add_child(host)
	var face := CoinDoorFace.new()
	host.add_child(face)
	var plate := CabinetBezel.coin_plate()
	face.fit_to(plate)
	assert_object(face.get_rect()).is_equal(plate)
	assert_bool(face.mouse_filter == Control.MOUSE_FILTER_IGNORE).is_true()
	assert_bool(face.show_behind_parent).is_true()
	var mat := face.door_material()
	assert_object(mat).is_not_null()
	assert_object(mat.get_shader_parameter(&"plate_size")).is_equal(plate.size)
	face.glow = 0.75
	assert_float(float(mat.get_shader_parameter(&"glow"))).is_equal(0.75)
	face.glow = 3.0
	assert_float(face.glow).is_equal(1.0)
	assert_object(mat.get_shader_parameter(&"paint_color")).is_equal((load(SURFACE) as CabinetSurface).paint_color)


func test_slit_is_inside_the_plate_and_is_the_drawn_slot() -> void:
	var plate := Rect2(Vector2.ZERO, CabinetBezel.coin_plate().size)
	var slit := CabinetBezel.slit(plate)
	assert_bool(plate.encloses(slit)).is_true()
	var slot := Rect2(CabinetBezel.SLOT_C - CabinetBezel.SLOT_HALF, CabinetBezel.SLOT_HALF * 2.0)
	assert_object(slit).is_equal(slot)
	# the lit plate sits below the slot and inside the plate
	var btn := CabinetBezel.price_button(plate)
	assert_bool(plate.encloses(btn)).is_true()
	assert_float(btn.position.y).is_greater(slit.end.y)


func test_coin_slot_owns_a_door_face_that_follows_the_glow() -> void:
	var slot := auto_free(CoinSlot.new()) as CoinSlot
	slot.tuning = CabinetBootTuning.new()
	add_child(slot)
	var face := slot.door_face()
	assert_object(face).is_not_null()
	assert_object(face.get_rect()).is_equal(Rect2(Vector2.ZERO, CabinetBezel.coin_plate().size))
	slot.set_peeled()
	slot.insert()
	slot.phase = CoinSlot.Phase.CREDITED
	slot.queue_redraw()
	await await_idle_frame()
	assert_float(face.glow).is_equal(1.0)


func test_price_text_sits_fully_on_the_lit_plate_inside_the_inner_panel() -> void:
	var plate := Rect2(Vector2.ZERO, CabinetBezel.coin_plate().size)
	var lit := CabinetBezel.price_button(plate)
	var s := load(SURFACE) as CabinetSurface
	var text := TranslationServer.translate("CAB_COIN_PRICE")
	var sz := BezelText.ink_size(text, s.price_cap, s.price_stroke, s.price_tracking)
	assert_bool(CabinetBezel.fits_price()).is_true()
	assert_float(sz.x).is_less_equal(lit.size.x)
	assert_float(sz.y).is_less_equal(lit.size.y)
	assert_float(lit.get_center().x).is_equal_approx(plate.size.x * 0.5, 0.001)
	# a sensible plate: the lettering (VectorText, smaller cap height) has a margin, and the plate is not huge
	assert_float(lit.size.x - sz.x).is_greater(2.0)
	assert_float(lit.size.y).is_less(14.0)
	# the plate sits inside the door's inner panel (door 55.2 wide, rim 3.2)
	assert_float(lit.position.x).is_greater_equal(0.4 + 3.2)
	assert_float(lit.end.x).is_less_equal(plate.size.x - 0.4 - 3.2)
	assert_bool(plate.encloses(lit)).is_true()


func test_the_lit_plate_is_the_one_reject_and_price_plate_below_the_slot() -> void:
	var plate := Rect2(Vector2.ZERO, CabinetBezel.coin_plate().size)
	var lit := CabinetBezel.price_button(plate)
	assert_object(CabinetBezel.button_center()).is_equal(lit.get_center())
	assert_object(CabinetBezel.button_half()).is_equal(lit.size * 0.5)
	assert_float(lit.position.y).is_greater(CabinetBezel.slit(plate).end.y)
	# it clears the coin-return pocket (centre y 67, half 5) that sits below it
	assert_float(lit.end.y).is_less(62.0)


func test_face_carries_a_contact_shadow_behind_it_that_follows_the_light() -> void:
	var host := auto_free(Control.new()) as Control
	add_child(host)
	var face := CoinDoorFace.new()
	host.add_child(face)
	face.fit_to(CabinetBezel.coin_plate())
	var sh := face.contact_shadow()
	assert_object(sh).is_not_null()
	assert_bool(sh.show_behind_parent).is_true()
	assert_bool(sh.get_rect().encloses(Rect2(Vector2.ZERO, face.size))).is_true()
	var mat := sh.material as ShaderMaterial
	assert_object(mat.get_shader_parameter(&"cab_hole")).is_not_null()
	assert_float(float(mat.get_shader_parameter(&"strength"))).is_equal((load(SURFACE) as CabinetSurface).contact_shadow)


func test_lighting_is_pushed_from_the_hole_and_the_surface() -> void:
	var s := load(SURFACE) as CabinetSurface
	var m := ShaderMaterial.new()
	CabinetLighting.apply(m, s)
	var h := CabinetBezel.hole()
	assert_object(m.get_shader_parameter(&"cab_hole")).is_equal(Vector4(h.position.x, h.position.y, h.size.x, h.size.y))
	assert_float(float(m.get_shader_parameter(&"cab_warm_gain"))).is_equal(s.warm_gain)
	assert_float(s.bottom_gain).is_less(s.top_gain)    # the cabinet falls into shadow toward the bottom
