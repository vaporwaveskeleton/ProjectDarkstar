extends GdUnitTestSuite
## The coin door's physical face (owner direction 2026-11-18): the CabinetSurface resource, the
## CoinDoorFace shader node, and the slit staying inside the drawn slot. Headless cannot render, so
## these check wiring, not pixels.

const SURFACE := "res://data/cabinet/cabinet_surface.tres"
const KEYS := [
	"label_paper_color", "paint_color", "chrome_color", "bare_steel_color", "brass_color", "lens_color", "rust_color",
	"wear", "grime", "smudge", "lamp_idle", "noise_seed", "light_direction",
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
	for v in [s.wear, s.grime, s.smudge, s.lamp_idle]:
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
	# the price button sits below the slot and inside the plate
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


func test_price_text_sits_fully_on_the_label_inside_the_inner_panel() -> void:
	var plate := Rect2(Vector2.ZERO, CabinetBezel.coin_plate().size)
	var label := CabinetBezel.price_label(plate)
	var text := TranslationServer.translate("CAB_COIN_PRICE")
	var w := float(PixelText.width(text, 1))
	assert_bool(CabinetBezel.fits_price()).is_true()
	var x := label.get_center().x - w * 0.5
	assert_float(x).is_greater_equal(label.position.x)
	assert_float(x + w).is_less_equal(label.end.x)
	assert_float(x - floorf(x)).is_equal(0.0)          # starts on a whole unit
	assert_float(label.size.y).is_greater_equal(float(PixelText.H))
	# the strip sits inside the door's inner panel (door 55.2 wide, rim 3.2)
	assert_float(label.position.x).is_greater_equal(0.4 + 3.2)
	assert_float(label.end.x).is_less_equal(plate.size.x - 0.4 - 3.2)
	assert_bool(plate.encloses(label)).is_true()


func test_the_lit_button_is_small_unlettered_and_clear_of_the_label() -> void:
	var plate := Rect2(Vector2.ZERO, CabinetBezel.coin_plate().size)
	var btn := CabinetBezel.price_button(plate)
	var label := CabinetBezel.price_label(plate)
	assert_float(btn.size.x).is_less_equal(16.0)
	assert_float(btn.size.y).is_less_equal(10.0)
	assert_bool(plate.encloses(btn)).is_true()
	assert_bool(btn.intersects(label)).is_false()
	assert_float(btn.position.y).is_greater(CabinetBezel.slit(plate).end.y)
	assert_object(CabinetBezel.button_center()).is_equal(btn.get_center())
