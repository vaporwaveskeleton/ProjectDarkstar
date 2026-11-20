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

const SIZE := Vector2i(64, 64)     ## ✱ px, the hidden target
const FRAMES := 2                  ## ✱ frames drawn before the warm-up is freed


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


## Instances `packed` without adding it to the tree (no _ready runs), collects its CanvasItem
## materials and GPU particles, draws them for FRAMES frames under `host`, then frees everything.
static func warm(host: Node, packed: PackedScene) -> void:
	if host == null or packed == null or not host.is_inside_tree():
		return
	var root := host.get_tree().root
	var targets: Array[SubViewport] = [_target(root.msaa_2d, root.use_hdr_2d)]
	if root.msaa_2d != Viewport.MSAA_DISABLED or not root.use_hdr_2d:
		targets.append(_target(Viewport.MSAA_DISABLED, true))
	var inst := packed.instantiate()
	var stack: Array[Node] = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is GPUParticles2D:
			var flags := Node.DUPLICATE_SCRIPTS if n.get_script() != null else 0
			for vp in targets:
				var p := (n as GPUParticles2D).duplicate(flags) as GPUParticles2D
				p.position = Vector2(SIZE) * 0.5
				p.emitting = true
				vp.add_child(p)
	for m in materials_of(inst):
		for vp in targets:
			var r := ColorRect.new()
			r.size = Vector2(SIZE)
			r.material = m
			vp.add_child(r)
	inst.free()
	for vp in targets:
		host.add_child(vp)
	for _i in FRAMES:
		await host.get_tree().process_frame
	for vp in targets:
		vp.queue_free()


static func _target(msaa: Viewport.MSAA, hdr: bool) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.msaa_2d = msaa
	vp.use_hdr_2d = hdr
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	return vp
