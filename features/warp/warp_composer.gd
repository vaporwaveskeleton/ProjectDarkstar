class_name WarpComposer
extends Node
## WarpComposer (TECH-001 §5.1): one per sector, the single owner of which warp effects are live.
## Built for the M2 slice's T1 set (Q-T100; WARP-001 §2.2):
##   standing  W1-01 Wrong Three, W1-03 Parallax Arrives  — the PM-01 AetherLook draws them (far layer);
##                                                          this composer adds the near mote sheets
##             W1-02 Breathing          — Grub/Sepulchre views and geode teeth scale ±breath_px
##             W1-05 Teeth in the Rock  — a WarpTeeth ring on every geode
##             W1-08 Chant Under Music  — a buried chant bed (AudioService) + its visual chant mark
##   Frayed    W1-06 Chromatic Edge     — play-layer edge split + the far layer's split
##             W1-07 False Chant        — a positional chant from an empty direction, 1 per 40 s
##   scheduled W1-09 Smudged Blip, W1-10 Ledger Smudge — through HudLiar (Smear, Glyph; never lies)
## Laws held here: the tier comes from RunSessionCore at Seam entry (WARP-001 §1.3) and is never saved;
## nothing fires in the first `entry_quiet_s` (§1.4); ≤ `novel_per_sector` novel transients (R-02); the
## live cost sum stays ≤ `budget_ms` (§5.2); Steady Ledger pins W1-09/W1-10 off (§4.4); photosensitivity
## and reduced motion swap variants live (§4.5); no hitbox, radius or speed is ever touched (§5.1).
## Also wires SYS-001 §1.5 `Warp Tier passive` (−0.1/s × T) into the sector's Composure.

signal warp_tier_set(tier: int)
signal warp_effect_started(effect_id: StringName)
signal warp_effect_ended(effect_id: StringName)

const MOTES_SHADER := preload("res://shaders/warp/warp_motes.gdshader")
const EDGE_SHADER := preload("res://shaders/warp/warp_chromatic_edge.gdshader")
const SHOWCASE_ARG := "--warp-showcase"
const TEETH_NAME := &"WarpTeeth"
const SCAN_S := 0.5            ## ✱ how often new geodes / views are picked up
const FADE_IN_S := 3.0         ## ✱ standing set fades in after entry_quiet_s (no luminance step, §1.4)
const CHANT_BED_LEVEL := 0.07  ## ✱ W1-08 buried chant level (AudioService 0..1; Ruins uses 0.08)
const FALSE_CHANT_DB := -10.0  ## ✱ W1-07 positional cue level
## ✱ first false cue after dropping into Frayed, as a fraction of the 40 s period: at T1 the passive
## drain crosses the Frayed band in about 30 s, so the first cue must land inside that visit.
const FIRST_FALSE_CHANT := 0.25

@export var warp_set: WarpSet
@export var tier_stats: WarpTierStats

## Injected by the sector (bind). Any may be null in tests.
var session: RunSessionCore
var composure: Composure
var far: AetherFarLayer
var compass: LedgerCompass
var index_strip: VigilIndexStrip
var camera: Camera2D
var torus: Torus
var vigil: Node2D

var tier: WarpTier = WarpTier.new()
var schedule: WarpSchedule = WarpSchedule.new()
var liar: HudLiar = HudLiar.new()
## Seam depth of the standing set (WARP-001 §2.2 escalation inside Act 1's window).
var depth: float = 1.0
## Composer clock (s since sector entry); physics-stepped, so it stops while the tree is paused.
var t: float = 0.0
## Effect ids live now.
var live: Dictionary = {}
## Ids refused this sector (budget or novelty), for tests and the dev overlay.
var refused: Array[StringName] = []
var showcase := false

var _cam_centre := Vector2.ZERO
var _cam_last := Vector2.ZERO
var _scan_left := 0.0
var _next_false_chant := INF
var _false_chant_end := -1.0
var _breathers: Array[CanvasItem] = []
var _teeth: Array[WarpTeeth] = []
var _motes_back: ColorRect
var _motes_front: ColorRect
var _edge: ColorRect
var _sign: WarpChantSign
var _chant_player: AudioStreamPlayer2D
var _bound := false


func _ready() -> void:
	showcase = OS.is_debug_build() and OS.get_cmdline_user_args().has(SHOWCASE_ARG)


## Sector entry: inject the sector's pieces, compute the tier, build the standing set.
func bind(p_session: RunSessionCore, p_composure: Composure, p_far: AetherFarLayer,
		p_compass: LedgerCompass, p_strip: VigilIndexStrip, p_camera: Camera2D, p_torus: Torus,
		p_vigil: Node2D) -> void:
	session = p_session
	composure = p_composure
	far = p_far
	compass = p_compass
	index_strip = p_strip
	camera = p_camera
	torus = p_torus
	vigil = p_vigil
	enter_seam()


## (Re)computes the tier for the current Seam and resets the sector's warp state (WARP-001 §1.5:
## the tier is recomputed at every Seam entry). Called by bind and when the session is swapped.
func enter_seam() -> void:
	for id in live.keys():
		_end(id as StringName)
	live.clear()
	refused.clear()
	t = 0.0
	var inputs := session.warp_inputs() if session else {}
	tier = WarpTier.compute(tier_stats, int(inputs.get("act", 1)), int(inputs.get("entropy", 0)),
		bool(inputs.get("hollow", false)), bool(inputs.get("composure_zero", false)))
	var seam := int(inputs.get("seam_index", 1))
	depth = warp_set.depth_for_seam(seam) if warp_set else 1.0
	schedule = WarpSchedule.plan(warp_set, int(inputs.get("seed", 0)), seam)
	if showcase:
		_plan_showcase()
	liar = HudLiar.new()
	liar.tier = current_tier()
	if compass:
		compass.model.liar = liar
	if index_strip:
		index_strip.liar = liar
	if far:
		far.set_tier(current_tier())
	_next_false_chant = INF
	_false_chant_end = -1.0
	_build_layers()
	_bound = true
	_scan_left = 0.0
	if camera:
		_cam_last = camera.global_position
		_cam_centre = _cam_last
	warp_tier_set.emit(current_tier())


func current_tier() -> int:
	return tier.effective(tier_stats)


## True when this sector runs the T1 set (WARP-001 §1.3: Act 1 = T1).
func runs_set() -> bool:
	return warp_set != null and current_tier() >= warp_set.tier


func is_live(effect_id: StringName) -> bool:
	return live.has(effect_id)


func live_count() -> int:
	return live.size()


## Sum of the live effects' cost (ms/frame, budgeted ✱), with reduced variants where they apply.
func live_cost_ms() -> float:
	var sum := 0.0
	for id in live.keys():
		var e := warp_set.effect(id as StringName)
		if e:
			sum += e.cost_ms(_reduced())
	return sum


func _physics_process(delta: float) -> void:
	if not _bound:
		return
	step(delta)


## One composer tick (tests drive it directly).
func step(delta: float) -> void:
	t += delta
	liar.now_s = t
	# SYS-001 §1.5 `Warp Tier passive`, from the end of the entry quiet (WARP-001 §1.4: entry never
	# costs Composure directly; nothing warp-driven happens in the first entry_quiet_s).
	if composure and (warp_set == null or t >= warp_set.entry_quiet_s):
		composure.warp_passive(delta, current_tier())
		if composure.band == Composure.Band.HOLLOWED and tier.force_hollowed(tier_stats):
			liar.tier = current_tier()
			warp_tier_set.emit(current_tier())
	if not runs_set():
		return
	if t < warp_set.entry_quiet_s:
		return
	_step_standing()
	_step_frayed()
	_step_scheduled()
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = SCAN_S
		_scan()
	_drive_visuals()


func _step_standing() -> void:
	for e in warp_set.effects:
		if e.is_standing() and e.trigger == WarpEffect.Trigger.TIER_START and not live.has(e.id):
			_start(e.id)


## W1-06 standing while Frayed; W1-07 at the Frayed cue rate (SYS-001 §1.5 Frayed row).
func _step_frayed() -> void:
	if showcase_frayed() and composure != null and composure.band == Composure.Band.CLEAR:
		composure.change(SHOWCASE_FRAYED_VALUE - composure.value)   # dev showcase only
	var frayed := composure != null and composure.band == Composure.Band.FRAYED
	if frayed and not live.has(&"W1-06"):
		_start(&"W1-06")
	elif not frayed and live.has(&"W1-06"):
		_end(&"W1-06")
	if frayed:
		if _next_false_chant == INF:
			_next_false_chant = t + (0.0 if showcase else warp_set.false_chant_period_s * FIRST_FALSE_CHANT)
		if t >= _next_false_chant and not live.has(&"W1-07"):
			if schedule.admit(&"W1-07"):
				_start(&"W1-07")
				_false_chant_end = t + warp_set.false_chant_s
			_next_false_chant = t + warp_set.false_chant_period_s
	else:
		_next_false_chant = INF
	if live.has(&"W1-07") and t >= _false_chant_end:
		_end(&"W1-07")


func _step_scheduled() -> void:
	for id: StringName in [&"W1-09", &"W1-10"]:
		if not schedule.planned.has(id):
			continue
		if not live.has(id) and t >= schedule.start_of(id) and t < schedule.end_of(id) \
				and not refused.has(id) and not _witnessed(id):
			if HudModel.steady_ledger_on():
				continue   # WARP-001 §4.4: pinned off; the sector simply never shows it
			if not schedule.admit(id) or not _begin_deviation(id):
				refused.append(id)
				continue
			_start(id)
		elif live.has(id) and t >= schedule.end_of(id):
			_end(id)


var _done: Dictionary = {}


func _witnessed(id: StringName) -> bool:
	return _done.has(id)


func _begin_deviation(id: StringName) -> bool:
	var dur := schedule.end_of(id) - t
	if id == &"W1-09":
		return liar.begin_smear(_smear_slot(), warp_set.blip_lag_s, dur)
	if id == &"W1-10":
		var digits := str(index_strip.value).length() if index_strip else 1
		return liar.begin_glyph(posmod(int(schedule.start_of(id) * 7.0), maxi(1, digits)), dur)
	return false


## The first non-Vigil compass slot that is a Grub, else a geode, else slot 1.
func _smear_slot() -> int:
	if compass == null:
		return 1
	var kinds := compass.model.marker_kinds
	for want: StringName in [&"grub", &"geode"]:
		for i in range(1, kinds.size()):
			if kinds[i] == want:
				return i
	return 1


func _start(id: StringName) -> void:
	var e := warp_set.effect(id)
	if e == null:
		return
	if live_cost_ms() + e.cost_ms(_reduced()) > warp_set.budget_ms:
		refused.append(id)   # WARP-001 §5.3: refused, logged in dev only
		if OS.is_debug_build():
			print_verbose("WarpComposer: %s refused, over budget" % id)
		return
	live[id] = t
	match id:
		&"W1-06":
			if far:
				far.set_chromatic_edge(true)
		&"W1-07":
			_begin_false_chant()
		&"W1-08":
			AudioService.set_chant(CHANT_BED_LEVEL * depth)
	warp_effect_started.emit(id)


func _end(id: StringName) -> void:
	if not live.has(id):
		return
	live.erase(id)
	match id:
		&"W1-06":
			if far:
				far.set_chromatic_edge(false)
		&"W1-07":
			if _chant_player:
				_chant_player.stop()
			if _sign:
				_sign.false_dir = Vector2.ZERO
		&"W1-08":
			AudioService.set_chant(0.0)
		&"W1-09", &"W1-10":
			_done[id] = true
	warp_effect_ended.emit(id)


func _exit_tree() -> void:
	if live.has(&"W1-08"):
		AudioService.set_chant(0.0)


func _reduced() -> bool:
	return _setting(&"reduced_motion") or _setting(&"photosensitivity")


static func _setting(key: StringName) -> bool:
	var loop := Engine.get_main_loop() as SceneTree
	var svc: Node = loop.root.get_node_or_null(^"SettingsService") if loop else null
	if svc == null:
		return false
	return svc.call(&"get_value", key) == true


# --- visuals -------------------------------------------------------------------------------------

func _build_layers() -> void:
	if _motes_back != null:
		return
	_motes_back = _mote_rect(-6, false)
	_motes_front = _mote_rect(3, true)
	var edge_layer := CanvasLayer.new()
	edge_layer.name = &"WarpEdge"
	edge_layer.layer = 4
	add_child(edge_layer)
	_edge = ColorRect.new()
	_edge.name = &"ChromaticEdge"
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	var em := ShaderMaterial.new()
	em.shader = EDGE_SHADER
	_edge.material = em
	_edge.visible = false
	edge_layer.add_child(_edge)
	var sign_layer := CanvasLayer.new()
	sign_layer.name = &"WarpSigns"
	sign_layer.layer = 6
	add_child(sign_layer)
	_sign = WarpChantSign.new()
	_sign.name = &"ChantSign"
	_sign.set_anchors_preset(Control.PRESET_FULL_RECT)
	sign_layer.add_child(_sign)
	_chant_player = AudioStreamPlayer2D.new()
	_chant_player.name = &"FalseChant"
	_chant_player.bus = &"BUS-CHO"
	_chant_player.volume_db = FALSE_CHANT_DB
	var chant := AudioService.chirp_stream(&"chant")
	_chant_player.stream = chant if chant != null else SfxSynth.build_chant_loop()
	add_child(_chant_player)


func _mote_rect(layer: int, front: bool) -> ColorRect:
	var cl := CanvasLayer.new()
	cl.name = &"WarpMotesFront" if front else &"WarpMotesBack"
	cl.layer = layer
	add_child(cl)
	var r := ColorRect.new()
	r.name = &"Motes"
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = MOTES_SHADER
	m.set_shader_parameter(&"foreground", front)
	m.set_shader_parameter(&"base_a", Pal.BONE_4)
	m.set_shader_parameter(&"base_b", Pal.AETHER_3)
	# The Wrong Three (W1-01): from the Aether ramp, never a faction, phosphor or SIGNAL hue.
	m.set_shader_parameter(&"wrong_a", Pal.AETHER_5)
	m.set_shader_parameter(&"wrong_b", Pal.AETHER_2)
	m.set_shader_parameter(&"wrong_c", Pal.AETHER_4)
	m.set_shader_parameter(&"intensity", 0.0)
	r.material = m
	r.visible = false
	cl.add_child(r)
	return r


## Geodes get teeth; Grub and Sepulchre views breathe. Found through the compass group the sector
## already registers them in (no new coupling).
func _scan() -> void:
	_breathers.clear()
	var tree := get_tree()
	if tree == null:
		return
	var alive_teeth: Array[WarpTeeth] = []
	for n in tree.get_nodes_in_group(LedgerCompass.GROUP):
		var kind := LedgerCompass.kind_of(n)
		if kind == &"geode" and live.has(&"W1-05"):
			var teeth := n.get_node_or_null(NodePath(String(TEETH_NAME))) as WarpTeeth
			if teeth == null:
				teeth = WarpTeeth.new()
				teeth.name = TEETH_NAME
				var r: Variant = n.get(&"radius")
				teeth.radius = float(r) if r != null else 10.0
				teeth.count = warp_set.teeth_count
				teeth.tooth_len = warp_set.teeth_len_px
				teeth.seed_value = int(n.get_instance_id() % 9973)
				n.add_child(teeth)
			alive_teeth.append(teeth)
		for c in n.get_children():
			if c is GrubView or c is SepulchreView:
				_breathers.append(c as CanvasItem)
	_teeth = alive_teeth


func _drive_visuals() -> void:
	var ps := _setting(&"photosensitivity")
	var rm := _setting(&"reduced_motion")
	var fade := clampf((t - warp_set.entry_quiet_s) / FADE_IN_S, 0.0, 1.0) * depth
	_step_cam()
	var breath := 0.0 if rm else sin(TAU * t / maxf(0.1, warp_set.breath_period_s))
	var motes_on := live.has(&"W1-03") or live.has(&"W1-01")
	for r: ColorRect in [_motes_back, _motes_front]:
		r.visible = motes_on
		var m := r.material as ShaderMaterial
		m.set_shader_parameter(&"cam", _cam_centre)
		m.set_shader_parameter(&"t", t)
		m.set_shader_parameter(&"intensity", fade)
		m.set_shader_parameter(&"twinkle", 0.0 if ps else 1.0)
		m.set_shader_parameter(&"drift", 0.0 if rm else 1.0)
		m.set_shader_parameter(&"breath", breath)
	# W1-02: a breath wave travelling outward from the Vigil; ±breath_px on views, never hitboxes.
	if live.has(&"W1-02"):
		var origin := vigil.global_position if is_instance_valid(vigil) else Vector2.ZERO
		for b in _breathers:
			if not is_instance_valid(b):
				continue
			var n2 := b as Node2D
			var lag := origin.distance_to(n2.global_position) / maxf(1.0, warp_set.breath_wave_px_s)
			var s := 0.0 if rm else sin(TAU * (t - lag) / maxf(0.1, warp_set.breath_period_s))
			var k := 1.0 + s * warp_set.breath_px * fade / 8.0   # 8 px ✱ reference half-size
			n2.scale = Vector2(k, k)
	for teeth in _teeth:
		if not is_instance_valid(teeth):
			continue
		teeth.strength = fade
		var lag2 := 0.0
		if is_instance_valid(vigil):
			lag2 = vigil.global_position.distance_to(teeth.global_position) / maxf(1.0, warp_set.breath_wave_px_s)
		var s2 := 0.0 if rm else sin(TAU * (t - lag2) / maxf(0.1, warp_set.breath_period_s))
		teeth.breath_scale = 1.0 + s2 * warp_set.breath_px * fade / maxf(4.0, teeth.radius) \
			if live.has(&"W1-02") else 1.0
	# W1-06: never drawn under photosensitivity (the wick and the flame carry the band, WARP-001 §4.6).
	_edge.visible = live.has(&"W1-06") and not ps
	if _edge.visible:
		var em := _edge.material as ShaderMaterial
		em.set_shader_parameter(&"split_px", warp_set.chromatic_edge_px)
	_sign.under_music = live.has(&"W1-08")
	_sign.strength = clampf(fade + 0.25, 0.0, 1.0)
	_sign.still = ps or rm
	if live.has(&"W1-07"):
		_sign.phase = 1.0 - clampf((_false_chant_end - t) / maxf(0.1, warp_set.false_chant_s), 0.0, 1.0)
	if live.has(&"W1-10") and index_strip:
		index_strip.queue_redraw()


func _step_cam() -> void:
	if camera == null:
		return
	var now := camera.global_position
	_cam_centre += torus.delta(_cam_last, now) if torus else now - _cam_last
	_cam_last = now


## W1-07: the chant from a direction with no procession in it (WARP-001 §2.2). The direction is the
## one furthest from every Choir body the compass knows, from the `warp` stream.
func _begin_false_chant() -> void:
	var origin := vigil.global_position if is_instance_valid(vigil) else Vector2.ZERO
	var rng := RunSeed.new(int(t * 1000.0)).stream(RunSeed.STREAM_WARP, 0)
	var best := Vector2.RIGHT
	var best_score := -INF
	for k in 8:
		var cand := Vector2.from_angle(TAU * float(k) / 8.0 + rng.randf() * 0.3)
		var score := 0.0
		for n in get_tree().get_nodes_in_group(LedgerCompass.GROUP):
			var kind := LedgerCompass.kind_of(n)
			if kind != &"grub" and kind != &"sepulchre":
				continue
			var d := torus.delta(origin, (n as Node2D).global_position) if torus \
				else (n as Node2D).global_position - origin
			score -= maxf(0.0, cand.dot(d.normalized()))
		if score > best_score:
			best_score = score
			best = cand
	if _chant_player:
		_chant_player.global_position = origin + best * warp_set.false_chant_distance_px
		if not AudioService.muted_for_tests:
			_chant_player.play()
	if _sign:
		_sign.false_dir = best


# --- dev showcase (automation captures only; dev builds) ----------------------------------------

var _showcase_frayed_from := INF
const SHOWCASE_FRAYED_VALUE := 5.5   ## ✱ dev showcase: Composure set into the Frayed band (SYS-001 §1.5)


func showcase_frayed() -> bool:
	return showcase and t >= _showcase_frayed_from


## Deterministic order for the warp_t1 capture scenario: standing set from entry_quiet_s, W1-09 at
## +4 s, W1-10 at +8 s, then Frayed (W1-06, W1-07) from +12 s. Dev builds only (`--warp-showcase`).
func _plan_showcase() -> void:
	var q := warp_set.entry_quiet_s
	schedule.planned[&"W1-09"] = {"start_s": q + 4.0, "end_s": q + 4.0 + warp_set.blip_smear_s}
	schedule.planned[&"W1-10"] = {"start_s": q + 8.0, "end_s": q + 8.0 + warp_set.glyph_s}
	_showcase_frayed_from = q + 12.0
