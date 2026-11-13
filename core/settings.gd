extends Node
## Player-facing settings that persist between launches (user://settings.cfg).
##
## Holds only what an options screen exposes: the graphics level, fullscreen,
## field of view, mouse sensitivity, and the bus volumes.
##
## No class_name: the autoload name (Settings) is the global identifier.

signal pixel_size_changed(pixel_size: int)
signal volume_changed(bus: StringName, percent: int)
signal fullscreen_changed(enabled: bool)
signal fov_changed(degrees: int)
signal mouse_sensitivity_changed(percent: int)

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION_GRAPHICS: String = "graphics"
const KEY_PIXEL_SIZE: String = "pixel_size"
const SECTION_AUDIO: String = "audio"
## Medium: 640x360 at the 1280x720 base size.
const DEFAULT_PIXEL_SIZE: int = 2
const KEY_FULLSCREEN: String = "fullscreen"
const KEY_FOV: String = "fov"
const SECTION_CONTROLS: String = "controls"
const KEY_MOUSE_SENSITIVITY: String = "mouse_sensitivity"
## Vertical field of view in degrees. 75 is Godot's Camera3D default, about
## 107 degrees horizontal at 16:9.
const DEFAULT_FOV: int = 75
const MIN_FOV: int = 60
const MAX_FOV: int = 110
const FOV_STEP: int = 5
## Percent of the player's base look speed.
const DEFAULT_MOUSE_SENSITIVITY: int = 100
const MIN_MOUSE_SENSITIVITY: int = 10
const MAX_MOUSE_SENSITIVITY: int = 300
const MOUSE_SENSITIVITY_STEP: int = 10
const PERCENT: float = 100.0

## GameView pixel size (1 = full resolution, higher = chunkier and faster).
var pixel_size: int = DEFAULT_PIXEL_SIZE
var fullscreen: bool = false
var fov: int = DEFAULT_FOV
var mouse_sensitivity: int = DEFAULT_MOUSE_SENSITIVITY
## Volume in percent (0-100) per bus in AudioBuses.DEFAULT_VOLUMES.
var volumes: Dictionary[StringName, int] = {}
## Where settings are read from and written to. Tests point this elsewhere.
var file_path: String = SETTINGS_PATH


func _init() -> void:
	_reset_volumes()


func _ready() -> void:
	load_settings()
	_apply_fullscreen()


## Saves immediately, so a change survives even if the game crashes later.
func set_pixel_size(value: int) -> void:
	var clamped: int = clampi(value, GameView.MIN_PIXEL_SIZE, GameView.MAX_PIXEL_SIZE)
	if clamped == pixel_size:
		return
	pixel_size = clamped
	pixel_size_changed.emit(pixel_size)
	save_settings()


func set_fullscreen(enabled: bool) -> void:
	if enabled == fullscreen:
		return
	fullscreen = enabled
	_apply_fullscreen()
	fullscreen_changed.emit(fullscreen)
	save_settings()


func set_fov(degrees: int) -> void:
	var clamped: int = clampi(degrees, MIN_FOV, MAX_FOV)
	if clamped == fov:
		return
	fov = clamped
	fov_changed.emit(fov)
	save_settings()


func set_mouse_sensitivity(percent: int) -> void:
	var clamped: int = clampi(percent, MIN_MOUSE_SENSITIVITY, MAX_MOUSE_SENSITIVITY)
	if clamped == mouse_sensitivity:
		return
	mouse_sensitivity = clamped
	mouse_sensitivity_changed.emit(mouse_sensitivity)
	save_settings()


## Multiplier for the player's base look speed (1.0 at 100%).
func mouse_sensitivity_scale() -> float:
	return mouse_sensitivity / PERCENT


## 100 for a bus without a volume setting.
func get_volume(bus: StringName) -> int:
	return volumes.get(bus, AudioBuses.MAX_PERCENT)


## Saves immediately, like set_pixel_size.
func set_volume(bus: StringName, percent: int) -> void:
	if not AudioBuses.DEFAULT_VOLUMES.has(bus):
		push_warning("Settings: '%s' has no volume setting." % bus)
		return
	var clamped: int = clampi(percent, 0, AudioBuses.MAX_PERCENT)
	if clamped == get_volume(bus):
		return
	volumes[bus] = clamped
	volume_changed.emit(bus, clamped)
	save_settings()


## ConfigFile key for a bus volume, e.g. "music_volume".
static func volume_key(bus: StringName) -> String:
	return "%s_volume" % String(bus).to_lower()


## Missing, unreadable, or invalid values fall back to the defaults, so a
## bad settings file can never stop the game from starting.
func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	pixel_size = DEFAULT_PIXEL_SIZE
	fullscreen = false
	fov = DEFAULT_FOV
	mouse_sensitivity = DEFAULT_MOUSE_SENSITIVITY
	_reset_volumes()
	if config.load(file_path) != OK:
		return
	var stored: Variant = config.get_value(SECTION_GRAPHICS, KEY_PIXEL_SIZE, DEFAULT_PIXEL_SIZE)
	if stored is int:
		pixel_size = clampi(stored, GameView.MIN_PIXEL_SIZE, GameView.MAX_PIXEL_SIZE)
	var stored_fullscreen: Variant = config.get_value(SECTION_GRAPHICS, KEY_FULLSCREEN, false)
	if stored_fullscreen is bool:
		fullscreen = stored_fullscreen
	var stored_fov: Variant = config.get_value(SECTION_GRAPHICS, KEY_FOV, DEFAULT_FOV)
	if stored_fov is int:
		fov = clampi(stored_fov, MIN_FOV, MAX_FOV)
	var stored_sensitivity: Variant = config.get_value(
		SECTION_CONTROLS, KEY_MOUSE_SENSITIVITY, DEFAULT_MOUSE_SENSITIVITY
	)
	if stored_sensitivity is int:
		mouse_sensitivity = clampi(
			stored_sensitivity, MIN_MOUSE_SENSITIVITY, MAX_MOUSE_SENSITIVITY
		)
	for bus: StringName in AudioBuses.DEFAULT_VOLUMES:
		var volume: Variant = config.get_value(SECTION_AUDIO, volume_key(bus), volumes[bus])
		if volume is int:
			volumes[bus] = clampi(volume, 0, AudioBuses.MAX_PERCENT)


func save_settings() -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION_GRAPHICS, KEY_PIXEL_SIZE, pixel_size)
	config.set_value(SECTION_GRAPHICS, KEY_FULLSCREEN, fullscreen)
	config.set_value(SECTION_GRAPHICS, KEY_FOV, fov)
	config.set_value(SECTION_CONTROLS, KEY_MOUSE_SENSITIVITY, mouse_sensitivity)
	for bus: StringName in volumes:
		config.set_value(SECTION_AUDIO, volume_key(bus), volumes[bus])
	var result: Error = config.save(file_path)
	if result != OK:
		push_warning("Settings: could not save to %s (%s)." % [file_path, error_string(result)])
	return result


## Only the autoload is in the tree; test instances never touch the window.
func _apply_fullscreen() -> void:
	if not is_inside_tree():
		return
	# Borderless rather than exclusive, so alt-tab stays instant.
	get_window().mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED


func _reset_volumes() -> void:
	volumes.clear()
	for bus: StringName in AudioBuses.DEFAULT_VOLUMES:
		volumes[bus] = AudioBuses.DEFAULT_VOLUMES[bus]
