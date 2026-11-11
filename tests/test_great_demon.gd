extends GutTest
## Great demon fight rules (docs/enemies.md, Level 8). Obelisks are
## simulated by calling GreatDemonPhases.on_obelisk_destroyed().

const SCENE_PATH: String = "res://enemies/great_demon/great_demon.tscn"
const FINAL_DATA_PATH: String = "res://enemies/great_demon/great_demon_final.tres"
const OBELISKS: int = 4
const MAX_SUMMONS: int = 12
const SETTLE_FRAMES: int = 3
const ALL_TYPES: Array[Damage.Type] = [
	Damage.Type.SLASH, Damage.Type.PIERCE, Damage.Type.BLUNT,
	Damage.Type.FIRE, Damage.Type.MAGIC, Damage.Type.THROWN, Damage.Type.LIGHTNING,
]

var _arena: Node3D
var _demon: Enemy
var _phases: GreatDemonPhases
var _health: HealthComponent
var _demons: EnemySummoner
var _imps: EnemySummoner
var _werewolves: EnemySummoner


func before_each() -> void:
	_arena = Node3D.new()
	add_child_autofree(_arena)
	_demon = (load(SCENE_PATH) as PackedScene).instantiate() as Enemy
	_arena.add_child(_demon)
	_phases = _demon.get_node("Phases") as GreatDemonPhases
	_health = HealthComponent.find_on(_demon)
	_demons = _demon.get_node("DemonSummoner") as EnemySummoner
	_imps = _demon.get_node("ImpSummoner") as EnemySummoner
	_werewolves = _demon.get_node("WerewolfSummoner") as EnemySummoner
	await wait_physics_frames(SETTLE_FRAMES)


func _destroy_obelisks(count: int) -> void:
	for i: int in count:
		_phases.on_obelisk_destroyed()


func _crack_visible(index: int) -> bool:
	return (_demon.get_node("Sprite/Crack%d" % index) as Node3D).visible


func test_sealed_demon_takes_no_damage_of_any_type() -> void:
	for type: Damage.Type in ALL_TYPES:
		_health.take_damage(100.0, type, null)
	assert_eq(_health.current_health, _health.max_health)


func test_summon_cap_stays_within_budget() -> void:
	var total: int = _demons.max_alive + _imps.max_alive + _werewolves.max_alive
	assert_lte(total, MAX_SUMMONS)


func test_summons_demons_and_imps_once_alerted_but_not_werewolves() -> void:
	assert_false(_demons.is_active(), "quiet until it notices the player")
	_demon.wake()
	assert_true(_demons.is_active())
	assert_true(_imps.is_active())
	assert_false(_werewolves.is_active())


func test_werewolves_join_after_second_obelisk() -> void:
	_demon.wake()
	_destroy_obelisks(1)
	assert_false(_werewolves.is_active())
	_destroy_obelisks(1)
	assert_true(_werewolves.is_active())


func test_obelisk_wakes_a_sleeping_demon() -> void:
	_destroy_obelisks(1)
	assert_true(_demons.is_active())


func test_each_obelisk_opens_a_crack_and_speeds_up_summons() -> void:
	_demon.wake()
	var before: float = _demons.summon_interval
	_destroy_obelisks(1)
	assert_true(_crack_visible(1))
	assert_false(_crack_visible(2))
	assert_lt(_demons.summon_interval, before)


func test_still_immune_after_three_obelisks() -> void:
	_destroy_obelisks(OBELISKS - 1)
	for type: Damage.Type in ALL_TYPES:
		_health.take_damage(100.0, type, null)
	assert_eq(_health.current_health, _health.max_health)


func test_final_phase_stops_summoning_and_only_lightning_hurts() -> void:
	_demon.wake()
	_destroy_obelisks(OBELISKS)
	assert_true(_phases.is_final_phase())
	assert_eq(_demon.data, load(FINAL_DATA_PATH))
	for summoner: EnemySummoner in [_demons, _imps, _werewolves]:
		assert_false(summoner.is_active())
	for i: int in OBELISKS:
		assert_true(_crack_visible(i + 1))
	for type: Damage.Type in ALL_TYPES:
		if type != Damage.Type.LIGHTNING:
			_health.take_damage(100.0, type, null)
	assert_eq(_health.current_health, _health.max_health, "only lightning")
	_health.take_damage(50.0, Damage.Type.LIGHTNING, null)
	assert_eq(_health.current_health, _health.max_health - 50.0)


func test_extra_obelisk_events_are_ignored() -> void:
	_destroy_obelisks(OBELISKS + 2)
	assert_eq(_phases.obelisks_destroyed, OBELISKS)


func test_obelisk_event_bus_drives_the_fight() -> void:
	EventBus.obelisk_destroyed.emit()
	assert_eq(_phases.obelisks_destroyed, 1)


func test_counts_as_one_kill_with_summons_excluded() -> void:
	assert_eq(Level._count_enemies(_arena), 1)
