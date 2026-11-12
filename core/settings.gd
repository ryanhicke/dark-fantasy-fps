extends Node
## Player-facing settings that persist between launches (user://settings.cfg).
##
## Holds only what an options screen exposes: the graphics level and the
## bus volumes. Add mouse sensitivity etc. here as options for them appear.
##
## No class_name: the autoload name (Settings) is the global identifier.

signal pixel_size_changed(pixel_size: int)
signal volume_changed(bus: StringName, percent: int)

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION_GRAPHICS: String = "graphics"
const KEY_PIXEL_SIZE: String = "pixel_size"
const SECTION_AUDIO: String = "audio"
## Medium: 640x360 at the 1280x720 base size.
const DEFAULT_PIXEL_SIZE: int = 2

## GameView pixel size (1 = full resolution, higher = chunkier and faster).
var pixel_size: int = DEFAULT_PIXEL_SIZE
## Volume in percent (0-100) per bus in AudioBuses.DEFAULT_VOLUMES.
var volumes: Dictionary[StringName, int] = {}
## Where settings are read from and written to. Tests point this elsewhere.
var file_path: String = SETTINGS_PATH


func _init() -> void:
	_reset_volumes()


func _ready() -> void:
	load_settings()


## Saves immediately, so a change survives even if the game crashes later.
func set_pixel_size(value: int) -> void:
	var clamped: int = clampi(value, GameView.MIN_PIXEL_SIZE, GameView.MAX_PIXEL_SIZE)
	if clamped == pixel_size:
		return
	pixel_size = clamped
	pixel_size_changed.emit(pixel_size)
	save_settings()


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
	_reset_volumes()
	if config.load(file_path) != OK:
		return
	var stored: Variant = config.get_value(SECTION_GRAPHICS, KEY_PIXEL_SIZE, DEFAULT_PIXEL_SIZE)
	if stored is int:
		pixel_size = clampi(stored, GameView.MIN_PIXEL_SIZE, GameView.MAX_PIXEL_SIZE)
	for bus: StringName in AudioBuses.DEFAULT_VOLUMES:
		var volume: Variant = config.get_value(SECTION_AUDIO, volume_key(bus), volumes[bus])
		if volume is int:
			volumes[bus] = clampi(volume, 0, AudioBuses.MAX_PERCENT)


func save_settings() -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION_GRAPHICS, KEY_PIXEL_SIZE, pixel_size)
	for bus: StringName in volumes:
		config.set_value(SECTION_AUDIO, volume_key(bus), volumes[bus])
	var result: Error = config.save(file_path)
	if result != OK:
		push_warning("Settings: could not save to %s (%s)." % [file_path, error_string(result)])
	return result


func _reset_volumes() -> void:
	volumes.clear()
	for bus: StringName in AudioBuses.DEFAULT_VOLUMES:
		volumes[bus] = AudioBuses.DEFAULT_VOLUMES[bus]
