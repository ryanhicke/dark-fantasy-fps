class_name Enemy
extends CharacterBody3D
## Base enemy body: senses the player and turns EnemyBrain decisions into
## actions. Movement math lives in EnemyMovement, ranged shots in
## EnemyRangedAttack, and visuals in EnemySprite.
##
## Expects children: CollisionShape3D, Sprite (EnemySprite),
## HealthComponent, and SightCast (RayCast3D).
## Optional children: Voice (AudioStreamPlayer3D) for EnemyData sounds,
## RiseTrigger to start hidden in the ground (e.g. skeletons).

## Emitted when the enemy first notices the player (IDLE -> CHASE), however
## it was woken: sight, pain, rising, or wake().
signal alerted

## Seconds between line-of-sight checks while idle. Each enemy starts at a
## random offset, so a room full of enemies doesn't raycast on the same frame.
const SIGHT_CHECK_INTERVAL: float = 0.2
## How far below a dead flyer to look for the floor its corpse lands on.
const CORPSE_DROP_MAX: float = 50.0
## Seconds a dead flyer takes to fall to the floor.
const CORPSE_FALL_TIME: float = 0.4

@export var data: EnemyData
## Separate from project gravity, matching the player.
@export var gravity: float = 15.0
## Meters above the target's origin that sight rays and shots aim at (chest height).
@export var target_aim_height: float = 1.2
## False for summoned enemies: they don't add to the level's kill total,
## and killing them isn't tallied, so 100% kills stays reachable.
@export var counts_for_stats: bool = true

var _brain: EnemyBrain
var _target: Node3D
var _target_health: HealthComponent
var _sight_timer: float = 0.0
var _can_see_target: bool = false

@onready var _health: HealthComponent = $HealthComponent
@onready var _sprite: EnemySprite = $Sprite
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _sight_cast: RayCast3D = $SightCast
@onready var _voice: AudioStreamPlayer3D = get_node_or_null("Voice") as AudioStreamPlayer3D


func _enter_tree() -> void:
	# The player's homing spells pick targets from this group.
	add_to_group(HomingProjectile.TARGET_GROUP)


func _ready() -> void:
	if data == null:
		push_error("%s: no EnemyData assigned." % name)
		set_physics_process(false)
		return
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)
	_sight_cast.enabled = false
	_sight_cast.add_exception(self)
	_apply_data()
	_sight_timer = randf() * SIGHT_CHECK_INTERVAL
	# Deferred: in map levels the player is spawned by the Level root, whose
	# _ready runs after its children's.
	_acquire_target.call_deferred()


## (Re)builds everything that depends on [member data]. Runs at spawn and
## again when a second phase takes over the same node.
func _apply_data() -> void:
	_brain = EnemyBrain.new(data)
	_brain.state_changed.connect(_on_brain_state_changed)
	_brain.attack_struck.connect(_on_brain_attack_struck)
	_health.max_health = data.max_health
	_health.resistances = data.resistances
	_health.reset()
	_sprite.set_sheet(data.sprite_sheet)
	_sprite.set_base_color(data.placeholder_color)
	_show_state()


## One group lookup at spawn, never per frame. Levels are reloaded on
## respawn, so the target never changes during an enemy's life.
func _acquire_target() -> void:
	_target = get_tree().get_first_node_in_group(Player.GROUP) as Node3D
	_target_health = HealthComponent.find_on(_target)


func _physics_process(delta: float) -> void:
	var distance: float = INF
	var target_alive: bool = false
	if _target != null:
		distance = global_position.distance_to(_target.global_position)
		target_alive = _target_health == null or not _target_health.is_dead()

	# Melee enemies only need sight to wake up, so once awake they skip the
	# raycast. Ranged enemies keep checking so they never shoot into walls.
	if _target != null and (_brain.state == EnemyBrain.State.IDLE or data.is_ranged()):
		_update_sight(delta, distance)
	_brain.update(delta, distance, _can_see_target, target_alive)

	var chasing: bool = _brain.state == EnemyBrain.State.CHASE and _target != null
	var target_position: Vector3 = _target.global_position if _target != null else global_position
	if data.flying:
		velocity = EnemyMovement.flying_velocity(
			global_position, target_position, data.hover_height, data.move_speed, chasing
		)
	else:
		velocity = EnemyMovement.ground_velocity(
			velocity, global_position, target_position, data.move_speed,
			chasing, is_on_floor(), gravity, delta
		)
	move_and_slide()


func _update_sight(delta: float, distance: float) -> void:
	_sight_timer -= delta
	if _sight_timer > 0.0:
		return
	_sight_timer = SIGHT_CHECK_INTERVAL
	_can_see_target = distance <= data.sight_range and _has_line_of_sight()


func _has_line_of_sight() -> bool:
	var aim_point: Vector3 = _target.global_position + Vector3.UP * target_aim_height
	_sight_cast.target_position = _sight_cast.to_local(aim_point)
	_sight_cast.force_raycast_update()
	return _sight_cast.get_collider() == _target


func _on_damaged(_amount: float, _type: Damage.Type, _source: Node) -> void:
	# A lethal hit is handled entirely by _on_died.
	if _health.is_dead():
		return
	_brain.take_hit(randf())
	_sprite.flash_pain(_brain.state, _brain.is_winding_up())


func _on_died(_source: Node) -> void:
	_brain.die()
	set_physics_process(false)
	# Deferred: changing collision state inside a physics callback is not allowed.
	_collision.set_deferred("disabled", true)
	var collapse: Tween = _sprite.collapse()
	if data.flying:
		_drop_corpse_to_floor()
	if data.revive_as != null:
		# Same node rises again, so there is no spawn (and no stutter), and
		# the level's enemy count stays one per node.
		collapse.tween_interval(data.revive_delay)
		collapse.tween_callback(_rise_as.bind(data.revive_as))
		return
	EventBus.enemy_killed.emit(self)


func is_dead() -> bool:
	return _health.is_dead()


## HomingProjectile.TARGET_GROUP contract: alive and tangible (not buried
## or a corpse).
func can_be_targeted() -> bool:
	return not _health.is_dead() and not _collision.disabled


## HomingProjectile.TARGET_GROUP contract: the body's center, so missiles
## hit small flyers and huge bosses alike.
func get_aim_point() -> Vector3:
	return _collision.global_position


## Alerts the enemy as if it had seen the player.
func wake() -> void:
	_brain.wake()


## Switches this node to [param next_data] in place: new stats, fresh
## health, and a new brain that is already hunting. Used for second phases
## (disguised werewolves) and boss phase changes.
func change_data(next_data: EnemyData) -> void:
	data = next_data
	_apply_data()
	velocity = Vector3.ZERO
	_collision.disabled = false
	set_physics_process(true)
	# No sight check needed: waking plays its alert sound (e.g. a howl).
	_brain.wake()


## Brings this node back as a fresh enemy rising out of the ground at
## [param at]. Used by EnemySummoner to reuse pooled (or dead) enemies
## instead of spawning new nodes mid-fight.
func respawn_rising(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	_apply_data()
	make_dormant()
	rise_from_ground()


## Hides the enemy in the ground with no AI or collision until
## rise_from_ground(). Used by RiseTrigger.
func make_dormant() -> void:
	set_physics_process(false)
	_collision.disabled = true
	_sprite.hide_in_ground()


## Climbs out of the ground, then hunts the player without needing sight.
func rise_from_ground() -> void:
	if _brain == null or _brain.state != EnemyBrain.State.IDLE:
		return
	_sprite.climb_out().tween_callback(_finish_rising)


func _finish_rising() -> void:
	_collision.disabled = false
	set_physics_process(true)
	_brain.wake()


## Physics is off once dead, so a flyer's corpse is moved down by one
## raycast at death instead of falling under gravity every frame.
func _drop_corpse_to_floor() -> void:
	if _target != null:
		_sight_cast.add_exception(_target)
	_sight_cast.target_position = Vector3.DOWN * CORPSE_DROP_MAX
	_sight_cast.force_raycast_update()
	if _target != null:
		_sight_cast.remove_exception(_target)
	if not _sight_cast.is_colliding():
		return
	var floor_point: Vector3 = _sight_cast.get_collision_point()
	var fall: Tween = create_tween()
	fall.tween_property(self, "global_position:y", floor_point.y, CORPSE_FALL_TIME)


func _rise_as(next_data: EnemyData) -> void:
	_sprite.stand_up()
	change_data(next_data)


func _on_brain_state_changed(new_state: EnemyBrain.State, old_state: EnemyBrain.State) -> void:
	_show_state()
	if old_state == EnemyBrain.State.IDLE and new_state == EnemyBrain.State.CHASE:
		play_sound(data.alert_sound)
		alerted.emit()


func _on_brain_attack_struck(hit: bool) -> void:
	_show_state()
	if not hit:
		return
	if data.is_ranged():
		if _target != null:
			EnemyRangedAttack.fire(data, self, _target, target_aim_height)
	elif _target_health != null:
		_target_health.take_damage(data.attack_damage, data.attack_damage_type, self)


func _show_state() -> void:
	_sprite.show_state(_brain.state, _brain.is_winding_up())


## Plays through the optional Voice child; silent if either is missing.
func play_sound(stream: AudioStream) -> void:
	if stream == null or _voice == null:
		return
	_voice.stream = stream
	_voice.play()
