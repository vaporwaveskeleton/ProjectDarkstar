class_name LastLamp
extends LanternMarker
## The first Unmaking's last light (beat 6, route &"aether"): a stand-in, NOT the Vigil scene (M1
## owns that). A small brass-and-glass lantern standing on the faint outline of an unlit hull, drifting.
## It is the last coloured thing the erasure front reaches: its hull hint is eaten first, then the
## lamp dims slowly (no flash), then one phosphor ember of it fades across the black (PHOS: the
## afterglow is the truth that something was lit). Keeps LanternMarker's warm PointLight2D (the key
## light, GAS only here, ART-001 §4) and scales it with `light_amount`. Draws nothing black: over
## the entity's mass it fades by alpha. Every size here is ✱ (logical px).

## ✱ the lantern stands this far above the hull's centre line.
const LANTERN_LIFT := 5.0

## 0 = out … 1 = lit.
var light_amount: float = 1.0
## 0 … 1: the unlit hull outline's alpha.
var hull_alpha: float = 1.0
## 0 … 1: the phosphor ember's alpha (after the lamp is out).
var ember_alpha: float = 0.0
var brass: Color = Pal.BONE_2


func configure(look: AetherLook) -> void:
	brass = look.brass
	super.configure(look)


## Push the beat-6 state (UnmakingTimeline.lamp_light / hull_alpha / ember).
func set_state(light_v: float, hull_v: float, ember_v: float) -> void:
	light_amount = clampf(light_v, 0.0, 1.0)
	hull_alpha = clampf(hull_v, 0.0, 1.0)
	ember_alpha = clampf(ember_v, 0.0, 1.0)
	lit = light_amount > 0.001
	apply()


func apply() -> void:
	super.apply()
	if light != null:
		light.energy = energy * light_amount


## The glass's centre in this node's space (where the light and the ember sit).
func glass_centre() -> Vector2:
	return Vector2(0.0, -LANTERN_LIFT)


func _draw() -> void:
	var y := sin(_t * TAU / BOB_S) * BOB_PX
	var o := Vector2(0.0, y)
	# the hull hint: an unlit leaf of a hull seen from above, a broken cold outline (no fill, no light)
	if hull_alpha > 0.001:
		var c := Pal.VOID_5
		c.a = 0.6 * hull_alpha
		var pts := PackedVector2Array([o + Vector2(-19, 1), o + Vector2(-11, -4), o + Vector2(8, -4),
			o + Vector2(20, 1), o + Vector2(10, 6), o + Vector2(-9, 6.5)])
		for i in pts.size():
			if i == 2:
				continue   # a gap: a hint, not a drawn shape
			draw_line(pts[i], pts[(i + 1) % pts.size()], c, 1.0, true)
		var keel := Pal.VOID_4
		keel.a = 0.45 * hull_alpha
		draw_line(o + Vector2(-13, 1.5), o + Vector2(-2, 1.5), keel, 1.0, true)
		draw_line(o + Vector2(5, 1.5), o + Vector2(14, 1.5), keel, 1.0, true)
	var g := o + glass_centre()
	var la := light_amount
	if la > 0.001:
		# the lantern: base plate, glass body with its flame, brass uprights, a peaked cap and a ring
		var b := brass
		b.a = smoothstep(0.0, 0.6, la)
		var glass := Pal.GAS_2.lerp(Pal.GAS_3, 0.4)
		glass.a = la
		draw_rect(Rect2(g + Vector2(-3.0, -3.5), Vector2(6.0, 7.0)), glass)
		var inner := Pal.GAS_4
		inner.a = la
		draw_rect(Rect2(g + Vector2(-2.0, -2.5), Vector2(4.0, 5.0)), inner)
		var core := Pal.GAS_5 * lerpf(1.0, CORE_HDR, la)
		core.a = la
		draw_circle(g + Vector2(0.0, 0.3), 1.3, core)
		draw_rect(Rect2(g + Vector2(-4.0, 3.5), Vector2(8.0, 1.5)), b)
		draw_line(g + Vector2(-3.5, -3.5), g + Vector2(-3.5, 3.5), b, 1.0, true)
		draw_line(g + Vector2(3.5, -3.5), g + Vector2(3.5, 3.5), b, 1.0, true)
		draw_colored_polygon(PackedVector2Array([g + Vector2(-4.5, -3.5), g + Vector2(4.5, -3.5), g + Vector2(0.0, -7.5)]), b)
		draw_arc(g + Vector2(0.0, -9.0), 1.6, 0.0, TAU, 10, b, 1.0, true)
	if ember_alpha > 0.001:
		# the afterglow: one phosphor ember where the flame was, and a faint halo
		var halo := Pal.PHOS_2
		halo.a = 0.35 * ember_alpha
		draw_circle(g + Vector2(0.0, 0.3), 2.6, halo)
		var ember := Pal.PHOS_4
		ember.a = ember_alpha
		draw_circle(g + Vector2(0.0, 0.3), 1.1, ember)
