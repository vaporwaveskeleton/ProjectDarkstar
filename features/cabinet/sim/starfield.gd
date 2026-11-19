class_name Starfield
extends ArcadeLayer
## Three parallax star layers plus the chalk seam of the torus (WARP-001 W0-09 "Honest Seam").
## `pull` > 0 drags every star toward a point: the Unmaking eats the sky (W0-07, the reveal).
## S8 (THE LAST NORMAL DAY only, `CabinetStage.spine_stars`): 20 extra faint stars trace the entity's
## spine as an S-curved column. When the reveal's pull begins they brighten and hold, then travel to
## the maw's 20 vertebrae and vanish as each one is shown: the stars become the vertebrae.

const LAYERS := [
	{"count": 90, "parallax": 0.25, "color": Pal.VOID_4},
	{"count": 60, "parallax": 0.5, "color": Pal.VOID_5},
	{"count": 30, "parallax": 0.8, "color": Pal.BONE_2},
]

const SPINE_COUNT := 20            ## one star per vertebra (MawView.SEGMENTS)
const SPINE_PARALLAX := 0.8        ## ✱ the far layer's parallax and look
const SPINE_X_FRAC := 0.7          ## ✱ column centre, fraction of the star tile width
const SPINE_TOP_FRAC := 0.15       ## ✱ first star, fraction of the tile height
const SPINE_LENGTH_FRAC := 0.7     ## ✱ column length, fraction of the tile height
const SPINE_SWAY_PX := 14.0        ## ✱ half-width of the S curve
const SPINE_WAVES := 1.0           ## ✱ full sine periods along the column (1 = a gentle S)

var _stars: Array[PackedVector2Array] = []
var _spine: PackedVector2Array = PackedVector2Array()   ## tile-space spine star positions (formula, no RNG)
var pull := 0.0                      ## 0..1, set by the reveal
var pull_target := Vector2.ZERO    ## screen point the sky drains into (the play view centre, set in reset)
var desaturate := 0.0                ## 0..1, T0→T1 costume removal (W0-08)
var show_seams := true
var spine_stars := false             ## S8: set from the stage in reset()
var maw: MawView                     ## wired by CabinetGame: the live vertebra positions and reveal


func reset() -> void:
	_stars.clear()
	_spine = PackedVector2Array()
	pull_target = world.screen_centre
	spine_stars = world.stage != null and world.stage.spine_stars
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for layer in LAYERS:
		var pts := PackedVector2Array()
		for i in int(layer.count):
			pts.append(Vector2(r.randf() * world.view_size.x, r.randf() * world.view_size.y))
		_stars.append(pts)
	if spine_stars:
		for i in SPINE_COUNT:
			var u := float(i) / (SPINE_COUNT - 1)
			_spine.append(Vector2(
				world.view_size.x * SPINE_X_FRAC + SPINE_SWAY_PX * sin(u * TAU * SPINE_WAVES),
				world.view_size.y * (SPINE_TOP_FRAC + SPINE_LENGTH_FRAC * u)))


## Where a tile-space star sits on screen for a parallax factor (no pull).
func _tile_pos(s: Vector2, par: float) -> Vector2:
	var off := -world.view_centre * par
	var tile := world.view_size
	return world.view_rect.position + Vector2(fposmod(s.x + off.x, tile.x), fposmod(s.y + off.y, tile.y))


func spine_star_count() -> int:
	return _spine.size()


## k: 0 while the spine holds, then 0..1 as the stars travel to the vertebrae.
func spine_travel() -> float:
	var ft := world.fx_tuning
	return clampf((pull - ft.spine_hold_pull) / ft.spine_pull_span, 0.0, 1.0)


## Has the maw shown vertebra `i` yet? Then the star has become it.
func spine_star_hidden(i: int) -> bool:
	return maw != null and i < ceili(clampf(maw.reveal, 0.0, 1.0) * MawView.SEGMENTS)


func spine_star_pos(i: int) -> Vector2:
	var p := _tile_pos(_spine[i], SPINE_PARALLAX)
	if pull > 0.0 and maw != null:
		p = p.lerp(maw.vertebra_screen_pos(i), spine_travel())
	return p


## BONE_2 in play (the far layer's look, never highlighted); BONE_5 once the pull begins.
func spine_star_color() -> Color:
	if pull > 0.0:
		return Look.c(Pal.BONE_5)
	var col := Look.c(Pal.BONE_2)
	if desaturate > 0.0:
		col = col.lerp(Look.c(Pal.BONE_1), desaturate * 0.6)
	return col


func _draw() -> void:
	if world == null or world.torus == null:
		return
	var tile := world.view_size
	var origin := world.view_rect.position
	for li in LAYERS.size():
		var layer: Dictionary = LAYERS[li]
		var par: float = layer.parallax
		var col: Color = Look.c(layer.color as Color)
		if desaturate > 0.0:
			col = col.lerp(Look.c(Pal.BONE_1), desaturate * 0.6)
		var off := -world.view_centre * par
		for i in _stars[li].size():
			var s: Vector2 = _stars[li][i]
			var p := origin + Vector2(fposmod(s.x + off.x, tile.x), fposmod(s.y + off.y, tile.y))
			if pull > 0.0:
				p = p.lerp(pull_target, clampf(pull * (1.0 + par), 0.0, 1.0))
			var twinkle := (i * 7 + int(world.time * 3.0)) % 23 == 0
			draw_rect(Rect2(p.round(), Vector2.ONE), Look.c(Pal.BONE_5) if twinkle else col)
	for i in _spine.size():
		if not spine_star_hidden(i):
			draw_rect(Rect2(spine_star_pos(i).round(), Vector2.ONE), spine_star_color())
	if show_seams and pull <= 0.0:
		_draw_seams()


## The field's edges, drawn as dashed chalk where they cross the screen.
func _draw_seams() -> void:
	var size := world.torus.size
	var origin := world.to_screen(Vector2.ZERO)
	var view := world.view_rect
	for kx in [-1, 0, 1]:
		var x: float = origin.x + kx * size.x
		if x >= view.position.x and x <= view.end.x:
			for y in range(int(view.position.y), int(view.end.y), 8):
				draw_line(Vector2(x, y), Vector2(x, y + 3), Look.c(Pal.BONE_0))
	for ky in [-1, 0, 1]:
		var y: float = origin.y + ky * size.y
		if y >= view.position.y and y <= view.end.y:
			for x in range(int(view.position.x), int(view.end.x), 8):
				draw_line(Vector2(x, y), Vector2(x + 3, y), Look.c(Pal.BONE_0))
