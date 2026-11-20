class_name SectorDarkness
extends Node
## The dark kit look (PM-02; TECH-001 §2.9; ART-001 §16.6l): real 2D lighting on the play canvas only.
## A CanvasModulate takes the play layer (canvas layer 0) down to the kit's VOID-tinted ambient (never
## black), and a pool of PointLight2D discs lifts back what is self-lit: geodes, loose glass, the
## Vigil's lantern, the Acolyte's ember, the light pocket. A CanvasModulate tints only its own canvas,
## so the far layer (layer -10), the near depth (-5), the foreground (2) and the HUD (5) are never
## dimmed (2026-11-20 fix: the first build multiplied a veil over every layer below it, which crushed
## the lantern-down Presence to near-black and drew a hard-edged band). A kit with `dark_default`
## false builds nothing. Reads only; the sector injects every source. No RNG, no signals.

const MAX_LIT := 32
const GEODE_R := 22.0
const SHARD_R := 12.0
const EMBER_R := 26.0
## The lantern's disc: its far-look radius up, this when down; strength up / down.
const LANTERN_DOWN_R := 30.0
const LANTERN_UP_S := 0.9
const LANTERN_DOWN_S := 0.55
## Light texture: a soft disc, full inside 30% of the radius, fading to 0 at the rim.
const TEX_PX := 128

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

var _modulate: CanvasModulate
var _lights: Array[PointLight2D] = []
var _pool: Node2D
var _lift := 0.5
## The lit discs of the last update: Vector4(screen x, screen y, radius, strength).
var discs := PackedVector4Array()
## World positions of the same discs (near the camera, torus-unwrapped), for the lights.
var disc_world := PackedVector2Array()


## Applies `p_kit`: builds the ambient and lights when it is dark, tears them down otherwise.
func apply_kit(p_kit: SectorKit) -> void:
	kit = p_kit
	_teardown()
	active = kit != null and kit.dark_default
	if not active:
		return
	_modulate = CanvasModulate.new()
	_modulate.name = "DarkAmbient"
	_modulate.color = kit.dark_ambient
	add_child(_modulate)
	# how far a strength-1 light lifts the ambient back to full brightness
	_lift = clampf(1.0 - minf(kit.dark_ambient.r, minf(kit.dark_ambient.g, kit.dark_ambient.b)), 0.1, 1.0)
	var tex := _disc_texture()
	for i in MAX_LIT:
		var l := PointLight2D.new()
		l.name = "Lit%d" % i
		l.texture = tex
		l.blend_mode = Light2D.BLEND_MODE_ADD
		l.shadow_enabled = false
		l.enabled = false
		add_child(l)
		_lights.append(l)
	_pool = _PoolView.new()
	_pool.name = "LightPool"
	_pool.z_index = -1
	(_pool as _PoolView).radius = kit.light_pocket_radius_px
	add_child(_pool)
	update_veil()


static func _disc_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = TEX_PX
	t.height = TEX_PX
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _teardown() -> void:
	for n: Node in [_modulate, _pool]:
		if is_instance_valid(n):
			n.queue_free()
	for l in _lights:
		if is_instance_valid(l):
			l.queue_free()
	_lights.clear()
	_modulate = null
	_pool = null
	discs = PackedVector4Array()
	disc_world = PackedVector2Array()


func _process(_delta: float) -> void:
	update_veil()


## Gathers the lit discs and places the lights. Public so tests drive it.
func update_veil() -> void:
	if not active or camera == null or torus == null or _modulate == null:
		return
	var view := camera.get_viewport_rect().size
	var centre := camera.get_screen_center_position()
	var z := camera.zoom.x
	discs = PackedVector4Array()
	disc_world = PackedVector2Array()
	_disc(centre, z, view, kit.light_pocket_pos, kit.light_pocket_radius_px, 1.0)
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
	for i in _lights.size():
		var l := _lights[i]
		if i < discs.size():
			l.enabled = true
			l.global_position = disc_world[i]
			l.texture_scale = discs[i].z / z * 2.0 / float(TEX_PX)
			l.energy = discs[i].w * _lift
		else:
			l.enabled = false
	if _pool != null:
		_pool.global_position = centre + torus.delta(centre, kit.light_pocket_pos)


func _disc(centre: Vector2, z: float, view: Vector2, world: Vector2, radius: float, strength: float) -> void:
	if discs.size() >= MAX_LIT:
		return
	var near := centre + torus.delta(centre, world)
	var s := (near - centre) * z + view * 0.5
	if s.x < -radius * z or s.y < -radius * z or s.x > view.x + radius * z or s.y > view.y + radius * z:
		return
	discs.append(Vector4(s.x, s.y, radius * z, strength))
	disc_world.append(near)


## The cold pool at the light pocket: PHOS_2 / PHOS_3 soft rings (a spill of honest light).
class _PoolView extends Node2D:
	var radius := 110.0

	func _draw() -> void:
		for i in 6:
			var f := float(6 - i) / 6.0
			draw_circle(Vector2.ZERO, radius * f, Color(Pal.PHOS_2, 0.07))
		draw_circle(Vector2.ZERO, radius * 0.35, Color(Pal.PHOS_3, 0.08))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(Pal.PHOS_2, 0.25), 1.0)
