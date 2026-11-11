extends GutTest
## Necromancer boss (docs/enemies.md): fireballs, then below half health
## summons melee demons, capped at 5 alive, from a fixed pool.

const NECROMANCER_SCENE_PATH: String = "res://enemies/necromancer/necromancer.tscn"
const NECROMANCER_DATA_PATH: String = "res://enemies/necromancer/necromancer.tres"
const DEMON_DATA_PATH: String = "res://enemies/melee_demon/melee_demon.tres"
const DEMON_CAP: int = 5
## Fast waves so the test doesn't wait on real tuning values.
const TEST_INTERVAL: float = 0.05
## Pool fill is deferred; give it a few frames.
const SETTLE_FRAMES: int = 3
const WAVES_WAIT: float = 1.0

var _arena: Node3D
var _necromancer: Enemy
var _summoner: EnemySummoner


func before_each() -> void:
	_arena = Node3D.new()
	add_child_autofree(_arena)
	_necromancer = (load(NECROMANCER_SCENE_PATH) as PackedScene).instantiate() as Enemy
	_summoner = _necromancer.get_node("Summoner") as EnemySummoner
	_summoner.summon_interval = TEST_INTERVAL
	_arena.add_child(_necromancer)
	await wait_physics_frames(SETTLE_FRAMES)


func _summons() -> Array[Enemy]:
	var found: Array[Enemy] = []
	for child: Node in _arena.get_children():
		if child is Enemy and child != _necromancer:
			found.append(child as Enemy)
	return found


func _drop_below_half() -> void:
	var health: HealthComponent = HealthComponent.find_on(_necromancer)
	health.take_damage(health.max_health * 0.6, Damage.Type.SLASH, null)


func test_wave_size_respects_cap() -> void:
	assert_eq(EnemySummoner.wave_size(0, DEMON_CAP, 2), 2)
	assert_eq(EnemySummoner.wave_size(4, DEMON_CAP, 2), 1)
	assert_eq(EnemySummoner.wave_size(5, DEMON_CAP, 2), 0)
	assert_eq(EnemySummoner.wave_size(7, DEMON_CAP, 2), 0)


func test_casts_fireballs() -> void:
	var data: EnemyData = load(NECROMANCER_DATA_PATH) as EnemyData
	assert_true(data.is_ranged())
	assert_eq(data.attack_damage_type, Damage.Type.FIRE)


func test_pool_is_prebuilt_at_cap_and_uncounted() -> void:
	var summons: Array[Enemy] = _summons()
	assert_eq(summons.size(), DEMON_CAP, "whole pool exists from the start")
	for summon: Enemy in summons:
		assert_eq(summon.data, load(DEMON_DATA_PATH))
		assert_false(summon.counts_for_stats)
		assert_false(summon.is_physics_processing(), "dormant until summoned")


func test_no_summons_above_half_health() -> void:
	await wait_seconds(WAVES_WAIT)
	assert_eq(_summoner.alive_count(), 0)


func test_never_more_than_cap_alive() -> void:
	_drop_below_half()
	await wait_seconds(WAVES_WAIT)
	assert_eq(_summoner.alive_count(), DEMON_CAP)
	assert_eq(_summons().size(), DEMON_CAP, "no nodes added beyond the pool")


func test_dead_summons_are_reused() -> void:
	_drop_below_half()
	await wait_seconds(WAVES_WAIT)
	for summon: Enemy in _summons():
		HealthComponent.find_on(summon).take_damage(1000.0, Damage.Type.SLASH, null)
	assert_eq(_summoner.alive_count(), 0)
	await wait_seconds(WAVES_WAIT)
	assert_eq(_summoner.alive_count(), DEMON_CAP, "corpses came back as fresh demons")
	assert_eq(_summons().size(), DEMON_CAP)


func test_stops_summoning_when_dead() -> void:
	_drop_below_half()
	HealthComponent.find_on(_necromancer).take_damage(10000.0, Damage.Type.SLASH, null)
	var alive_at_death: int = _summoner.alive_count()
	await wait_seconds(WAVES_WAIT)
	assert_eq(_summoner.alive_count(), alive_at_death)


func test_summons_do_not_count_toward_level_kills() -> void:
	assert_eq(Level._count_enemies(_arena), 1, "only the necromancer counts")
