class_name ArcLanceEmitter
extends Node
## Weapon component: while the fire action is held, spawns a LanceProjectile at the fire rate along
## the Vigil facing. Child of the Vigil. No recoil (SYS-001 §1.3).

const PROJECTILE_SCENE := preload("res://features/arc_lance/lance_projectile.tscn")

signal lance_fired(direction: Vector2)

@export var stats: ArcLanceStats
@export var input: VigilInput
## Node whose global rotation is the aim (the Vigil's Facing node).
@export var facing_node: Node2D
## Where shots are parented. Null = the current scene.
@export var projectile_parent: Node

var enabled: bool = true
var _cooldown_s: float = 0.0


func _physics_process(delta: float) -> void:
	if not enabled or stats == null or facing_node == null:
		return
	var held: bool = input != null and input.firing
	advance(delta, held)


## Deterministic step: tick the cooldown, fire once if held and ready.
## Returns the projectile fired this step, or null.
func advance(delta: float, held: bool) -> LanceProjectile:
	_cooldown_s = maxf(0.0, _cooldown_s - delta)
	if not held or _cooldown_s > 0.0001:
		return null
	_cooldown_s += stats.fire_interval_s()
	return _spawn()


func _spawn() -> LanceProjectile:
	var dir := Vector2.from_angle(facing_node.global_rotation)
	var origin := facing_node.global_position + dir * stats.muzzle_offset_px
	var shot := PROJECTILE_SCENE.instantiate() as LanceProjectile
	var parent: Node = projectile_parent if projectile_parent else get_tree().current_scene
	parent.add_child(shot)
	var owner_node := get_parent()
	shot.launch(stats, origin, dir, owner_node.get_instance_id() if owner_node else 0)
	lance_fired.emit(dir)
	return shot
