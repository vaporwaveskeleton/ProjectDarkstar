extends GdUnitTestSuite
## P4 (TECH-001 §1.3): the arcade screen is 256×304 and every screen-side script derives its sizes
## from CabinetScreenSpec. No 640/360 (or the old 320/180/480/240 view) literal may live in them;
## messages wrap to the screen; the attract screen is confined to the hole.

const SPEC := "res://data/cabinet/cabinet_screen.tres"
const ATTRACT := "res://scenes/attract/attract_mode.tscn"

## The screen-side scripts: everything drawn into the arcade SubViewport or the attract hole.
const SCREEN_SIDE := [
	"res://features/cabinet/sim/arcade_world.gd", "res://features/cabinet/sim/starfield.gd",
	"res://features/cabinet/sim/acolyte_squad.gd", "res://features/cabinet/sim/shot_layer.gd",
	"res://features/cabinet/sim/geode_field.gd", "res://features/cabinet/sim/glass_field.gd",
	"res://features/cabinet/sim/grub_flock.gd", "res://features/cabinet/sim/fx_layer.gd",
	"res://features/cabinet/sim/sepulchre_ritual.gd", "res://features/cabinet/sim/vigil_ship.gd",
	"res://features/cabinet/cabinet_screen_hud.gd", "res://features/cabinet/maw_view.gd",
	"res://features/cabinet/cabinet_messages.gd", "res://features/cabinet/arcade_screen.gd",
	"res://features/cabinet/hole_fit.gd", "res://scenes/attract/attract_backdrop.gd",
	"res://scenes/attract/power_on_test.gd", "res://scenes/attract/attract_pages.gd",
	"res://scenes/attract/attract_logo.gd", "res://scenes/attract/attract_crt.gd",
	"res://shaders/crt.gdshader", "res://shaders/crt_attract.gdshader", "res://shaders/crt_common.gdshaderinc",
]


func test_no_screen_side_script_hard_codes_the_old_screen_size() -> void:
	var re := RegEx.create_from_string("(?<![A-Za-z0-9_.])(640|360|320|480)(?![A-Za-z0-9_])")
	for path: String in SCREEN_SIDE:
		var src := FileAccess.get_file_as_string(path)
		assert_str(src).override_failure_message("cannot read %s" % path).is_not_empty()
		for line in src.split("\n"):
			if line.strip_edges().begins_with("#") or line.strip_edges().begins_with("//"):
				continue
			var code := line.split("##")[0].split("//")[0]
			assert_bool(re.search(code) == null).override_failure_message("%s hard-codes a screen size: %s" % [path, line.strip_edges()]).is_true()


func _fits(text: String, scale: int, limit: float) -> bool:
	for line in PixelText.wrap(text, scale, limit):
		if float(PixelText.width(line, scale)) > limit:
			return false
	return true


## Every message the cabinet can show, at the scale it is drawn at, fits the 256 px screen once wrapped
## at spaces (a single word never exceeds it).
func test_every_cabinet_message_fits_the_screen_at_its_scale() -> void:
	var limit := float((load(SPEC) as CabinetScreenSpec).grid.x) - 2.0 * CabinetMessages.MARGIN
	var items := [
		["CAB_STAGE_A0_1", 3], ["CAB_STAGE_A0_3", 3], ["CAB_STAGE_A0_1_SUB", 1], ["CAB_STAGE_A0_3_SUB", 1],
		["CAB_READY", 2], ["CAB_GAME_OVER", 2], ["CAB_VIGIL_COMPLETE", 2], ["CAB_ENTITY_DOWN", 2],
		["CAB_EXTRA_VIGIL", 1], ["CAB_CAPTION_WHISPER", 1], ["CAB_CREDIT", 1],
		["ENTITY_IT_WAKES", 3], ["REVEAL_PRETENCE", 3], ["REVEAL_ONE_SKY_LESS", 3], ["CAB_MAKER", 1],
	]
	for i in 7:
		items.append(["CAB_CREDITS_%d" % (i + 1), 2])
	for it in items:
		var s := tr(it[0])
		assert_str(s).override_failure_message("%s has no translation" % it[0]).is_not_equal(it[0])
		assert_bool(_fits(s, it[1], limit)).override_failure_message("%s at x%d does not fit %s px" % [it[0], it[1], limit]).is_true()


func test_wrap_breaks_at_spaces_and_keeps_every_word() -> void:
	assert_array(PixelText.wrap("THE LAST NORMAL DAY", 3, 248.0)).is_equal(PackedStringArray(["THE LAST", "NORMAL DAY"]))
	assert_array(PixelText.wrap("HELLO", 1, 10.0)).is_equal(PackedStringArray(["HELLO"]))
	assert_array(PixelText.wrap("", 1, 100.0)).is_equal(PackedStringArray([""]))


func test_messages_sit_in_the_play_view_and_clip_at_the_strip() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	var m := CabinetMessages.new()
	add_child(m)
	auto_free(m)
	assert_vector(m.position).is_equal(spec.play_rect().position)
	assert_vector(m.size).is_equal(spec.play_rect().size)
	assert_bool(m.clip_contents).is_true()


func test_logo_takes_the_largest_scale_that_fits() -> void:
	assert_int(AttractLogo.title_scale("DARKSTAR", 232.0)).is_equal(4)
	assert_int(AttractLogo.title_scale("DARKSTAR", 400.0)).is_equal(6)


func _attract() -> Node:
	var scene := (load(ATTRACT) as PackedScene).instantiate()
	scene.set("demo_enabled", false)
	add_child(scene)
	return scene


## The attract screen is the hole, not the window: backdrop, strip, menu, power-on and CRT are
## children of the clipped hole; the bezel and the coin door are outside it.
func test_attract_screen_is_confined_to_the_hole() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	var scene := _attract()
	await get_tree().process_frame
	var hole := scene.get_node("%Hole") as Control
	assert_object(Rect2(hole.position, hole.size)).is_equal(ScreenFit.hole_rect(spec.grid))
	assert_bool(hole.clip_contents).is_true()
	for n in ["Backdrop", "%StripHud", "%Play", "%PowerOn", "Crt"]:
		var c := (scene.find_child(n.trim_prefix("%"), true, false)) as Control
		assert_bool(hole.is_ancestor_of(c)).override_failure_message("%s should be inside the hole" % n).is_true()
		assert_bool(Rect2(Vector2.ZERO, hole.size).encloses(Rect2(c.position, c.size)) or n == "%Play") \
			.override_failure_message("%s leaves the hole" % n).is_true()
	for n in ["Frame", "CoinSlot"]:
		assert_bool(hole.is_ancestor_of(scene.find_child(n, true, false))).override_failure_message("%s must be outside the hole" % n).is_false()
	var play := scene.get_node("%Play") as Control
	assert_object(Rect2(play.position, play.size)).is_equal(spec.play_rect())
	var crt := scene.find_child("Crt", true, false) as ColorRect
	assert_float(float((crt.material as ShaderMaterial).get_shader_parameter(&"rows"))).is_equal(float(spec.grid.y))
	var coin := scene.find_child("CoinSlot", true, false) as Control
	assert_bool(coin.get_rect().intersects(Rect2(hole.position, hole.size))).is_false()
	scene.queue_free()


func test_attract_menu_fits_the_play_view_at_100_percent_text() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	var scene := _attract()
	await get_tree().process_frame
	await get_tree().process_frame
	var play := scene.get_node("%Play") as Control
	var bounds := Rect2(Vector2.ZERO, play.size)
	for n in ["Logo", "Pages", "NewVigil", "Settings", "Quit"]:
		var c := scene.find_child(n, true, false) as Control
		var r := Rect2(c.global_position - play.global_position, c.size) if play.get_global_transform().get_scale().is_equal_approx(Vector2.ONE) \
			else play.get_global_transform().affine_inverse() * c.get_global_rect()
		assert_bool(bounds.encloses(r)).override_failure_message("%s %s outside the play view %s" % [n, r, bounds]).is_true()
	assert_float(float(spec.grid.x)).is_equal(256.0)
	scene.queue_free()
