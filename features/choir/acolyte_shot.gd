class_name AcolyteShot
extends Area2D
## One censer shot (Aether Acolyte): an ember bolt flying straight at `speed_px_s` for `life_s`, then
## gone. It touches the Vigil's hurtbox (layer vigil_hurtbox) and delivers `damage` there; the hull's
## own HealthComponent decides the rest. Lives under the sector's %Actors (SectorWrap re-images it).
## Torus-aware: it wraps with the field.

var direction := Vector2.RIGHT
var speed_px_s := 240.0
var damage := 1
var life_s := 1.5
var age_s := 0.0
var spent := false
var torus: Torus
var source_id := 0
## One attack window per shot, so the hull's one-hit-per-window rule never swallows a second shot.
static var _next_window := 1
var _window := 0


func _ready() -> void:
	collision_layer = PhysicsLayers.bit(PhysicsLayers.CHOIR_SHOTS)
	collision_mask = PhysicsLayers.bit(PhysicsLayers.VIGIL_HURTBOX)
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)
	area_entered.connect(resolve_contact)


## Configure before adding to the tree.
func launch(at: Vector2, dir: Vector2, stats: AcolyteStats, p_torus: Torus, p_source_id: int) -> void:
	position = at
	direction = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	speed_px_s = stats.shot_speed_px_s
	damage = stats.shot_damage
	life_s = stats.shot_life_s
	torus = p_torus
	source_id = p_source_id
	_window = _next_window
	_next_window += 1


func _physics_process(delta: float) -> void:
	advance(delta)


## One tick. Public so tests drive it.
func advance(delta: float) -> void:
	if spent:
		return
	age_s += delta
	global_position += direction * speed_px_s * delta
	if torus != null:
		global_position = torus.wrap(global_position)
	if age_s >= life_s - 0.0001:
		_spend()
	queue_redraw()


## Touching `area`: a hurtbox takes the hit and the shot is spent.
func resolve_contact(area: Area2D) -> void:
	if spent or not (area is HurtboxComponent):
		return
	(area as HurtboxComponent).receive_hit(HitInfo.make(damage, source_id, _window, &"censer_shot"))
	_spend()


func _spend() -> void:
	spent = true
	set_deferred("monitoring", false)
	visible = false
	queue_free()


## CHOIR_4 ember bolt with a short CHOIR_1 trail (no flash).
func _draw() -> void:
	if spent:
		return
	draw_line(Vector2.ZERO, -direction * 8.0, Pal.CHOIR_1, 2.0)
	draw_line(Vector2.ZERO, -direction * 4.0, Pal.CHOIR_3, 1.0)
	draw_circle(Vector2.ZERO, 3.0, Color(Pal.CHOIR_4, 0.35))
	draw_circle(Vector2.ZERO, 1.6, Pal.CHOIR_4)
