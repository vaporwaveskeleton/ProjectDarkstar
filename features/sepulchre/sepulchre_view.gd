class_name SepulchreView
extends Node2D
## Draws its parent Sepulchre (runtime vector, Aether tier, ART-001 §15). Reads only; never owns
## hit truth. Filled bone slab of fused vertebrae with a brass ornament ring, a faint Choir halo,
## the entity's will as a black punctum (the only true black is the entity, ART-001 §16); 20
## module slots (segment plates), built ones bone-lit; a Choir ring pulse on each deposit.

const SLAB := [Vector2(-24, 18), Vector2(24, 18), Vector2(18, 26), Vector2(-18, 26)]   ## px ✱ (Cabinet)
const PUNCTUM_PX := 9.0      ## ✱ (Cabinet)
const SLOT_RING_PX := 20.0   ## ✱ (Cabinet)
const SPIN_BASE := 0.2       ## rad/s ✱ (Cabinet)
const SPIN_PER_SEGMENT := 0.02
const HALO_RINGS := 4            ## ✱ drawing
const HALO_RADIUS_PX := 34.0     ## ✱ drawing: outermost halo ring
const HALO_ALPHA := 0.05         ## ✱ drawing: per-ring opacity
const BODY_FILL_ALPHA := 0.6     ## ✱ drawing: disc and slab fill opacity
const ORNAMENT_RING_PX := 14.0   ## ✱ drawing: brass ring radius
const ORNAMENT_STUDS := 8        ## ✱ drawing: brass studs on the ring
const PLATE_PX := 3.0            ## ✱ drawing: segment plate size

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
	for r in HALO_RINGS:
		draw_circle(Vector2.ZERO, HALO_RADIUS_PX * float(r + 1) / HALO_RINGS, Color(Pal.CHOIR_2, HALO_ALPHA))
	var slab := PackedVector2Array()
	for v: Vector2 in SLAB:
		slab.append(v)
	draw_colored_polygon(slab, Color(Pal.BONE_1, BODY_FILL_ALPHA))
	Pal.glow_polyline(self, slab, Pal.BONE_3, Pal.BONE_0)
	draw_circle(Vector2.ZERO, SLOT_RING_PX + 3.0, Color(Pal.BONE_0, BODY_FILL_ALPHA))
	draw_arc(Vector2.ZERO, SLOT_RING_PX + 3.0, 0.0, TAU, 32, Pal.BONE_2, 1.0)
	# brass ornament ring with studs
	draw_arc(Vector2.ZERO, ORNAMENT_RING_PX, 0.0, TAU, 32, Pal.GAS_2, 1.0)
	for i in ORNAMENT_STUDS:
		var sq := (Vector2.from_angle(-_rot * 0.5 + TAU * i / ORNAMENT_STUDS) * ORNAMENT_RING_PX).round()
		draw_rect(Rect2(sq - Vector2.ONE, Vector2(2, 2)), Pal.GAS_3)
	draw_circle(Vector2.ZERO, PUNCTUM_PX, Pal.NULL)
	draw_arc(Vector2.ZERO, PUNCTUM_PX, 0.0, TAU, 24, Pal.VOID_5, 1.0)
	var total := sepulchre.stats.segments_total
	for i in total:
		var a := _rot + TAU * i / total
		var q := (Vector2.from_angle(a) * SLOT_RING_PX).round()
		var plate := Rect2(q - Vector2.ONE * (PLATE_PX * 0.5), Vector2.ONE * PLATE_PX)
		if i < sepulchre.segments:
			draw_rect(plate, Pal.BONE_4)
			draw_rect(plate, Pal.BONE_2, false, 1.0)
		else:
			draw_rect(plate, Color(Pal.BONE_0, 0.8))
	if sepulchre.pulse_left > 0.0 and sepulchre.stats.deposit_pulse_s > 0.0:
		var k := 1.0 - sepulchre.pulse_left / sepulchre.stats.deposit_pulse_s
		draw_arc(Vector2.ZERO, lerpf(PUNCTUM_PX, sepulchre.stats.deposit_radius_px, k), 0.0, TAU, 24, Pal.CHOIR_4, 1.0)
