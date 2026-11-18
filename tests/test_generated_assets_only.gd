extends GdUnitTestSuite
## GDD-001 D-13 / D-14: every image is generated (vector or shader) and every sound is synthesised.
## Nothing the game loads may be an image, texture, font or audio file. ART-001 §14, AUDIO-001 §11.

const ROOTS := ["res://features", "res://scenes", "res://core", "res://autoload", "res://data"]
const FILE_EXT := ["png", "jpg", "jpeg", "webp", "svg", "bmp", "tga", "exr", "hdr", "ktx",
	"wav", "ogg", "mp3", "flac", "ttf", "otf", "woff", "woff2", "fnt", "font"]
const RESOURCE_TYPES := ["Texture2D", "CompressedTexture2D", "ImageTexture", "AtlasTexture",
	"AudioStreamWAV", "AudioStreamOggVorbis", "AudioStreamMP3", "FontFile", "SpriteFrames"]


static func _files(root: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var n := dir.get_next()
	while n != "":
		var full := root.path_join(n)
		if dir.current_is_dir():
			if not n.begins_with(".") and n != "tests":
				out.append_array(_files(full))
		elif n.ends_with(".gd") or n.ends_with(".tscn") or n.ends_with(".tres") or n.ends_with(".gdshader"):
			out.append(full)
		n = dir.get_next()
	return out


func test_no_game_file_references_an_image_font_or_audio_file() -> void:
	var path_re := RegEx.create_from_string("res://[^\"'\\s)]+\\.(%s)\\b" % "|".join(FILE_EXT))
	var type_re := RegEx.create_from_string("\\[ext_resource type=\"(%s)\"" % "|".join(RESOURCE_TYPES))
	var bad: Array[String] = []
	for root in ROOTS:
		for f in _files(root):
			var text := FileAccess.get_file_as_string(f)
			var m := path_re.search(text)
			if m != null:
				bad.append("%s → %s" % [f, m.get_string(0)])
			var m2 := type_re.search(text)
			if m2 != null:
				bad.append("%s → ext_resource %s" % [f, m2.get_string(1)])
	assert_array(bad).override_failure_message("D-13/D-14 violated (generate it in code instead): %s" % [bad]).is_empty()


func test_project_settings_load_no_image_or_audio_file() -> void:
	var text := FileAccess.get_file_as_string("res://project.godot")
	var re := RegEx.create_from_string("res://[^\"]+\\.(%s)\"" % "|".join(FILE_EXT))
	assert_object(re.search(text)).override_failure_message("project.godot references an image/audio/font file").is_null()


func test_the_cabinet_sound_set_is_synthesised() -> void:
	var cues := SfxSynth.build_cabinet_set()
	assert_int(cues.size()).is_greater(10)
	for id in cues:
		var s: AudioStream = cues[id]
		assert_bool(s is AudioStreamWAV).is_true()
		assert_int((s as AudioStreamWAV).data.size()).override_failure_message("cue %s is empty" % id).is_greater(0)
