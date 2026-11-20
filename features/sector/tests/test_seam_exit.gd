extends GdUnitTestSuite
## SeamExit (Q-T275, Q-T278): the clear rule (cold again after `knocks_required` segments knocked
## off), the latch, the throat opening and showing on the compass, the pass check across the torus
## seam, the dev switches, and the data rows.

const SEP_SCENE := "res://features/sepulchre/sepulchre.tscn"
const SEP_STATS := "res://data/sepulchre/sepulchre.tres"
const STATS := preload("res://data/sector/seam_exit.tres")
const WORLD := Vector2(1920, 720)

var holder: Node2D
var torus: Torus
var sep: Sepulchre
var vigil: Node2D
var ex: SeamExit
var events: Array[String] = []


func before_test() -> void:
	events = []
	holder = auto_free(Node2D.new())
	add_child(holder)
	torus = Torus.new(WORLD)
	sep = (load(SEP_SCENE) as PackedScene).instantiate()
	sep.configure(load(SEP_STATS), torus, Vector2(1100, 560))
	sep.sfx = Callable()
	holder.add_child(sep)
	vigil = Node2D.new()
	vigil.position = Vector2(320, 180)
	holder.add_child(vigil)
	ex = SeamExit.new()
	ex.stats = STATS
	ex.bind(torus, vigil, sep, holder, true)
	ex.set_physics_process(false)
	holder.add_child(ex)
	ex.throat_opened.connect(func() -> void: events.append("opened"))
	ex.throat_entered.connect(func() -> void: events.append("entered"))


func _knock(n: int) -> void:
	for i in n:
		sep.take_charge_hit()


func test_data_rows() -> void:
	var s := STATS as SeamExitStats
	assert_str(s.ds_namespace).is_equal("ds_sector.exit")
	assert_int(s.knocks_required).is_equal(3)          # proposed SYS-001 §6 row
	assert_vector(s.throat_pos).is_equal(Vector2(0, 360))
	assert_float(s.throat_radius_px).is_greater(0.0)
	assert_float(s.return_hold_s).is_greater(0.0)


func test_rule_is_cold_again_after_enough_knocks() -> void:
	assert_bool(SeamExit.is_clear(0, 3, 3)).is_true()
	assert_bool(SeamExit.is_clear(0, 2, 3)).is_false()   # not enough knocked off
	assert_bool(SeamExit.is_clear(1, 5, 3)).is_false()   # still standing
	assert_bool(SeamExit.is_clear(0, 0, 0)).is_false()   # a cold start never clears (required ≥ 1)


func test_a_cold_sepulchre_does_not_clear_the_seam() -> void:
	ex.step(0.1)
	assert_bool(ex.cleared).is_false()
	assert_bool(ex.throat.visible).is_false()
	assert_array(events).is_empty()


func test_unmaking_the_sepulchre_opens_the_throat_once() -> void:
	sep.segments = 3
	_knock(2)
	ex.step(0.1)
	assert_bool(ex.cleared).is_false()
	_knock(1)
	ex.step(0.1)
	assert_bool(ex.cleared).is_true()
	assert_bool(ex.throat.visible).is_true()
	assert_bool(ex.throat.is_in_group(LedgerCompass.GROUP)).is_true()
	ex.step(STATS.throat_open_s)
	assert_float(ex.throat.open_frac).is_equal(1.0)
	assert_array(events).is_equal(["opened"])


func test_the_clear_latches_when_the_grubs_build_again() -> void:
	sep.segments = 3
	_knock(3)
	ex.step(0.1)
	sep.segments = 2
	ex.step(0.1)
	assert_bool(ex.cleared).is_true()
	assert_array(events).is_equal(["opened"])


func test_flying_into_the_open_throat_across_the_seam() -> void:
	ex.step(0.1)
	vigil.position = Vector2(5, 360)
	ex.step(0.1)
	assert_array(events).is_empty()                     # shut: no pass
	ex.open()
	vigil.position = Vector2(1900, 370)                  # 20 px left of x = 0, across the torus seam
	ex.step(0.1)
	assert_bool(ex.entered).is_true()
	ex.step(0.1)
	assert_array(events).is_equal(["opened", "entered"])


func test_outside_the_throat_is_no_pass() -> void:
	ex.open()
	vigil.position = Vector2(0, 360 + STATS.throat_radius_px + 5.0)
	ex.step(0.1)
	assert_bool(ex.entered).is_false()


func test_throat_offset_is_the_short_way_round() -> void:
	vigil.position = Vector2(1900, 300)
	assert_vector(ex.throat_offset()).is_equal(Vector2(20, 60))


func test_dev_switches() -> void:
	var applied := ex.apply_dev_args(PackedStringArray(["--clear-knocks=1", "--sepulchre-start=2"]))
	assert_array(Array(applied)).is_equal(["clear-knocks", "sepulchre-start"])
	assert_int(ex.knocks_required).is_equal(1)
	assert_int(sep.segments).is_equal(2)
	_knock(2)
	ex.step(0.1)
	assert_bool(ex.cleared).is_true()


func test_bad_dev_switches_are_ignored() -> void:
	var applied := ex.apply_dev_args(PackedStringArray(["--clear-knocks=0", "--sepulchre-start=x"]))
	assert_int(applied.size()).is_equal(0)
	assert_int(ex.knocks_required).is_equal(3)
	assert_int(sep.segments).is_equal(0)
