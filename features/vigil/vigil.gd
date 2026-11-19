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
## The hull's honest Composure read (WARP-001 §4.2 L10); the sector injects its Composure.
@onready var cockpit_flame: CockpitFlame = %CockpitFlame


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
	apply_hull_override(HullMode.parse_args(OS.get_cmdline_user_args()))


## Applies a tester override (`--hull=1|2`); invalid values keep the data value (D-08).
func apply_hull_override(override: int) -> void:
	var resolved := HullMode.resolve(override, health.max_hp)
	if resolved != health.max_hp:
		set_hull_max_hp(resolved)


## D-08 hull A/B switch (SYS-001 §1.2): 1 = one-hit hull, 2 = plated. Takes effect at once and
## restores the hull to full. Post-hit grace only applies at max HP >= 2 (HealthComponent).
## Pass the `ds_vigil.hull.max_hp` value (e.g. from a TunableRegistry lookup).
func set_hull_max_hp(max_hp: int) -> void:
	health.set_max_hp(max_hp)


func get_hull_max_hp() -> int:
	return health.max_hp


## Unit vector the Vigil is facing (its aim). Read by the sector camera for lookahead.
func get_aim_dir() -> Vector2:
	return Vector2.from_angle(motor.facing_node.rotation) if motor.facing_node else Vector2.RIGHT


func _on_health_depleted() -> void:
	motor.enabled = false
	velocity = Vector2.ZERO
	hull_breached.emit()
