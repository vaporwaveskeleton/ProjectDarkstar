class_name HitboxComponent
extends Area2D
## A temporary attack volume. Gameplay code (or an AnimationPlayer method track, as a *request*)
## calls open_window()/close_window(); hit truth is decided here, in the physics tick.
## Each window hits each hurtbox at most once; HealthComponent also dedupes by window key.

signal hit_landed(hurtbox: HurtboxComponent, accepted: bool)

@export var damage: int = 1
@export var kind: StringName = &"generic"
## Source identity for one-hit-per-window. Defaults to the owner's instance id.
@export var source: Node

var window_id: int = 0
var is_active: bool = false
var _hit_this_window: Dictionary = {}   # hurtbox instance id -> true


func _ready() -> void:
	monitorable = false
	monitoring = false


func open_window() -> void:
	window_id += 1
	_hit_this_window.clear()
	is_active = true
	monitoring = true


func close_window() -> void:
	is_active = false
	set_deferred("monitoring", false)


func _physics_process(_delta: float) -> void:
	if is_active:
		scan_overlaps()


## Resolve overlaps now. Public so tests can drive it without waiting a frame.
func scan_overlaps() -> void:
	for area in get_overlapping_areas():
		if area is HurtboxComponent:
			try_hit(area as HurtboxComponent)


func try_hit(hurtbox: HurtboxComponent) -> bool:
	if not is_active:
		return false
	var id := hurtbox.get_instance_id()
	if _hit_this_window.has(id):
		return false
	_hit_this_window[id] = true
	var src := source if source else owner
	var src_id := src.get_instance_id() if src else get_instance_id()
	var accepted := hurtbox.receive_hit(HitInfo.make(damage, src_id, window_id, kind))
	hit_landed.emit(hurtbox, accepted)
	return accepted
