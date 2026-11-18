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
@onready var emitter: ArcLanceEmitter = %ArcLanceEmitter


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


## D-08 hull A/B switch (SYS-001 §1.2): 1 = one-hit hull, 2 = plated. Takes effect at once and
## restores the hull to full. Post-hit grace only applies at max HP >= 2 (HealthComponent).
## Pass the `ds_vigil.hull.max_hp` value (e.g. from a TunableRegistry lookup).
func set_hull_max_hp(max_hp: int) -> void:
	health.set_max_hp(max_hp)


func get_hull_max_hp() -> int:
	return health.max_hp


func _on_health_depleted() -> void:
	motor.enabled = false
	velocity = Vector2.ZERO
	hull_breached.emit()
