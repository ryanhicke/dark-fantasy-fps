extends GutTest
## GameState level progression and how the player bundle moves between
## levels. Uses a fresh GameState instance, not the autoload, and never adds
## it to the tree, so its _ready (default list, EventBus hookup) doesn't run.

const GameStateScript: GDScript = preload("res://core/game_state.gd")
const LEVEL_A: String = "res://levels/a.tscn"
const LEVEL_B: String = "res://levels/b.tscn"
const LEVEL_C: String = "res://levels/c.tscn"

var _state: Node


func before_each() -> void:
	_state = autofree(GameStateScript.new())
	var list: LevelList = LevelList.new()
	list.level_paths = [LEVEL_A, LEVEL_B, LEVEL_C] as Array[String]
	_state.level_list = list
	watch_signals(_state)


func _bundle(health: float, arrows: int) -> PlayerState:
	var bundle: PlayerState = PlayerState.new()
	bundle.health = health
	bundle.ammo = {&"arrows": arrows}
	return bundle


func test_start_game_loads_the_level_with_a_pistol_start() -> void:
	_state.start_game(1)
	assert_eq(_state.current_level_index, 1)
	assert_signal_emitted_with_parameters(_state, "level_load_requested", [LEVEL_B])
	assert_null(_state.get_entry_state())


func test_start_game_with_a_bad_index_falls_back_to_the_first_level() -> void:
	_state.start_game(7)
	assert_eq(_state.current_level_index, 0)
	assert_push_error("no level at index 7")


func test_finish_level_reports_stats_and_whether_it_was_final() -> void:
	var stats: LevelStats = LevelStats.new()
	_state.start_game(0)
	_state.finish_level(_bundle(80.0, 5), stats)
	assert_signal_emitted_with_parameters(_state, "level_finished", [stats, false])
	_state.start_game(2)
	_state.finish_level(_bundle(80.0, 5), stats)
	assert_signal_emitted_with_parameters(_state, "level_finished", [stats, true])


func test_advancing_carries_the_exit_bundle_into_the_next_level() -> void:
	_state.start_game(0)
	_state.finish_level(_bundle(42.0, 7), LevelStats.new())
	_state.advance_to_next_level()
	assert_eq(_state.current_level_index, 1)
	assert_signal_emitted_with_parameters(_state, "level_load_requested", [LEVEL_B])
	var entry: PlayerState = _state.get_entry_state()
	assert_eq(entry.health, 42.0)
	assert_eq(entry.ammo[&"arrows"], 7)


func test_changing_the_exit_bundle_afterwards_does_not_leak_in() -> void:
	var bundle: PlayerState = _bundle(42.0, 7)
	_state.start_game(0)
	_state.finish_level(bundle, LevelStats.new())
	bundle.health = 1.0
	bundle.ammo[&"arrows"] = 0
	_state.advance_to_next_level()
	assert_eq(_state.get_entry_state().health, 42.0)
	assert_eq(_state.get_entry_state().ammo[&"arrows"], 7)


func test_restart_uses_the_bundle_the_level_was_entered_with() -> void:
	_state.start_game(0)
	_state.finish_level(_bundle(42.0, 7), LevelStats.new())
	_state.advance_to_next_level()
	_state.restart_level()
	assert_eq(_state.current_level_index, 1)
	assert_signal_emit_count(_state, "level_load_requested", 3)
	assert_eq(_state.get_entry_state().health, 42.0)


func test_advancing_past_the_final_level_starts_a_new_run() -> void:
	_state.start_game(2)
	_state.finish_level(_bundle(42.0, 7), LevelStats.new())
	_state.advance_to_next_level()
	assert_eq(_state.current_level_index, 0)
	assert_signal_emitted_with_parameters(_state, "level_load_requested", [LEVEL_A])
	assert_null(_state.get_entry_state())
