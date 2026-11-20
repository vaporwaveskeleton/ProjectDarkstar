class_name SectorDarkness
extends Node
## The dark kit look (PM-02; TECH-001 §2.9): a multiply veil over the play layer, never black, with
## soft lit discs where things are self-lit (geodes, loose glass, the Vigil's lantern, the Acolyte's
## ember, the light pocket), a darker unlit corridor, and a cold PHOS pool drawn at the light pocket.
## The veil is a ColorRect on a CanvasLayer between the play layer (0) and the depth front (2), so the
## HUD and the far layer are never dimmed. A kit with `dark_default` false builds nothing.
## Reads only; the sector injects every source. No RNG, no signals.

const SHADER := preload("res://shaders/dark_veil.gdshader")
const LAYER := 1
const MAX_LIT := 32
const GEODE_R := 22.0
const SHARD_R := 12.0
const EMBER_R := 26.0
## The lantern's disc: its far-look radius up, this when down; strength up / down.
const LANTERN_DOWN_R := 30.0
const LANTERN_UP_S := 0.9
const LANTERN_DOWN_S := 0.55

var torus: Torus
var camera: Camera2D
var vigil: Node2D
var lantern: VigilLantern
var geodes: GeodeSandbox
var shards: ShardField
var acolytes: Array = []
## The lantern's light radius when up (px), from the far look.
var lantern_radius_px := 120.0

var kit: SectorKit
var active := false

var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial
var _pool: Node2D
## The lit discs of the last update: Vector4(screen x, screen y, radius, strength).
var discs := PackedVector4Array()


## Applies `p_kit`: builds the veil and pool when it is dark, tears them down otherwise.
func apply_kit(p_kit: SectorKit) -> void:
	kit = p_kit
	_teardown()
	active = kit != null and kit.dark_default
	if not active:
		return
	_layer = CanvasLayer.new()
	_layer.name = "DarkVeilLayer"
	_layer.layer = LAYER
	_rect = ColorRect.new()
	_rect.name = "DarkVeil"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter(&"ambient", kit.dark_ambient)
	_rect.material = _mat
	_layer.add_child(_rect)
	add_child(_layer)
	_pool = _PoolView.new()
	_pool.name = "LightPool"
	_pool.z_index = -1
	(_pool as _PoolView).radius = kit.light_pocket_radius_px
	add_child(_pool)
	update_veil()


func _teardown() -> void:
	for n: Node in [_layer, _pool]:
		if is_instance_valid(n):
			n.queue_free()
	_layer = null
	_pool = null
	_rect = null
	_mat = null
	discs = PackedVector4Array()


func _process(_delta: float) -> void:
	update_veil()


## Gathers the lit discs and pushes them to the shader. Public so tests drive it.
func update_veil() -> void:
	if not active or camera == null or torus == null or _mat == null:
		return
	var view := camera.get_viewport_rect().size
	_rect.size = view
	var centre := camera.get_screen_center_position()
	var z := camera.zoom.x
	discs = PackedVector4Array()
	_disc(centre, z, view, centre + torus.delta(centre, kit.light_pocket_pos), kit.light_pocket_radius_px, 1.0)
	if is_instance_valid(vigil):
		var up := lantern == null or lantern.is_up
		_disc(centre, z, view, vigil.global_position, lantern_radius_px if up else LANTERN_DOWN_R,
			LANTERN_UP_S if up else LANTERN_DOWN_S)
	if geodes != null:
		for g in geodes.geodes:
			if is_instance_valid(g) and g.alive:
				_disc(centre, z, view, g.home, GEODE_R, 1.0)
	if shards != null:
		for i in shards.live_indices():
			_disc(centre, z, view, shards.positions[i], SHARD_R, 1.0)
	for a: AetherAcolyte in acolytes:
		if is_instance_valid(a) and not a.dead:
			_disc(centre, z, view, a.global_position + a.view.censer_pos(), EMBER_R, 1.0)
	_mat.set_shader_parameter(&"lit_count", discs.size())
	var padded := discs.duplicate()
	padded.resize(MAX_LIT)
	_mat.set_shader_parameter(&"lit", padded)
	var c := kit.unlit_corridor
	if c.size != Vector2.ZERO:
		var mid := centre + torus.delta(centre, c.get_center())
		var top := (mid.y - c.size.y * 0.5 - centre.y) * z + view.y * 0.5
		var bottom := (mid.y + c.size.y * 0.5 - centre.y) * z + view.y * 0.5
		_mat.set_shader_parameter(&"corridor", Vector3(top, bottom, kit.corridor_dim))
	else:
		_mat.set_shader_parameter(&"corridor", Vector3(0, 0, 1))
	if _pool != null:
		_pool.global_position = centre + torus.delta(centre, kit.light_pocket_pos)


func _disc(centre: Vector2, z: float, view: Vector2, world: Vector2, radius: float, strength: float) -> void:
	if discs.size() >= MAX_LIT:
		return
	var s := torus.delta(centre, world) * z + view * 0.5
	if s.x < -radius * z or s.y < -radius * z or s.x > view.x + radius * z or s.y > view.y + radius * z:
		return
	discs.append(Vector4(s.x, s.y, radius * z, strength))


## The cold pool at the light pocket: PHOS_2 / PHOS_3 soft rings (a spill of honest light).
class _PoolView extends Node2D:
	var radius := 110.0

	func _draw() -> void:
		for i in 6:
			var f := float(6 - i) / 6.0
			draw_circle(Vector2.ZERO, radius * f, Color(Pal.PHOS_2, 0.07))
		draw_circle(Vector2.ZERO, radius * 0.35, Color(Pal.PHOS_3, 0.08))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(Pal.PHOS_2, 0.25), 1.0)
