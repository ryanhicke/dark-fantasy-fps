extends GutTest
## Settings save/load and fallbacks. Uses a fresh Settings instance writing
## to a test file, never the player's real user://settings.cfg.

const SettingsScript: GDScript = preload("res://core/settings.gd")
const TEST_PATH: String = "user://test_settings.cfg"

var _settings: Node


func before_each() -> void:
	_delete_test_file()
	_settings = autofree(SettingsScript.new())
	_settings.file_path = TEST_PATH
	watch_signals(_settings)


func after_each() -> void:
	_delete_test_file()


func _delete_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func _fresh_load() -> Node:
	var other: Node = autofree(SettingsScript.new())
	other.file_path = TEST_PATH
	other.load_settings()
	return other


func test_missing_file_gives_the_default() -> void:
	_settings.load_settings()
	assert_eq(_settings.pixel_size, SettingsScript.DEFAULT_PIXEL_SIZE)


func test_changed_pixel_size_is_saved_and_reloaded() -> void:
	_settings.set_pixel_size(3)
	assert_signal_emitted_with_parameters(_settings, "pixel_size_changed", [3])
	assert_eq(_fresh_load().pixel_size, 3)


func test_setting_the_same_value_does_nothing() -> void:
	_settings.set_pixel_size(SettingsScript.DEFAULT_PIXEL_SIZE)
	assert_signal_not_emitted(_settings, "pixel_size_changed")
	assert_false(FileAccess.file_exists(TEST_PATH))


func test_out_of_range_values_are_clamped() -> void:
	_settings.set_pixel_size(99)
	assert_eq(_settings.pixel_size, GameView.MAX_PIXEL_SIZE)
	_settings.set_pixel_size(-5)
	assert_eq(_settings.pixel_size, GameView.MIN_PIXEL_SIZE)


func test_garbage_file_falls_back_to_the_default() -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("this is [not a valid config")
	file.close()
	assert_eq(_fresh_load().pixel_size, SettingsScript.DEFAULT_PIXEL_SIZE)


func test_wrong_value_type_falls_back_to_the_default() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SettingsScript.SECTION_GRAPHICS, SettingsScript.KEY_PIXEL_SIZE, "big")
	config.save(TEST_PATH)
	assert_eq(_fresh_load().pixel_size, SettingsScript.DEFAULT_PIXEL_SIZE)


func test_out_of_range_saved_value_is_clamped_on_load() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SettingsScript.SECTION_GRAPHICS, SettingsScript.KEY_PIXEL_SIZE, 50)
	config.save(TEST_PATH)
	assert_eq(_fresh_load().pixel_size, GameView.MAX_PIXEL_SIZE)
