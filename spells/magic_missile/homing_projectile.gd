class_name HomingProjectile
extends Projectile
## A projectile that steers toward [member homing_target] at a limited turn
## rate, keeping its speed. Turn rate comes from SpellData.homing_turn_rate.
## Shared by imps and (later) the player's wand of magic missile.

## Meters above the target's origin the missile steers toward (chest).
const TARGET_AIM_HEIGHT: float = 1.0

## Set by whoever fires it, after launch(). Null flies straight.
var homing_target: Node3D
var turn_rate: float = 0.0


func apply_weapon_data(weapon_data: WeaponData) -> void:
	var spell: SpellData = weapon_data as SpellData
	if spell != null:
		turn_rate = spell.homing_turn_rate


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
	# is_instance_valid: the target may be freed mid-flight (level change).
	if turn_rate > 0.0 and homing_target != null and is_instance_valid(homing_target):
		var aim: Vector3 = homing_target.global_position + Vector3.UP * TARGET_AIM_HEIGHT
		velocity = steer(velocity, aim - global_position, turn_rate * delta)
	super(delta)
