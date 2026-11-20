class_name RevealVast
extends AetherShaderRect
## The vast life the lantern hides (CH-3 lantern-down reveal; ART-001 §16.6k, Q-T301..303, pass 2
## Q-T311..313). Up to three bodies far bigger than the Vigil hang in the fog: a small skull on a long
## ribbed neck, a deep finned body, a tail of tendrils, rows of paired PHOS portholes. They are always
## there: the lantern's light washes them out, so lantern down (when the presenter also crushes the
## fog to near-VOID) shows them at once against a dim distant glow on the horizon. One crosses in front
## of that glow so its whole outline shows; one is near and so big that one of its flank lights is
## about the Vigil's size; their necks bend so the heads turn toward the Vigil (it is watched).
## Far layer only (the backdrop's VastLayer, screen space): never a hitbox, no physics body, no light
## in the play layer, never black (reveal_vast.gdshader). Reduced motion: fixed places, no drift and
## no turn; photosensitivity / reduced motion hold the lights steady. Every number here is ✱.

const MAX_BODIES := 3
## ✱ the distant glow on the horizon (screen px) and its radii; body 0 crosses in front of it.
const HORIZON := Vector2(420.0, 78.0)
const HORIZON_R := Vector2(300.0, 130.0)
## ✱ per body: `anchor` (&"horizon" or &"lantern"), `off` (px from the anchor), `drift` (px amplitude)
## and `period` (s) of a slow drift, `heading` (rad, the body's axis; the head leads), `len` and `w`
## (length and max half-width, px), `par` (how much it lags the camera's travel: 0 screen-fixed …
## 1 fixed in the world), `light` (porthole size scale), `seed`.
const BODIES: Array[Dictionary] = [
	{"anchor": &"horizon", "off": Vector2(-170.0, 14.0), "drift": Vector2(60.0, 8.0), "period": 90.0,
		"heading": PI, "len": 400.0, "w": 44.0, "par": 0.15, "light": 1.0, "seed": 1.7},
	{"anchor": &"lantern", "off": Vector2(420.0, 175.0), "drift": Vector2(50.0, 10.0), "period": 120.0,
		"heading": 0.06, "len": 1500.0, "w": 150.0, "par": 0.5, "light": 8.0, "seed": 4.3},
	{"anchor": &"lantern", "off": Vector2(-250.0, -60.0), "drift": Vector2(10.0, 36.0), "period": 100.0,
		"heading": -1.7, "len": 720.0, "w": 76.0, "par": 0.35, "light": 1.6, "seed": 7.9},
]
## ✱ how fast they close back in on their place (px/s), how fast a head turns (rad/s), how far the
## neck can bend the head off the body's axis (rad), and the share of the turn toward the Vigil.
const FOLLOW_PX_S := 28.0
const TURN_RATE := 0.12
const MAX_BEND := 1.0
const LOOK_SHARE := 0.7
## ✱ kept for the far-layer lag test: the near giant's travel lag.
const PARALLAX := 0.5

var count: int = 0
var positions: Array[Vector2] = []
## The head's direction (radians), turned toward the lantern within MAX_BEND of the body's heading.
var headings: Array[float] = []
var _placed := false
var _t := 0.0


func _ready() -> void:
	super._ready()
	set_param(&"body_col", Pal.VOID_0)
	set_param(&"body_hi", Pal.VOID_1)
	set_param(&"glow_col", Pal.AETHER_3)
	set_param(&"rim_col", Pal.AETHER_5)
	set_param(&"photo_col", Pal.PHOS_4)
	set_param(&"head_col", Pal.PHOS_5)
	set_param(&"floor_col", Pal.VOID_0)
	set_param(&"horizon_px", HORIZON)
	set_param(&"horizon_r", HORIZON_R)
	for i in MAX_BODIES:
		positions.append(Vector2.ZERO)
		headings.append(float(BODIES[i]["heading"]))


func configure(look: AetherLook) -> void:
	count = clampi(look.reveal_vast_count if look != null else 0, 0, MAX_BODIES)
	set_param(&"count", count)
	_placed = false


## Pulse held steady (reduced motion or photosensitivity).
func set_steady(on: bool) -> void:
	set_param(&"steady", 1.0 if on else 0.0)


## 0 = lantern up (unseen) … 1 = lantern down (shown). The backdrop's monotonic ramp.
func set_reveal(r: float) -> void:
	set_param(&"reveal", clampf(r, 0.0, 1.0))


## Where body `i` wants to be now: its anchor plus its offset and a slow drift.
func target(i: int, lantern: Vector2, t: float, still: bool) -> Vector2:
	var b := BODIES[i]
	var anchor := HORIZON if b["anchor"] == &"horizon" else lantern
	var ph := 0.0 if still else TAU * t / float(b["period"])
	var drift: Vector2 = b["drift"]
	return anchor + (b["off"] as Vector2) + Vector2(sin(ph) * drift.x, sin(ph * 1.3 + 1.0) * drift.y)


## Advance by `delta` s: they lag the camera's travel (`travel_step`, screen px this frame) by their
## `par`, then close back in on their place. Their heads turn toward `lantern` (screen px) at
## TURN_RATE. `still` = reduced motion.
func step(delta: float, lantern: Vector2, travel_step: Vector2, still: bool) -> void:
	var dt := maxf(delta, 0.0)
	if not still:
		_t += dt
	for i in count:
		var b := BODIES[i]
		var goal := target(i, lantern, _t, still)
		if still or not _placed:
			positions[i] = goal
		else:
			positions[i] = (positions[i] - travel_step * float(b["par"])).move_toward(goal, FOLLOW_PX_S * dt)
		var axis := float(b["heading"])
		var to_l := lantern - positions[i]
		var want := axis
		if to_l.length() > 0.001:
			want = axis + clampf(angle_difference(axis, to_l.angle()) * LOOK_SHARE, -MAX_BEND, MAX_BEND)
		if still or not _placed:
			headings[i] = want
		else:
			headings[i] = rotate_toward(headings[i], want, TURN_RATE * dt)
	_placed = true
	_upload(lantern)


## 0..1: how squarely body `i`'s head points at `lantern`.
func facing(i: int, lantern: Vector2) -> float:
	var to_l := lantern - positions[i]
	if to_l.length() < 0.001:
		return 1.0
	return clampf(Vector2.from_angle(headings[i]).dot(to_l.normalized()), 0.0, 1.0)


func _upload(lantern: Vector2) -> void:
	var a := PackedVector4Array()
	var bb := PackedVector4Array()
	var cc := PackedVector4Array()
	for i in MAX_BODIES:
		if i < count:
			var b := BODIES[i]
			var axis := float(b["heading"])
			var bend := clampf(angle_difference(axis, headings[i]) / MAX_BEND, -1.0, 1.0)
			a.append(Vector4(positions[i].x, positions[i].y, axis, float(b["len"])))
			bb.append(Vector4(float(b["w"]), float(b["seed"]), bend, float(b["light"])))
			cc.append(Vector4(facing(i, lantern), 1.0, 0.0, 0.0))
		else:
			a.append(Vector4.ZERO)
			bb.append(Vector4.ZERO)
			cc.append(Vector4.ZERO)
	set_param(&"body_a", a)
	set_param(&"body_b", bb)
	set_param(&"body_c", cc)
