class_name GameView
extends SubViewportContainer
## Renders the game world and HUD into a low-resolution SubViewport that is
## upscaled with nearest-neighbor filtering. This is the main performance
## lever for integrated graphics and gives the chunky retro pixel look.
##
## The resolution is set by a whole-number pixel size: each rendered pixel
## covers pixel_size x pixel_size layout units. Whole numbers keep every
## pixel the same size on screen.
##
## The SubViewport's 2D content (the HUD) keeps the full layout size via
## size_2d_override, so HUD elements stay the same size at every pixel size
## and only get chunkier.
##
## Lives directly in main.tscn rather than as its own scene: exported builds
## (text scenes converted to binary) lost nodes that main.tscn added inside
## an instanced GameView's SubViewport.

const MIN_PIXEL_SIZE: int = 1
const MAX_PIXEL_SIZE: int = 4
## Debug-only key that cycles the pixel size while playing. A raw key rather
## than an input action because it is a dev tool, not a player control.
const DEBUG_CYCLE_KEY: Key = KEY_F2

## Mirrors Settings.pixel_size, which is the source of truth (and is saved).
var pixel_size: int = Settings.DEFAULT_PIXEL_SIZE

@onready var _viewport: SubViewport = $SubViewport


func _ready() -> void:
	resized.connect(_apply_scale)
	Settings.pixel_size_changed.connect(set_pixel_size)
	set_pixel_size(Settings.pixel_size)


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == DEBUG_CYCLE_KEY:
		get_viewport().set_input_as_handled()
		# Through Settings, so the options screen and saved file stay in sync.
		Settings.set_pixel_size(next_pixel_size(pixel_size))


func set_pixel_size(value: int) -> void:
	pixel_size = clampi(value, MIN_PIXEL_SIZE, MAX_PIXEL_SIZE)
	_apply_scale()


## The SubViewport resolution for a container of [param container_size].
static func render_size_for(container_size: Vector2, pixels: int) -> Vector2i:
	var divisor: int = maxi(pixels, MIN_PIXEL_SIZE)
	return Vector2i(
		maxi(floori(container_size.x / divisor), 1),
		maxi(floori(container_size.y / divisor), 1)
	)


static func next_pixel_size(current: int) -> int:
	return MIN_PIXEL_SIZE if current >= MAX_PIXEL_SIZE else current + 1


func _apply_scale() -> void:
	# With stretch on, the container sizes the SubViewport to size / shrink.
	stretch_shrink = pixel_size
	_viewport.size_2d_override = Vector2i(size)
	EventBus.render_resolution_changed.emit(render_size_for(size, pixel_size))
