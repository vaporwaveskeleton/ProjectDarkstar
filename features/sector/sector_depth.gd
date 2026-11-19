class_name SectorDepth
extends Node2D
## The sector's near depth (Q-T163 resolved 2026-11-19; ART-001 §16): drifting glass motes and fog
## wisps at several parallax factors between the Aether far layer and the play layer, so speed and
## space read without the M1 debug grid. Lives on its own CanvasLayer (screen space); the sector
## host feeds it the continuous camera centre (the same one the far layer gets, Q-T127 option B), so
## it never jumps at the torus seam. No collision, no input, no game state. Pal colours only.

@export var style: SectorDepthStyle

## The continuous camera centre (world px), set every frame by the sector host.
var camera_centre := Vector2.ZERO
var time_s := 0.0
## Draw passes so far (tests read it).
var draw_count := 0


func set_camera(centre: Vector2) -> void:
	camera_centre = centre
	queue_redraw()


func _process(delta: float) -> void:
	time_s += delta
	queue_redraw()


## Integer hash of a cell, stable across runs (no RNG state). Returns [0, 1).
static func cell_hash(ix: int, iy: int, layer: int, salt: int) -> float:
	var h := (ix * 73856093) ^ (iy * 19349663) ^ (layer * 83492791) ^ (salt * 2654435761)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(posmod(h, 65536)) / 65536.0


## Screen-space origin of `layer`'s pattern for a camera centre: the pattern moves at `p` × camera.
static func layer_offset(centre: Vector2, p: float, drift: Vector2) -> Vector2:
	return -centre * p + drift


func _reduced_motion() -> bool:
	return bool(SettingsService.get_value(&"reduced_motion"))


func _draw() -> void:
	if style == null:
		return
	draw_count += 1
	var view := get_viewport_rect().size
	var rm := _reduced_motion()
	var drift := Vector2.ZERO if rm else style.drift_px_s * time_s
	for layer in style.layer_count():
		var cell := style.cell_px[layer]
		if cell <= 0.0:
			continue
		var p := style.parallax[layer]
		var off := layer_offset(camera_centre, p, drift * (0.5 + p))
		var r := style.radius_px[layer]
		var c := style.colour[layer]
		var a := style.alpha[layer]
		var ix0 := floori((-off.x - r) / cell)
		var iy0 := floori((-off.y - r) / cell)
		var ix1 := ceili((view.x - off.x + r) / cell)
		var iy1 := ceili((view.y - off.y + r) / cell)
		for iy in range(iy0, iy1 + 1):
			for ix in range(ix0, ix1 + 1):
				var hx := cell_hash(ix, iy, layer, 1)
				var hy := cell_hash(ix, iy, layer, 2)
				var hs := cell_hash(ix, iy, layer, 3)
				var pos := off + Vector2((ix + hx) * cell, (iy + hy) * cell)
				if style.wisp[layer]:
					_draw_wisp(pos, r * (0.6 + 0.8 * hs), c, a)
				else:
					var tw := 1.0
					if not rm and style.twinkle_s > 0.0:
						tw = 0.55 + 0.45 * sin(TAU * (time_s / style.twinkle_s + hs))
					_draw_mote(pos, r * (0.5 + hs), c, a * tw)


func _draw_mote(pos: Vector2, r: float, c: Color, a: float) -> void:
	draw_circle(pos, r * 3.0, Color(c, a * 0.12))
	draw_circle(pos, r * 1.6, Color(c, a * 0.3))
	draw_circle(pos, maxf(0.5, r * 0.6), Color(Pal.BONE_5, a))


func _draw_wisp(pos: Vector2, r: float, c: Color, a: float) -> void:
	# A soft fog lens: stacked low-alpha ellipses, wider than tall (ART-001 §16 slow fog bands).
	draw_set_transform(pos, 0.0, Vector2(1.0, 0.38))
	for k in 7:
		var f := 1.0 - float(k) * 0.13
		draw_circle(Vector2.ZERO, r * f, Color(c, a * 0.14))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
