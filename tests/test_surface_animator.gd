extends GutTest
## Animated map surfaces scroll in whole texels, flicker, and are restored
## when the level ends.


func _surface(scroll: Vector2, flicker: float) -> AnimatedSurface:
	var surface: AnimatedSurface = AnimatedSurface.new()
	surface.material = StandardMaterial3D.new()
	surface.scroll = scroll
	surface.flicker_amount = flicker
	return surface


func test_scroll_snaps_to_texels() -> void:
	var surface: AnimatedSurface = _surface(Vector2(0.1, 0.0), 0.0)
	var animator: SurfaceAnimator = SurfaceAnimator.create([surface] as Array[AnimatedSurface])
	add_child_autofree(animator)
	animator._process(0.5)
	var texel: float = 1.0 / surface.texels
	var x: float = animator.get_offset(0).x
	assert_almost_eq(fmod(x, texel), 0.0, 0.0001)
	assert_gt(x, 0.0)


func test_flicker_never_brightens() -> void:
	var surface: AnimatedSurface = _surface(Vector2.ZERO, 0.3)
	var animator: SurfaceAnimator = SurfaceAnimator.create([surface] as Array[AnimatedSurface])
	add_child_autofree(animator)
	for step: int in 20:
		animator._process(0.07)
		assert_lte(surface.material.albedo_color.r, 1.0)
		assert_gte(surface.material.albedo_color.r, 0.69)


func test_material_restored_on_exit() -> void:
	var surface: AnimatedSurface = _surface(Vector2(0.5, 0.5), 0.3)
	var animator: SurfaceAnimator = SurfaceAnimator.create([surface] as Array[AnimatedSurface])
	add_child(animator)
	animator._process(0.33)
	remove_child(animator)
	animator.free()
	assert_eq(surface.material.uv1_offset, Vector3.ZERO)
	assert_eq(surface.material.albedo_color, Color.WHITE)


func test_shipped_list_loads() -> void:
	var list: AnimatedSurfaceList = load("res://levels/animated_surfaces.tres") as AnimatedSurfaceList
	assert_eq(list.surfaces.size(), 3)
	for surface: AnimatedSurface in list.surfaces:
		assert_not_null(surface.material)
