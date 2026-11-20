extends GdUnitTestSuite
## The Tree station screen (LanternTreeScreen + LanternTreeConfirm; UI-001 §3–§8): one lamp per node,
## default focus on the suggested lamp, explicit wrapping neighbours, the confirmation with the safe
## default, ui_cancel at each level, the honest Ember readout, no raw keys, and the 200 % safe area.

const TREE := preload("res://data/lantern_tree/m2_tree.tres")

var _host: Control
var _stack: ScreenStack


func before_test() -> void:
	SettingsService.persist = false


func after_test() -> void:
	SettingsService.set_value(&"text_scale", 1.0)
	SettingsService.persist = true
	get_tree().paused = false


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


func _ids(list: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for s: Variant in list:
		out.append(StringName(str(s)))
	return out


func _open(owned: Array[StringName], ember: int) -> Array:
	_host = auto_free(Control.new())
	_stack = ScreenStack.new()
	_stack.name = "Overlays"
	_host.add_child(_stack)
	var runner := scene_runner(_host)
	var screen := LanternTreeScreen.create(TREE, owned, ember)
	_stack.push(screen)
	await runner.simulate_frames(3)
	return [runner, screen]


func test_one_focusable_named_lamp_per_node() -> void:
	var r: Array = await _open(_ids([]), 60)
	var screen: LanternTreeScreen = r[1]
	assert_int(screen.lamps.size()).is_equal(30)
	for n in TREE.nodes:
		var lamp := screen.get_node_or_null("%" + "Lamp_" + String(n.id).replace("-", "_")) as TreeLantern
		assert_object(lamp).override_failure_message("no lamp for %s" % n.id).is_not_null()
		assert_int(lamp.focus_mode).is_equal(Control.FOCUS_ALL)
		assert_float(lamp.size.y).is_greater_equal(22.0)   # UI-001 §4 touch-safe height


func test_default_focus_is_the_first_affordable_lamp() -> void:
	var r: Array = await _open(_ids([]), 60)
	assert_str(_focus().name).is_equal("Lamp_LANTERN_1")
	var screen: LanternTreeScreen = r[1]
	assert_str(String(screen.shown_id())).is_equal("LANTERN-1")


func test_default_focus_moves_on_after_a_purchase_history() -> void:
	await _open(_ids(["LANTERN-1"]), 60)
	assert_str(_focus().name).is_equal("Lamp_HULL_1")


func test_every_lamp_has_four_neighbours_that_resolve_to_lamps() -> void:
	var r: Array = await _open(_ids([]), 60)
	var screen: LanternTreeScreen = r[1]
	for id: StringName in screen.lamps:
		var lamp: TreeLantern = screen.lamps[id]
		for p: NodePath in [lamp.focus_neighbor_left, lamp.focus_neighbor_right, lamp.focus_neighbor_top,
				lamp.focus_neighbor_bottom, lamp.focus_next, lamp.focus_previous]:
			assert_bool(p.is_empty()).override_failure_message("%s has an empty neighbour" % id).is_false()
			assert_object(lamp.get_node_or_null(p) as TreeLantern).override_failure_message("%s -> %s" % [id, p]).is_not_null()


func test_arrows_walk_the_rows_and_wrap() -> void:
	var r: Array = await _open(_ids([]), 60)
	var runner: GdUnitSceneRunner = r[0]
	assert_str(_focus().name).is_equal("Lamp_LANTERN_1")
	runner.simulate_action_pressed("ui_left")      # wraps to the far end of the tier-1 row
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("Lamp_MADNESS_4")
	runner.simulate_action_pressed("ui_right")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("Lamp_LANTERN_1")
	runner.simulate_action_pressed("ui_right")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("Lamp_LANTERN_2")
	runner.simulate_action_pressed("ui_up")         # up to the tier-2 lamp above
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("Lamp_LANTERN_5")
	runner.simulate_action_pressed("ui_up")         # wraps back down to tier 1
	await runner.simulate_frames(2)
	assert_str(String((_focus() as TreeLantern).node_id).get_slice("-", 0)).is_equal("LANTERN")


func test_accept_on_a_buyable_lamp_asks_with_the_safe_default() -> void:
	var r: Array = await _open(_ids([]), 60)
	var runner: GdUnitSceneRunner = r[0]
	var screen: LanternTreeScreen = r[1]
	var bought: Array = []
	screen.purchase_confirmed.connect(func(id: StringName) -> void: bought.append(id))
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	assert_int(_stack.depth()).is_equal(2)
	assert_object(_stack.top()).is_instanceof(LanternTreeConfirm)
	assert_str(_focus().name).is_equal("ConfirmKeep")   # the safe choice (UI-001 §3)
	runner.simulate_action_pressed("ui_accept")         # a mashed accept keeps the Ember
	await runner.simulate_frames(2)
	assert_int(_stack.depth()).is_equal(1)
	assert_array(bought).is_empty()
	assert_str(_focus().name).is_equal("Lamp_LANTERN_1")   # focus comes back to the lamp


func test_confirming_emits_the_purchase_once() -> void:
	var r: Array = await _open(_ids([]), 60)
	var runner: GdUnitSceneRunner = r[0]
	var screen: LanternTreeScreen = r[1]
	var bought: Array = []
	screen.purchase_confirmed.connect(func(id: StringName) -> void: bought.append(id))
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("ui_left")   # to LIGHT IT
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("ConfirmLight")
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	assert_array(bought).is_equal([&"LANTERN-1"])
	assert_int(_stack.depth()).is_equal(1)


func test_ui_cancel_closes_the_confirm_then_the_tree() -> void:
	var r: Array = await _open(_ids([]), 60)
	var runner: GdUnitSceneRunner = r[0]
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("ui_cancel")
	await runner.simulate_frames(2)
	assert_int(_stack.depth()).is_equal(1)
	runner.simulate_action_pressed("ui_cancel")
	await runner.simulate_frames(2)
	assert_bool(_stack.is_empty()).is_true()


func test_locked_lamps_open_no_confirmation() -> void:
	var r: Array = await _open(_ids([]), 60)
	var screen: LanternTreeScreen = r[1]
	for id: StringName in [&"LANTERN-5", &"WARD-1"]:   # a dark tier-2 lamp, a Codex-gated lamp
		(screen.lamps[id] as TreeLantern).pressed.emit()
		await r[0].simulate_frames(1)
		assert_int(_stack.depth()).is_equal(1)
	assert_str(String((screen.lamps[&"LANTERN-5"] as TreeLantern).state)).is_equal(String(LanternTreeRules.NOT_IN_SLICE))
	assert_str(String((screen.lamps[&"WARD-1"] as TreeLantern).state)).is_equal(String(LanternTreeRules.NEEDS_CODEX))


func test_the_ember_readout_is_the_banked_value() -> void:
	var r: Array = await _open(_ids([]), 60)
	var screen: LanternTreeScreen = r[1]
	var ember := screen.find_child("Ember", true, false) as VectorLabel
	assert_str(ember.shown_text()).is_equal("60 EMBER")
	screen.show_state(_ids(["LANTERN-1"]), 20)
	assert_str(ember.shown_text()).is_equal("20 EMBER")
	assert_bool((screen.lamps[&"LANTERN-1"] as TreeLantern).is_lit()).is_true()
	assert_str(String((screen.lamps[&"HULL-1"] as TreeLantern).state)).is_equal(String(LanternTreeRules.SHORT))


func test_the_plate_reads_the_focused_lamp_with_no_raw_keys() -> void:
	var r: Array = await _open(_ids([]), 60)
	var screen: LanternTreeScreen = r[1]
	for id: StringName in screen.lamps:
		(screen.lamps[id] as TreeLantern).grab_focus()
		await r[0].simulate_frames(1)
		assert_str(String(screen.shown_id())).is_equal(String(id))
		for l: VectorLabel in _labels(screen):
			assert_bool(l.shown_text().contains("RUINS_TREE_")).override_failure_message("raw key on %s: %s" % [l.name, l.shown_text()]).is_false()
			assert_bool(l.shown_text().contains("{")).override_failure_message("unfilled %s" % l.shown_text()).is_false()
			# the tree's name arrives in the Codex, never on the station (LOOP-001 §10.5.3)
			assert_bool(l.shown_text().to_lower().contains("lantern tree")).is_false()


func test_everything_stays_inside_the_safe_area_at_200_percent_text() -> void:
	SettingsService.set_value(&"text_scale", 2.0)
	var r: Array = await _open(_ids([]), 60)
	var screen: LanternTreeScreen = r[1]
	var area := LanternTreeScreen.logical_area(screen).grow(0.5)
	for c: Control in _labels(screen) + screen.lamps.values():
		assert_bool(area.encloses(c.get_rect())).override_failure_message("%s outside %s: %s" % [c.name, area, c.get_rect()]).is_true()
	# the longest effect line on the plate, then the confirmation
	(screen.lamps[&"MADNESS-1"] as TreeLantern).grab_focus()
	await r[0].simulate_frames(1)
	for l: VectorLabel in _labels(screen):
		assert_bool(area.encloses(l.get_rect())).override_failure_message("%s outside: %s" % [l.name, l.get_rect()]).is_true()
	(screen.lamps[&"LANTERN-1"] as TreeLantern).grab_focus()
	r[0].simulate_action_pressed("ui_accept")
	await r[0].simulate_frames(2)
	var confirm := _stack.top() as LanternTreeConfirm
	assert_object(confirm).is_not_null()
	var carea := LanternTreeScreen.logical_area(confirm).grow(0.5)
	for c: Control in confirm.get_children():
		assert_bool(carea.encloses(c.get_rect())).override_failure_message("%s outside: %s" % [c.name, c.get_rect()]).is_true()


func _labels(screen: Node) -> Array[Control]:
	var out: Array[Control] = []
	for c in screen.get_children():
		if c is VectorLabel:
			out.append(c as Control)
	return out
