extends GutTest
## Intermission time formatting and PlayerState copying.


func test_format_time() -> void:
	assert_eq(LevelStats.format_time(0.0), "0:00")
	assert_eq(LevelStats.format_time(9.9), "0:09")
	assert_eq(LevelStats.format_time(75.4), "1:15")
	assert_eq(LevelStats.format_time(3600.0), "60:00")


func test_format_time_clamps_negative_to_zero() -> void:
	assert_eq(LevelStats.format_time(-5.0), "0:00")


func test_player_state_copy_is_independent() -> void:
	var original: PlayerState = PlayerState.new()
	original.health = 50.0
	original.ammo = {&"arrows": 3}
	var copied: PlayerState = original.copy()
	original.health = 10.0
	original.ammo[&"arrows"] = 0
	assert_eq(copied.health, 50.0)
	assert_eq(copied.ammo[&"arrows"], 3)
