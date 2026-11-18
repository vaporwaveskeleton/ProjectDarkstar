class_name Pal
extends RefCounted
## ART-001 §4 palette entries as constants for code-drawn art (the Act 0 vector costume, HUD
## glyphs). Values must match assets/palettes/darkstar_palette.json — core/ui/tests checks it.

const VOID_0 := Color8(0x0A, 0x0A, 0x12)
const VOID_1 := Color8(0x13, 0x14, 0x28)
const VOID_2 := Color8(0x1D, 0x20, 0x40)
const VOID_3 := Color8(0x2A, 0x30, 0x57)
const VOID_4 := Color8(0x3C, 0x45, 0x74)
const VOID_5 := Color8(0x56, 0x60, 0x8F)
const BONE_0 := Color8(0x3A, 0x3B, 0x44)
const BONE_1 := Color8(0x5A, 0x5C, 0x67)
const BONE_2 := Color8(0x8A, 0x8C, 0x93)
const BONE_3 := Color8(0xB9, 0xB8, 0xAE)
const BONE_4 := Color8(0xE4, 0xDF, 0xD1)
const BONE_5 := Color8(0xF7, 0xF4, 0xE8)
const CHOIR_0 := Color8(0x2C, 0x12, 0x30)
const CHOIR_1 := Color8(0x4A, 0x1C, 0x4A)
const CHOIR_2 := Color8(0x6E, 0x2A, 0x64)
const CHOIR_3 := Color8(0x9A, 0x3E, 0x76)
const CHOIR_4 := Color8(0xC5, 0x5A, 0x86)
const CHOIR_5 := Color8(0xEF, 0xA6, 0xB0)
const PHOS_0 := Color8(0x0C, 0x2A, 0x2E)
const PHOS_1 := Color8(0x14, 0x51, 0x4F)
const PHOS_2 := Color8(0x1E, 0x7C, 0x71)
const PHOS_3 := Color8(0x34, 0xA8, 0x8F)
const PHOS_4 := Color8(0x62, 0xCF, 0xA8)
const PHOS_5 := Color8(0xA8, 0xF0, 0xD0)
const GAS_0 := Color8(0x3A, 0x24, 0x10)
const GAS_1 := Color8(0x6B, 0x44, 0x15)
const GAS_2 := Color8(0xA8, 0x70, 0x1F)
const GAS_3 := Color8(0xD9, 0x9A, 0x2E)
const GAS_4 := Color8(0xF2, 0xC6, 0x5C)
const GAS_5 := Color8(0xFF, 0xEF, 0xC0)
const NULL := Color8(0x00, 0x00, 0x00)
const SIGNAL := Color8(0xFF, 0x4A, 0x57)

const ALL := {
	"VOID-0": VOID_0, "VOID-1": VOID_1, "VOID-2": VOID_2, "VOID-3": VOID_3, "VOID-4": VOID_4, "VOID-5": VOID_5,
	"BONE-0": BONE_0, "BONE-1": BONE_1, "BONE-2": BONE_2, "BONE-3": BONE_3, "BONE-4": BONE_4, "BONE-5": BONE_5,
	"CHOIR-0": CHOIR_0, "CHOIR-1": CHOIR_1, "CHOIR-2": CHOIR_2, "CHOIR-3": CHOIR_3, "CHOIR-4": CHOIR_4, "CHOIR-5": CHOIR_5,
	"PHOS-0": PHOS_0, "PHOS-1": PHOS_1, "PHOS-2": PHOS_2, "PHOS-3": PHOS_3, "PHOS-4": PHOS_4, "PHOS-5": PHOS_5,
	"GAS-0": GAS_0, "GAS-1": GAS_1, "GAS-2": GAS_2, "GAS-3": GAS_3, "GAS-4": GAS_4, "GAS-5": GAS_5,
	"NULL": NULL, "SIGNAL": SIGNAL,
}


## Vector "glow": a wide dim stroke under a thin bright one. Both colours are palette entries.
static func glow_polyline(ci: CanvasItem, pts: PackedVector2Array, bright: Color, dim: Color, closed: bool = true) -> void:
	var p := pts
	if closed and p.size() > 0:
		p = pts.duplicate()
		p.append(pts[0])
	ci.draw_polyline(p, dim, 3.0)
	ci.draw_polyline(p, bright, 1.0)
