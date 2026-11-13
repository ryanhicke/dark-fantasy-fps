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


func test_volumes_start_at_their_defaults() -> void:
	_settings.load_settings()
	for bus: StringName in AudioBuses.DEFAULT_VOLUMES:
		assert_eq(_settings.get_volume(bus), AudioBuses.DEFAULT_VOLUMES[bus], String(bus))


func test_changed_volume_is_saved_and_reloaded() -> void:
	_settings.set_volume(AudioBuses.MUSIC, 30)
	assert_signal_emitted_with_parameters(_settings, "volume_changed", [AudioBuses.MUSIC, 30])
	var reloaded: Node = _fresh_load()
	assert_eq(reloaded.get_volume(AudioBuses.MUSIC), 30)
	assert_eq(reloaded.get_volume(AudioBuses.SFX), AudioBuses.DEFAULT_VOLUMES[AudioBuses.SFX])


func test_volume_is_clamped_to_0_100() -> void:
	_settings.set_volume(AudioBuses.SFX, 250)
	assert_eq(_settings.get_volume(AudioBuses.SFX), 100)
	_settings.set_volume(AudioBuses.SFX, -10)
	assert_eq(_settings.get_volume(AudioBuses.SFX), 0)


func test_unknown_bus_volume_is_ignored() -> void:
	_settings.set_volume(&"Nope", 10)
	assert_signal_not_emitted(_settings, "volume_changed")
	assert_eq(_settings.get_volume(&"Nope"), 100)


func test_bad_saved_volume_falls_back_to_the_default() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SettingsScript.SECTION_AUDIO, SettingsScript.volume_key(AudioBuses.MUSIC), "loud")
	config.set_value(SettingsScript.SECTION_AUDIO, SettingsScript.volume_key(AudioBuses.SFX), 999)
	config.save(TEST_PATH)
	var reloaded: Node = _fresh_load()
	assert_eq(reloaded.get_volume(AudioBuses.MUSIC), AudioBuses.DEFAULT_VOLUMES[AudioBuses.MUSIC])
	assert_eq(reloaded.get_volume(AudioBuses.SFX), 100)


func test_saving_volume_keeps_the_graphics_setting() -> void:
	_settings.set_pixel_size(3)
	_settings.set_volume(AudioBuses.MASTER, 40)
	var reloaded: Node = _fresh_load()
	assert_eq(reloaded.pixel_size, 3)
	assert_eq(reloaded.get_volume(AudioBuses.MASTER), 40)


func test_new_options_start_at_their_defaults() -> void:
	_settings.load_settings()
	assert_false(_settings.fullscreen)
	assert_eq(_settings.fov, SettingsScript.DEFAULT_FOV)
	assert_eq(_settings.mouse_sensitivity, SettingsScript.DEFAULT_MOUSE_SENSITIVITY)
	assert_eq(_settings.mouse_sensitivity_scale(), 1.0)


func test_fullscreen_is_saved_and_reloaded() -> void:
	_settings.set_fullscreen(true)
	assert_signal_emitted_with_parameters(_settings, "fullscreen_changed", [true])
	assert_true(_fresh_load().fullscreen)


func test_fov_is_clamped_saved_and_reloaded() -> void:
	_settings.set_fov(90)
	assert_signal_emitted_with_parameters(_settings, "fov_changed", [90])
	assert_eq(_fresh_load().fov, 90)
	_settings.set_fov(500)
	assert_eq(_settings.fov, SettingsScript.MAX_FOV)
	_settings.set_fov(1)
	assert_eq(_settings.fov, SettingsScript.MIN_FOV)


func test_mouse_sensitivity_is_clamped_saved_and_reloaded() -> void:
	_settings.set_mouse_sensitivity(150)
	assert_signal_emitted_with_parameters(_settings, "mouse_sensitivity_changed", [150])
	assert_eq(_fresh_load().mouse_sensitivity, 150)
	assert_eq(_settings.mouse_sensitivity_scale(), 1.5)
	_settings.set_mouse_sensitivity(0)
	assert_eq(_settings.mouse_sensitivity, SettingsScript.MIN_MOUSE_SENSITIVITY)
	_settings.set_mouse_sensitivity(9999)
	assert_eq(_settings.mouse_sensitivity, SettingsScript.MAX_MOUSE_SENSITIVITY)


func test_bad_saved_new_options_fall_back_or_clamp() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SettingsScript.SECTION_GRAPHICS, SettingsScript.KEY_FULLSCREEN, "yes")
	config.set_value(SettingsScript.SECTION_GRAPHICS, SettingsScript.KEY_FOV, 999)
	config.set_value(
		SettingsScript.SECTION_CONTROLS, SettingsScript.KEY_MOUSE_SENSITIVITY, "fast"
	)
	config.save(TEST_PATH)
	var reloaded: Node = _fresh_load()
	assert_false(reloaded.fullscreen)
	assert_eq(reloaded.fov, SettingsScript.MAX_FOV)
	assert_eq(reloaded.mouse_sensitivity, SettingsScript.DEFAULT_MOUSE_SENSITIVITY)


func test_changing_one_option_keeps_the_others() -> void:
	_settings.set_fov(100)
	_settings.set_mouse_sensitivity(60)
	_settings.set_volume(AudioBuses.MASTER, 40)
	var reloaded: Node = _fresh_load()
	assert_eq(reloaded.fov, 100)
	assert_eq(reloaded.mouse_sensitivity, 60)
	assert_eq(reloaded.get_volume(AudioBuses.MASTER), 40)
