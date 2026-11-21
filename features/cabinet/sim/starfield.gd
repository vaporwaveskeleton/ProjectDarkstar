class_name Starfield
extends ArcadeLayer
## Three parallax star layers plus the chalk seam of the torus (WARP-001 W0-09 "Honest Seam").
## `pull` > 0 drags every star toward a point: the Unmaking eats the sky (W0-07, the reveal).
## S8 (THE LAST NORMAL DAY only, `CabinetStage.spine_stars`): 20 extra faint stars trace the entity's
## spine along the SAME curve the S2 impact frame draws (MawView.spine_points). When the reveal's pull begins they brighten and hold, then travel to
## the maw's 20 vertebrae and vanish as each one is shown: the stars become the vertebrae.

const LAYERS := [
	{"count": 90, "parallax": 0.25, "color": Pal.VOID_4},
	{"count": 60, "parallax": 0.5, "color": Pal.VOID_5},
	{"count": 30, "parallax": 0.8, "color": Pal.BONE_2},
]

const SPINE_COUNT := 20            ## vertebrae (MawView.SEGMENTS)
const SPINE_STARS := 40            ## two stars per vertebra, straddling the curve (S2 silhouette width)
const SPINE_PARALLAX := 0.8        ## ✱ the far layer's parallax and look
const SPINE_X_FRAC := 0.7          ## ✱ column centre, fraction of the star tile width
const SPINE_TOP_FRAC := 0.15       ## ✱ first star, fraction of the tile height
const SPINE_LENGTH_FRAC := 0.7     ## ✱ column length, fraction of the tile height

## Stage signatures (CabinetStage.backdrop; PM under owner autonomy grant, 2026-11-19): a dim VOID
## motif behind the stars so a still says which stage it is. VOID registers only (never a faction
## hue, so it never reads as a hazard), formula-placed (no RNG), clipped to the playfield.
const BACKDROPS := [&"", &"currents", &"chains", &"shoal", &"horizon"]
const CURRENT_LINES := 7           ## ✱ Drift: horizontal current lines across the view
const CURRENT_DASH := 10.0         ## ✱ px dash, then CURRENT_GAP px gap
const CURRENT_GAP := 14.0          ## ✱
const CURRENT_PARALLAX := 0.35     ## ✱
const CURRENT_FLOW := 6.0          ## ✱ px/s the currents flow along x (sim time)
const CHAINS := 6                  ## ✱ Censer Watch: chains hanging from the top of the view
const CHAIN_LINK := 4.0            ## ✱ px between links
const CHAIN_PARALLAX := 0.3        ## ✱ x parallax (they hang from the view's top edge)
const CHAIN_SWING := 3.0           ## ✱ px the censer swings at the chain's end
const SCHOOLS := 5                 ## ✱ Shoal: schools of glass motes
const SCHOOL_MOTES := 30           ## ✱ motes per school (2×1 px flecks)
const SCHOOL_RADIUS := Vector2(24, 9)    ## ✱ px school half-size
const SCHOOL_PARALLAX := 0.6       ## ✱
const SCHOOL_SWIM := 4.0           ## ✱ px/s
const HORIZON_FRAC := 0.68         ## ✱ Stillwater: the horizon line, fraction of the view height
const HORIZON_PARALLAX := 0.25     ## ✱ x parallax of the ripples
const HORIZON_RIPPLES := [[4.0, 9], [9.0, 6], [15.0, 4], [22.0, 2]]   ## ✱ [px below the line, dashes]

var backdrop: StringName = &""      ## set from the stage in reset()
## The stage hand-off (Q-T457): the next stage's signature dissolves in over this stage's. `morph` runs 0..1; every
## mark leaves or arrives by a fixed per-mark threshold (a dither, never a blend, so only Pal registers are drawn).
var morph_to: StringName = &""
var morph := 0.0
var _morph_dur := 0.0
const MORPH_STEP := 0.61803399   ## per-mark threshold = frac(i x this): an even, formula-only dissolve (no RNG)

var _stars: Array[PackedVector2Array] = []
var _spine: PackedVector2Array = PackedVector2Array()   ## tile-space spine star positions (formula, no RNG)
var pull := 0.0                      ## 0..1, set by the reveal
var pull_target := Vector2.ZERO    ## screen point the sky drains into: the wound's off-centre origin (MawView.centre), else the play view centre; set in reset
var desaturate := 0.0                ## 0..1, T0→T1 costume removal (W0-08)
var show_seams := true
var spine_stars := false             ## S8: set from the stage in reset()
var maw: MawView                     ## wired by CabinetGame: the live vertebra positions and reveal

var _streak_rng := RandomNumberGenerator.new()   ## starfield-local: never world.rng, so the sim and the autopilot seeds are untouched
var _streak_next := 0.0              ## world.time of the next streak
var _streak_t0 := -1.0               ## world.time the live streak began (< 0 = none)
var _streak_from := Vector2.ZERO     ## screen start of the live streak
var _streak_vec := Vector2.ZERO      ## screen travel of the live streak (length = view crossing, direction = its heading)
var _streak_len := 0.0


func reset() -> void:
	morph = 0.0
	morph_to = &""
	_morph_dur = 0.0
	_stars.clear()
	_spine = PackedVector2Array()
	pull_target = maw.centre if maw != null else world.screen_centre   # the sky drains into the wound (MawView, Q-T262)
	spine_stars = world.stage != null and world.stage.spine_stars
	backdrop = world.stage.backdrop if world.stage != null and BACKDROPS.has(world.stage.backdrop) else &""
	_streak_rng.seed = 4242
	_streak_t0 = -1.0
	_streak_next = world.time + _streak_rng.randf_range(world.fx_tuning.streak_interval_min_s, world.fx_tuning.streak_interval_max_s)
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for layer in LAYERS:
		var pts := PackedVector2Array()
		for i in int(layer.count):
			pts.append(Vector2(r.randf() * world.view_size.x, r.randf() * world.view_size.y))
		_stars.append(pts)
	if spine_stars:
		var length := world.view_size.y * SPINE_LENGTH_FRAC
		var head := Vector2(world.view_size.x * SPINE_X_FRAC, world.view_size.y * SPINE_TOP_FRAC)
		var width_scale := length / (SepulchreRitual.TRUE_LENGTH_MULT * SepulchreRitual.BODY_DRAWN_RADIUS)   # the S2 silhouette, enlarged to the sky column
		_spine = MawView.spine_ladder(head, Vector2.DOWN, length, width_scale)


## Begin the hand-off morph toward stage signature `to` over `seconds` (reset() ends it: the next stage starts on the finished look).
func begin_morph(to: StringName, seconds: float) -> void:
	morph_to = to if BACKDROPS.has(to) else &""
	morph = 0.0
	_morph_dur = maxf(seconds, 0.05)


func morphing() -> bool:
	return _morph_dur > 0.0


func tick(delta: float) -> void:
	if _morph_dur > 0.0:
		morph = minf(1.0, morph + delta / _morph_dur)


## Horizontal warp of the sky at this row: a travelling sine, loudest mid-morph (bell), 0 at both ends. None under
## photosensitivity or reduced motion (the dissolve alone remains: it is dim, small and never a flash).
func warp_dx(y: float) -> float:
	if _morph_dur <= 0.0 or not streaks_enabled():
		return 0.0
	return roundf(sin(y * 0.09 + world.shader_time * 9.0) * world.fx_tuning.handoff_warp_px * sin(PI * morph))


## Is mark / star number `i` of the OLD look still drawn at this morph? (the new look draws it when this is false)
func morph_keeps_old(i: int) -> bool:
	return fposmod(float(i) * MORPH_STEP, 1.0) >= morph


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
	return maw != null and (i >> 1) < ceili(clampf(maw.reveal, 0.0, 1.0) * MawView.SEGMENTS)


## Has the star arrived at its slot? From then on MawView draws it (S8 hand-off), not the starfield.
func spine_star_arrived() -> bool:
	return maw != null and pull > 0.0 and spine_travel() >= 1.0


## Does the starfield itself draw spine star i this frame?
func spine_star_drawn(i: int) -> bool:
	return not spine_star_hidden(i) and not spine_star_arrived()


## 1 px in play; a 2x2 dot once the pull begins, so the column reads in a clip.
func spine_star_size() -> Vector2:
	return Vector2(2, 2) if pull > 0.0 else Vector2.ONE


func spine_star_pos(i: int) -> Vector2:
	var p := _tile_pos(_spine[i], SPINE_PARALLAX)
	if pull > 0.0 and maw != null:
		p = p.lerp(maw.vertebra_star_pos(i >> 1, i & 1), spine_travel())
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
	if pull <= 0.0:                     # the sky drains in the reveal: the signature goes first
		if morph > 0.0:
			_draw_morph()
		else:
			var bcol := backdrop_color()
			for m: Rect2 in backdrop_marks():
				draw_rect(m, bcol)
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
			var scol := Look.c(Pal.BONE_5) if twinkle else col
			if morph > 0.0 and pull <= 0.0:
				p.x += warp_dx(p.y)
				if streaks_enabled() and not twinkle and fposmod(float(i + li * 31) * MORPH_STEP, 1.0) < 0.25 * sin(PI * morph):
					scol = Look.c(Pal.BONE_3)    # a sparkle sweep mid-morph: 1 px dots, never a field flash
			draw_rect(Rect2(p.round(), Vector2.ONE), scol)
	for i in _spine.size():
		if spine_star_drawn(i):
			draw_rect(Rect2(spine_star_pos(i).round(), spine_star_size()), spine_star_color())
	if pull <= 0.0:
		_update_streak()
		var sp := _streak_points()
		if sp.size() == 2:
			draw_line(sp[0], sp[1], Look.c(Pal.VOID_5))
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


# --- Stage signatures (CabinetStage.backdrop) -------------------------------------------------------

## The signature's colour: a VOID register (Drift and Censer Watch the darkest; Shoal the brightest), greyed by the
## T0→T1 costume removal like the stars.
func backdrop_color(kind: StringName = &"-") -> Color:
	if kind == &"-":
		kind = backdrop
	var col := Look.c(Pal.VOID_3)
	if kind == &"shoal":
		col = Look.c(Pal.VOID_5)            # the glass motes: the brightest VOID, still never a faction hue
	elif kind == &"horizon":
		col = Look.c(Pal.VOID_4)
	if desaturate > 0.0:
		col = col.lerp(Look.c(Pal.BONE_1), desaturate * 0.6)
	return col


## Every mark of this stage's signature this frame, in screen (grid) pixels, inside the playfield
## (never over the HUD strip or the footer). Empty for the plain sky (a0_1, off the three-stage shift).
func backdrop_marks() -> Array[Rect2]:
	return _marks_of(backdrop, false)


## The hand-off frame: this look's marks that survive the dissolve, in its register, then the next look's that
## have arrived, in its register; both warped by warp_dx and clipped to the playfield. Mark order is stable
## (formula-placed), so the thresholds do not shimmer.
func _draw_morph() -> void:
	var old_col := backdrop_color(backdrop)
	var new_col := backdrop_color(morph_to)
	var old_marks := _marks_of(backdrop, true)
	for i in old_marks.size():
		if morph_keeps_old(i):
			draw_rect(old_marks[i], old_col)
	var new_marks := _marks_of(morph_to, true)
	for i in new_marks.size():
		if not morph_keeps_old(i):
			draw_rect(new_marks[i], new_col)


## `kind`'s marks this frame. With `warped`, each mark is shifted by the morph's row warp BEFORE the playfield clip,
## and a mark that clips away is kept as an empty rect so the mark numbering (the dissolve threshold) never moves.
func _marks_of(kind: StringName, warped: bool) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if world == null or world.torus == null:
		return out
	match kind:
		&"currents":
			_currents(out)
		&"chains":
			_chains(out)
		&"shoal":
			_shoal(out)
		&"horizon":
			_horizon(out)
	var field := world.playfield_rect
	var kept: Array[Rect2] = []
	for m in out:
		if warped:
			m.position.x += warp_dx(m.position.y)
		var c := m.intersection(field)
		var r := Rect2()
		if c.has_area():
			# rounding can nudge a sliver across the playfield edge: clip once more after it
			r = Rect2(c.position.round(), c.size.round().max(Vector2.ONE)).intersection(field)
		if r.has_area() or warped:
			kept.append(r)
	return kept


func _par_off(par: float) -> Vector2:
	return -world.view_centre * par


func _currents(out: Array[Rect2]) -> void:
	var tile := world.view_size
	var o := world.view_rect.position
	var off := _par_off(CURRENT_PARALLAX)
	var period := CURRENT_DASH + CURRENT_GAP
	for k in CURRENT_LINES:
		var y := o.y + fposmod((float(k) + 0.5) / CURRENT_LINES * tile.y + off.y, tile.y)
		var shift := fposmod(off.x + world.time * CURRENT_FLOW * (1.0 + 0.25 * (k % 3)) + k * 9.0, period)
		var x := o.x - period + shift
		while x < o.x + tile.x:
			out.append(Rect2(x, y, CURRENT_DASH, 1.0))
			x += period


func _chains(out: Array[Rect2]) -> void:
	var tile := world.view_size
	var o := world.view_rect.position
	var off := _par_off(CHAIN_PARALLAX)
	for k in CHAINS:
		var x0 := o.x + fposmod((float(k) + 0.5) / CHAINS * tile.x + off.x, tile.x)
		var length := tile.y * (0.22 + 0.09 * float((k * 3) % 4))
		var swing := sin(world.time * 1.1 + float(k) * 1.7) * CHAIN_SWING
		var y := 0.0
		while y < length:
			out.append(Rect2(x0 + swing * (y / length), o.y + y, 1.0, 1.0))
			y += CHAIN_LINK
		var c := Vector2(x0 + swing, o.y + length + 2.0)   # the censer: a hollow 5×5 box
		out.append(Rect2(c.x - 2.0, c.y - 2.0, 5.0, 1.0))
		out.append(Rect2(c.x - 2.0, c.y + 2.0, 5.0, 1.0))
		out.append(Rect2(c.x - 2.0, c.y - 1.0, 1.0, 3.0))
		out.append(Rect2(c.x + 2.0, c.y - 1.0, 1.0, 3.0))


func _shoal(out: Array[Rect2]) -> void:
	var tile := world.view_size
	var o := world.view_rect.position
	var off := _par_off(SCHOOL_PARALLAX)
	for k in SCHOOLS:
		var home := Vector2(fposmod(float(k) * 0.37 + 0.11, 1.0) * tile.x, (float(k) + 0.5) / SCHOOLS * tile.y)
		home.x += world.time * SCHOOL_SWIM * (1.0 if k % 2 == 0 else -1.0)
		for m in SCHOOL_MOTES:
			var a := float(m) * 2.39996           # golden angle: an even school with no RNG
			var r := sqrt((float(m) + 0.5) / SCHOOL_MOTES)
			var p := home + Vector2(cos(a) * SCHOOL_RADIUS.x, sin(a) * SCHOOL_RADIUS.y) * r + off
			out.append(Rect2(o.x + fposmod(p.x, tile.x), o.y + fposmod(p.y, tile.y), 2.0, 1.0))


func _horizon(out: Array[Rect2]) -> void:
	var tile := world.view_size
	var o := world.view_rect.position
	var y := o.y + tile.y * HORIZON_FRAC
	out.append(Rect2(o.x, y, tile.x, 1.0))
	var off := _par_off(HORIZON_PARALLAX)
	for row: Array in HORIZON_RIPPLES:
		var dy: float = row[0]
		var n: int = row[1]
		var w := 12.0 - dy * 0.35
		for i in n:
			var x := o.x + fposmod((float(i) + 0.5) / n * tile.x + off.x * (1.0 + dy / 30.0), tile.x)
			out.append(Rect2(x - w * 0.5, y + dy, w, 1.0))


# --- Distant streaks (draw-only) ---------------------------------------------------------------------

## Are streaks allowed? Off under photosensitivity or reduced motion.
func streaks_enabled() -> bool:
	return not (bool(SettingsService.get_value(&"photosensitivity")) or bool(SettingsService.get_value(&"reduced_motion")))


## Is a streak crossing the view right now? (tests)
func streak_active() -> bool:
	return _streak_t0 >= 0.0


## Advance the streak clock (called from _draw): every streak_interval_min_s..max_s one thin dim line crosses a random part of the view over streak_cross_s.
## Driven by the starfield's own RNG and world.time; nothing in the sim reads it.
func _update_streak() -> void:
	var ft := world.fx_tuning
	if not streaks_enabled():
		_streak_t0 = -1.0
		return
	if _streak_t0 < 0.0:
		if world.time < _streak_next:
			return
		var view := world.view_rect
		var ang := _streak_rng.randf_range(0.0, TAU)
		var dir := Vector2.from_angle(ang)
		_streak_len = _streak_rng.randf_range(ft.streak_length_min_px, ft.streak_length_max_px)
		var mid := view.position + Vector2(_streak_rng.randf_range(0.2, 0.8) * view.size.x, _streak_rng.randf_range(0.2, 0.8) * view.size.y)
		_streak_vec = dir * view.size.x * 0.45
		_streak_from = mid - _streak_vec * 0.5
		_streak_t0 = world.time
	var k := (world.time - _streak_t0) / maxf(0.05, ft.streak_cross_s)
	if k >= 1.0:
		_streak_t0 = -1.0
		_streak_next = world.time + _streak_rng.randf_range(ft.streak_interval_min_s, ft.streak_interval_max_s)
		return


## The live streak as screen points [tail, head], or empty when none or off the playfield.
func _streak_points() -> PackedVector2Array:
	var out := PackedVector2Array()
	if _streak_t0 < 0.0:
		return out
	var k := (world.time - _streak_t0) / maxf(0.05, world.fx_tuning.streak_cross_s)
	var head := _streak_from + _streak_vec * k
	var tail := head - _streak_vec.normalized() * _streak_len
	var field := world.playfield_rect
	if field.has_point(head.round()) and field.has_point(tail.round()):
		out.append(tail.round())
		out.append(head.round())
	return out
