extends GdUnitTestSuite
## Palette lint for UI (ART-001 §4: palette violations are bugs). Every colour in the project
## theme and in bootstrap scenes must be a palette entry (alpha ignored for dim overlays).

const PALETTE_JSON := "res://assets/palettes/darkstar_palette.json"
const SCENES := [
	"res://data/ui/darkstar_theme.tres",
	"res://scenes/boot/boot.tscn",
	"res://scenes/attract/attract_mode.tscn",
	"res://scenes/sector/sector_stub.tscn",
	"res://features/vigil/vigil.tscn",
]


static func palette() -> Array[Color]:
	var out: Array[Color] = []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PALETTE_JSON))
	for entry: Dictionary in data["index"]:
		out.append(Color.html(str(entry["hex"])))
	return out


static func _in_palette(c: Color, pal: Array[Color]) -> bool:
	for p in pal:
		if absf(p.r - c.r) < 0.003 and absf(p.g - c.g) < 0.003 and absf(p.b - c.b) < 0.003:
			return true
	return false


func test_palette_file_has_32_entries() -> void:
	assert_int(palette().size()).is_equal(32)


func test_theme_and_scene_colours_are_palette_entries() -> void:
	var pal := palette()
	var re := RegEx.create_from_string("Color\\(([0-9.e-]+), ([0-9.e-]+), ([0-9.e-]+), ([0-9.e-]+)\\)")
	var bad: Array[String] = []
	for path in SCENES:
		var text := FileAccess.get_file_as_string(path)
		for m in re.search_all(text):
			var c := Color(m.get_string(1).to_float(), m.get_string(2).to_float(), m.get_string(3).to_float())
			if not _in_palette(c, pal):
				bad.append("%s: %s" % [path.get_file(), m.get_string(0)])
	assert_array(bad).override_failure_message("off-palette colours: %s" % [bad]).is_empty()


func test_text_scale_applies_and_restores() -> void:
	var t := UiTheme.get_theme()
	UiTheme.apply_text_scale(2.0)
	assert_int(t.default_font_size).is_equal(UiTheme.BASE_FONT_SIZE * 2)
	UiTheme.apply_text_scale(1.0)
	assert_int(t.default_font_size).is_equal(UiTheme.BASE_FONT_SIZE)


func test_code_palette_constants_match_the_palette_file() -> void:
	# Pal (code-drawn costume art) must be the ART-001 §4 palette, entry for entry.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PALETTE_JSON))
	var bad: Array[String] = []
	for entry: Dictionary in data["index"]:
		var name := str(entry["name"])
		if not Pal.ALL.has(name):
			bad.append("missing " + name)
		elif not (Pal.ALL[name] as Color).is_equal_approx(Color.html(str(entry["hex"]))):
			bad.append("wrong " + name)
	assert_array(bad).is_empty()


func after_test() -> void:
	Look.t = 0.0


func test_neon_cabinet_palette_covers_every_role_and_matches_art_001() -> void:
	var art := FileAccess.get_file_as_string("res://docs/02-art/ART_BIBLE.md")
	var missing: Array[String] = []
	for name: String in Pal.ALL:
		if not Look.NEON.has(name):
			missing.append("no neon entry for " + name)
			continue
		var hex := "#" + (Look.NEON[name] as Color).to_html(false).to_upper()
		if not (hex in art):
			missing.append("%s %s not in ART-001 §15.2" % [name, hex])
	assert_array(missing).is_empty()


func test_look_dial_morphs_neon_into_the_base_palette() -> void:
	Look.t = 0.0
	assert_bool(Look.c(Pal.CHOIR_3).is_equal_approx(Look.NEON["CHOIR-3"])).is_true()
	Look.t = 1.0
	assert_bool(Look.c(Pal.CHOIR_3).is_equal_approx(Pal.CHOIR_3)).is_true()
	Look.t = 0.5
	var mid := Look.c(Pal.GAS_4)
	var neon: Color = Look.NEON["GAS-4"]
	assert_float(mid.r).is_between(minf(neon.r, Pal.GAS_4.r), maxf(neon.r, Pal.GAS_4.r))
	# non-palette colours pass through untouched, alpha is kept
	assert_bool(Look.c(Color(0.123, 0.456, 0.789, 0.5)).is_equal_approx(Color(0.123, 0.456, 0.789, 0.5))).is_true()
	assert_float(Look.c(Color(Pal.BONE_5, 0.25)).a).is_equal_approx(0.25, 0.001)


func test_role_law_holds_in_neon_player_and_choir_hues_stay_apart() -> void:
	# ART-001 §4 law 1 at T0: the player's ramp (yellow) and the Choir's (magenta) never share a hue.
	for i in 6:
		var gas: Color = Look.NEON["GAS-%d" % i]
		for j in 6:
			var choir: Color = Look.NEON["CHOIR-%d" % j]
			var dh := absf(gas.h - choir.h)
			assert_float(minf(dh, 1.0 - dh)).override_failure_message("GAS-%d vs CHOIR-%d too close in hue" % [i, j]).is_greater(0.15)
