extends GutTest
## Enemies come back from a quicksave alive or dead, hurt, awake, risen or
## still buried, and in the right phase, without replaying sounds or
## re-reporting kills.

const BANDIT_SCENE: PackedScene = preload("res://enemies/bandit/bandit.tscn")
const SKELETON_SCENE: PackedScene = preload("res://enemies/skeleton/skeleton.tscn")
const DISGUISED_SCENE: PackedScene = preload("res://enemies/werewolf/disguised_bandit.tscn")
const WEREWOLF_DATA: String = "res://enemies/werewolf/werewolf.tres"


func _spawn(scene: PackedScene) -> Enemy:
	var enemy: Enemy = scene.instantiate() as Enemy
	add_child_autofree(enemy)
	return enemy


func _round_trip(scene: PackedScene, prepare: Callable) -> Enemy:
	var before: Enemy = _spawn(scene)
	await wait_physics_frames(2)
	prepare.call(before)
	var state: Dictionary = before.save_state()
	var after: Enemy = _spawn(scene)
	await wait_physics_frames(2)
	after.load_state(state)
	return after


func test_hurt_awake_enemy_comes_back_hurt_and_awake() -> void:
	var after: Enemy = await _round_trip(BANDIT_SCENE, func(enemy: Enemy) -> void:
		enemy.global_position = Vector3(3.0, 0.0, -2.0)
		HealthComponent.find_on(enemy).current_health = 11.0
		enemy.wake())
	assert_eq(HealthComponent.find_on(after).current_health, 11.0)
	assert_almost_eq(after.global_position.x, 3.0, 0.01)
	assert_true(after.is_physics_processing())


func test_dead_enemy_comes_back_a_corpse_without_a_kill_report() -> void:
	watch_signals(EventBus)
	var after: Enemy = await _round_trip(BANDIT_SCENE, func(enemy: Enemy) -> void:
		HealthComponent.find_on(enemy).take_damage(1000.0, Damage.Type.SLASH, null))
	assert_signal_emit_count(EventBus, "enemy_killed", 1, "only the original death")
	assert_true(after.is_dead())
	assert_false(after.can_be_targeted())
	assert_false(after.is_physics_processing())


func test_buried_skeleton_stays_buried() -> void:
	var after: Enemy = await _round_trip(SKELETON_SCENE, func(_enemy: Enemy) -> void: pass)
	assert_true(after.is_dormant())
	assert_false(after.is_physics_processing())


func test_risen_skeleton_comes_back_risen_at_once() -> void:
	var after: Enemy = await _round_trip(SKELETON_SCENE, func(enemy: Enemy) -> void:
		enemy.rise_from_ground())
	assert_false(after.is_dormant())
	assert_true(after.can_be_targeted())
	assert_almost_eq((after.get_node("Sprite") as Node3D).scale.y, 1.0, 0.001)


func test_risen_werewolf_keeps_its_phase() -> void:
	var after: Enemy = await _round_trip(DISGUISED_SCENE, func(enemy: Enemy) -> void:
		enemy.change_data(load(WEREWOLF_DATA) as EnemyData))
	assert_eq(after.data.resource_path, WEREWOLF_DATA)
	assert_false(after.is_dead())


func test_werewolf_saved_mid_rise_comes_back_risen() -> void:
	var after: Enemy = await _round_trip(DISGUISED_SCENE, func(enemy: Enemy) -> void:
		HealthComponent.find_on(enemy).take_damage(1000.0, Damage.Type.SLASH, null))
	assert_eq(after.data.resource_path, WEREWOLF_DATA)
	assert_false(after.is_dead())
