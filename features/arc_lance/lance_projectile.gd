class_name LanceProjectile
extends Area2D
## One Arc-Lance shot. Flies straight along +x of its rotation, expires at its lifetime,
## and is spent after `hits_per_projectile` hits. Hit truth lives here, never in the visual.

signal lance_hit(target: Node)

var stats: ArcLanceStats
var direction: Vector2 = Vector2.RIGHT
var age_s: float = 0.0
var hits_left: int = 1
var source_id: int = 0
var _spent: bool = false

@onready var _shape: CollisionShape2D = %LanceShape


func _ready() -> void:
	collision_layer = PhysicsLayers.bit(PhysicsLayers.VIGIL_SHOTS)
	collision_mask = PhysicsLayers.mask([PhysicsLayers.WORLD, PhysicsLayers.CHOIR_HURTBOX])
	monitorable = false
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_apply_shape()


## Configure before adding to the tree (or right after). `dir` need not be normalised.
func launch(p_stats: ArcLanceStats, p_pos: Vector2, dir: Vector2, p_source_id: int = 0) -> void:
	stats = p_stats
	direction = dir.normalized()
	global_position = p_pos
	rotation = direction.angle()
	hits_left = stats.hits_per_projectile
	source_id = p_source_id
	if is_node_ready():
		_apply_shape()
	queue_redraw()


func is_spent() -> bool:
	return _spent


func _physics_process(delta: float) -> void:
	advance(delta)


## Deterministic step (also called by tests). Returns false once the shot is gone.
func advance(delta: float) -> bool:
	if _spent or stats == null:
		return false
	position += direction * stats.projectile_speed * delta
	age_s += delta
	if age_s >= stats.lifetime_s - 0.0001:
		_finish()
		return false
	return true


## True when the lance can hurt `target`: any hurtbox unless it sets `bites = false`.
static func can_bite(target: Node) -> bool:
	return not (target is HurtboxComponent) or (target as HurtboxComponent).bites


## Apply one hit to `target`. Biting hurtboxes take damage; non-biting hurtboxes (Sepulchre,
## entity) and walls just absorb the shot.
func register_hit(target: Node) -> bool:
	if _spent:
		return false
	if target is HurtboxComponent and can_bite(target):
		(target as HurtboxComponent).receive_hit(HitInfo.make(stats.damage, source_id, get_instance_id(), &"arc_lance"))
	hits_left -= 1
	lance_hit.emit(target)
	if hits_left <= 0:
		_finish()
	return true


func _on_area_entered(area: Area2D) -> void:
	register_hit(area)


func _on_body_entered(body: Node2D) -> void:
	register_hit(body)


func _finish() -> void:
	_spent = true
	set_deferred("monitoring", false)
	queue_free()


func _apply_shape() -> void:
	if stats and _shape and _shape.shape is RectangleShape2D:
		(_shape.shape as RectangleShape2D).size = Vector2(stats.visual_length_px, 3.0)
		_shape.position = Vector2(stats.visual_length_px * 0.5, 0.0)


func _draw() -> void:
	var len_px: float = stats.visual_length_px if stats else 14.0
	draw_line(Vector2.ZERO, Vector2(len_px, 0.0), Pal.GAS_4, 2.0)
	draw_line(Vector2(len_px * 0.3, 0.0), Vector2(len_px, 0.0), Pal.GAS_5, 1.0)
