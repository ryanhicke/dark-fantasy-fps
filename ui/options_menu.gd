class_name OptionsMenu
extends MenuPage
## Options page. Enter on the graphics row cycles the graphics level; the
## change applies (and is saved) at once through Settings.

signal back_selected

## Graphics level names by GameView pixel size.
const LEVEL_NAMES: Dictionary[int, String] = {
	1: "High",
	2: "Medium",
	3: "Low",
	4: "Very Low",
}

@onready var _graphics_button: Button = $GraphicsButton
@onready var _back_button: Button = $BackButton


func _ready() -> void:
	super()
	_graphics_button.pressed.connect(_on_graphics_pressed)
	_back_button.pressed.connect(back_selected.emit)
	Settings.pixel_size_changed.connect(_refresh)
	_refresh(Settings.pixel_size)


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


func _on_graphics_pressed() -> void:
	Settings.set_pixel_size(GameView.next_pixel_size(Settings.pixel_size))


func _refresh(pixel_size: int) -> void:
	_graphics_button.text = graphics_label(pixel_size, base_size())
