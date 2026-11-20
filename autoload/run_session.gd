extends Node
## RunSession (autoload) — why global: run and Iteration state outlive every sector scene across the
## 5 Seams and must be readable by the Ruins (TECH-001 §2.8, §4.2a). A thin forwarder: every rule is
## in `core` (`RunSessionCore`, features/run). This node owns one core, ticks it at stage −20 (§4.1),
## hands it SaveService as its saver and keeps the clock-pause reasons it can see (Q-T138).
## Must not: own sector nodes, write saves itself, hold display text, read input.

const STATS_PATH := "res://data/run/run_session.tres"
## §4.1 stage −20: clock and run timers run before intent.
const PHYSICS_PRIORITY := -20

var core: RunSessionCore

## Pause reasons this node holds on the core from what it observes, reason -> bool.
var _held: Dictionary = {}

## Read-only scalars for the automation id `run/session` (core/automation/ui_view.gd). Dev/QA reads.
var ember: int:
	get: return core.profile().ember_banked if core else 0
var act0_banked: bool:
	get: return core.profile().act0_banked if core else false
var hourglass_left: float:
	get: return core.loop_min_left() if core else 0.0
var skies_dark: int:
	get: return core.skies_dark() if core else 0
var seam_index: int:
	get: return core.run().seam_index if core else 0
var clock_paused: bool:
	get: return core.is_clock_paused() if core else false
var run_active: bool:
	get: return core.run().is_active() if core else false
var tree_owned: int:
	get: return core.profile().tree_nodes.size() if core else 0
## Codex entries stamped and runs ended on this profile (Q-T350, Q-T353).
var codex_known: int:
	get: return core.profile().codex_known.size() if core else 0
var runs_ended: int:
	get: return core.profile().runs_ended if core else 0


func _ready() -> void:
	# Pausable: SceneTree.paused (the pause menu) also stops the clock (§4.2a).
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = PHYSICS_PRIORITY
	core = RunSessionCore.new(load(STATS_PATH) as RunSessionStats, SaveService)
	core.load_from_saver()


func _physics_process(delta: float) -> void:
	# Q-T138: a route curtain or loading, and attract mode / Act 0 routes, hold the clock.
	_hold(RunSessionCore.PAUSE_CURTAIN, SceneRouter.is_busy)
	_hold(RunSessionCore.PAUSE_ATTRACT, core.stats.clock_free_routes.has(SceneRouter.current_route))
	core.tick(unscaled(delta))


## Real seconds for one physics tick: slow-mo and hit-stop (Engine.time_scale) do not slow the
## clock (Q-T138).
static func unscaled(delta: float) -> float:
	if Engine.time_scale > 0.0:
		return delta / Engine.time_scale
	return 1.0 / float(Engine.physics_ticks_per_second)


func _hold(reason: StringName, on: bool) -> void:
	var was := bool(_held.get(reason, false))
	if on == was:
		return
	_held[reason] = on
	if on:
		core.pause_clock(reason)
	else:
		core.resume_clock(reason)
