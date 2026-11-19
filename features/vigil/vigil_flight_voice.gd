class_name VigilFlightVoice
extends Node
## The Aether Vigil's sound of flying (AUDIO-001 §12.19, C11–C16; resolves TECH-001 Q-T42). Reads the
## Vigil's motion each physics tick and pushes it to AudioService.set_flight as fractions of the
## Vigil's own SYS-001 values (speed / max_speed, turn rate / snap_turn), so the ship-handling numbers
## can change without touching the sound. Never sets a level: AudioService and FlightMix own the mix.
## Pushes only when a value moved by more than PUSH_EPS (AUDIO-001 §7.5: parameters on change).
## Stops the flight layers when the hull is breached or the node leaves the tree.

const PUSH_EPS := 0.01   ## ✱ smallest change worth a push

@export var vigil: Vigil
## Who receives the push (AudioService unless a test injects a spy): needs set_flight, stop_flight.
var sink: Object

var _last := Vector4(-1.0, -1.0, -1.0, -1.0)
var _last_facing := 0.0
var _has_facing := false
var _dead := false


func _ready() -> void:
	if sink == null:
		sink = get_node_or_null(^"/root/AudioService")
	if vigil != null and not vigil.hull_breached.is_connected(_on_hull_breached):
		vigil.hull_breached.connect(_on_hull_breached)


func _exit_tree() -> void:
	_stop()


## The pause menu stops the ship's sound (the layers release); unpausing re-pushes on the next tick.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_stop()
	elif what == NOTIFICATION_UNPAUSED:
		_last = Vector4(-1.0, -1.0, -1.0, -1.0)


func _physics_process(delta: float) -> void:
	if _dead or vigil == null or not is_instance_valid(vigil) or vigil.motor == null or vigil.motor.stats == null:
		return
	var s := vigil.motor.stats
	var facing := vigil.motor.facing_node.rotation if vigil.motor.facing_node != null else 0.0
	var turn_rate := 0.0
	if _has_facing and delta > 0.0:
		turn_rate = absf(wrapf(facing - _last_facing, -PI, PI)) / delta
	_last_facing = facing
	_has_facing = true
	var braking := vigil.input.braking if vigil.input != null else false
	var thrust := 0.0 if braking or vigil.input == null else clampf(vigil.input.move_dir.length(), 0.0, 1.0)
	var v := Vector4(
		fraction(vigil.velocity.length(), s.max_speed),
		thrust,
		fraction(turn_rate, deg_to_rad(s.snap_turn)),
		1.0 if braking else 0.0)
	if _changed(v):
		_last = v
		if sink != null and sink.has_method(&"set_flight"):
			sink.call(&"set_flight", v.x, v.y, v.z, v.w > 0.5)


## value / full, clamped to 0..1 (0 when full is not positive).
static func fraction(value: float, full: float) -> float:
	return clampf(value / full, 0.0, 1.0) if full > 0.0 else 0.0


func _changed(v: Vector4) -> bool:
	return absf(v.x - _last.x) > PUSH_EPS or absf(v.y - _last.y) > PUSH_EPS \
		or absf(v.z - _last.z) > PUSH_EPS or v.w != _last.w


func _on_hull_breached() -> void:
	_dead = true
	_stop()


func _stop() -> void:
	if sink != null and is_instance_valid(sink) and sink.has_method(&"stop_flight"):
		sink.call(&"stop_flight")
