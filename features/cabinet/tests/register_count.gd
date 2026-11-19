extends RefCounted
## Dev/test helper (Q-T108): how many of the Act 0 screen's 16 colour registers an image uses, by the
## same nearest-match rule the CRT shader applies (VideoRegisters.nearest_register over its match set).
## Every pixel maps to some register, so the count is at most 16 by construction; `worst_snap` says how
## far the furthest pixel was from its register's match colour (0 = every pixel is an exact match).

const REGISTERS := "res://data/cabinet/screen_registers.tres"


static func _match_set() -> Dictionary:
	return VideoRegisters.match_set(load(REGISTERS) as ScreenRegisters)


## Number of distinct register indices the pixels of `img` map to.
static func distinct_registers(img: Image) -> int:
	return registers_used(img).size()


## Register index -> pixel count, for every register `img` uses.
static func registers_used(img: Image) -> Dictionary:
	var ms := _match_set()
	var rgb: PackedVector3Array = ms["rgb"]
	var reg: PackedInt32Array = ms["reg"]
	var by_colour := {}   # rgba32 -> register (captures repeat colours a lot)
	var used := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var key := c.to_rgba32()
			var r: int
			if by_colour.has(key):
				r = int(by_colour[key])
			else:
				r = VideoRegisters.nearest_register(c, rgb, reg)
				by_colour[key] = r
			used[r] = int(used.get(r, 0)) + 1
	return used


## Largest squared RGB distance from any pixel to its nearest match-set colour.
static func worst_snap(img: Image) -> float:
	var rgb: PackedVector3Array = _match_set()["rgb"]
	var seen := {}
	var worst := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var key := c.to_rgba32()
			if seen.has(key):
				continue
			seen[key] = true
			var p := Vector3(c.r, c.g, c.b)
			var best := 1.0e20
			for m in rgb:
				best = minf(best, p.distance_squared_to(m))
			worst = maxf(worst, best)
	return worst
