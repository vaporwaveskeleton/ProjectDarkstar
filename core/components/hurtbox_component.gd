class_name HurtboxComponent
extends Area2D
## Receives hits and forwards them to a HealthComponent. Collision shape is a primitive child,
## sized from data, never from the sprite (TECH-001 §2.6). Animation never moves or toggles it.

signal hit_received(hit: HitInfo, accepted: bool)

@export var health: HealthComponent


func _ready() -> void:
	monitoring = false   # hurtboxes are detected, they do not scan
	monitorable = true


func receive_hit(hit: HitInfo) -> bool:
	var accepted := health.apply_hit(hit) if health else false
	hit_received.emit(hit, accepted)
	return accepted
