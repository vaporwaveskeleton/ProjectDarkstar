class_name SepulchreRitual
extends ArcadeLayer
## The Sepulchre and the thing it builds: the Waking lifecycle (GDD §8.4, SYS-001 §2, §2.1).
## Grubs deposit glass; every `shards_per_segment` deposits adds one of 20 segments. At the Guard
## threshold more Acolytes come; at Quickening the structure twitches and whispers; at 20/20 the
## chant cuts to silence, then "IT WAKES." The entity hunts the Vigil (contact kills), heals by
## eating geodes and Choir, and is unmade by 13 Charges. Before it wakes, a Charge on the
## Sepulchre knocks 1–3 modules off. A Cold Sepulchre (W0-05) builds but never wakes.

enum Phase { SEED, PROCESSION, GUARD, QUICKENING, AWAKENING, RAMPAGE, UNMADE }

const BODY_RADIUS := 30.0        ## ✱ costume scale
const BODY_DRAWN_RADIUS := BODY_RADIUS + 4.0   ## px ✱ body ring + vertebra plate reach: the silhouette the S6 chalk ring encloses
const TRUE_FRAME_FILL: Color = Pal.NULL    ## the costume disc's colour
const TRUE_FRAME_LINE: Color = Pal.BONE_3  ## the costume plates' colour
const TRUE_LENGTH_MULT := 3.5     ## x BODY_DRAWN_RADIUS ✱ S2: the column's length, head to tail
const TRUE_POPUP_GAP := 3.0      ## px ✱ S2: clearance between the silhouette and the hit's score popup
const CONTACT_INSET := 4.0       ## ✱ SYS-001 §2.1's 16 px inset at the 64 px module scale, ÷4 for the costume
const SEPULCHRE_RADIUS := 26.0   ## ✱ deposit / Charge contact radius of the altar
const ENTITY_TURN := 2.2         ## ✱ rad/s steering: kite-able, never twitchy

var pos := Vector2.ZERO
var entity_pos := Vector2.ZERO
var entity_dir := Vector2.RIGHT
var radius := SEPULCHRE_RADIUS
var segments := 0
var shard_points := 0
var phase: int = Phase.SEED
var awake := false
var hits_left := 13
var wakes := true

var _awaken_t := 0.0
var _stagger_hits := 0
var _staggered := 0.0
var _eating := 0.0
var _unit_meal_cd := 0.0
var _restores := 0
var _twitch := 0.0
var _rot := 0.0
var _line_said := false
var _true_dir := Vector2.DOWN        ## which way the S2 column trails, fixed at the hit
var _true_frames_left := 0       ## DRAWN frames of the S2 true-body silhouette still to show (counts in _draw, so it survives hit-stop)


func reset() -> void:
	var t := world.tuning
	# SYS-001 §1.7: straight ahead of the Vigil's starting heading (the Vigil resets first, see ArcadeWorld.start)
	pos = world.torus.wrap(world.vigil.pos + Vector2.from_angle(world.vigil.facing) * t.field_sepulchre_start_px)
	entity_pos = pos
	wakes = world.stage.sepulchre_wakes
	segments = clampi(world.stage.sepulchre_start_segments, 0, t.segments_total)
	shard_points = 0
	awake = false
	hits_left = t.unravel_hits
	_awaken_t = 0.0
	_stagger_hits = 0
	_staggered = 0.0
	_restores = 0
	_line_said = false
	_true_frames_left = 0
	_set_phase(_phase_for(segments))
	world.segments_changed.emit(segments)
	if segments >= t.segments_total and wakes:
		_begin_awakening()


func _phase_for(n: int) -> int:
	var t := world.tuning
	if n <= 0:
		return Phase.SEED
	if n >= t.quickening_at:
		return Phase.QUICKENING
	if n >= t.guard_at:
		return Phase.GUARD
	return Phase.PROCESSION


func _set_phase(p: int) -> void:
	if p == phase:
		return
	var was := phase
	phase = p
	world.phase_changed.emit(p)
	if p == Phase.GUARD and was < Phase.GUARD:
		world.acolytes.on_guard_phase()
	if p == Phase.QUICKENING and was < Phase.QUICKENING and wakes:
		world.caption.emit("CAB_CAPTION_WHISPER")


func accepts_deposits() -> bool:
	return not awake and phase < Phase.AWAKENING


## A Grub delivered one shard (SYS-001 §2 phase 1: one segment point).
func deposit() -> void:
	var t := world.tuning
	shard_points += 1
	if world.record != null:
		world.record.glass_carried += 1
	world.fx.ring(pos, Look.c(Pal.CHOIR_4), world.fx_tuning.ritual_deposit_ring_radius)
	if shard_points < t.shards_per_segment or segments >= t.segments_total:
		return
	shard_points = 0
	segments += 1
	world.segments_changed.emit(segments)
	if world.on_screen(pos, 0.0) or segments >= t.quickening_at:
		world.sfx(&"segment_deposit", -6.0 + minf(6.0, segments * 0.4))
	if segments >= t.segments_total and wakes:
		_begin_awakening()
	else:
		_set_phase(_phase_for(segments))


func _begin_awakening() -> void:
	_set_phase(Phase.AWAKENING)
	_awaken_t = 0.0
	_stagger_hits = 0
	AudioService.silence(world.tuning.awakening_silence)    # the scare chord is silence (GDD §12)


## Where a flying Charge should home, or null when there is nothing to hit.
func charge_target() -> Variant:
	if phase == Phase.UNMADE:
		return null
	if awake or phase == Phase.AWAKENING:
		return entity_pos
	return pos if segments > 0 else null


## A Charge touched the ritual? Resolves the hit and returns true if it was consumed.
func charge_contact(p: Vector2, r: float) -> bool:
	if phase == Phase.UNMADE:
		return false
	var centre := entity_pos if (awake or phase == Phase.AWAKENING) else pos
	var reach := (BODY_RADIUS if awake or phase == Phase.AWAKENING else SEPULCHRE_RADIUS) + r
	if world.torus.distance(p, centre) > reach:
		return false
	if awake or phase == Phase.AWAKENING:
		_hit_entity(p)
	elif segments > 0:
		_knock_modules(p)
	else:
		world.fx.burst(p, Look.c(Pal.BONE_2), world.fx_tuning.ritual_bare_hit_burst_count, world.fx_tuning.ritual_bare_hit_burst_speed)
	return true


func _knock_modules(at: Vector2) -> void:
	var t := world.tuning
	var n := mini(segments, world.rng.randi_range(t.knock_min, t.knock_max))
	segments -= n
	world.segments_changed.emit(segments)
	for k in n:
		world.award(t.score_module, world.torus.wrap(pos + Vector2.from_angle(world.rng.randf() * TAU) * 20.0))
	world.sfx(&"segment_knocked")
	world.sfx(&"charge_hit", -4.0)
	world.fx.burst(pos, Look.c(Pal.BONE_4), world.fx_tuning.modules_knocked_burst_per_module * n, world.fx_tuning.modules_knocked_burst_speed)
	world.fx.ring(at, Look.c(Pal.PHOS_4), world.fx_tuning.modules_knocked_ring_radius)
	world.shake(world.fx_tuning.modules_knocked_shake_amp, world.fx_tuning.modules_knocked_shake_dur)
	world.hitstop(world.fx_tuning.hitstop_modules_knocked_frames, &"modules_knocked")
	_set_phase(_phase_for(segments))
	if segments <= 0 and world.stage.goal == CabinetStage.Goal.CLEAR_SEPULCHRE:
		world.sepulchre_cleared.emit()


func _hit_entity(at: Vector2) -> void:
	var t := world.tuning
	hits_left -= 1
	world.end_slowmo()                                   # scale must be exactly 1.0 when hit-stop starts
	var head := world.to_screen(entity_pos).round()
	_true_dir = true_frame_dir_for(head)
	world.award(t.score_module, entity_pos)              # a piece of the entity (SYS-001 §7.1)
	var popup := true_frame_popup_pos(head, str(t.score_module))
	world.fx.place_last_text(entity_pos + (popup - head))   # S2: the popup stays out of the silhouette
	world.sfx(&"charge_hit")
	world.fx.burst(at, Look.c(Pal.BONE_4), world.fx_tuning.entity_hit_burst_count, world.fx_tuning.entity_hit_burst_speed)
	world.fx.ring(at, Look.c(Pal.PHOS_5), world.fx_tuning.entity_hit_ring_radius)
	world.shake(world.fx_tuning.entity_hit_shake_amp, world.fx_tuning.entity_hit_shake_dur)
	world.hitstop(world.fx_tuning.hitstop_charge_hits_entity_frames, &"charge_hits_entity")
	_twitch = 0.5
	_true_frames_left = world.fx_tuning.true_frame_frames
	if phase == Phase.AWAKENING and _awaken_t <= t.awakening_silence + t.stagger_window:
		_stagger_hits += 1
		if _stagger_hits >= t.stagger_hits:
			_staggered = t.stagger_window         # ✱ a stagger freezes it for one more window
	if hits_left <= 0:
		_unmake()


func _unmake() -> void:
	_set_phase(Phase.UNMADE)
	awake = false
	world.award(world.tuning.score_entity, entity_pos)
	world.sfx(&"entity_unmade")
	world.fx.burst(entity_pos, Look.c(Pal.BONE_4), world.fx_tuning.entity_unmade_burst_a_count, world.fx_tuning.entity_unmade_burst_a_speed)
	world.fx.burst(entity_pos, Look.c(Pal.PHOS_5), world.fx_tuning.entity_unmade_burst_b_count, world.fx_tuning.entity_unmade_burst_b_speed)
	world.fx.ring(entity_pos, Look.c(Pal.BONE_5), world.fx_tuning.entity_unmade_ring_radius)
	world.shake(world.fx_tuning.entity_unmade_shake_amp, world.fx_tuning.entity_unmade_shake_dur)
	world.hitstop(world.fx_tuning.hitstop_entity_unmade_frames, &"entity_unmade")
	AudioService.set_chant(0.0)
	world.entity_unmade.emit()


func lance_test(p: Vector2, dir: Vector2 = Vector2.RIGHT) -> bool:
	if phase == Phase.UNMADE:
		return false
	var centre := entity_pos if awake or phase == Phase.AWAKENING else pos
	var r := BODY_RADIUS if awake or phase == Phase.AWAKENING else SEPULCHRE_RADIUS * 0.7
	if world.torus.distance(p, centre) > r:
		return false
	world.fx.chalk_tick(p, dir)          # the lance does not bite (AUDIO-001 A03): a dim tick, no sparks, no rng
	world.sfx(&"lance_dull", world.fx_tuning.lance_dull_db)
	return true


func tick(delta: float) -> void:
	var t := world.tuning
	_rot += delta * (0.2 + segments * 0.02)
	_twitch = maxf(0.0, _twitch - delta)
	if phase == Phase.QUICKENING and world.rng.randf() < delta * 1.5:
		_twitch = 0.15
	_update_chant()
	_tick_leash(delta)
	match phase:
		Phase.AWAKENING:
			_awaken_t += delta
			entity_pos = pos
			if _awaken_t >= t.awakening_silence and not _line_said:
				_line_said = true
				world.entity_line.emit("ENTITY_IT_WAKES")
				world.sfx(&"wake_hit")
				world.shake(world.fx_tuning.it_wakes_shake_amp, world.fx_tuning.it_wakes_shake_dur)
				world.hitstop(world.fx_tuning.hitstop_it_wakes_frames, &"it_wakes")
				world.fx.ring(pos, Look.c(Pal.NULL), world.fx_tuning.it_wakes_ring_radius)
				AudioService.set_chant(0.0)
			if _awaken_t >= t.awakening_silence + t.stagger_window:
				awake = true
				_set_phase(Phase.RAMPAGE)
		Phase.RAMPAGE:
			_rampage(delta)


## SYS-001 §1.7 leash: a Sepulchre that is not yet awake drifts toward a Vigil farther than
## field_sepulchre_leash_px at field_sepulchre_drift_px_s (slower than the Vigil: never escaped for good).
## The forming and awake entity stay put / chase on their own rules.
func _tick_leash(delta: float) -> void:
	if awake or phase >= Phase.AWAKENING:
		return
	var t := world.tuning
	var to_v := world.torus.delta(pos, world.vigil.pos)
	if to_v.length() <= t.field_sepulchre_leash_px:
		return
	pos = world.torus.wrap(pos + to_v.normalized() * minf(t.field_sepulchre_drift_px_s * delta, to_v.length()))
	entity_pos = pos


func _rampage(delta: float) -> void:
	var t := world.tuning
	_unit_meal_cd = maxf(0.0, _unit_meal_cd - delta)
	if _staggered > 0.0:
		_staggered -= delta
		return
	if _eating > 0.0:
		_eating -= delta
		return
	var v := world.vigil
	if v.alive:
		var want := world.torus.delta(entity_pos, v.pos).normalized()
		var ang := entity_dir.angle_to(want)
		entity_dir = entity_dir.rotated(clampf(ang, -ENTITY_TURN * delta, ENTITY_TURN * delta))
	entity_pos = world.torus.wrap(entity_pos + entity_dir * t.rampage_speed * delta)
	# contact death (SYS-001 §2 phase 5 🔒)
	if v.alive and world.torus.distance(entity_pos, v.pos) <= BODY_RADIUS - CONTACT_INSET + v.radius:
		v.kill(entity_pos, world.torus.delta(v.pos, entity_pos).normalized(), BODY_DRAWN_RADIUS)
	# it eats to heal (SYS-001 §2.1)
	var g := world.geodes.hit_test(entity_pos, BODY_RADIUS - CONTACT_INSET)
	if g != null:
		world.geodes.devour(g)
		_eating = t.eat_geode_time
		_heal()
	var grub := world.grubs.hit_test(entity_pos, BODY_RADIUS - CONTACT_INSET)
	if grub != null and _unit_meal_cd <= 0.0 and _restores < t.eat_restore_cap:
		world.grubs.kill(grub, false)
		_unit_meal_cd = t.eat_unit_cooldown
		_restores += 1
		_heal()


func _heal() -> void:
	hits_left = mini(world.tuning.unravel_hits, hits_left + 1)
	world.fx.ring(entity_pos, Look.c(Pal.CHOIR_4), world.fx_tuning.heal_ring_radius)


func _update_chant() -> void:
	if not world.stage.chant or phase >= Phase.AWAKENING:
		return
	var d := world.torus.distance(pos, world.vigil.pos)
	var near := clampf(1.0 - d / 900.0, 0.0, 1.0)
	var built := float(segments) / world.tuning.segments_total
	AudioService.set_chant(clampf(0.12 + built * 0.6, 0.0, 1.0) * (0.35 + 0.65 * near))


func _draw() -> void:
	if world == null:
		return
	if phase != Phase.UNMADE and (awake or phase == Phase.AWAKENING):
		if _true_frames_left > 0:
			_draw_true_frame()
		else:
			_draw_entity()
	elif phase != Phase.UNMADE:
		_draw_sepulchre()
	advance_draw_frame()


## One drawn frame has passed (end of _draw; tests call it directly). Counts drawn frames, not sim
## ticks, so the impact frame is never swallowed by the hit-stop that follows the hit.
func advance_draw_frame() -> void:
	_true_frames_left = maxi(0, _true_frames_left - 1)


## S2: is this drawn frame the impact frame (true silhouette instead of the costume)?
func showing_true_frame() -> bool:
	return _true_frames_left > 0


## S2 impact frame. GDD §20 (closed 2026-11-17): in Act 0 the entity is seen only as a silhouette;
## NARR-001 §3.4: no face. The costume is replaced by the true body, a spine: one filled polygon (the
## costume disc's NULL, so it hides the stars behind it) with a closed 1 px outline (the plates' BONE_3),
## head on the costume centre, the column running on past the costume's bounds: the disc was only the
## end of something longer. No eye, veins or interior.
func _draw_true_frame() -> void:
	if not visible_at(entity_pos, BODY_RADIUS + 8.0):
		return
	var c := world.to_screen(entity_pos).round()
	if _twitch > 0.0:
		c += Vector2(roundf(sin(world.time * 80.0) * 2.0), roundf(cos(world.time * 70.0) * 1.0))
	var poly := true_frame_polygon(c)
	draw_colored_polygon(poly, Look.c(TRUE_FRAME_FILL))
	var outline := PackedVector2Array()
	for q in poly:
		outline.append(q + Vector2(0.5, 0.5))      # pixel-centred 1 px line (TECH-001 §1.3)
	outline.append(outline[0])
	draw_polyline(outline, Look.c(TRUE_FRAME_LINE), 1.0)


## Which way the column trails from the head: toward the middle of the screen's height, so it stays on screen.
func true_frame_dir_for(screen_pos: Vector2) -> Vector2:
	return Vector2.DOWN if screen_pos.y < world.screen_centre.y else Vector2.UP


## The silhouette with its head at screen point `c`: integer vertices (they pixel-centre exactly).
func true_frame_polygon(c: Vector2) -> PackedVector2Array:
	var poly := MawView.spine_silhouette(c, _true_dir, TRUE_LENGTH_MULT * BODY_DRAWN_RADIUS)
	for i in poly.size():
		poly[i] = poly[i].round()
	return poly


## Screen-space bounds of the silhouette with its head at `c` (outline included).
func true_frame_box(c: Vector2) -> Rect2:
	var poly := true_frame_polygon(c)
	var r := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		r = r.expand(q)
	return r.grow(1.0)


## Screen rect a score popup placed at screen point `p` covers (FxLayer draws it at p + (-w/2, -12)).
func popup_rect(p: Vector2, text: String) -> Rect2:
	return Rect2(p + Vector2(-PixelText.width(text) * 0.5, -12.0), Vector2(PixelText.width(text), PixelText.H))


## The hit's "500" must not sit inside the silhouette: put it just past the head (or, if that is off
## screen, beside the column). Returns a screen point; deterministic, no rng.
func true_frame_popup_pos(c: Vector2, text: String) -> Vector2:
	var box := true_frame_box(c).grow(TRUE_POPUP_GAP)
	var w := float(PixelText.width(text))
	var cands: Array[Vector2] = []
	if _true_dir.y > 0.0:
		cands.append(Vector2(c.x, box.position.y + 12.0 - float(PixelText.H)))
	else:
		cands.append(Vector2(c.x, box.end.y + 12.0))
	cands.append(Vector2(box.end.x + w * 0.5, c.y))
	cands.append(Vector2(box.position.x - w * 0.5, c.y))
	for p in cands:
		if world.view_rect.encloses(popup_rect(p, text)):
			return p
	return cands[0]


func _draw_sepulchre() -> void:
	if not visible_at(pos, 60.0):
		return
	var jitter := Vector2(roundf(sin(world.time * 60.0) * 1.0), 0.0) if _twitch > 0.0 else Vector2.ZERO
	var c := world.to_screen(pos).round() + jitter
	var cold := not wakes
	# the altar: a slab of fused vertebrae
	var slab := PackedVector2Array([c + Vector2(-24, 18), c + Vector2(24, 18), c + Vector2(18, 26), c + Vector2(-18, 26)])
	Pal.glow_polyline(self, slab, Look.c(Pal.BONE_1) if cold else Look.c(Pal.BONE_2), Look.c(Pal.BONE_0))
	# the punctum: the will of the thing, a hole where a star should be
	draw_circle(c, 9.0, Look.c(Pal.NULL))
	draw_arc(c, 9.0, 0.0, TAU, 24, Look.c(Pal.VOID_3) if cold else Look.c(Pal.VOID_5), 1.0)
	if phase >= Phase.QUICKENING and not cold:
		for k in 4:
			var a := _rot * 2.0 + k * TAU / 4.0
			draw_line(c + Vector2.from_angle(a) * 9.0, c + Vector2.from_angle(a + 0.3) * 20.0, Look.c(Pal.PHOS_2))
	# the 20 module slots
	var total := world.tuning.segments_total
	for i in total:
		var a := _rot + TAU * i / total
		var q := (c + Vector2.from_angle(a) * 20.0).round()
		if i < segments:
			var col := Look.c(Pal.BONE_2) if cold else (Look.c(Pal.BONE_5) if phase >= Phase.QUICKENING else Look.c(Pal.BONE_4))
			draw_rect(Rect2(q - Vector2(1, 1), Vector2(3, 3)), col)
		else:
			draw_rect(Rect2(q, Vector2.ONE), Look.c(Pal.BONE_0))


func _draw_entity() -> void:
	if not visible_at(entity_pos, BODY_RADIUS + 8.0):
		return
	var c := world.to_screen(entity_pos).round()
	if _twitch > 0.0:
		c += Vector2(roundf(sin(world.time * 80.0) * 2.0), roundf(cos(world.time * 70.0) * 1.0))
	var forming := phase == Phase.AWAKENING
	var k := clampf(_awaken_t / maxf(0.01, world.tuning.awakening_silence), 0.0, 1.0) if forming else 1.0
	var r := lerpf(20.0, BODY_RADIUS, k)
	# body: the void it is made of
	draw_circle(c, r - 6.0, Look.c(Pal.NULL))
	# 20 vertebrae, minus the pieces the Charges took
	var total := world.tuning.segments_total
	var present := total if forming else int(ceil(float(total) * hits_left / world.tuning.unravel_hits))
	for i in total:
		var a := _rot * 1.7 + TAU * i / total
		var q := c + Vector2.from_angle(a) * r
		if i < present:
			var plate := PackedVector2Array([q + Vector2.from_angle(a) * 4.0, q + Vector2.from_angle(a + 1.6) * 3.0,
				q - Vector2.from_angle(a) * 3.0, q + Vector2.from_angle(a - 1.6) * 3.0])
			draw_colored_polygon(plate, Look.c(Pal.BONE_3))
			draw_polyline(plate + PackedVector2Array([plate[0]]), Look.c(Pal.BONE_5))
		else:
			draw_rect(Rect2(q.round(), Vector2.ONE), Look.c(Pal.PHOS_3))
	# the eye: always on you
	var look := world.torus.delta(entity_pos, world.vigil.pos).normalized() if world.vigil.alive else entity_dir
	var eye := (c + look * (r * 0.35)).round()
	draw_circle(eye, 4.0, Look.c(Pal.PHOS_1))
	draw_circle(eye, 2.0, Look.c(Pal.PHOS_5))
	if _staggered > 0.0 and int(world.time * 10.0) % 2 == 0:
		draw_arc(c, r + 6.0, 0.0, TAU, 32, Look.c(Pal.BONE_5), 1.0)
