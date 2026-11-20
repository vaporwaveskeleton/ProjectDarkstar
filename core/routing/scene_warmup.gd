class_name SceneWarmup
extends RefCounted
## Draws a scene's materials and particles once in hidden SubViewports before the scene is shown,
## so the GPU compiles their pipelines off-camera (Q-T243: the first Unmaking hitched on its first
## frames). The SubViewports copy the root's 2D MSAA and HDR settings, because a pipeline compiled
## for another framebuffer format would not be reused; a second target has the HDR, no-MSAA format
## of an offscreen Aether layer. Nothing here is ever on screen.
## Q-T340: materials that a node builds in code in `_ready` (AetherShaderRect, from its exported
## `shader`) do not exist on the un-mounted instance, so their shader is wrapped in a throwaway
## material here, and a particle node keeps its script so its `_ready` makes its materials.
## Q-T344: `warm_spread` does the same a few items per frame under a time budget (one blocking pass
## stalled the reveal's black frame for 0.9 s), and `warm` stays as the one-shot fallback.

const SIZE := Vector2i(64, 64)     ## ✱ px, the hidden target
const FRAMES := 2                  ## ✱ frames drawn before the warm-up is freed
const BUDGET_MS := 4.0             ## ✱ ms of extra frame time `warm_spread` aims to add per frame
const BASE_MS := 2.0               ## ✱ ms a frame costs without warm-up (to read the added cost)
const PAUSE_MS := 20.0             ## ✱ a frame slower than this pauses the spread for one frame


## The distinct materials a scene instance would draw with: every CanvasItem material, plus a
## throwaway ShaderMaterial for each node that has no material yet but an exported `shader`.
static func materials_of(inst: Node) -> Array[Material]:
	var out: Array[Material] = []
	var seen := {}
	var stack: Array[Node] = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if not n is CanvasItem or n is GPUParticles2D:
			continue
		var m := (n as CanvasItem).material
		if m == null:
			var sh := n.get(&"shader") as Shader
			if sh != null:
				var sm := ShaderMaterial.new()
				sm.shader = sh
				m = sm
		if m != null and not seen.has(m):
			seen[m] = true
			out.append(m)
	return out


## One-shot: draws everything for FRAMES frames under `host`, then frees it. Blocks that long.
static func warm(host: Node, packed: PackedScene) -> void:
	if host == null or packed == null or not host.is_inside_tree():
		return
	var targets := _targets(host)
	var inst := packed.instantiate()
	var jobs := _jobs(inst)
	for j: Variant in jobs:
		_add_job(j, targets, inst)
	inst.free()
	for vp in targets:
		host.add_child(vp)
	for _i in FRAMES:
		await host.get_tree().process_frame
	for vp in targets:
		if is_instance_valid(vp):
			vp.queue_free()

## Spread (Q-T344): draws every shader of the scene at `path` a few jobs per frame, so the added frame
## time stays near BUDGET_MS (the job cost is learned from the frames just drawn). It never
## instantiates the scene (that alone cost 125 ms on the main thread, and is not safe on a worker):
## the shaders come from the resource dependencies and from `res://` shader paths in the scripts
## among them (AetherLife preloads its particle shaders). `state["done"]` becomes true when all are
## drawn and freed; `state["jobs"]` / `state["left"]` say how many there were and are left.
static func warm_spread(host: Node, path: String, state: Dictionary) -> void:
	state["done"] = false
	if host == null or path == "" or not host.is_inside_tree():
		state["done"] = true
		return
	var tree := host.get_tree()
	var targets := _targets(host)
	for vp in targets:
		host.add_child(vp)
	var jobs := shader_jobs(path)
	state["jobs"] = jobs.size()
	var next := 0
	var live: Array = []                  # [frame_added, Array[Node]]
	var est := BUDGET_MS                  # ms one job adds to a frame, learned below
	var frame := 0
	var last := Time.get_ticks_usec()
	while next < jobs.size() or not live.is_empty():
		var added := 0
		if next < jobs.size() and float(state.get("last_ms", 0.0)) <= PAUSE_MS:
			var n := maxi(int(BUDGET_MS / maxf(est, 0.1)), 1)
			var nodes: Array[Node] = []
			while added < n and next < jobs.size():
				nodes.append_array(_add_shader_job(jobs[next] as Dictionary, targets))
				next += 1
				added += 1
			live.append([frame, nodes])
		state["left"] = jobs.size() - next
		await tree.process_frame
		if not is_instance_valid(host):
			state["done"] = true
			return
		frame += 1
		var now := Time.get_ticks_usec()
		var ms := float(now - last) / 1000.0
		last = now
		state["last_ms"] = ms
		state["max_ms"] = maxf(float(state.get("max_ms", 0.0)), ms)
		if added > 0:
			est = lerpf(est, maxf(ms - BASE_MS, 0.1) / float(added), 0.5)
		while not live.is_empty() and frame - int((live[0] as Array)[0]) >= FRAMES:
			for node: Node in (live.pop_front() as Array)[1]:
				if is_instance_valid(node):
					node.queue_free()
	for vp in targets:
		if is_instance_valid(vp):
			vp.queue_free()
	state["done"] = true


## The shaders the scene at `path` draws with, as jobs {"shader": Shader, "draw": Shader or null}: a
## canvas_item shader is drawn on a rect; a particles shader runs on a GPUParticles2D, with the
## sibling `<name>_draw.gdshader` (if any) as its draw material. Follows scene and resource
## dependencies, and `res://...gdshader` strings in the scripts found on the way.
static func shader_jobs(path: String) -> Array:
	var paths: Array[String] = []
	_collect_shaders(path, {}, paths)
	var jobs: Array = []
	for p in paths:
		var sh := load(p) as Shader
		if sh == null:
			continue
		if sh.get_mode() == Shader.MODE_PARTICLES:
			var draw_path := p.get_basename() + "_draw.gdshader"
			jobs.append({"shader": sh, "draw": load(draw_path) as Shader if paths.has(draw_path) else null})
		elif sh.get_mode() == Shader.MODE_CANVAS_ITEM:
			# a `_draw` shader that belongs to a particles shader is drawn with it, not alone
			var owner_path := p.get_basename().trim_suffix("_draw") + ".gdshader"
			if p.ends_with("_draw.gdshader") and paths.has(owner_path) and (load(owner_path) as Shader).get_mode() == Shader.MODE_PARTICLES:
				continue
			jobs.append({"shader": sh, "draw": null})
	return jobs


static func _collect_shaders(path: String, seen: Dictionary, out: Array[String]) -> void:
	if seen.has(path):
		return
	seen[path] = true
	if path.ends_with(".gdshader"):
		out.append(path)
		return
	if path.ends_with(".gd"):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var src := f.get_as_text()
			var rx := RegEx.create_from_string("\"(res://[^\"]+\\.gdshader)\"")
			for m in rx.search_all(src):
				_collect_shaders(m.get_string(1), seen, out)
		return
	if not (path.ends_with(".tscn") or path.ends_with(".tres") or path.ends_with(".scn") or path.ends_with(".res")):
		return
	for d in ResourceLoader.get_dependencies(path):
		var p := d.get_slice("::", 2) if "::" in d else d
		if p != "":
			_collect_shaders(p, seen, out)


static func _add_shader_job(job: Dictionary, targets: Array[SubViewport]) -> Array[Node]:
	var out: Array[Node] = []
	var sh := job["shader"] as Shader
	for vp in targets:
		var m := ShaderMaterial.new()
		m.shader = sh
		if sh.get_mode() == Shader.MODE_PARTICLES:
			var p := GPUParticles2D.new()
			p.process_material = m
			if job["draw"] != null:
				var dm := ShaderMaterial.new()
				dm.shader = job["draw"] as Shader
				p.material = dm
			p.amount = 4
			p.position = Vector2(SIZE) * 0.5
			p.emitting = true
			vp.add_child(p)
			out.append(p)
		else:
			var r := ColorRect.new()
			r.size = Vector2(SIZE)
			r.material = m
			vp.add_child(r)
			out.append(r)
	return out


static func _targets(host: Node) -> Array[SubViewport]:
	var root := host.get_tree().root
	var targets: Array[SubViewport] = [_target(root.msaa_2d, root.use_hdr_2d)]
	if root.msaa_2d != Viewport.MSAA_DISABLED or not root.use_hdr_2d:
		targets.append(_target(Viewport.MSAA_DISABLED, true))
	return targets


## What to draw: every GPUParticles2D node (as itself) and every material.
static func _jobs(inst: Node) -> Array:
	var jobs: Array = []
	var stack: Array[Node] = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is GPUParticles2D:
			jobs.append(n)
	jobs.append_array(materials_of(inst))
	return jobs


## Puts one job into every target; returns the nodes made (to free later).
static func _add_job(job: Variant, targets: Array[SubViewport], _inst: Node) -> Array[Node]:
	var out: Array[Node] = []
	for vp in targets:
		if job is GPUParticles2D:
			var src := job as GPUParticles2D
			# keep the script (flag 4): a script builds its process and draw materials in _ready
			var p := src.duplicate(Node.DUPLICATE_SCRIPTS if src.get_script() != null else 0) as GPUParticles2D
			p.position = Vector2(SIZE) * 0.5
			p.emitting = true
			vp.add_child(p)
			out.append(p)
		else:
			var r := ColorRect.new()
			r.size = Vector2(SIZE)
			r.material = job as Material
			vp.add_child(r)
			out.append(r)
	return out


static func _target(msaa: Viewport.MSAA, hdr: bool) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.msaa_2d = msaa
	vp.use_hdr_2d = hdr
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	return vp
