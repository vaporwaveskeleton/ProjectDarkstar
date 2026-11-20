class_name WarpTeeth
extends Node2D
## W1-05 Teeth in the Rock (WARP-001 §2.2): a geode's rim reads as a ring of teeth. Runtime vector in
## Pal bone colours (ART-001 §14); a drawn child of the geode, so the geode's Hurtbox, faces and mining
## math are untouched (SYS-001 §1.3; WARP-001 §5.1 "Nothing moves a hitbox"). One tooth in the ring is
## missing and one is doubled: symmetry breaks before detail (WARP-001 §5.1).

var radius: float = 10.0
var count: int = 12
var tooth_len: float = 3.0
## 0..1: the Seam depth (WARP-001 §2.2 escalation through a run) times the fade-in.
var strength: float = 1.0:
	set(v):
		strength = clampf(v, 0.0, 1.0)
		queue_redraw()
## Breath scale from W1-02 (1 ± breath_px / radius); purely visual.
var breath_scale: float = 1.0:
	set(v):
		if not is_equal_approx(v, breath_scale):
			breath_scale = v
			queue_redraw()
var seed_value: int = 0


func _draw() -> void:
	if strength <= 0.0 or count <= 0:
		return
	var missing := posmod(seed_value, count)
	var doubled := posmod(seed_value * 7 + 3, count)
	var r := radius * breath_scale
	var gum := Color(Pal.BONE_1, 0.85 * strength)
	var enamel := Color(Pal.BONE_4, strength)
	var tip := Color(Pal.BONE_5, strength)
	for k in count:
		if k == missing:
			continue
		var a := TAU * (float(k) + 0.5) / float(count)
		_tooth(a, r, tooth_len * strength, gum, enamel, tip)
		if k == doubled:
			_tooth(a + TAU / float(count) * 0.38, r, tooth_len * strength * 0.7, gum, enamel, tip)


## One inward-pointing fang on the rim at angle `a`.
func _tooth(a: float, r: float, length: float, gum: Color, enamel: Color, tip: Color) -> void:
	var dir := Vector2.from_angle(a)
	var side := dir.orthogonal() * maxf(1.0, length * 0.42)
	var base := dir * r
	var point := dir * (r - length)
	draw_colored_polygon(PackedVector2Array([base - side, base + side, point]), enamel)
	draw_line(base - side, base + side, gum, 1.0)
	draw_rect(Rect2(point.round() - Vector2(0.5, 0.5), Vector2.ONE), tip)
