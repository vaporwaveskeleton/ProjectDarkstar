class_name Brass
extends RefCounted
## Victorian brass instrument drawing for the Aether-tier HUD (ART-001 §15 fidelity ladder, §12.5
## brass furniture; TECH-001 §5.4). Static helpers only: a bevelled plate with rivets and an engraved
## inner line, a glass lamp (lit = phosphor, the truth colour; unlit = smoked glass). GAS ramp = brass,
## BONE = chalk/engraving, PHOS = honest reads. Runtime vector, Pal colours only (D-13).

## ✱ Drawing geometry (px), not tunables.
const BEVEL := 1.0
const RIVET_R := 1.2
const RIVET_INSET := 3.0
const CORNER_CUT := 3.0


## A brass plate filling `r`: cut corners, dark rim, lit top bevel, engraved inner line, four rivets.
static func plate(ci: CanvasItem, r: Rect2, inner: Color = Pal.GAS_1) -> void:
	var outline := _cut_rect(r, CORNER_CUT)
	ci.draw_colored_polygon(outline, Pal.GAS_0)
	var body := _cut_rect(r.grow(-BEVEL), CORNER_CUT - 0.5)
	ci.draw_colored_polygon(body, Pal.GAS_2)
	# lit top and left bevel, shadowed bottom and right (light from the upper left, ART-001 §7)
	ci.draw_line(Vector2(r.position.x + CORNER_CUT, r.position.y + 1.0),
		Vector2(r.end.x - CORNER_CUT, r.position.y + 1.0), Pal.GAS_4, 1.0)
	ci.draw_line(Vector2(r.position.x + 1.0, r.position.y + CORNER_CUT),
		Vector2(r.position.x + 1.0, r.end.y - CORNER_CUT), Pal.GAS_3, 1.0)
	ci.draw_line(Vector2(r.position.x + CORNER_CUT, r.end.y - 1.0),
		Vector2(r.end.x - CORNER_CUT, r.end.y - 1.0), Pal.GAS_1, 1.0)
	var face := r.grow(-RIVET_INSET - 2.0)
	if face.size.x > 2.0 and face.size.y > 2.0:
		ci.draw_rect(face, inner, true)
		ci.draw_rect(face.grow(0.5), Pal.GAS_0, false, 1.0)
	for c: Vector2 in [r.position + Vector2(RIVET_INSET, RIVET_INSET),
			Vector2(r.end.x - RIVET_INSET, r.position.y + RIVET_INSET),
			Vector2(r.position.x + RIVET_INSET, r.end.y - RIVET_INSET), r.end - Vector2(RIVET_INSET, RIVET_INSET)]:
		rivet(ci, c)


static func rivet(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_circle(c, RIVET_R + 0.4, Pal.GAS_0)
	ci.draw_circle(c, RIVET_R, Pal.GAS_3)
	ci.draw_circle(c - Vector2(0.4, 0.4), RIVET_R * 0.45, Pal.GAS_5)


## A glass lamp: lit = phosphor (an honest read, ART-001 role law), unlit = smoked glass.
static func lamp(ci: CanvasItem, c: Vector2, r: float, lit: bool) -> void:
	ci.draw_circle(c, r + 1.0, Pal.GAS_0)
	if lit:
		ci.draw_circle(c, r + 2.5, Color(Pal.PHOS_4, 0.18))
		ci.draw_circle(c, r, Pal.PHOS_3)
		ci.draw_circle(c, r * 0.55, Pal.PHOS_5)
	else:
		ci.draw_circle(c, r, Pal.VOID_2)
		ci.draw_circle(c, r * 0.55, Pal.VOID_3)
	ci.draw_circle(c - Vector2(r * 0.35, r * 0.35), maxf(0.5, r * 0.25), Color(Pal.BONE_5, 0.7))


static func _cut_rect(r: Rect2, cut: float) -> PackedVector2Array:
	var k := minf(cut, minf(r.size.x, r.size.y) * 0.5)
	return PackedVector2Array([
		r.position + Vector2(k, 0), Vector2(r.end.x - k, r.position.y), Vector2(r.end.x, r.position.y + k),
		Vector2(r.end.x, r.end.y - k), Vector2(r.end.x - k, r.end.y), Vector2(r.position.x + k, r.end.y),
		Vector2(r.position.x, r.end.y - k), Vector2(r.position.x, r.position.y + k)])
