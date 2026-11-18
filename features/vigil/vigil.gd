class_name Vigil
extends CharacterBody2D
## The player's ship. A thin root that wires its components; behaviour lives in children:
##   VigilInput (intent) -> VigilMotor (velocity, facing) ; HealthComponent + Hurtbox (hull).
## Collision radius comes from VigilMoveStats, never from the sprite.

signal hull_breached

@onready var motor: VigilMotor = %VigilMotor
@onready var input: VigilInput = %VigilInput
@onready var health: HealthComponent = %HealthComponent
@onready var hurtbox: HurtboxComponent = %Hurtbox


func _ready() -> void:
	add_to_group(&"vigil")
	collision_layer = PhysicsLayers.bit(PhysicsLayers.VIGIL)
	collision_mask = PhysicsLayers.mask([PhysicsLayers.WORLD, PhysicsLayers.SHROUD])
	hurtbox.collision_layer = PhysicsLayers.bit(PhysicsLayers.VIGIL_HURTBOX)
	hurtbox.collision_mask = 0
	var radius := motor.stats.hitbox_circle_px * 0.5
	(%BodyShape.shape as CircleShape2D).radius = radius
	(%HurtShape.shape as CircleShape2D).radius = radius
	health.health_depleted.connect(_on_health_depleted)


func _on_health_depleted() -> void:
	motor.enabled = false
	velocity = Vector2.ZERO
	hull_breached.emit()
