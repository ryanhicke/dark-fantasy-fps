extends GutTest
## EffectPrewarmer copies only meshes and materials, and cleans itself up.

const FIREBALL: PackedScene = preload("res://spells/fireball/fireball.tscn")
const EXPLOSION: PackedScene = preload("res://spells/fireball/fireball_explosion.tscn")
const ARROW: PackedScene = preload("res://weapons/arrow/arrow.tscn")


func _free_all(meshes: Array[GeometryInstance3D]) -> void:
	for mesh: GeometryInstance3D in meshes:
		mesh.free()


func test_copies_have_no_scripts_and_keep_the_mesh() -> void:
	var copies: Array[GeometryInstance3D] = EffectPrewarmer.copy_meshes(FIREBALL)
	# Sprite, its bright core, and the ember trail.
	assert_eq(copies.size(), 3)
	assert_null(copies[0].get_script())
	assert_not_null((copies[0] as MeshInstance3D).mesh)
	_free_all(copies)


func test_material_override_is_carried_over() -> void:
	var copies: Array[GeometryInstance3D] = EffectPrewarmer.copy_meshes(EXPLOSION)
	# The burst sprite and the sparks.
	assert_eq(copies.size(), 2)
	assert_not_null(copies[0].material_override)
	_free_all(copies)


func test_every_mesh_in_a_scene_is_copied() -> void:
	var copies: Array[GeometryInstance3D] = EffectPrewarmer.copy_meshes(ARROW)
	assert_eq(copies.size(), 2)
	_free_all(copies)


func test_null_scene_gives_nothing() -> void:
	assert_eq(EffectPrewarmer.copy_meshes(null).size(), 0)


func test_shipped_list_loads() -> void:
	var list: EffectPrewarmList = load("res://levels/effect_prewarm_list.tres") as EffectPrewarmList
	assert_not_null(list)
	assert_gt(list.scenes.size(), 0)
	for scene: PackedScene in list.scenes:
		assert_not_null(scene)


func test_frees_itself_after_drawing() -> void:
	var camera: Camera3D = Camera3D.new()
	add_child_autofree(camera)
	var prewarmer: EffectPrewarmer = EffectPrewarmer.start(camera, [FIREBALL, ARROW] as Array[PackedScene])
	assert_eq(prewarmer.get_parent(), camera)
	# Fireball sprite, core, and embers, plus the arrow's two meshes.
	assert_eq(prewarmer.get_child_count(), 5)
	await wait_process_frames(EffectPrewarmer.FRAMES_TO_DRAW + 2)
	assert_false(is_instance_valid(prewarmer))
