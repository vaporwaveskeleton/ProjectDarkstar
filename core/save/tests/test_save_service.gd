extends GdUnitTestSuite
## SaveService + SaveEnvelope: round trip, cadence guard, corruption, backup recovery, versioning.
## Uses a private SaveService instance with an in-memory backend; never touches the real autoload slots.

const SaveServiceScript := preload("res://autoload/save_service.gd")

var svc: Node
var mem: MemorySaveBackend


func before_test() -> void:
	svc = auto_free(SaveServiceScript.new())
	mem = MemorySaveBackend.new()
	svc.set_backend(mem)


func test_round_trip_keeps_types_and_values() -> void:
	var payload := {"tree": ["lt_ward_1", "lt_hull_4"], "ember": 120, "codex": {"c_001": true}}
	assert_int(svc.save_slot(&"profile", payload, &"ruins_entry")).is_equal(OK)
	var r: Dictionary = svc.load_slot(&"profile")
	assert_bool(r.ok).is_true()
	assert_array(r.payload.tree).is_equal(["lt_ward_1", "lt_hull_4"])
	assert_int(int(r.payload.ember)).is_equal(120)
	assert_bool(r.payload.codex.c_001).is_true()


func test_run_slot_refuses_mid_run_saves() -> void:
	var failures: Array[StringName] = []
	svc.save_failed.connect(func(_s, reason): failures.append(reason))
	assert_int(svc.save_slot(&"run", {"seam": 2}, &"pause_menu")).is_equal(ERR_UNAUTHORIZED)
	assert_array(failures).is_equal([&"not_allowed_now"])
	assert_bool(mem.exists("run")).is_false()
	assert_int(svc.save_slot(&"run", {"seam": 2}, &"seam_boundary")).is_equal(OK)


## PM 2026-11-19: the Cabinet saves the furthest Act 0 stage reached at each stage start.
func test_profile_accepts_the_cabinet_stage_reason() -> void:
	assert_int(svc.save_slot(&"profile", {"act0_stage_reached": 2}, &"cabinet_stage")).is_equal(OK)
	assert_int(svc.save_slot(&"run", {"seam": 2}, &"cabinet_stage")).is_equal(ERR_UNAUTHORIZED)


func test_unknown_slot_is_refused() -> void:
	assert_int(svc.save_slot(&"cheats", {}, &"ruins_entry")).is_equal(ERR_INVALID_PARAMETER)
	assert_str(String(svc.load_slot(&"cheats").reason)).is_equal("unknown_slot")


func test_missing_slot_is_not_an_error() -> void:
	var failed := [false]
	svc.load_failed.connect(func(_s, _r): failed[0] = true)
	var r: Dictionary = svc.load_slot(&"iteration")
	assert_bool(r.ok).is_false()
	assert_str(String(r.reason)).is_equal("missing")
	assert_bool(failed[0]).is_false()


func test_corrupt_main_copy_recovers_from_backup() -> void:
	svc.save_slot(&"profile", {"ember": 1}, &"ruins_entry")
	svc.save_slot(&"profile", {"ember": 2}, &"tree_purchase")
	mem.files["profile"] = "{ not json"
	var r: Dictionary = svc.load_slot(&"profile")
	assert_bool(r.ok).is_true()
	assert_bool(r.recovered).is_true()
	assert_int(int(r.payload.ember)).is_equal(1)


func test_tampered_payload_fails_checksum() -> void:
	svc.save_slot(&"profile", {"ember": 5}, &"ruins_entry")
	mem.files["profile"] = (mem.files["profile"] as String).replace("5", "9999")
	mem.backups.clear()
	var r: Dictionary = svc.load_slot(&"profile")
	assert_bool(r.ok).is_false()
	assert_str(String(r.reason)).is_equal("corrupt")


func test_newer_schema_is_refused_not_overwritten() -> void:
	var env := SaveEnvelope.create("profile", {"ember": 1})
	env.schema_version = SaveEnvelope.SCHEMA_VERSION + 1
	mem.files["profile"] = env.to_json()
	var r: Dictionary = svc.load_slot(&"profile")
	assert_bool(r.ok).is_false()
	assert_str(String(r.reason)).is_equal("newer_version")


func test_slot_mismatch_is_rejected() -> void:
	mem.files["profile"] = SaveEnvelope.create("run", {"seam": 1}).to_json()
	assert_bool(svc.load_slot(&"profile").ok).is_false()


func test_write_failure_is_reported() -> void:
	mem.fail_writes = true
	var failures: Array[StringName] = []
	svc.save_failed.connect(func(_s, reason): failures.append(reason))
	assert_int(svc.save_slot(&"profile", {}, &"ruins_entry")).is_not_equal(OK)
	assert_array(failures).is_equal([&"write_failed"])


func test_file_backend_atomic_write_and_backup() -> void:
	var root := "user://test_saves_%d" % Time.get_ticks_usec()
	var fb := FileSaveBackend.new(root)
	assert_int(fb.write_text("profile", "A")).is_equal(OK)
	assert_int(fb.write_text("profile", "B")).is_equal(OK)
	assert_str(fb.read_text("profile")).is_equal("B")
	assert_str(fb.read_backup("profile")).is_equal("A")
	assert_bool(FileAccess.file_exists(root.path_join("profile.json.tmp"))).is_false()
	fb.remove("profile")
	assert_bool(fb.exists("profile")).is_false()
	DirAccess.remove_absolute(root)


func test_every_failure_reason_has_player_text() -> void:
	for reason in [&"write_failed", &"not_allowed_now", &"unknown_slot", &"newer_version", &"corrupt", &"recovered", &"something_new"]:
		var text := PlayerMessages.save_message(reason)
		assert_str(text).is_not_empty()
		assert_bool(text.begins_with("MSG_")).override_failure_message("untranslated key for %s" % reason).is_false()
		assert_bool(text.contains(String(reason))).is_false()
