class_name BezelAssembly
extends RefCounted
## Builds the parts of the one printed sheet that both the attract frame and the in-game HUD share, in the
## one draw order (TECH-001 §2.10): the defocused arcade (ArcadeBackdrop) and the cabinet's side panel (CabinetRoom) behind everything; then, on top of the two printed columns and
## below the glass, the marquee, the printed border round the rounded opening, the T-molding and the
## bolts; then the glass; then the tube over the screen (rounded mask and the very faint glass layer, the
## only thing ever drawn over the opening). One ScreenLight (the screen lights the cabinet) rides along.
## `host` is the Frame / Hud Control (a child of the ScreenRig).


## Before the glass: backdrop and room (behind the host), marquee, border, trim. Returns them so the host can hide them on peel.
static func add_sheet_parts(host: Control, rig: ScreenRig) -> Array[Control]:
	var out: Array[Control] = []
	var backdrop := ArcadeBackdrop.new()
	backdrop.rig = rig
	host.add_child(backdrop)
	out.append(backdrop)
	var room := CabinetRoom.new()
	room.rig = rig
	host.add_child(room)
	out.append(room)
	for part in [BezelMarquee.new(), BezelFrame.new()]:
		host.add_child(part)
		out.append(part)
	var trim := CabinetTrim.new()
	trim.rig = rig
	host.add_child(trim)
	out.append(trim)
	return out


## After the glass: the tube over the screen. Returns it.
static func add_tube(host: Control) -> ScreenTube:
	var t := ScreenTube.new()
	host.add_child(t)
	return t


## The screen-light sampler. `source` is the arcade screen's SubViewport (the game and the attract screen).
static func add_light(host: Node, source: SubViewport) -> ScreenLight:
	var l := ScreenLight.new()
	l.source = source
	host.add_child(l)
	return l
