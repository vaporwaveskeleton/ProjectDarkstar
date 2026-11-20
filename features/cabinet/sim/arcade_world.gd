class_name ArcadeWorld
extends Node2D
## The Cabinet's playfield (Act 0): a torus of authored size, seen through a camera that follows
## the Vigil. Owns the shared services every layer uses (torus maths, RNG, view transform, shake,
## sound) and ticks the layers in a fixed order (TECH-001 §4.1). Holds no rules of its own:
## each rule lives in its layer.
##
## Why not Godot physics here (TECH-001 §11.2, 2026-11-18): the Act 0 costume is a wrap-around
## vector field; circle overlaps in torus space are exact, deterministic and cheap at these counts.

signal score_awarded(points: int, at: Vector2)
signal vigil_destroyed
signal charges_changed(count: int)
signal segments_changed(count: int)
signal phase_changed(phase: int)
signal entity_line(key: String)
signal entity_unmade
signal sepulchre_cleared
signal caption(key: String)
signal hitstop_started(beat: StringName)   ## a hit-stop freeze began or was extended (beat id of the cause)
signal slowmo_changed(scale: float)         ## the world's sim speed changed (1.0 = normal); drives the audio bed bend

@export var screen_spec: CabinetScreenSpec   ## the arcade grid and HUD strip (data/cabinet/cabinet_screen.tres)
@export var tuning: CabinetTuning
@export var fx_tuning: CabinetFxTuning     ## presentation numbers (data/cabinet/cabinet_fx_tuning.tres)
@export var move_stats: VigilMoveStats

var stage: CabinetStage
var record: ServiceRecord             ## S7 run-wide counts; owned by CabinetGame, survives start()
var torus: Torus
var neighbourhood: Neighbourhood      ## SYS-001 §1.7: the box of free units round the Vigil (re-wrap + spawn placement)
var rng := RandomNumberGenerator.new()
var view_centre := Vector2.ZERO
var view_rect := Rect2()              ## the play view in screen (grid) coordinates: the grid below the HUD strip
var view_size := Vector2.ZERO         ## its size: what the player sees of the field
var playfield_rect := Rect2()         ## view_rect minus the footer band: chalk clips here, never over cabinet text
var screen_centre := Vector2.ZERO     ## where the Vigil is drawn: the centre of the play view
var paused_sim := false
var time := 0.0
var shader_time := 0.0                ## like `time` but keeps running through hit-stop (CRT shader clock)

var hitstop_left := 0                 ## sim frames still frozen (hit-stop; see hitstop())

var sim_scale := 1.0                  ## world sim speed for the last-Charge slow-mo; 1.0 = normal (world only, never Engine.time_scale)

var _slowmo_target := 1.0
var _slowmo_real_t := 0.0             ## real seconds of the current slow-mo episode (failsafe)
var _slowmo_locked := false           ## failsafe fired: no slow-mo until the lethal condition clears
var _shake := 0.0
var _shake_amp := 0.0

@onready var stars: Starfield = %Stars
@onready var geodes: GeodeField = %Geodes
@onready var glass: GlassField = %Glass
@onready var ritual: SepulchreRitual = %Ritual
@onready var grubs: GrubFlock = %Grubs
@onready var acolytes: AcolyteSquad = %Acolytes
@onready var shots: ShotLayer = %Shots
@onready var vigil: VigilShip = %Vigil
@onready var fx: FxLayer = %Fx

var layers: Array[ArcadeLayer] = []


func _ready() -> void:
	if screen_spec == null:
		screen_spec = load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	view_rect = screen_spec.play_rect()
	playfield_rect = screen_spec.playfield_rect()
	view_size = view_rect.size
	screen_centre = view_rect.get_center()


func start(p_stage: CabinetStage) -> void:
	stage = p_stage
	torus = Torus.new(stage.field_size)
	neighbourhood = Neighbourhood.new(self)
	rng.seed = stage.seed
	time = 0.0
	shader_time = 0.0
	hitstop_left = 0
	_reset_slowmo()
	layers = [stars, geodes, glass, ritual, grubs, acolytes, shots, vigil, fx]
	for l in layers:
		l.world = self
	# the Vigil resets first: the Sepulchre and every spawn are placed relative to it (SYS-001 §1.7)
	vigil.reset()
	view_centre = vigil.pos
	for l in layers:
		if l != vigil:
			l.reset()
	view_centre = vigil.pos


func _physics_process(delta: float) -> void:
	if stage == null or paused_sim:
		return
	step(delta)


## One simulation tick. Public so tests can drive it without a frame loop.
func step(delta: float) -> void:
	shader_time += delta
	if hitstop_left > 0:
		# Hit-stop: the sim hangs (sparks, shake, timers inside layers) but the view still redraws.
		hitstop_left -= 1
		for l in layers:
			l.queue_redraw()
		return
	_step_slowmo(delta)
	var sdt := delta * sim_scale          # world time; the Vigil, audio, input and the CRT clock stay on real time
	time += sdt
	for l in layers:
		l.tick(delta if l == vigil else sdt)
	neighbourhood.step()                  # SYS-001 §1.7: free units re-wrap round the Vigil, after everything has moved
	# camera: glue to the Vigil (critically damped follow is the Act 1 camera, SYS-001 §9)
	view_centre = vigil.pos
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - sdt)
	for l in layers:
		l.queue_redraw()


## Ask for slow-mo (`t` < 1.0) or normal speed (1.0). Reduced Motion refuses any slow-down.
## Clearing the request (1.0) also clears the failsafe lockout.
func set_slowmo_target(t: float) -> void:
	if t >= 1.0:
		_slowmo_target = 1.0
		_slowmo_locked = false
		return
	if _slowmo_locked or SettingsService.get_value(&"reduced_motion"):
		return
	_slowmo_target = clampf(t, 0.0, 1.0)


## Snap back to normal speed now (an impact is about to hit-stop). Emits once if it was slowed.
func end_slowmo() -> void:
	_slowmo_target = 1.0
	_slowmo_real_t = 0.0
	_slowmo_locked = false
	if sim_scale != 1.0:
		sim_scale = 1.0
		slowmo_changed.emit(1.0)


func slowmo_active() -> bool:
	return sim_scale < 1.0 or _slowmo_target < 1.0


func _reset_slowmo() -> void:
	_slowmo_target = 1.0
	_slowmo_real_t = 0.0
	_slowmo_locked = false
	if sim_scale != 1.0:
		sim_scale = 1.0
		slowmo_changed.emit(1.0)


## Ramp the sim scale toward its target on REAL time (linear in scale); enforce the failsafe.
func _step_slowmo(delta: float) -> void:
	if fx_tuning == null:
		return
	if slowmo_active():
		_slowmo_real_t += delta
		if _slowmo_target < 1.0 and _slowmo_real_t > fx_tuning.slowmo_max_real_s:
			_slowmo_target = 1.0
			_slowmo_locked = true
	else:
		_slowmo_real_t = 0.0
	if sim_scale == _slowmo_target:
		return
	var span := 1.0 - fx_tuning.slowmo_scale
	var down := _slowmo_target < sim_scale
	var secs := fx_tuning.slowmo_ramp_in_s if down else fx_tuning.slowmo_ramp_out_s
	var rate := span / maxf(secs, 0.001)
	var prev := sim_scale
	sim_scale = move_toward(sim_scale, _slowmo_target, rate * delta)
	if sim_scale != prev:
		slowmo_changed.emit(sim_scale)


func to_screen(p: Vector2) -> Vector2:
	return torus.to_screen(p, view_centre, screen_centre + shake_offset())


## Is `p` inside the visible play view (grown by `margin` px)? Margin 0 = what the player can see.
func on_screen(p: Vector2, margin: float = 64.0) -> bool:
	var s := to_screen(p)
	return view_rect.grow(margin).has_point(s)


## Screen shake, capped by SYS-001 §9 (≤ 4 px, ≤ 0.25 s). Reduced Motion turns it off.
func shake(amp: float, dur: float) -> void:
	if SettingsService.get_value(&"reduced_motion"):
		return
	_shake_amp = minf(4.0, maxf(_shake_amp if _shake > 0.0 else 0.0, amp))
	_shake = minf(0.25, maxf(_shake, dur))


## Freeze the sim for `frames` physics ticks (hit-stop, ✱ PROPOSED values in CabinetFxTuning).
## Reduced Motion scales it; stacking keeps the longer one; capped at hitstop_max_frames.
## Never touches Engine.time_scale or the tree pause: audio, CRT, input and state timers run on.
func hitstop(frames: int, beat: StringName = &"") -> void:
	if frames <= 0 or fx_tuning == null:
		return
	if SettingsService.get_value(&"reduced_motion"):
		frames = roundi(frames * fx_tuning.hitstop_reduced_motion_scale)
		if frames <= 0:
			return
	var new_left := mini(maxi(hitstop_left, frames), fx_tuning.hitstop_max_frames)
	if new_left > hitstop_left:
		hitstop_left = new_left
		hitstop_started.emit(beat)


func shake_offset() -> Vector2:
	if _shake <= 0.0:
		return Vector2.ZERO
	var a := _shake_amp * (_shake / 0.25)
	return Vector2(roundf(sin(time * 91.0) * a), roundf(cos(time * 73.0) * a))


func sfx(id: StringName, volume_db: float = 0.0) -> void:
	AudioService.play(id, volume_db)


func award(points: int, at: Vector2) -> void:
	score_awarded.emit(points, at)   # the HUD strip shows the score; no floating numbers on the arcade screen (owner F-2, 2026-11-20)


## A random point at least `clear` px from `avoid` (spawning away from the Vigil).
func random_point(avoid: Vector2 = Vector2(-99999, -99999), clear: float = 0.0) -> Vector2:
	for i in 30:
		var p := Vector2(rng.randf() * torus.size.x, rng.randf() * torus.size.y)
		if torus.distance(p, avoid) >= clear:
			return p
	return Vector2(rng.randf() * torus.size.x, rng.randf() * torus.size.y)
