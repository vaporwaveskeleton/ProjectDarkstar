class_name VectorFace
extends Resource
## How VectorText looks at a size: stroke weight, cap height, spacing and the cosmetic hand-drawn
## wobble. `jitter`, `grain` and `seed` are cosmetic (engineering-only); they use a local hash of
## `seed`, never the gameplay or warp RNG streams (TECH-001 RNG rules).

@export var stroke_width: float = 2.0         ## logical px
@export var size: float = 16.0                ## cap height, logical px
@export var tracking: float = 0.0             ## extra logical px between glyphs
@export var jitter: float = 0.0               ## ✱ cosmetic: px of per-point wobble (0 = exact)
@export var grain: float = 0.0                ## ✱ cosmetic: px of fine roughness along strokes (0 = exact)
@export var seed: int = 0                     ## ✱ cosmetic: seeds jitter and grain only


func duplicate_with(p_size: float, p_stroke: float) -> VectorFace:
	var f: VectorFace = duplicate() as VectorFace
	f.size = p_size
	f.stroke_width = p_stroke
	return f
