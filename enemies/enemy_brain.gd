class_name EnemyBrain
extends RefCounted
## Decides what an enemy is doing: IDLE, CHASE, ATTACK, PAIN, or DIE.
##
## Pure logic with no nodes. The Enemy feeds it what it senses each tick and
## acts on the resulting state and signals. Kept separate so the rules can be
## unit tested without physics or a scene tree.

enum State {
	IDLE,
	CHASE,
	ATTACK,
	PAIN,
	DIE,
}

signal state_changed(new_state: State, old_state: State)
## Emitted when an attack's windup finishes. [param hit] is false if the
## target backed out of range or died during the windup.
signal attack_struck(hit: bool)

## Leftover time below this counts as finished, so float residue from
## summing frame deltas never adds an extra frame.
const TIME_EPSILON: float = 0.0001

var state: State = State.IDLE
var data: EnemyData

## Countdown for the timed states (ATTACK windup/recovery, PAIN).
var _time_left: float = 0.0
var _winding_up: bool = false


func _init(enemy_data: EnemyData) -> void:
	data = enemy_data


func is_winding_up() -> bool:
	return state == State.ATTACK and _winding_up


## Starts chasing if idle. Used for anything that alerts the enemy besides
## sight (being hurt now, noise later).
func wake() -> void:
	if state == State.IDLE:
		_change_state(State.CHASE)


## Advance one tick. [param can_see] only matters while idle; once awake the
## enemy chases relentlessly, Doom-style.
func update(delta: float, distance: float, can_see: bool, target_alive: bool) -> void:
	match state:
		State.IDLE:
			if target_alive and can_see and distance <= data.sight_range:
				_change_state(State.CHASE)
		State.CHASE:
			if not target_alive:
				_change_state(State.IDLE)
			elif distance <= data.attack_range:
				_start_attack()
		State.ATTACK:
			_time_left -= delta
			if _time_left > TIME_EPSILON:
				return
			if _winding_up:
				_winding_up = false
				_time_left = data.attack_recovery
				attack_struck.emit(target_alive and distance <= data.attack_range)
			else:
				_resume(target_alive)
		State.PAIN:
			_time_left -= delta
			if _time_left <= TIME_EPSILON:
				_resume(target_alive)
		State.DIE:
			pass


## Call for every non-lethal hit. [param pain_roll] is a 0..1 random value,
## passed in so tests can force either outcome.
func take_hit(pain_roll: float) -> void:
	if state == State.DIE:
		return
	wake()
	if pain_roll < data.pain_chance:
		# Pain cancels a windup in progress: the stagger reward for hitting first.
		_winding_up = false
		_time_left = data.pain_duration
		_change_state(State.PAIN)


func die() -> void:
	_change_state(State.DIE)


func _start_attack() -> void:
	# Set before the state change so listeners already see the windup.
	_winding_up = true
	_time_left = data.attack_windup
	_change_state(State.ATTACK)


func _resume(target_alive: bool) -> void:
	_change_state(State.CHASE if target_alive else State.IDLE)


func _change_state(new_state: State) -> void:
	if new_state == state:
		return
	var old_state: State = state
	state = new_state
	state_changed.emit(new_state, old_state)
