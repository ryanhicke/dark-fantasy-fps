class_name SurfaceAnimator
extends Node
## Drives every AnimatedSurface in a level. Added by Level at load.
##
## The materials are shared resources, so the cost is the same no matter
## how many brushes use them. Original values are restored on exit so the
## editor and other levels see the materials as saved.

var _surfaces: Array[AnimatedSurface] = []
var _base_colors: Array[Color] = []
var _base_offsets: Array[Vector3] = []
var _time: float = 0.0


static func create(surfaces: Array[AnimatedSurface]) -> SurfaceAnimator:
	var animator: SurfaceAnimator = SurfaceAnimator.new()
	animator.name = "SurfaceAnimator"
	for surface: AnimatedSurface in surfaces:
		if surface != null and surface.material != null:
			animator._surfaces.append(surface)
			animator._base_colors.append(surface.material.albedo_color)
			animator._base_offsets.append(surface.material.uv1_offset)
	return animator


func _process(delta: float) -> void:
	_time += delta
	for i: int in _surfaces.size():
		_apply(i)


func _exit_tree() -> void:
	for i: int in _surfaces.size():
		_surfaces[i].material.albedo_color = _base_colors[i]
		_surfaces[i].material.uv1_offset = _base_offsets[i]


func _apply(index: int) -> void:
	var surface: AnimatedSurface = _surfaces[index]
	var material: StandardMaterial3D = surface.material
	if surface.scroll != Vector2.ZERO:
		var offset: Vector2 = surface.scroll * _time
		offset = Vector2(fposmod(offset.x, 1.0), fposmod(offset.y, 1.0))
		if surface.texels > 0:
			offset = (offset * surface.texels).floor() / surface.texels
		material.uv1_offset = _base_offsets[index] + Vector3(offset.x, offset.y, 0.0)
	if surface.flicker_amount > 0.0:
		# Two out-of-step sines, so the flicker never looks like a metronome.
		var wave: float = 0.5 + 0.25 * (sin(_time * TAU * surface.flicker_speed)
			+ sin(_time * TAU * surface.flicker_speed * 2.37))
		var brightness: float = 1.0 - surface.flicker_amount * wave
		var base: Color = _base_colors[index]
		material.albedo_color = Color(base.r * brightness, base.g * brightness, base.b * brightness, base.a)


## The current offset of [param index], for tests.
func get_offset(index: int) -> Vector3:
	return _surfaces[index].material.uv1_offset
