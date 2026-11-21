extends Node
## Developer debug menu (TECH-001 §9.1 "Debug menu"): P toggles an overlay with an Act 0 stage select.
## Dev builds only: Boot loads this file by path when the build has feature `editor` or `automation_dev`
## (never `automation_qa`, never a release build, which also excludes core/automation/*), outside the
## boot smoke and outside a scenario run. No class_name, no autoload, game code never references it.
## P is read here as a raw key, never an InputMap action (GDD §4.1/§4.3; tests/test_input_map.gd).
## Writes nothing: the shift override lives in this node only, never in data/ or a save.

const MenuScreen := preload("res://core/automation/debug_menu_screen.gd")
const ALL_STAGES_PATH := "res://data/cabinet/stage_roster_five.tres"   ## every Act 0 stage, in id order
const STACK_LAYER := 110                                               ## above Boot's curtain (100)

## The shift chosen in the menu (runtime only), or null = the data roster (stage_roster.tres).
var override: CabinetStageRoster = null
## Where mounted routes live (Boot's %RouteHost). Tests set it.
var route_host: Node = null
var stack: ScreenStack

var _was_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if route_host == null and get_parent() != null:
		route_host = get_parent().get_node_or_null("%RouteHost")
	stack = ScreenStack.new()
	stack.name = "DebugStack"
	stack.layer = STACK_LAYER
	stack.emptied.connect(_on_emptied)
	add_child(stack)
	SceneRouter.route_changed.connect(_on_route_changed)


func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo and k.physical_keycode == KEY_P:
		get_viewport().set_input_as_handled()
		toggle()


func is_open() -> bool:
	return not stack.is_empty()


func toggle() -> void:
	if is_open():
		while not stack.is_empty():
			stack.pop()
		return
	_was_paused = get_tree().paused
	get_tree().paused = true
	var s := MenuScreen.new() as Screen
	s.set("menu", self)
	s.process_mode = Node.PROCESS_MODE_ALWAYS
	stack.push(s)


func _on_emptied() -> void:
	get_tree().paused = _was_paused


# --- stage data and shift state ------------------------------------------------------------------

## Every Act 0 stage (a0_1..a0_5), the five-stage roster's list.
func all_stages() -> Array[CabinetStage]:
	var r := load(ALL_STAGES_PATH) as CabinetStageRoster
	var out: Array[CabinetStage] = []
	if r != null:
		out.assign(r.stages)
	return out


## The shift the cabinet plays now: the override, else stage_roster.tres.
func active_roster() -> CabinetStageRoster:
	return override if override != null else CabinetStageRoster.default_roster()


static func make_roster(stages: Array) -> CabinetStageRoster:
	var r := CabinetStageRoster.new()
	var typed: Array[CabinetStage] = []
	for s in stages:
		typed.append(s as CabinetStage)
	r.stages = typed
	return r


# --- acting on the running cabinet ---------------------------------------------------------------

## The mounted, non-demo cabinet, or null (attract, Ruins, the demo).
func cabinet() -> CabinetGame:
	if route_host == null:
		return null
	for c in route_host.get_children():
		var g := c as CabinetGame
		if g != null and not g.demo and g.is_node_ready():
			return g
	return null


## Keep `stages` (in this order) as the session's shift and restart the cabinet on its first stage.
## False when no cabinet is mounted: the override still waits and applies when one starts.
func apply_shift(stages: Array) -> bool:
	override = make_roster(stages)
	var cab := cabinet()
	if cab == null:
		return false
	cab.roster = override
	cab.new_game(0)
	return true


## Back to stage_roster.tres.
func reset_shift() -> bool:
	override = null
	var cab := cabinet()
	if cab == null:
		return false
	cab.roster = CabinetStageRoster.default_roster()
	cab.new_game(0)
	return true


## Play `stage` now, a fresh game (score and lives reset). Inside the active shift it keeps its slot (its
## wear level and Unmaking count); outside it, it plays as a one-stage shift for this cabinet only.
func play_stage(stage: CabinetStage) -> bool:
	var cab := cabinet()
	if cab == null or stage == null:
		return false
	var r := active_roster()
	var i := r.index_of(stage.id)
	if i < 0:
		r = make_roster([stage])
		i = 0
	cab.roster = r
	cab.new_game(i)
	return true


## A cabinet that mounts later (New Vigil from attract) plays the chosen shift.
func _on_route_changed(_route: StringName) -> void:
	if override == null:
		return
	var cab := cabinet()
	if cab != null and cab.roster != override:
		cab.roster = override
		cab.new_game(0)
