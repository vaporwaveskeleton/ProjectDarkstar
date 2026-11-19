extends GdUnitTestSuite
## GrubProcession: spawns the sandbox count on a ring round the Sepulchre, counts kills (score
## 150), and the Sepulchre births a replacement after the 6.0 s respawn.

const SEPULCHRE := "res://features/sepulchre/sepulchre.tscn"
const DT := 1.0 / 60.0
const WORLD := Vector2(1920, 720)
const SEP_AT := Vector2(1480, 400)

var holder: Node2D
var torus: Torus
var sep: Sepulchre
var procession: GrubProcession


func before_test() -> void:
	SettingsService.persist = false
	holder = auto_free(Node2D.new())
	add_child(holder)
	torus = Torus.new(WORLD)
	var field: ShardField = (load("res://features/charges/shard_field.tscn") as PackedScene).instantiate()
	holder.add_child(field)
	field.set_physics_process(false)
	field.setup(torus)
	sep = (load(SEPULCHRE) as PackedScene).instantiate()
	sep.configure(load("res://data/sepulchre/sepulchre.tres"), torus, SEP_AT)
	holder.add_child(sep)
	procession = GrubProcession.new()
	procession.stats = load("res://data/choir/grub.tres")
	procession.shard_field = field
	procession.sfx = func(_id: StringName, _db: float = 0.0) -> void: pass
	holder.add_child(procession)
	procession.set_physics_process(false)
	procession.begin(torus, holder, null, sep, PackedVector2Array([Vector2(900, 560)]), 4, 60.0)


func after_test() -> void:
	SettingsService.persist = true


func test_spawns_four_on_the_ring_and_joins_the_compass() -> void:
	assert_int(procession.grubs.size()).is_equal(4)
	assert_int(procession.alive_count()).is_equal(4)
	for g in procession.grubs:
		assert_float(torus.distance(g.home(), SEP_AT)).is_equal_approx(60.0, 0.01)
		assert_bool(g.is_in_group(LedgerCompass.GROUP)).is_true()
		assert_str(str(LedgerCompass.kind_of(g))).is_equal("grub")
	var idx: Array = procession.grubs.map(func(g: OublietteGrub) -> int: return g.index)
	assert_array(idx).is_equal([0, 1, 2, 3])


func test_a_killed_grub_scores_and_respawns_at_the_sepulchre_after_six_seconds() -> void:
	var victim: OublietteGrub = procession.grubs[1]
	victim.die()
	procession.tick(DT)
	assert_int(procession.kills).is_equal(1)
	assert_int(procession.score).is_equal(150)
	assert_int(procession.alive_count()).is_equal(3)
	assert_bool(victim.is_queued_for_deletion()).is_true()
	for _t in 358:   # 359 ticks in total: not yet
		procession.tick(DT)
	assert_int(procession.alive_count()).is_equal(3)
	procession.tick(DT)   # 360 ticks = 6.0 s
	assert_int(procession.alive_count()).is_equal(4)
	var fresh: OublietteGrub = procession.grubs[3]
	assert_vector(fresh.home()).is_equal_approx(SEP_AT, Vector2(0.01, 0.01))
	assert_int(fresh.index).is_equal(4)
	assert_int(procession.carrying_count()).is_equal(0)
