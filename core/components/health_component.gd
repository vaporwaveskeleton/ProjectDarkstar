class_name HealthComponent
extends Node
## Reusable hit-point owner. Knows nothing about who hits it or who listens.
## - One hit per attack window per source (HitInfo.window_key()).
## - Optional invulnerability after a hit (HealthStats.invulnerable_after_hit_s).
## - max_hp comes from HealthStats so D-08 (one-hit hull) stays a data switch.
## Time is advanced by the physics tick (`_physics_process`) or explicitly via `advance()` in tests.

signal damaged(amount: int, remaining: int)
signal healed(amount: int, remaining: int)
signal health_depleted
signal hit_rejected(reason: StringName)

const TIME_EPSILON := 0.0001

@export var stats: HealthStats

var current_hp: int = 1
var max_hp: int = 1
var is_depleted: bool = false
var _invulnerable_left: float = 0.0
var _seen_windows: Dictionary = {}   # window_key -> true


func _ready() -> void:
	reset()


## Restore to full from `stats`. Call on spawn / respawn.
func reset() -> void:
	max_hp = stats.max_hp if stats else 1
	current_hp = max_hp
	is_depleted = false
	_invulnerable_left = 0.0
	_seen_windows.clear()


func _physics_process(delta: float) -> void:
	advance(delta)


## Advance internal timers. Deterministic: called once per physics tick.
func advance(delta: float) -> void:
	if _invulnerable_left > 0.0:
		_invulnerable_left -= delta
		if _invulnerable_left < TIME_EPSILON:   # absorb float drift from summed ticks
			_invulnerable_left = 0.0


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


## Apply a hit. Returns true if it changed health.
func apply_hit(hit: HitInfo) -> bool:
	if is_depleted:
		hit_rejected.emit(&"depleted")
		return false
	var key := hit.window_key()
	if _seen_windows.has(key):
		hit_rejected.emit(&"same_window")
		return false
	if is_invulnerable():
		hit_rejected.emit(&"invulnerable")
		return false
	if hit.amount <= 0:
		hit_rejected.emit(&"no_damage")
		return false
	_seen_windows[key] = true
	current_hp = maxi(0, current_hp - hit.amount)
	damaged.emit(hit.amount, current_hp)
	if current_hp == 0:
		is_depleted = true
		health_depleted.emit()
	elif stats and stats.invulnerable_after_hit_s > 0.0:
		_invulnerable_left = stats.invulnerable_after_hit_s
	return true


func heal(amount: int) -> int:
	if is_depleted or amount <= 0:
		return 0
	var before := current_hp
	current_hp = mini(max_hp, current_hp + amount)
	var gained := current_hp - before
	if gained > 0:
		healed.emit(gained, current_hp)
	return gained


## Forget seen attack windows for one source (e.g. when that attacker is freed).
func forget_source(source_id: int) -> void:
	for k in _seen_windows.keys():
		if (k as String).begins_with("%d:" % source_id):
			_seen_windows.erase(k)
