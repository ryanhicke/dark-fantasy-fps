extends GutTest
## Difficulty tables, and that the chosen level reaches enemy health and
## the damage the player takes.

const BANDIT_SCENE: PackedScene = preload("res://enemies/bandit/bandit.tscn")
const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const HIT: float = 20.0


func after_each() -> void:
	# The autoload outlives the test; leave it as the other tests expect.
	GameState.difficulty = Difficulty.DEFAULT


func _spawn_health(scene: PackedScene, level: Difficulty.Skill) -> HealthComponent:
	GameState.difficulty = level
	var node: Node = scene.instantiate()
	add_child_autofree(node)
	return HealthComponent.find_on(node)


func test_every_level_has_a_title_description_and_both_multipliers() -> void:
	for level: Difficulty.Skill in Difficulty.Skill.values():
		assert_ne(Difficulty.title(level), "", "title %d" % level)
		assert_ne(Difficulty.description(level), "", "description %d" % level)
		assert_true(Difficulty.PLAYER_DAMAGE_TAKEN.has(level), "damage %d" % level)
		assert_true(Difficulty.ENEMY_HEALTH.has(level), "health %d" % level)


func test_normal_changes_nothing() -> void:
	assert_eq(Difficulty.player_damage_taken(Difficulty.Skill.NORMAL), 1.0)
	assert_eq(Difficulty.enemy_health(Difficulty.Skill.NORMAL), 1.0)


func test_easy_is_gentler_and_hard_is_harsher_than_normal() -> void:
	assert_lt(Difficulty.player_damage_taken(Difficulty.Skill.EASY), 1.0)
	assert_lt(Difficulty.enemy_health(Difficulty.Skill.EASY), 1.0)
	assert_gt(Difficulty.player_damage_taken(Difficulty.Skill.HARD), 1.0)
	assert_gt(Difficulty.enemy_health(Difficulty.Skill.HARD), 1.0)


func test_from_variant_rejects_anything_that_is_not_a_level() -> void:
	assert_eq(Difficulty.from_variant(Difficulty.Skill.HARD), Difficulty.Skill.HARD)
	assert_eq(Difficulty.from_variant(0), Difficulty.Skill.EASY)
	assert_eq(Difficulty.from_variant(99), Difficulty.DEFAULT)
	assert_eq(Difficulty.from_variant("hard"), Difficulty.DEFAULT)
	assert_eq(Difficulty.from_variant(null), Difficulty.DEFAULT)


func test_enemy_health_scales_with_the_level() -> void:
	var normal: float = _spawn_health(BANDIT_SCENE, Difficulty.Skill.NORMAL).max_health
	var easy: HealthComponent = _spawn_health(BANDIT_SCENE, Difficulty.Skill.EASY)
	var hard: HealthComponent = _spawn_health(BANDIT_SCENE, Difficulty.Skill.HARD)
	assert_almost_eq(easy.max_health, normal * Difficulty.enemy_health(Difficulty.Skill.EASY), 0.001)
	assert_almost_eq(hard.max_health, normal * Difficulty.enemy_health(Difficulty.Skill.HARD), 0.001)
	assert_eq(hard.current_health, hard.max_health)


func test_player_takes_scaled_damage() -> void:
	for level: Difficulty.Skill in Difficulty.Skill.values():
		var health: HealthComponent = _spawn_health(PLAYER_SCENE, level)
		health.take_damage(HIT, Damage.Type.SLASH, null)
		assert_almost_eq(
			health.max_health - health.current_health,
			HIT * Difficulty.player_damage_taken(level), 0.001, "level %d" % level
		)
