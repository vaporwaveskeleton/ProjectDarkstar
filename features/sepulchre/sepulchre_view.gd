class_name SepulchreView
extends Node2D
## Draws its parent Sepulchre (runtime vector, base palette, ART-001 §14; Act 0 / Cabinet shapes
## without Look.c()). Reads only; never owns hit truth. Bone slab of fused vertebrae; the entity's
## will as a black punctum (the only true black is the entity, ART-001 §16); 20 module slots,
## built ones bone; a Choir ring pulse on each deposit (Choir hue, ART-001 role law).

const SLAB := [Vector2(-24, 18), Vector2(24, 18), Vector2(18, 26), Vector2(-18, 26)]   ## px ✱ (Cabinet)
const PUNCTUM_PX := 9.0      ## ✱ (Cabinet)
const SLOT_RING_PX := 20.0   ## ✱ (Cabinet)
const SPIN_BASE := 0.2       ## rad/s ✱ (Cabinet)
const SPIN_PER_SEGMENT := 0.02

@export var sepulchre: Sepulchre

var _rot: float = 0.0


func _process(delta: float) -> void:
	if sepulchre == null:
		return
	_rot += delta * (SPIN_BASE + sepulchre.segments * SPIN_PER_SEGMENT)
	queue_redraw()


func _draw() -> void:
	if sepulchre == null or sepulchre.stats == null:
		return
	var slab := PackedVector2Array()
	for v: Vector2 in SLAB:
		slab.append(v)
	Pal.glow_polyline(self, slab, Pal.BONE_2, Pal.BONE_0)
	draw_circle(Vector2.ZERO, PUNCTUM_PX, Pal.NULL)
	draw_arc(Vector2.ZERO, PUNCTUM_PX, 0.0, TAU, 24, Pal.VOID_5, 1.0)
	var total := sepulchre.stats.segments_total
	for i in total:
		var a := _rot + TAU * i / total
		var q := (Vector2.from_angle(a) * SLOT_RING_PX).round()
		if i < sepulchre.segments:
			draw_rect(Rect2(q - Vector2(1, 1), Vector2(3, 3)), Pal.BONE_4)
		else:
			draw_rect(Rect2(q, Vector2.ONE), Pal.BONE_0)
	if sepulchre.pulse_left > 0.0 and sepulchre.stats.deposit_pulse_s > 0.0:
		var k := 1.0 - sepulchre.pulse_left / sepulchre.stats.deposit_pulse_s
		draw_arc(Vector2.ZERO, lerpf(PUNCTUM_PX, sepulchre.stats.deposit_radius_px, k), 0.0, TAU, 24, Pal.CHOIR_4, 1.0)
