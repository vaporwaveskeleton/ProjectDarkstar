class_name RevealVast
extends AetherShaderRect
## The vast life the lantern hides (CH-3 lantern-down reveal, pass 8; ART-001 §16.6k, Q-T301..303).
## Up to three bodies far bigger than the frame drift close around the Vigil in the fog. They are
## always there: the lantern's light washes them out, so lantern down shows them at once, huge and
## close, cut out against distant light, their heads slowly turning toward the Vigil (it is watched).
## Far layer only (the backdrop's VastLayer, screen space): never a hitbox, no physics body, no light
## in the play layer, never black (reveal_vast.gdshader). Ambient life: it never reacts to play
## except by turning toward the lantern. Reduced motion: they hold still at fixed places around the
## lantern (no drift, no turn); photosensitivity / reduced motion hold the photophores steady.
## Every number here is ✱.

const MAX_BODIES := 3
## ✱ per body: length (px), max half-width (px), resting distance from the lantern (px), orbit start
## angle (rad), orbit speed (rad/s; sign = direction) and seed. Lengths are 1.3–2.2 frame heights.
const BODIES: Array[Dictionary] = [
	{"len": 780.0, "w": 92.0, "dist": 190.0, "ang": 2.75, "orbit": 0.022, "seed": 1.7},
	{"len": 560.0, "w": 66.0, "dist": 165.0, "ang": 0.35, "orbit": -0.03, "seed": 4.3},
	{"len": 470.0, "w": 54.0, "dist": 230.0, "ang": 1.55, "orbit": 0.026, "seed": 7.9},
]
## ✱ how far they lag behind the camera's travel (0 = screen-fixed, 1 = fixed in the world), how fast
## they close back in on their place around the lantern (px/s), and how fast their heads turn (rad/s).
const PARALLAX := 0.5
const FOLLOW_PX_S := 28.0
const TURN_RATE := 0.12
## ✱ share of each heading turned toward the lantern (the rest is the orbit tangent: they pass by,
## heads turned toward you).
const LOOK_SHARE := 0.45

var count: int = 0
var positions: Array[Vector2] = []
var headings: Array[float] = []
var _placed := false
var _t := 0.0


func _ready() -> void:
	super._ready()
	set_param(&"body_col", Pal.VOID_1)
	set_param(&"glow_col", Pal.AETHER_2)
	set_param(&"rim_col", Pal.AETHER_3)
	set_param(&"photo_col", Pal.PHOS_4)
	set_param(&"head_col", Pal.PHOS_5)
	set_param(&"floor_col", Pal.VOID_0)
	for i in MAX_BODIES:
		positions.append(Vector2.ZERO)
		headings.append(0.0)


func configure(look: AetherLook) -> void:
	count = clampi(look.reveal_vast_count if look != null else 0, 0, MAX_BODIES)
	set_param(&"count", count)
	set_param(&"body_hi", look.far_silhouette if look != null else Pal.VOID_2)
	_placed = false


## Pulse held steady (reduced motion or photosensitivity).
func set_steady(on: bool) -> void:
	set_param(&"steady", 1.0 if on else 0.0)


## 0 = lantern up (unseen) … 1 = lantern down (shown). The backdrop's monotonic ramp.
func set_reveal(r: float) -> void:
	set_param(&"reveal", clampf(r, 0.0, 1.0))


## Where body `i` wants to be now: its place on a slow orbit around the lantern.
func target(i: int, lantern: Vector2, t: float, still: bool) -> Vector2:
	var b := BODIES[i]
	var ang: float = float(b["ang"]) + (0.0 if still else float(b["orbit"]) * t)
	return lantern + Vector2.from_angle(ang) * float(b["dist"])


## Advance by `delta` s: they lag the camera's travel (`travel_step`, screen px this frame) by
## PARALLAX, then close back in on their place around `lantern` (screen px). `still` = reduced motion.
func step(delta: float, lantern: Vector2, travel_step: Vector2, still: bool) -> void:
	var dt := maxf(delta, 0.0)
	if not still:
		_t += dt
	for i in count:
		var goal := target(i, lantern, _t, still)
		if still or not _placed:
			positions[i] = goal
		else:
			positions[i] = (positions[i] - travel_step * PARALLAX).move_toward(goal, FOLLOW_PX_S * dt)
		var b := BODIES[i]
		var tangent := Vector2.from_angle(float(b["ang"]) + float(b["orbit"]) * _t + PI * 0.5 * signf(float(b["orbit"])))
		var to_lantern := (lantern - positions[i]).normalized()
		var want := tangent.slerp(to_lantern, LOOK_SHARE).angle() if to_lantern != Vector2.ZERO else tangent.angle()
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
	for i in MAX_BODIES:
		if i < count:
			var b := BODIES[i]
			a.append(Vector4(positions[i].x, positions[i].y, headings[i], float(b["len"])))
			bb.append(Vector4(float(b["w"]), float(b["seed"]), facing(i, lantern), 1.0))
		else:
			a.append(Vector4.ZERO)
			bb.append(Vector4.ZERO)
	set_param(&"body_a", a)
	set_param(&"body_b", bb)
