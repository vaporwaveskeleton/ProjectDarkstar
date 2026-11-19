class_name RuinsLookData
extends TunableResource
## The look of the Ruins hall on the first visit (NARR-001 §5.7, ART-001 §16): one warm hall
## lantern, deep VOID shadows, brass and glass and chalk, the Aether seen outside through the
## hangar mouth and the torn vault. Colours are Pal entries; every number is an engineering ✱
## visual parameter (no game number lives here; SYS-001 owns those).

@export_group("Palette roles (Pal entries only)")
## Ambient: the CanvasModulate of the hall layer (deep shadow; never black).
@export var ambient: Color = Pal.VOID_3
## Hall lantern and Tree-lamp light colours (GAS only in a lamp's light and its own glass).
@export var lantern_colour: Color = Pal.GAS_4
@export var lamp_colour: Color = Pal.GAS_3
## Stone, mortar, floor and recess albedos (lit by the lamps).
@export var stone_a: Color = Pal.BONE_1
@export var stone_b: Color = Pal.BONE_0
@export var mortar: Color = Pal.VOID_2
@export var floor_a: Color = Pal.BONE_1
@export var floor_b: Color = Pal.VOID_3
## Brass (BONE mixes under warm light; ART-001 §16.6a) and its engraved shadow.
@export var brass: Color = Pal.BONE_2
@export var brass_hi: Color = Pal.BONE_4
@export var brass_shadow: Color = Pal.VOID_3
## Chalk marks on the stone.
@export var chalk: Color = Pal.BONE_4
## Veil over the openings: the Aether reads far and outside.
@export var veil: Color = Pal.VOID_1
## Cool spill of the Aether through the openings (haze, rim light).
@export var spill: Color = Pal.AETHER_3

@export_group("Lights ✱")
## ✱ hall lantern PointLight2D energy and radius (logical px); its core's HDR multiplier.
@export var lantern_energy: float = 1.7
@export var lantern_radius: float = 175.0
@export var lantern_core_hdr: float = 1.8
## ✱ Tree lamp energy, radius and core HDR (always below the hall lantern: lantern law).
@export var lamp_energy: float = 1.0
@export var lamp_radius: float = 85.0
@export var lamp_core_hdr: float = 1.2
## ✱ the hall lantern's pool on the floor beneath it: share of the lantern's energy, radius, and
## vertical squash (the floor seen at a low angle).
@export var floor_pool_share: float = 0.5
@export var floor_pool_radius: float = 150.0
@export var floor_pool_squash: float = 0.38
## ✱ light at the hangar mouth when fully lit (PointLight2D energy) and its radius.
@export var mouth_energy: float = 1.2
@export var mouth_radius: float = 105.0
## ✱ each lit lamp's share of the remaining mouth darkness: mouth = 1 − Π(1 − share × level).
@export_range(0.05, 1.0) var mouth_share: float = 0.55
## ✱ the hourglass's pool (by the mouth), at full mouth light.
@export var hourglass_energy: float = 0.7
## ✱ the wall Cabinet's phosphor spill (attract mode running; cool, low).
@export var cabinet_energy: float = 0.3
## ✱ haze (light in dusty air) strength around the lamps, and the cool spill through the openings.
@export var haze: float = 0.16
@export var spill_strength: float = 0.05

@export_group("Openings ✱")
## ✱ veil alpha over the hangar mouth before any Tree lamp: near-black (NARR-001 §5.7 "dark"; Q-T156).
## The veil's own colour is `veil` (VOID-1), so the mouth is never pure black.
@export_range(0.0, 1.0) var mouth_veil_dark: float = 1.0
## ✱ veil alpha once the first lamp has caught (the dim Aether glimpse), and the most that
## `mouth_aether_hint` lets through before any lamp.
@export_range(0.0, 1.0) var mouth_veil_glimpse: float = 0.88
## ✱ veil alpha with every lamp lit.
@export_range(0.0, 1.0) var mouth_veil_lit: float = 0.3
## ✱ before any lamp: 0 = the mouth is dark; 1 = the dim Aether glimpse (`mouth_veil_glimpse`)
## shows through it. An owner look switch (Q-T156); lamp-lit behaviour does not change.
@export_range(0.0, 1.0) var mouth_aether_hint: float = 0.0
## ✱ veil alpha over the torn vault.
@export_range(0.0, 1.0) var hole_veil: float = 0.38

@export_group("Props ✱")
## Tint of a focused prop's lift (a chalk rim of light, never a flash; Q-T158).
@export var prop_focus_tint: Color = Pal.BONE_4
## ✱ a focused prop's brightness lift (fraction over its own look), and a used prop's dimming.
@export_range(0.0, 0.5) var prop_focus_lift: float = 0.18
@export_range(0.0, 0.8) var prop_used_dim: float = 0.25

@export_group("Timing ✱")
## ✱ first visit: delay before the hall lantern catches, and how long the catch takes (s).
@export var entry_delay_s: float = 0.6
@export var entry_catch_s: float = 1.6
## ✱ a Tree lamp's catch (s).
@export var lamp_catch_s: float = 2.4
## ✱ a caught lamp's gentle breathing: rate (Hz, far under the 3 Hz rule) and depth.
@export var breath_hz: float = 0.18
@export var breath_depth: float = 0.03
## ✱ photosensitivity bound: the most a lamp's output may change in one 60 Hz frame (fraction of full).
@export var max_step_per_frame: float = 0.02

@export_group("Outside")
## The Aether seen through the openings (dimmed).
@export var outside_look: AetherLook


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["lantern_energy", "lantern_radius", "lantern_core_hdr", "floor_pool_share",
		"floor_pool_radius", "floor_pool_squash", "lamp_energy", "lamp_radius",
		"lamp_core_hdr", "mouth_energy", "mouth_radius", "mouth_share", "hourglass_energy", "cabinet_energy", "haze",
		"spill_strength", "mouth_veil_dark", "mouth_veil_glimpse", "mouth_veil_lit", "mouth_aether_hint",
		"hole_veil", "prop_focus_lift", "prop_used_dim", "entry_delay_s", "entry_catch_s",
		"lamp_catch_s", "breath_hz", "breath_depth", "max_step_per_frame"])


func colour_fields() -> PackedStringArray:
	return PackedStringArray(["ambient", "lantern_colour", "lamp_colour", "stone_a", "stone_b", "mortar", "floor_a",
		"floor_b", "brass", "brass_hi", "brass_shadow", "chalk", "veil", "spill", "prop_focus_tint"])
