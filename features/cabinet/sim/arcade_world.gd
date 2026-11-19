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

@export var screen_spec: CabinetScreenSpec   ## the arcade grid and HUD strip (data/cabinet/cabinet_screen.tres)
@export var tuning: CabinetTuning
@export var fx_tuning: CabinetFxTuning     ## presentation numbers (data/cabinet/cabinet_fx_tuning.tres)
@export var move_stats: VigilMoveStats

var stage: CabinetStage
var torus: Torus
var rng := RandomNumberGenerator.new()
var view_centre := Vector2.ZERO
var view_rect := Rect2()              ## the play view in screen (grid) coordinates: the grid below the HUD strip
var view_size := Vector2.ZERO         ## its size: what the player sees of the field
var screen_centre := Vector2.ZERO     ## where the Vigil is drawn: the centre of the play view
var paused_sim := false
var time := 0.0
var shader_time := 0.0                ## like `time` but keeps running through hit-stop (CRT shader clock)

var hitstop_left := 0                 ## sim frames still frozen (hit-stop; see hitstop())

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
	view_size = view_rect.size
	screen_centre = view_rect.get_center()


func start(p_stage: CabinetStage) -> void:
	stage = p_stage
	torus = Torus.new(stage.field_size)
	rng.seed = stage.seed
	time = 0.0
	shader_time = 0.0
	hitstop_left = 0
	layers = [stars, geodes, glass, ritual, grubs, acolytes, shots, vigil, fx]
	for l in layers:
		l.world = self
	for l in layers:
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
	time += delta
	for l in layers:
		l.tick(delta)
	# camera: glue to the Vigil (critically damped follow is the Act 1 camera, SYS-001 §9)
	view_centre = vigil.pos
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
	for l in layers:
		l.queue_redraw()


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
func hitstop(frames: int) -> void:
	if frames <= 0 or fx_tuning == null:
		return
	if SettingsService.get_value(&"reduced_motion"):
		frames = roundi(frames * fx_tuning.hitstop_reduced_motion_scale)
		if frames <= 0:
			return
	hitstop_left = mini(maxi(hitstop_left, frames), fx_tuning.hitstop_max_frames)


func shake_offset() -> Vector2:
	if _shake <= 0.0:
		return Vector2.ZERO
	var a := _shake_amp * (_shake / 0.25)
	return Vector2(roundf(sin(time * 91.0) * a), roundf(cos(time * 73.0) * a))


func sfx(id: StringName, volume_db: float = 0.0) -> void:
	AudioService.play(id, volume_db)


func award(points: int, at: Vector2) -> void:
	score_awarded.emit(points, at)
	fx.float_text(at, str(points))


## A random point at least `clear` px from `avoid` (spawning away from the Vigil).
func random_point(avoid: Vector2 = Vector2(-99999, -99999), clear: float = 0.0) -> Vector2:
	for i in 30:
		var p := Vector2(rng.randf() * torus.size.x, rng.randf() * torus.size.y)
		if torus.distance(p, avoid) >= clear:
			return p
	return Vector2(rng.randf() * torus.size.x, rng.randf() * torus.size.y)
