class_name ScreenRegisters
extends TunableResource
## Act 0 arcade screen: the Williams video limits (owner direction 2026-11-18, layer one only).
## The screen shows at most 16 colours at once, each chosen from RGB332 (3 bits red, 3 green, 2 blue).
## The 16 colour registers can be written at any time (cycling, fades = register writes). A video
## frame is 16.64 ms (14-bit counter at 1 MHz reloaded 0x3F00 = 16640 counts); gameplay stays at 60 Hz.
## This resource is the power-on state and the Pal-name map; the live registers are VideoRegisters.
## The bezel and anything outside the screen hole is never limited. The limits fade out as Look.t 0 -> 1.
## All values are engineering/presentation data (TECH-001), none are game numbers.

## Power-on register colours, RGB332-exact.
@export var defaults: PackedColorArray = PackedColorArray([
	Color8(0x00, 0x00, 0x00), Color8(0x00, 0x00, 0x55), Color8(0x24, 0x24, 0xFF), Color8(0x49, 0x6D, 0xFF),
	Color8(0x49, 0x49, 0xAA), Color8(0xB6, 0xB6, 0xFF), Color8(0xFF, 0xFF, 0xFF), Color8(0xB6, 0x00, 0xAA),
	Color8(0xFF, 0x00, 0xFF), Color8(0xFF, 0xB6, 0xFF), Color8(0x00, 0x92, 0xAA), Color8(0x00, 0xFF, 0xFF),
	Color8(0xB6, 0xFF, 0xFF), Color8(0xFF, 0x92, 0x00), Color8(0xFF, 0xFF, 0x00), Color8(0xFF, 0x00, 0x00),
])
## Palette entry name (Pal / Look.NEON key) -> the register its pixels are assigned to.
@export var pal_map: Dictionary = {}
## One video frame, seconds (16640 counts at 1 MHz). Register cycling counts these.
@export var video_frame_s: float = 0.01664

const REGISTER_COUNT := 16
const CYCLING_REGISTER := 15   ## flashes, explosions, SIGNAL red


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["video_frame_s"])


## Snap each channel to the nearest RGB332 level, expressed as the 8-bit value (R/G: v*255/7, B: v*255/3), so results equal the hex colours exactly. Alpha is kept.
static func to_rgb332(c: Color) -> Color:
	return Color(
		roundf(roundf(c.r * 7.0) * 255.0 / 7.0) / 255.0,
		roundf(roundf(c.g * 7.0) * 255.0 / 7.0) / 255.0,
		roundf(roundf(c.b * 3.0) * 255.0 / 3.0) / 255.0,
		c.a)
