class_name RangedWeapon
extends Weapon
## Fires projectiles from the camera.
##
## If the data has a charge_time, holding the trigger draws (charges) and
## releasing fires; damage and speed scale with how long it was held.
## Otherwise it fires on press and repeats while held.
##
## Optional view model children:
## - "ViewModel/Draw": pulled back toward the camera while charging.
## - "ViewModel/Draw/Loaded": shown only when ready to fire (e.g. a nocked arrow).

@export_group("Draw Animation")
## Meters the Draw node moves back toward the camera at full charge.
@export var draw_pull_distance: float = 0.2

@export_group("Spawn")
## Meters in front of the camera where projectiles appear, so they don't
## start inside the near clip plane.
@export var muzzle_offset: float = 0.2

var _charging: bool = false
var _charge_elapsed: float = 0.0
var _draw_rest_position: Vector3 = Vector3.ZERO

@onready var _draw_part: Node3D = get_node_or_null("ViewModel/Draw") as Node3D
@onready var _loaded_part: Node3D = get_node_or_null("ViewModel/Draw/Loaded") as Node3D


func _ready() -> void:
	super()
	if _draw_part != null:
		_draw_rest_position = _draw_part.position


func _tick(delta: float) -> void:
	if _charging:
		_charge_elapsed = minf(_charge_elapsed + delta, data.charge_time)
		_update_draw_pose()
	elif _trigger_held and can_attack() and has_ammo():
		if data.charge_time > 0.0:
			_charging = true
			_charge_elapsed = 0.0
		else:
			_fire(0.0)
	if _loaded_part != null:
		_loaded_part.visible = _charging or (not is_busy() and has_ammo())


func _on_trigger_released() -> void:
	if _charging:
		_fire(_charge_ratio())


func _on_interrupted() -> void:
	_charging = false
	_charge_elapsed = 0.0
	_update_draw_pose()


func _fire(charge: float) -> void:
	_charging = false
	_charge_elapsed = 0.0
	_update_draw_pose()
	if not _consume_ammo():
		return
	_begin_cooldown()
	var damage: float = data.damage
	var speed: float = data.projectile_speed
	if data.charge_time > 0.0:
		damage = lerpf(data.damage, data.max_charge_damage, charge)
		speed = lerpf(data.projectile_speed, data.max_charge_speed, charge)
	var projectile: Projectile = data.projectile_scene.instantiate() as Projectile
	# Parent to the level (the player's parent), not the weapon, so the
	# projectile doesn't move with the camera and is freed with the level.
	_owner_body.get_parent().add_child(projectile)
	var forward: Vector3 = -_aim.global_transform.basis.z
	projectile.launch(
		_aim.global_position + forward * muzzle_offset,
		forward * speed,
		data.projectile_gravity,
		damage,
		data.damage_type,
		_owner_body
	)


func _charge_ratio() -> float:
	if data.charge_time <= 0.0:
		return 0.0
	return _charge_elapsed / data.charge_time


func _update_draw_pose() -> void:
	if _draw_part != null:
		_draw_part.position = _draw_rest_position + Vector3.BACK * draw_pull_distance * _charge_ratio()
