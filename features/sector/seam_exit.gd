class_name SeamExit
extends Node
## How a Seam is cleared and left (TECH-001 §2.9; Q-T275, Q-T278). The sector host builds one,
## binds it to its torus, Vigil and Sepulchre, and listens:
##  - `throat_opened` once, when the Seam clears: the Sepulchre stands cold again (0 segments) after
##    Charges knocked at least `knocks_required` segments off it ("the Sepulchre unmade", the
##    slice's stand-in for "kit cleared" until the Waking is built; LOOP-001 §1, ZONES-001 §1.1).
##    The throat (SeamThroat) opens at `throat_pos` and shows on the Ledger Compass.
##  - `throat_entered` once, when the Vigil flies into the open throat. The host then reports the
##    Seam to RunSession and routes on (it owns the session and the router, never this node).
## The clear latches: Grubs depositing again later does not shut the throat.
## Must not: write the session, route, save, or read input.

signal throat_opened
signal throat_entered

## Dev/capture switches (honoured only in dev builds; the host passes them in):
## `--clear-knocks=N` overrides `knocks_required`, `--sepulchre-start=N` starts the Sepulchre built.
const ARG_KNOCKS := "clear-knocks"
const ARG_START := "sepulchre-start"

@export var stats: SeamExitStats

var torus: Torus
var vigil: Node2D
var sepulchre: Sepulchre
var throat: SeamThroat
## The rule's threshold now (stats, or a dev override).
var knocks_required := 0
var cleared := false
var entered := false
var _open_t := 0.0


## Wires the exit to this sector and puts the (shut) throat under `actors`.
func bind(p_torus: Torus, p_vigil: Node2D, p_sepulchre: Sepulchre, actors: Node, still: bool = false) -> void:
	torus = p_torus
	vigil = p_vigil
	sepulchre = p_sepulchre
	knocks_required = stats.knocks_required if stats else 1
	throat = SeamThroat.new()
	throat.name = "SeamThroat"
	throat.radius_px = stats.throat_radius_px if stats else 40.0
	throat.still = still
	throat.position = stats.throat_pos if stats else Vector2.ZERO
	if actors:
		actors.add_child(throat)


## Applies the dev switches (the host calls this only in a dev build). Returns the keys applied.
func apply_dev_args(args: PackedStringArray) -> PackedStringArray:
	var applied := PackedStringArray()
	var knocks := LaunchRoute.arg_value(args, ARG_KNOCKS)
	if knocks.is_valid_int() and int(knocks) >= 1:
		knocks_required = int(knocks)
		applied.append(ARG_KNOCKS)
	var start := LaunchRoute.arg_value(args, ARG_START)
	if start.is_valid_int() and int(start) >= 0 and sepulchre != null:
		sepulchre.segments = mini(int(start), sepulchre.stats.segments_total)
		sepulchre.phase = Sepulchre.phase_for(sepulchre.segments)
		applied.append(ARG_START)
	return applied


## The clear rule (pure): cold again after at least `required` (≥ 1) segments were knocked off.
static func is_clear(segments: int, knocked: int, required: int) -> bool:
	return segments <= 0 and knocked >= maxi(1, required)


## True when torus point `p` is inside the throat at `centre` (radius `r`).
static func in_throat(t: Torus, p: Vector2, centre: Vector2, r: float) -> bool:
	var d := t.distance(p, centre) if t else p.distance_to(centre)
	return d <= r


func _physics_process(delta: float) -> void:
	step(delta)


## One tick: latch the clear, open the throat, check the pass. Public so tests can drive it.
func step(delta: float) -> void:
	if not cleared and is_instance_valid(sepulchre) \
			and is_clear(sepulchre.segments, sepulchre.segments_knocked, knocks_required):
		open()
	if not cleared:
		return
	if is_instance_valid(throat):
		_open_t += delta
		var span := stats.throat_open_s if stats else 0.0
		throat.open_frac = 1.0 if span <= 0.0 else _open_t / span
	if entered or not is_instance_valid(vigil) or not is_instance_valid(throat):
		return
	if in_throat(torus, vigil.global_position, throat.global_position, throat.radius_px):
		entered = true
		throat_entered.emit()


## Opens the throat now (the clear). Idempotent.
func open() -> void:
	if cleared:
		return
	cleared = true
	_open_t = 0.0
	if is_instance_valid(throat):
		throat.open_frac = 0.01
		LedgerCompass.register(throat)
	throat_opened.emit()


## Torus offset from the Vigil to the throat (px); zero when either is missing.
func throat_offset() -> Vector2:
	if not is_instance_valid(vigil) or not is_instance_valid(throat):
		return Vector2.ZERO
	var c := stats.throat_pos if stats else throat.position
	return torus.delta(vigil.global_position, c) if torus else c - vigil.global_position
