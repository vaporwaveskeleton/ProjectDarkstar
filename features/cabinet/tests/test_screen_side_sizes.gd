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
	"res://scenes/attract/attract_logo.gd", "res://features/cabinet/arcade_button.gd", "res://features/cabinet/control_panel.gd",
	"res://shaders/crt.gdshader", "res://shaders/crt_common.gdshaderinc",
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
		["CAB_STAGE_A0_1", 3], ["CAB_STAGE_A0_2", 3], ["CAB_STAGE_A0_3", 3], ["CAB_STAGE_A0_4", 3], ["CAB_STAGE_A0_5", 3],
		["CAB_STAGE_A0_1_SUB", 1], ["CAB_STAGE_A0_2_SUB", 1], ["CAB_STAGE_A0_3_SUB", 1], ["CAB_STAGE_A0_4_SUB", 1],
		["CAB_STAGE_A0_5_SUB", 1], ["CAB_ZONE_DRIFT", 1], ["CAB_ZONE_CENSER_WATCH", 1], ["CAB_ZONE_SHOAL", 1],
		["CAB_ZONE_STILLWATER", 1],
		["CAB_READY", 2], ["CAB_GAME_OVER", 2], ["CAB_VIGIL_COMPLETE", 2], ["CAB_ENTITY_DOWN", 2],
		["CAB_EXTRA_VIGIL", 1], ["CAB_CAPTION_WHISPER", 1], ["CAB_CREDIT", 1],
		["ENTITY_IT_WAKES", 3], ["REVEAL_PRETENCE", 3], ["REVEAL_ONE_SKY_LESS", 3], ["CAB_MAKER", 1],
	]
	for i in 7:
		items.append(["CAB_CREDITS_%d" % (i + 1), 2])
	# S7 service record lines, formatted with a worst-case 3-digit count
	for key in ["CAB_CREDITS_STAT_GRUBS", "CAB_CREDITS_STAT_MINED", "CAB_CREDITS_STAT_CHARGES", "CAB_CREDITS_STAT_CARRIED"]:
		items.append([key, 2, 999])
	for it in items:
		var s := tr(it[0])
		assert_str(s).override_failure_message("%s has no translation" % it[0]).is_not_equal(it[0])
		if it.size() > 2:
			s = s % int(it[2])
		assert_bool(_fits(s, it[1], limit)).override_failure_message("%s at x%d does not fit %s px" % [it[0], it[1], limit]).is_true()
	# the mid-shift tally title, in the credits typeface (x2), with a worst-case 2-digit stage number
	var tally := tr("CAB_TALLY_TITLE")
	assert_str(tally).is_not_equal("CAB_TALLY_TITLE")
	assert_bool(_fits(tally.format({"n": 99}), 2, limit)).override_failure_message("CAB_TALLY_TITLE does not fit").is_true()


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


## The attract screen is the arcade screen, not the window (Q-T80): backdrop, strip, play view, cards and power-on
## are on the ArcadeScreen's SubViewport under its CRT; the bezel, the control panel and the coin door are outside it.
func test_attract_screen_is_drawn_in_the_arcade_viewport() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	var scene := _attract()
	await get_tree().process_frame
	var screen := scene.get_node("%ArcadeScreen") as ArcadeScreen
	var vp := scene.get_node("%ScreenViewport") as SubViewport
	assert_object(vp.size).is_equal(spec.grid)
	assert_object(Rect2(screen.position, screen.size)).is_equal(ScreenFit.hole_rect(spec.grid))
	assert_str(screen.crt_material().shader.resource_path).is_equal("res://shaders/crt.gdshader")
	assert_float(float(screen.crt_material().get_shader_parameter(&"rows"))).is_equal(float(spec.grid.y))
	assert_bool(screen.get_children().any(func(n: Node) -> bool: return n is VideoRegisters)).is_true()
	for n in ["Backdrop", "StripHud", "Play", "PowerOn", "Logo", "Pages"]:
		var c := scene.find_child(n, true, false)
		assert_bool(vp.is_ancestor_of(c)).override_failure_message("%s should be on the tube" % n).is_true()
	for n in ["Frame", "CoinSlot", "ControlPanel", "NewVigil", "Settings", "Power"]:
		assert_bool(vp.is_ancestor_of(scene.find_child(n, true, false))).override_failure_message("%s must be outside the tube" % n).is_false()
	var play := scene.get_node("%Play") as Control
	assert_object(Rect2(play.position, play.size)).is_equal(spec.play_rect())
	var coin := scene.find_child("CoinSlot", true, false) as Control
	assert_bool(coin.get_rect().intersects(ScreenFit.hole_rect(spec.grid))).is_false()
	# no focusable Control may live in the screen's viewport: its focus is separate from the root's
	var stack: Array[Node] = [vp]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Control:
			assert_int((n as Control).focus_mode).override_failure_message("%s is focusable" % n.name).is_equal(Control.FOCUS_NONE)
		stack.append_array(n.get_children())
	scene.queue_free()


func test_attract_cards_fit_the_play_view_at_100_percent_text() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	var scene := _attract()
	await get_tree().process_frame
	await get_tree().process_frame
	var play := scene.get_node("%Play") as Control
	for n in ["Logo", "Pages"]:
		var c := scene.find_child(n, true, false) as Control
		assert_bool(play.get_global_rect().encloses(c.get_global_rect())).override_failure_message("%s %s outside the play view %s" % [n, c.get_global_rect(), play.get_global_rect()]).is_true()
	assert_float(float(spec.grid.x)).is_equal(256.0)
	scene.queue_free()
