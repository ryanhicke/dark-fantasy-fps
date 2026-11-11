class_name HomingProjectile
extends Projectile
## A projectile that steers toward [member homing_target] at a limited turn
## rate, keeping its speed. Turn rate comes from SpellData.homing_turn_rate.
## Shared by imps (targeting the player) and the player's wand of magic
## missile (targeting enemies, picked by HomingLock).

## Group of things a player's homing spell may lock onto. Members are
## Node3Ds with get_aim_point() -> Vector3 and can_be_targeted() -> bool
## (enemies now, crystal obelisks later).
const TARGET_GROUP: StringName = &"homing_targets"
## Meters above the target's origin to steer toward when it has no
## get_aim_point() (the player: chest height).
const TARGET_AIM_HEIGHT: float = 1.0

var homing_target: Node3D:
	set = set_homing_target
var turn_rate: float = 0.0

## Cached per target, so flight never checks methods every tick.
var _target_reports_aim: bool = false


func apply_weapon_data(weapon_data: WeaponData) -> void:
	var spell: SpellData = weapon_data as SpellData
	if spell != null:
		turn_rate = spell.homing_turn_rate


## Set after launch(). Null flies straight.
func set_homing_target(target: Node3D) -> void:
	homing_target = target
	_target_reports_aim = target != null and target.has_method(&"get_aim_point")


## Turns [param current] toward [param desired_direction] by at most
## [param max_angle] radians, keeping its length. Static so tests can run
## the exact math the game uses.
static func steer(current: Vector3, desired_direction: Vector3, max_angle: float) -> Vector3:
	var speed: float = current.length()
	if speed <= 0.0 or desired_direction == Vector3.ZERO:
		return current
	var from: Vector3 = current / speed
	var to: Vector3 = desired_direction.normalized()
	var angle: float = from.angle_to(to)
	if angle <= max_angle:
		return to * speed
	return from.slerp(to, max_angle / angle) * speed


func _physics_process(delta: float) -> void:
	if turn_rate > 0.0 and _target_still_valid():
		velocity = steer(velocity, _target_aim_point() - global_position, turn_rate * delta)
	super(delta)


func _target_still_valid() -> bool:
	# is_instance_valid: the target may be freed mid-flight (level change).
	if homing_target == null or not is_instance_valid(homing_target):
		return false
	# A target that died mid-flight is let go, so the missile flies on
	# instead of circling a corpse.
	return not _target_reports_aim or homing_target.call(&"can_be_targeted")


func _target_aim_point() -> Vector3:
	if _target_reports_aim:
		return homing_target.call(&"get_aim_point")
	return homing_target.global_position + Vector3.UP * TARGET_AIM_HEIGHT
