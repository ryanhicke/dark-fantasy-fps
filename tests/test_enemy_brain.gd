extends GutTest
## State machine rules in EnemyBrain. Pure logic, no physics.

const STEP: float = 0.05
const WINDUP: float = 0.5
const RECOVERY: float = 0.6
const PAIN_TIME: float = 0.35
const ATTACK_RANGE: float = 1.8
const SIGHT_RANGE: float = 20.0
const NEAR: float = 1.0
const MID: float = 10.0
const FAR: float = 30.0
const NO_PAIN_ROLL: float = 0.99
const PAIN_ROLL: float = 0.0

var _brain: EnemyBrain
var _strikes: Array[bool] = []


func before_each() -> void:
	var data: EnemyData = EnemyData.new()
	data.attack_windup = WINDUP
	data.attack_recovery = RECOVERY
	data.pain_duration = PAIN_TIME
	data.pain_chance = 0.5
	data.attack_range = ATTACK_RANGE
	data.sight_range = SIGHT_RANGE
	_brain = EnemyBrain.new(data)
	_strikes.clear()
	_brain.attack_struck.connect(func(hit: bool) -> void: _strikes.append(hit))


## Runs the brain for [param seconds] with fixed senses.
func _run(seconds: float, distance: float, can_see: bool = true, alive: bool = true) -> void:
	for i: int in roundi(seconds / STEP):
		_brain.update(STEP, distance, can_see, alive)


func _start_attack() -> void:
	_brain.wake()
	_run(STEP, NEAR)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK, "precondition: attacking")


func test_starts_idle() -> void:
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_wakes_when_target_seen_in_range() -> void:
	_run(STEP, MID, true)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)


func test_stays_idle_when_target_out_of_sight() -> void:
	_run(1.0, MID, false)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_stays_idle_when_target_beyond_sight_range() -> void:
	_run(1.0, FAR, true)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_ignores_dead_target() -> void:
	_run(1.0, MID, true, false)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_hit_without_pain_wakes_and_chases() -> void:
	_brain.take_hit(NO_PAIN_ROLL)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)


func test_chase_stays_chasing_out_of_sight() -> void:
	_brain.wake()
	_run(1.0, MID, false)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)


func test_chase_attacks_when_in_range() -> void:
	_brain.wake()
	_run(STEP, NEAR)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK)
	assert_true(_brain.is_winding_up())


func test_chase_returns_to_idle_when_target_dies() -> void:
	_brain.wake()
	_run(STEP, MID, true, false)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_attack_hits_after_windup_not_before() -> void:
	_start_attack()
	_run(WINDUP - 2.0 * STEP, NEAR)
	assert_eq(_strikes.size(), 0, "no strike during windup")
	_run(2.0 * STEP, NEAR)
	assert_eq(_strikes, [true] as Array[bool])
	assert_false(_brain.is_winding_up())


func test_attack_misses_if_target_backs_off() -> void:
	_start_attack()
	_run(WINDUP, MID)
	assert_eq(_strikes, [false] as Array[bool])


func test_returns_to_chase_after_recovery() -> void:
	_start_attack()
	_run(WINDUP, NEAR)
	_run(RECOVERY - 2.0 * STEP, MID)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK, "still recovering")
	_run(2.0 * STEP, MID)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)


func test_pain_interrupts_windup() -> void:
	_start_attack()
	_brain.take_hit(PAIN_ROLL)
	assert_eq(_brain.state, EnemyBrain.State.PAIN)
	_run(PAIN_TIME, MID)
	assert_eq(_strikes.size(), 0, "cancelled attack never strikes")


func test_pain_returns_to_chase_after_duration() -> void:
	_brain.wake()
	_brain.take_hit(PAIN_ROLL)
	_run(PAIN_TIME - 2.0 * STEP, MID)
	assert_eq(_brain.state, EnemyBrain.State.PAIN, "still staggered")
	_run(2.0 * STEP, MID)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)


func test_no_pain_keeps_windup_going() -> void:
	_start_attack()
	_brain.take_hit(NO_PAIN_ROLL)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK)
	assert_true(_brain.is_winding_up())


func test_dead_brain_ignores_hits_and_updates() -> void:
	_start_attack()
	_brain.die()
	_brain.take_hit(PAIN_ROLL)
	_run(2.0, NEAR)
	assert_eq(_brain.state, EnemyBrain.State.DIE)
	assert_eq(_strikes.size(), 0)


func test_state_changed_reports_new_and_old() -> void:
	var changes: Array[Array] = []
	_brain.state_changed.connect(
		func(new_state: EnemyBrain.State, old_state: EnemyBrain.State) -> void:
			changes.append([new_state, old_state])
	)
	_brain.wake()
	assert_eq(changes, [[EnemyBrain.State.CHASE, EnemyBrain.State.IDLE]] as Array[Array])


func test_ranged_waits_for_sight_before_attacking() -> void:
	_brain.data.projectile_scene = PackedScene.new()
	_brain.data.attack_range = MID + 1.0
	_brain.wake()
	_run(1.0, MID, false)
	assert_eq(_brain.state, EnemyBrain.State.CHASE, "no sight: keeps chasing")
	_run(STEP, MID, true)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK)


func test_melee_attacks_without_fresh_sight() -> void:
	_brain.wake()
	_run(STEP, NEAR, false)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK)
