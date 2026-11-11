class_name SpellWeapon
extends RangedWeapon
## A staff or wand that casts a SpellData spell. Firing, mana cost, and
## cooldown come from RangedWeapon; this adds the cast motion (a short
## forward thrust of the view model) and, for homing spells, the lock-on.
## Future non-projectile spells such as healing will hook in here.
##
## Homing spells need a child RayCast3D named "LockCast" (disabled) for
## the lock-on's line-of-sight check.

@export_group("Cast Animation")
## Meters the view model thrusts forward when casting.
@export var thrust_distance: float = 0.12
@export var thrust_time: float = 0.06
@export var thrust_recover_time: float = 0.2

var _cast_tween: Tween

@onready var _lock_cast: RayCast3D = get_node_or_null("LockCast") as RayCast3D


func _ready() -> void:
	super()
	attacked.connect(_on_attacked)
	if _lock_cast != null:
		# Top-level so it isn't moved by the cast animation.
		_lock_cast.top_level = true
		_lock_cast.enabled = false


func setup(owner_body: CollisionObject3D, aim: Node3D, inventory: Inventory) -> void:
	super(owner_body, aim, inventory)
	if _lock_cast != null and owner_body != null:
		_lock_cast.add_exception(owner_body)


func _on_projectile_launched(projectile: Projectile) -> void:
	var homing: HomingProjectile = projectile as HomingProjectile
	var spell: SpellData = data as SpellData
	if homing == null or spell == null or spell.homing_lock_angle_deg <= 0.0 or _lock_cast == null:
		return
	homing.homing_target = HomingLock.find_target(
		get_tree(),
		_aim.global_position,
		-_aim.global_transform.basis.z,
		deg_to_rad(spell.homing_lock_angle_deg),
		spell.homing_lock_range,
		_lock_cast
	)


func _on_interrupted() -> void:
	super()
	_stop_cast_animation()
	if _view_model != null:
		_view_model.position = _rest_position


func _on_attacked() -> void:
	if _view_model == null:
		return
	_stop_cast_animation()
	_cast_tween = create_tween()
	_cast_tween.tween_property(_view_model, "position", _rest_position + Vector3.FORWARD * thrust_distance, thrust_time)
	_cast_tween.tween_property(_view_model, "position", _rest_position, thrust_recover_time)


func _stop_cast_animation() -> void:
	if _cast_tween != null:
		_cast_tween.kill()
		_cast_tween = null
