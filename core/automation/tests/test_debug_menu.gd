extends GdUnitTestSuite
## The P-key debug menu (TECH-001 §9.1 "Debug menu"): dev gate, the raw-key toggle (never an InputMap action),
## the stage list, and the runtime shift override acting on a real CabinetGame. Saves in memory; data/ untouched.

const BootScript := preload("res://scenes/boot/boot.gd")
const MenuScript := preload("res://core/automation/debug_menu.gd")
const GAME := preload("res://features/cabinet/cabinet_game.tscn")
const DATA_IDS: Array[StringName] = [&"a0_1", &"a0_4", &"a0_5"]

var _menu: Node
var _host: Node


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	_host = Node.new()
	add_child(_host)
	_menu = MenuScript.new()
	_menu.route_host = _host
	add_child(_menu)


func after_test() -> void:
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false
	_menu.queue_free()
	_host.queue_free()


static func _p_key() -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_P
	e.pressed = true
	return e


func _ids(r: CabinetStageRoster) -> Array[StringName]:
	var out: Array[StringName] = []
	for s in r.stages:
		out.append(s.id)
	return out


func _stage(id: StringName) -> CabinetStage:
	for s: CabinetStage in _menu.all_stages():
		if s.id == id:
			return s
	return null


func _mount_cabinet() -> CabinetGame:
	var g := GAME.instantiate() as CabinetGame
	_host.add_child(g)
	await get_tree().process_frame
	return g


func test_gate_is_editor_or_dev_never_qa_or_release() -> void:
	assert_bool(BootScript._debug_menu_allowed(func(_t: String) -> bool: return false)).is_false()
	assert_bool(BootScript._debug_menu_allowed(func(t: String) -> bool: return t == "automation_qa")).is_false()
	assert_bool(BootScript._debug_menu_allowed(func(t: String) -> bool: return t == "release")).is_false()
	assert_bool(BootScript._debug_menu_allowed(func(t: String) -> bool: return t == "editor")).is_true()
	assert_bool(BootScript._debug_menu_allowed(func(t: String) -> bool: return t == "automation_dev")).is_true()


func test_p_is_not_an_input_map_action() -> void:
	for action in InputMap.get_actions():
		for ev in InputMap.action_get_events(action):
			var k := ev as InputEventKey
			if k != null:
				assert_int(k.physical_keycode).override_failure_message("%s is bound to P" % action).is_not_equal(KEY_P)
				assert_int(k.keycode).override_failure_message("%s is bound to P" % action).is_not_equal(KEY_P)


func test_p_toggles_the_overlay_and_pauses() -> void:
	assert_bool(_menu.is_open()).is_false()
	_menu._input(_p_key())
	assert_bool(_menu.is_open()).is_true()
	assert_bool(get_tree().paused).is_true()
	_menu._input(_p_key())
	assert_bool(_menu.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_ui_cancel_closes_and_keeps_an_earlier_pause() -> void:
	get_tree().paused = true
	_menu.toggle()
	assert_bool(_menu.is_open()).is_true()
	_menu.stack.top().cancel()
	assert_bool(_menu.is_open()).is_false()
	assert_bool(get_tree().paused).is_true()   # it was paused before the menu opened


func test_lists_all_five_stages_and_the_data_shift_is_picked() -> void:
	var ids: Array[StringName] = []
	for s: CabinetStage in _menu.all_stages():
		ids.append(s.id)
	assert_array(ids).is_equal([&"a0_1", &"a0_2", &"a0_3", &"a0_4", &"a0_5"])
	assert_array(_ids(_menu.active_roster())).is_equal(DATA_IDS)
	_menu.toggle()
	var screen: Control = _menu.stack.top()
	assert_array(screen._picked).is_equal([0, 3, 4])   # indices of a0_1, a0_4, a0_5 in the five-stage list
	assert_int(screen._toggles.size()).is_equal(5)


func test_menu_text_has_no_missing_glyphs_or_raw_keys() -> void:
	_menu.toggle()
	var screen: Control = _menu.stack.top()
	await get_tree().process_frame
	for t: MenuText in [screen._shift_text, screen._unmake_text]:
		assert_array(t.missing_glyphs()).is_empty()
		assert_bool(t.shown_text().contains("MENU_DEBUG")).is_false()
	assert_str(screen._unmake_text.text).is_equal("Unmakings: 2")


func test_apply_shift_is_a_runtime_override_in_the_chosen_order() -> void:
	var cab := await _mount_cabinet()
	var order: Array[CabinetStage] = [_stage(&"a0_5"), _stage(&"a0_1")]
	assert_bool(_menu.apply_shift(order)).is_true()
	assert_array(_ids(cab.roster)).is_equal([&"a0_5", &"a0_1"])
	assert_int(cab.stage_index).is_equal(0)
	assert_str(String(cab.stages[0].id)).is_equal("a0_5")
	assert_int(cab.roster.unmakings_required()).is_equal(1)   # a0_1 is a clear-the-Sepulchre stage
	# data/ is untouched: the shipped roster still loads as the three stages
	var fresh := ResourceLoader.load(CabinetStageRoster.DEFAULT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as CabinetStageRoster
	assert_array(_ids(fresh)).is_equal(DATA_IDS)
	assert_bool(_menu.reset_shift()).is_true()
	assert_array(_ids(cab.roster)).is_equal(DATA_IDS)
	assert_object(_menu.override).is_null()


func test_play_stage_inside_the_shift_keeps_its_slot() -> void:
	var cab := await _mount_cabinet()
	assert_bool(_menu.play_stage(_stage(&"a0_4"))).is_true()
	assert_int(cab.stage_index).is_equal(1)
	assert_str(String(cab.stages[cab.stage_index].id)).is_equal("a0_4")


func test_play_stage_outside_the_shift_plays_it_alone() -> void:
	var cab := await _mount_cabinet()
	assert_bool(_menu.play_stage(_stage(&"a0_3"))).is_true()
	assert_int(cab.stage_index).is_equal(0)
	assert_str(String(cab.stages[0].id)).is_equal("a0_3")
	assert_int(cab.stages.size()).is_equal(1)
	assert_object(_menu.override).is_null()   # a single play is not the session shift


func test_no_cabinet_keeps_the_choice_for_the_next_one() -> void:
	assert_bool(_menu.apply_shift([_stage(&"a0_4")])).is_false()
	assert_array(_ids(_menu.active_roster())).is_equal([&"a0_4"])
	assert_bool(_menu.play_stage(_stage(&"a0_3"))).is_false()
	var cab := await _mount_cabinet()
	_menu._on_route_changed(&"cabinet")
	assert_array(_ids(cab.roster)).is_equal([&"a0_4"])
