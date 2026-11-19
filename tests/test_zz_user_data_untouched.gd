extends GdUnitTestSuite
## Suite-wide canary. Named test_zz_* so it sorts last in `-a tests`, which GdUnit runs after
## core/features/scenes. Fails only if THIS process tried to write a real player file
## (TestMode.allow_write recorded it). Other processes' writes never matter here.


func test_no_test_wrote_a_real_player_file() -> void:
	assert_array(TestMode.blocked_writes) \
		.override_failure_message("a test tried to write a real player file: %s" % ", ".join(TestMode.blocked_writes)) \
		.is_empty()
