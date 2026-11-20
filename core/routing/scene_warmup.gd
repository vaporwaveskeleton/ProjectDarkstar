class_name SceneWarmup
extends RefCounted
## Draws a scene's materials and particles once in a hidden SubViewport before the scene is shown,
## so the GPU compiles their pipelines off-camera (Q-T243: the first Unmaking hitched on its first
## frames). The SubViewport copies the root's 2D MSAA and HDR settings, because a pipeline compiled
## for another framebuffer format would not be reused. Nothing here is ever on screen.

const SIZE := Vector2i(64, 64)     ## ✱ px, the hidden target
const FRAMES := 2                  ## ✱ frames drawn before the warm-up is freed


## Instances `packed` without adding it to the tree (no _ready runs), collects its CanvasItem
## materials and GPU particles, draws them for FRAMES frames under `host`, then frees everything.
static func warm(host: Node, packed: PackedScene) -> void:
	if host == null or packed == null or not host.is_inside_tree():
		return
	var root := host.get_tree().root
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.msaa_2d = root.msaa_2d
	vp.use_hdr_2d = root.use_hdr_2d
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var inst := packed.instantiate()
	var stack: Array[Node] = [inst]
	var seen := {}
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is GPUParticles2D:
			var p := (n as GPUParticles2D).duplicate(0) as GPUParticles2D
			p.position = Vector2(SIZE) * 0.5
			p.emitting = true
			vp.add_child(p)
		elif n is CanvasItem:
			var m := (n as CanvasItem).material
			if m != null and not seen.has(m):
				seen[m] = true
				var r := ColorRect.new()
				r.size = Vector2(SIZE)
				r.material = m
				vp.add_child(r)
	inst.free()
	host.add_child(vp)
	for _i in FRAMES:
		await host.get_tree().process_frame
	vp.queue_free()
