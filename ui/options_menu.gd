class_name OptionsMenu
extends MenuPage
## Options page. Enter on the graphics row cycles the graphics level and on
## the fullscreen row toggles it; the field of view and sensitivity rows
## (StepSettingButton) and the volume rows (VolumeButton) step their value.
## Every change applies (and is saved) at once through Settings.

signal back_selected

## Graphics level names by GameView pixel size.
const LEVEL_NAMES: Dictionary[int, String] = {
	1: "High",
	2: "Medium",
	3: "Low",
	4: "Very Low",
}

@onready var _graphics_button: Button = $GraphicsButton
@onready var _fullscreen_button: Button = $FullscreenButton
@onready var _back_button: Button = $BackButton


func _ready() -> void:
	super()
	back_button = _back_button
	_graphics_button.pressed.connect(_on_graphics_pressed)
	_back_button.pressed.connect(back_selected.emit)
	Settings.pixel_size_changed.connect(_refresh)
	_refresh(Settings.pixel_size)
	_fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	Settings.fullscreen_changed.connect(_refresh_fullscreen)
	_refresh_fullscreen(Settings.fullscreen)


## E.g. "Graphics: Medium (640x360)" for pixel size 2 at a 1280x720 base.
static func graphics_label(pixel_size: int, base_size: Vector2) -> String:
	var render_size: Vector2i = GameView.render_size_for(base_size, pixel_size)
	return "Graphics: %s (%dx%d)" % [
		LEVEL_NAMES.get(pixel_size, "Custom"), render_size.x, render_size.y
	]


static func base_size() -> Vector2:
	return Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)


static func fullscreen_label(enabled: bool) -> String:
	return "Fullscreen: %s" % ("On" if enabled else "Off")


func _on_fullscreen_pressed() -> void:
	Settings.set_fullscreen(not Settings.fullscreen)


func _refresh_fullscreen(enabled: bool) -> void:
	_fullscreen_button.text = fullscreen_label(enabled)


func _on_graphics_pressed() -> void:
	Settings.set_pixel_size(GameView.next_pixel_size(Settings.pixel_size))


func _refresh(pixel_size: int) -> void:
	_graphics_button.text = graphics_label(pixel_size, base_size())
