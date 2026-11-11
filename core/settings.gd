extends Node
## Player-facing settings that persist between launches (user://settings.cfg).
##
## Holds only what an options screen exposes: the graphics level for now.
## Add mouse sensitivity, volume, etc. here as options for them appear.
##
## No class_name: the autoload name (Settings) is the global identifier.

signal pixel_size_changed(pixel_size: int)

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION_GRAPHICS: String = "graphics"
const KEY_PIXEL_SIZE: String = "pixel_size"
## Medium: 640x360 at the 1280x720 base size.
const DEFAULT_PIXEL_SIZE: int = 2

## GameView pixel size (1 = full resolution, higher = chunkier and faster).
var pixel_size: int = DEFAULT_PIXEL_SIZE
## Where settings are read from and written to. Tests point this elsewhere.
var file_path: String = SETTINGS_PATH


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


## Missing, unreadable, or invalid values fall back to the defaults, so a
## bad settings file can never stop the game from starting.
func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	pixel_size = DEFAULT_PIXEL_SIZE
	if config.load(file_path) != OK:
		return
	var stored: Variant = config.get_value(SECTION_GRAPHICS, KEY_PIXEL_SIZE, DEFAULT_PIXEL_SIZE)
	if stored is int:
		pixel_size = clampi(stored, GameView.MIN_PIXEL_SIZE, GameView.MAX_PIXEL_SIZE)


func save_settings() -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION_GRAPHICS, KEY_PIXEL_SIZE, pixel_size)
	var result: Error = config.save(file_path)
	if result != OK:
		push_warning("Settings: could not save to %s (%s)." % [file_path, error_string(result)])
	return result
