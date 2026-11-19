extends GdUnitTestSuite
## ChargeMagazine: cap from data (SYS-001 §1.4, 5 base), overflow refused.


func _magazine() -> ChargeMagazine:
	var m: ChargeMagazine = auto_free(ChargeMagazine.new())
	m.stats = load("res://data/charges/charge_magazine.tres")
	return m


func test_capacity_is_five() -> void:
	var m := _magazine()
	assert_int(m.capacity()).is_equal(5)
	assert_str(m.stats.ds_namespace).is_equal("ds_charges.magazine")


func test_fills_to_cap_and_refuses_overflow() -> void:
	var m := _magazine()
	for k in 5:
		assert_int(m.try_add(1)).is_equal(1)
	assert_bool(m.is_full()).is_true()
	assert_int(m.try_add(1)).is_equal(0)
	assert_int(m.count).is_equal(5)


func test_partial_add_clamps() -> void:
	var m := _magazine()
	m.try_add(3)
	assert_int(m.try_add(4)).is_equal(2)
	assert_int(m.try_add(-2)).is_equal(0)
	m.reset()
	assert_int(m.count).is_equal(0)
