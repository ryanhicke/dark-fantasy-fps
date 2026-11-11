extends GutTest
## Werewolf design rules from docs/enemies.md, plus the in-place second
## phase that disguised werewolves use.

const WEREWOLF_PATH: String = "res://enemies/werewolf/werewolf.tres"
const BANDIT_PATH: String = "res://enemies/bandit/bandit.tres"
const DISGUISE_PATHS: Array[String] = [
	"res://enemies/werewolf/disguised_bandit.tres",
	"res://enemies/werewolf/disguised_bandit_archer.tres",
	"res://enemies/werewolf/disguised_armored_mercenary.tres",
]
const DISGUISED_SCENE_PATH: String = "res://enemies/werewolf/disguised_bandit.tscn"
## Revive delay plus collapse time, with slack.
const REVIVE_WAIT: float = 2.0

var _werewolf: EnemyData
var _bandit: EnemyData


func before_all() -> void:
	_werewolf = load(WEREWOLF_PATH) as EnemyData
	_bandit = load(BANDIT_PATH) as EnemyData


func test_weak_to_fire() -> void:
	assert_gt(_werewolf.resistances.multiplier_for(Damage.Type.FIRE), 1.0)


func test_hits_harder_but_goes_down_easier_than_a_bandit() -> void:
	assert_gt(_werewolf.attack_damage, _bandit.attack_damage)
	assert_lt(_werewolf.max_health, _bandit.max_health)


func test_faster_than_a_bandit_but_slower_than_the_player() -> void:
	assert_gt(_werewolf.move_speed, _bandit.move_speed)
	var player: Node = (load("res://player/player.tscn") as PackedScene).instantiate()
	assert_lt(_werewolf.move_speed, player.get("move_speed") as float)
	player.free()


func test_every_disguise_rises_as_a_werewolf() -> void:
	for path: String in DISGUISE_PATHS:
		var disguise: EnemyData = load(path) as EnemyData
		assert_eq(disguise.revive_as, _werewolf, path)


func test_disguised_enemy_rises_in_place_and_counts_one_kill() -> void:
	var kills: Array[Node] = []
	var on_killed: Callable = func(enemy: Node) -> void: kills.append(enemy)
	EventBus.enemy_killed.connect(on_killed)
	var enemy: Enemy = (load(DISGUISED_SCENE_PATH) as PackedScene).instantiate() as Enemy
	add_child_autofree(enemy)
	var health: HealthComponent = HealthComponent.find_on(enemy)

	health.take_damage(1000.0, Damage.Type.SLASH, null)
	assert_eq(kills.size(), 0, "first death is not a kill")
	await wait_seconds(REVIVE_WAIT)
	assert_true(is_instance_valid(enemy), "same node survives")
	assert_eq(enemy.data, _werewolf)
	assert_eq(health.current_health, _werewolf.max_health)

	health.take_damage(1000.0, Damage.Type.SLASH, null)
	await wait_seconds(REVIVE_WAIT)
	assert_eq(kills.size(), 1, "second death counts once")
	assert_eq(enemy.data, _werewolf, "no third phase")
	EventBus.enemy_killed.disconnect(on_killed)
