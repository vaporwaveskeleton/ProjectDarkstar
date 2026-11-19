class_name Vigil
extends CharacterBody2D
## The player's ship. A thin root that wires its components; behaviour lives in children:
##   VigilInput (intent) -> VigilMotor (velocity, facing) ; HealthComponent + Hurtbox (hull).
## Collision radius comes from VigilMoveStats, never from the sprite.
## After THE PRETENCE the Vigil flies the Aether handling profile (SYS-001 §1.1a) with the owned
## Lantern Tree handling nodes applied (HandlingTree); `aether_stats.enabled = false` flies Cabinet.

signal hull_breached

## Base Aether handling profile (data/vigil/vigil_aether_move.tres).
@export var aether_stats: VigilAetherStats
## Owned Lantern Tree node ids; `--tree=HULL-1,LANTERN-10` overrides for testers.
@export var tree_nodes: PackedStringArray = PackedStringArray()

@onready var motor: VigilMotor = %VigilMotor
@onready var input: VigilInput = %VigilInput
@onready var health: HealthComponent = %HealthComponent
@onready var hurtbox: HurtboxComponent = %Hurtbox
@onready var emitter: ArcLanceEmitter = %ArcLanceEmitter
## The hull's honest Composure read (WARP-001 §4.2 L10); the sector injects its Composure.
@onready var cockpit_flame: CockpitFlame = %CockpitFlame
@onready var lantern: VigilLantern = %VigilLantern
@onready var rig: AetherVigilRig = %AetherVigilRig

var _was_aether: bool = false


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
	var cli_tree := HandlingTree.parse_args(OS.get_cmdline_user_args())
	if not cli_tree.is_empty():
		tree_nodes = cli_tree
	set_tree_nodes(tree_nodes)


func _physics_process(_delta: float) -> void:
	var aether := motor.aether_active
	if aether != _was_aether:
		_apply_visual_mode(aether)
	if aether:
		rig.set_pose(motor.hull_heading, motor.facing_node.rotation, velocity, motor.last_accel,
			motor.thrust_amount, motor.braking, lantern.is_up, motor.surging)


## Sets the owned Lantern Tree nodes and re-applies the handling readings to the Aether profile.
func set_tree_nodes(ids: PackedStringArray) -> void:
	tree_nodes = ids
	motor.aether_stats = HandlingTree.apply(aether_stats, ids) if aether_stats != null else null
	motor.reset_surge()
	rig.set_modules(ids)
	_apply_visual_mode(motor.aether_active)


## Aether: the brass rig replaces the placeholder hull (the cockpit flame stays). Cabinet: rig hidden.
func _apply_visual_mode(aether: bool) -> void:
	_was_aether = aether
	rig.visible = aether
	var placeholder := get_node_or_null("Facing/Visual/Placeholder") as CanvasItem
	var core := get_node_or_null("Facing/Visual/Core") as CanvasItem
	if placeholder:
		placeholder.visible = not aether
	if core:
		core.visible = not aether


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


## Velocity the sector camera leads by (Aether only; the Cabinet keeps aim lookahead alone).
func get_lead_velocity() -> Vector2:
	return velocity if motor.aether_active else Vector2.ZERO


func _on_health_depleted() -> void:
	motor.enabled = false
	velocity = Vector2.ZERO
	rig.play_breach()
	hull_breached.emit()
