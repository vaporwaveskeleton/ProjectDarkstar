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
	_ensure_textures()
	var view := get_viewport_rect().size
	var rm := _reduced_motion()
	var drift := Vector2.ZERO if rm else style.drift_px_s * time_s
	# Perf (Q-T248, 2026-11-19): one textured quad per wisp or mote halo, all sharing two generated
	# radial textures, so the canvas batches them; mote cores go in a second batched pass (a round dot).
	# The old path tessellated 3–7 alpha circles per item every frame (≈ 6 ms on a 4070).
	var cores: Array[Rect2] = []
	var core_cols: Array[Color] = []
	for layer in style.layer_count():
		var cell := style.cell_px[layer]
		if cell <= 0.0:
			continue
		var p := style.parallax[layer]
		var off := layer_offset(camera_centre, p, drift * (0.5 + p))
		var r := style.radius_px[layer]
		var c := style.colour[layer]
		var a := style.alpha[layer]
		var is_wisp := style.wisp[layer]
		var reach := r * (1.4 if is_wisp else 4.5)
		var ix0 := floori((-off.x - reach) / cell)
		var iy0 := floori((-off.y - reach) / cell)
		var ix1 := ceili((view.x - off.x + reach) / cell)
		var iy1 := ceili((view.y - off.y + reach) / cell)
		for iy in range(iy0, iy1 + 1):
			for ix in range(ix0, ix1 + 1):
				var hx := cell_hash(ix, iy, layer, 1)
				var hy := cell_hash(ix, iy, layer, 2)
				var hs := cell_hash(ix, iy, layer, 3)
				var pos := off + Vector2((ix + hx) * cell, (iy + hy) * cell)
				if is_wisp:
					# a soft fog lens, wider than tall (ART-001 §16 slow fog bands)
					var rw := r * (0.6 + 0.8 * hs)
					var ext := Vector2(rw, rw * WISP_SQUASH)
					draw_texture_rect(_wisp_tex, Rect2(pos - ext, ext * 2.0), false, Color(c, a * WISP_PEAK))
				else:
					var tw := 1.0
					if not rm and style.twinkle_s > 0.0:
						tw = 0.55 + 0.45 * sin(TAU * (time_s / style.twinkle_s + hs))
					var rm_px := r * (0.5 + hs)
					var halo := rm_px * 3.0
					draw_texture_rect(_mote_tex, Rect2(pos - Vector2(halo, halo), Vector2(halo, halo) * 2.0), false,
						Color(c, a * tw))
					var core := maxf(2.0, rm_px * 1.6)
					cores.append(Rect2(pos - Vector2(core, core) * 0.5, Vector2(core, core)))
					core_cols.append(Color(Pal.BONE_5, a * tw))
	for k in cores.size():
		draw_texture_rect(_dot_tex, cores[k], false, core_cols[k])


## ✱ Fog lens height over width, and its centre alpha share (matches the old 7-circle stack).
const WISP_SQUASH := 0.38
const WISP_PEAK := 0.65
## ✱ Generated texture size (px). Runtime GradientTexture2D, no image files (D-13).
const TEX_PX := 64

static var _wisp_tex: GradientTexture2D
static var _mote_tex: GradientTexture2D
static var _dot_tex: GradientTexture2D


static func _radial(offsets: PackedFloat32Array, alphas: PackedFloat32Array) -> GradientTexture2D:
	var g := Gradient.new()
	var cols := PackedColorArray()
	for al in alphas:
		cols.append(Color(1, 1, 1, al))
	g.offsets = offsets
	g.colors = cols
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = TEX_PX
	t.height = TEX_PX
	return t


static func _ensure_textures() -> void:
	if _wisp_tex == null:
		_wisp_tex = _radial(PackedFloat32Array([0.0, 0.45, 1.0]), PackedFloat32Array([1.0, 0.55, 0.0]))
	if _mote_tex == null:
		# halo profile of the old stack: 0.42 inside 1.6 r, 0.12 out to 3 r (radius 3 r = texture edge)
		_mote_tex = _radial(PackedFloat32Array([0.0, 0.5, 0.56, 1.0]), PackedFloat32Array([0.42, 0.3, 0.12, 0.0]))
	if _dot_tex == null:
		_dot_tex = _radial(PackedFloat32Array([0.0, 0.55, 0.85, 1.0]), PackedFloat32Array([1.0, 1.0, 0.35, 0.0]))
