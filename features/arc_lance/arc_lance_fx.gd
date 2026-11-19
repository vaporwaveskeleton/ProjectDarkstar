class_name ArcLanceFx
extends Node2D
## The Lance bite (presentation only, never hit truth): a muzzle star on each shot, two 1 px
## impact flecks where a shot bites, and a dim chalk tick plus `lance_dull` where it cannot
## (a hurtbox with `bites = false`). Draws in world space (top_level). Fixed geometry, no RNG.
## Values: ArcLanceFxStats (ds_arc_lance.fx, SYS-001 §9).

const MAX_FLECKS := 64   ## ✱ cap; oldest dropped first
const MAX_TICKS := 16    ## ✱ cap; oldest dropped first

class Fleck:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float

class ChalkTick:
	var pos: Vector2
	var dir: Vector2   ## unit, perpendicular to the lance
	var life: float

@export var emitter: ArcLanceEmitter
@export var stats: ArcLanceFxStats

## Plays a cue: (id: StringName, volume_db: float). Empty = AudioService.play. Tests inject a spy.
var sfx_player: Callable
var star_frames_left: int = 0
var star_pos: Vector2 = Vector2.ZERO
var flecks: Array[Fleck] = []
var chalk_ticks: Array[ChalkTick] = []


func _ready() -> void:
	top_level = true
	global_transform = Transform2D.IDENTITY
	if emitter:
		emitter.lance_fired.connect(_on_lance_fired)


func _process(delta: float) -> void:
	tick(delta)
	queue_redraw()


## True when the muzzle star may show (mirrors the Cabinet's VigilShip: Muzzle Flash on and
## Photosensitivity off). Read at fire time.
static func muzzle_star_allowed() -> bool:
	return bool(SettingsService.get_value(&"muzzle_flash")) and not bool(SettingsService.get_value(&"photosensitivity"))


func _on_lance_fired(direction: Vector2) -> void:
	if emitter.facing_node and emitter.stats:
		muzzle_star(emitter.facing_node.global_position + direction.normalized() * emitter.stats.muzzle_offset_px)
	track(emitter.last_shot)


## Show the star at `at` for `muzzle_star_frames` drawn frames, unless the settings forbid it.
func muzzle_star(at: Vector2) -> void:
	if not muzzle_star_allowed():
		return
	star_pos = at
	star_frames_left = stats.muzzle_star_frames


## Listen for this shot's hits.
func track(shot: LanceProjectile) -> void:
	if shot and is_instance_valid(shot):
		shot.lance_hit.connect(_on_lance_hit.bind(shot))


func _on_lance_hit(target: Node, shot: LanceProjectile) -> void:
	bite(target, shot.global_position, shot.direction)


## Classify one lance hit at `at` along `dir`: flecks if the lance bites, else tick + lance_dull.
func bite(target: Node, at: Vector2, dir: Vector2) -> void:
	if LanceProjectile.can_bite(target):
		fleck(at, dir)
	else:
		chalk_tick(at, dir)
		_play(&"lance_dull", stats.lance_dull_db)


## Two 1 px specks leaving perpendicular to the shot.
func fleck(at: Vector2, dir: Vector2) -> void:
	var side := dir.normalized().orthogonal()
	for sgn: float in [-1.0, 1.0]:
		if flecks.size() >= MAX_FLECKS:
			flecks.remove_at(0)
		var f := Fleck.new()
		f.pos = at
		f.vel = side * stats.fleck_speed_px_s * sgn
		f.max_life = stats.fleck_life_s
		f.life = f.max_life
		flecks.append(f)


## A dim dash across the lance's line: the lance cannot hurt this.
func chalk_tick(at: Vector2, dir: Vector2) -> void:
	if chalk_ticks.size() >= MAX_TICKS:
		chalk_ticks.remove_at(0)
	var t := ChalkTick.new()
	t.pos = at
	t.dir = dir.normalized().orthogonal()
	t.life = stats.tick_life_s
	chalk_ticks.append(t)


## Advance flecks and ticks by `delta` seconds (tests call it directly).
func tick(delta: float) -> void:
	for f in flecks:
		f.life -= delta
		f.pos += f.vel * delta
	flecks.assign(flecks.filter(func(f: Fleck) -> bool: return f.life > 0.0))
	for k in chalk_ticks:
		k.life -= delta
	chalk_ticks.assign(chalk_ticks.filter(func(k: ChalkTick) -> bool: return k.life > 0.0))


## One drawn frame has passed (end of _draw; tests call it directly).
func advance_draw_frame() -> void:
	star_frames_left = maxi(0, star_frames_left - 1)


func _play(id: StringName, volume_db: float) -> void:
	if sfx_player.is_valid():
		sfx_player.call(id, volume_db)
	else:
		AudioService.play(id, volume_db)


func _draw() -> void:
	if stats:
		if star_frames_left > 0:
			var m := star_pos.round()
			var arm := float(stats.muzzle_star_px)
			draw_line(m - Vector2(arm, 0), m + Vector2(arm, 0), Pal.GAS_5, 1.0)
			draw_line(m - Vector2(0, arm), m + Vector2(0, arm), Pal.GAS_5, 1.0)
		for f in flecks:
			var fc := Pal.BONE_4 if f.life > f.max_life * 0.35 else Pal.BONE_1
			draw_rect(Rect2(f.pos.round(), Vector2.ONE), fc)
		var half := float(stats.tick_len_px) * 0.5
		for k in chalk_ticks:
			var kc := k.pos.round()
			draw_line((kc - k.dir * half).round(), (kc + k.dir * half).round(), Pal.BONE_2, 1.0)
	advance_draw_frame()
