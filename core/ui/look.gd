class_name Look
extends RefCounted
## The visual fidelity ladder's colour dial (ART-001 §15). Act 0 draws in the Neon Cabinet palette;
## THE PRETENCE sweeps `t` from 0 (neon arcade) to 1 (the base palette, the Aether). Every cabinet colour goes through
## `Look.c(Pal.X)`, so the same 32 roles morph entry by entry and the faction laws never break.
## A presentation dial, like the theme: global, not game state, never saved.

## 0 = Neon Cabinet (T0), 1 = base palette (§4), the Aether look (§16). Set by the cabinet and the reveal.
static var t := 0.0

## Neon Cabinet palette (ART-001 §15.2), keyed by the base palette entry's name.
const NEON := {
	"VOID-0": Color8(0x00, 0x00, 0x00), "VOID-1": Color8(0x06, 0x06, 0x1E), "VOID-2": Color8(0x0C, 0x0C, 0x3A),
	"VOID-3": Color8(0x15, 0x1A, 0x66), "VOID-4": Color8(0x26, 0x33, 0xD9), "VOID-5": Color8(0x5B, 0x6C, 0xFF),
	"BONE-0": Color8(0x2B, 0x2B, 0x4D), "BONE-1": Color8(0x4A, 0x4A, 0x80), "BONE-2": Color8(0x8C, 0x8C, 0xC0),
	"BONE-3": Color8(0xC8, 0xC8, 0xF0), "BONE-4": Color8(0xE8, 0xE8, 0xFF), "BONE-5": Color8(0xFF, 0xFF, 0xFF),
	"CHOIR-0": Color8(0x33, 0x00, 0x2B), "CHOIR-1": Color8(0x66, 0x00, 0x4F), "CHOIR-2": Color8(0xA8, 0x00, 0x8A),
	"CHOIR-3": Color8(0xF0, 0x00, 0xC0), "CHOIR-4": Color8(0xFF, 0x4D, 0xE1), "CHOIR-5": Color8(0xFF, 0xB3, 0xF7),
	"PHOS-0": Color8(0x00, 0x26, 0x26), "PHOS-1": Color8(0x00, 0x5A, 0x5A), "PHOS-2": Color8(0x00, 0x9E, 0x9E),
	"PHOS-3": Color8(0x00, 0xE0, 0xE0), "PHOS-4": Color8(0x33, 0xFF, 0xF2), "PHOS-5": Color8(0xB3, 0xFF, 0xFF),
	"GAS-0": Color8(0x3A, 0x1F, 0x00), "GAS-1": Color8(0x7A, 0x44, 0x00), "GAS-2": Color8(0xFF, 0x88, 0x00),
	"GAS-3": Color8(0xFF, 0xC4, 0x00), "GAS-4": Color8(0xFF, 0xF0, 0x33), "GAS-5": Color8(0xFF, 0xFF, 0xB3),
	"NULL": Color8(0x00, 0x00, 0x00), "SIGNAL": Color8(0xFF, 0x1F, 0x3D),
}

static var _by_rgba: Dictionary = {}   # base palette colour (rgba32) -> neon colour


## The colour to draw for base palette entry `lamp` at the current point on the ladder.
## Colours that are not palette entries pass through unchanged.
static func c(lamp: Color) -> Color:
	if t >= 1.0:
		return lamp
	if _by_rgba.is_empty():
		for name: String in Pal.ALL:
			_by_rgba[(Pal.ALL[name] as Color).to_rgba32()] = NEON[name]
	var key := Color(lamp.r, lamp.g, lamp.b, 1.0).to_rgba32()
	if not _by_rgba.has(key):
		return lamp
	var neon: Color = _by_rgba[key]
	var out := neon.lerp(Color(lamp.r, lamp.g, lamp.b, 1.0), clampf(t, 0.0, 1.0))
	out.a = lamp.a
	return out
